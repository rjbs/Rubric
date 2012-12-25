use strict;
use warnings;
package Rubric::WebApp;
# ABSTRACT: the web interface to Rubric

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Rubric::WebApp;
 Rubric::WebApp->new->run();

It's a CGI::Application!

=head1 DESCRIPTION

Rubric::WebApp provides a CGI-based interface to Rubric data.  It's built on
top of CGI::Application, which does most of the boring work.  This module's
code sets up the dispatch tables and implements the responses to various
queries.

=head1 REQUESTS DISPATCH

Requests are I<mostly> path-based, though some involve form submission.  The
basic dispatch table looks something like this:

 request      | description                               | method called
 -------------+-------------------------------------------+--------------
 /login       | log in to a user account                  | login
 /logout      | log out                                   | logout
 /preferences | view or change account settings           | preferences
 /newuser     | create a new user account                 | newuser
 /verify      | verify a pending user account             | verify
 /link        | view the details of entries for a link    | link
 /post        | post or edit an entry (must be logged in) | post
 /edit        | edit an entry (must be logged in)         | edit
 /delete      | delete an entry (must be logged in)       | delete
 /entry/ENTRY | find and display the identified entry     | entry
 /entries/Q   | find and display results for query Q      | entries
 /~USER/TAGS  | see a user's entries for given tags       | (in flux)
 /doc/PAGE    | view the named page in the documentation  | doc
 /style/PAGE  | get the named style sheet                 | style

If the system is private and no user is logged in, the default action is to
display a login screen.  If the system is public, or a user is logged in, the
default action is to display entries.

=cut

use CGI::Application 3;
use base qw(CGI::Application);
use CGI::Carp qw(fatalsToBrowser);

use Digest::MD5 qw(md5_hex);
use Encode 2 qw(decode_utf8);

use HTML::TagCloud;
use DateTime;

use Email::Address;
use Email::Sender::Simple qw(sendmail);

use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;
use Rubric::WebApp::URI;
use Rubric::WebApp::Session;

use String::Truncate qw(elide);

=head1 METHODS

=head2 redirect($uri, $message)

This method simplifies redirection; it redirects to the given URI, printing the
given message as the body of the HTTP response.

=cut

sub redirect {
  my ($self, $uri, $message) = @_;

  $self->header_type('redirect');
  $self->header_props(-url=> $uri);
  return $message;
}

=head2 redirect_root($message)

This is shorthand to redirect to the Rubric's root URI.  It calls C<redirect>.

=cut

sub redirect_root {
  my ($self, $message) = @_;

  return $self->redirect(Rubric::Config->uri_root, $message);
}

=head2 cgiapp_init

This method is called during CGI::Application's initialization.  It sets up the
session configuration.

=cut

sub cgiapp_init {
  my ($self) = @_;

  my $login_class = Rubric::Config->login_class;

  ## no critic (StringyEval)
  eval("require $login_class; 1") or die;
  ## use critic
  $login_class->check_for_login($self);
}

=head2 cgiapp_prerun

This method is called before the selected runmode.  It checks for a login,
checks for updates to result-set paging, and starts processing the request
path.

=cut

sub cgiapp_prerun {
  my ($self) = @_;

  $self->check_pager_data;

  my @path = split '/', $self->query->path_info;
  $self->param(path => [ @path[ 2 .. $#path ] ]);
}

=head2 next_path_part

This method shifts the next item off of the request path and returns it.

=cut

sub next_path_part {
  my ($self) = @_;
  shift @{$self->param('path')};
}

=head2 check_pager_data

This method is called by C<cgiapp_init>, and sets up parameters used for paging
entry listings.  The following parameters are used:

 per_page - how many items per page; default 25, maximum 100; stored in session;
 page     - which page to display; default 1

=cut

sub check_pager_data {
  my ($self) = @_;

  $self->session->param('per_page', int(
    $self->query->param('per_page')
    || $self->session->param('per_page')
    || Rubric::Config->default_page_size
  ));

  $self->session->param('per_page', Rubric::Config->max_page_size)
     if $self->session->param('per_page') > Rubric::Config->max_page_size;

  $self->param('per_page', $self->session->param('per_page'));
  $self->param('page',     int(($self->query->param('page') || 1)));
}

=head2 template($template, \%variables)

This method is used to render a template with both provided and default
variables.

Templates are rendered by calling the C<process> method on the template
renderer, which is retrieved by calling the C<renderer> method on the WebApp.

The following variables are passed by default:

 current_user - the currently logged-in user (a Rubric::User object)
 per_page     - entries per page (see check_pager_data)
 page         - which page (see check_pager_data)

=cut

sub template {
  my ($self, $template, $stash) = @_;
  $stash ||= {};
  $stash->{current_user} = $self->param('current_user');
  $stash->{per_page} = $self->param('per_page');
  $stash->{page} = $self->param('page');

  my $type = $self->query->param('format');
     $type = 'html' unless $type and $type =~ /^[\pL\d_]+$/;

  my ($content_type, $output) =
    Rubric::Renderer->process($template, $type, $stash);

  $self->header_add(-type => $content_type);
  return $output;
}

=head2 setup

This method, called by CGI::Application's initialization process, sets up
the dispatch table for requests, as described above.

=cut

sub setup {
  my ($self) = @_;

  $self->mode_param(path_info => 1);

  $self->start_mode('login');
  $self->run_modes([ qw(style doc login newuser reset_password verify) ]);

  if ($self->param('current_user') or not Rubric::Config->private_system) {
    $self->start_mode('entries');
    $self->run_modes([
      qw(delete edit entries entry link logout post preferences tag_cloud calendar)
    ]);
  }

  $self->run_modes(AUTOLOAD => '_default_handler');
}

sub _default_handler {
  my ($self, $runmode) = @_;
  if (substr($runmode, 0, 1) eq '~') {
    return $self->_entries_shortcut(substr($runmode, 1));
  }
  $self->redirect_root;
}

sub _entries_shortcut {
  my ($self, $user) = @_;
  my $path = $self->param('path');

  # If there the number of elements in the path is odd, the first one is tags;
  # otherwise, it's a normal query; this may or may not be safe, in the end.  I
  # guess we'll find out. -- rjbs, 2006-02-20
  unshift @$path, 'tags' if @$path % 2;
  unshift @$path, 'user', $user;

  $self->entries;
}

=head2 entries

This passes off responsibility to the class named in the C<entries_query_class>
configuration option.  This option defaults to Rubric::WebApp::Entries.

=cut

sub entries {
  my ($self) = @_;

  my $entries_class = Rubric::Config->entries_query_class;
  ## no critic (StringyEval)
  die $@ unless eval "require $entries_class";
  ## use critic
  $entries_class->entries($self);
}

=head2 entry

This displays the single requested entry.

=cut

sub entry {
  my ($self) = @_;

  my $entry = $self->get_entry;

  return $self->template('no_entry', { reason => 'missing' }) unless $entry;

  return $self->template('no_entry', { reason => 'access' })
    if  grep { $_ eq Rubric::Config->private_tag } $entry->tags
    and (not $self->param('current_user')
         or  $entry->user ne $self->param('current_user'));

  $self->template('entry_long' => {
    entry             => $self->param('entry'),
    self_url          => $self->query->self_url(),
    # FIX ME: hack to put the title of the entry in the <title> tag
    query_description => $entry->title,
    long_form         => 1
  });
}

=head2 get_entry

This method gets the next part of the path, assumes it to be a Rubric::Entry
id, and puts the corresponding entry in the "entry" parameter.

=cut

sub get_entry {
  my ($self) = @_;

  my $entry = Rubric::Entry->retrieve($self->next_path_part);
  $self->param(entry => $entry);
}

=head2 link

This runmode displays entries that point to a given link, identified either by
URI or MD5 sum.

=cut

sub link {
  my ($self) = @_;
  return $self->redirect_root("...no such link") unless $self->get_link;
  $self->display_entries;
}

=head2 get_link

This method look for a C<uri> or, failing that, C<url> query parameter.  If
found, it finds a Rubric::Link for that URI and puts it in the "link"
parameter.

=cut

sub get_link {
  my ($self) = @_;
  my %search;
  $search{md5} = $self->query->param('md5');
  $search{uri} = $self->query->param('uri') || $self->query->param('url');
  for (qw(md5sum uri)) {
    delete $search{$_} unless $search{$_};
  }
  return unless %search;
  return unless my ($link) = Rubric::Link->search(\%search);
  $self->param('link', $link);
}

=head2 tag_cloud

=cut

sub tag_cloud {
  my ($self, $options) = @_;

  my $tags = Rubric::DBI->db_Main->selectall_arrayref(
     "SELECT tag, count(*)
        FROM entrytags
       WHERE tag not like '@%'
    GROUP BY tag
    ORDER BY tag");

  my $cloud = HTML::TagCloud->new();
  foreach my $tag (@$tags) {
    my $href = Rubric::WebApp::URI->entries({tags => [ $tag->[0] ]});
    $cloud->add($tag->[0], $href, $tag->[1]);
  }

  return $self->template('tag_cloud' => {
    cloud => $cloud,
    query_description => 'All Tags',
  });

}

=head2 calendar

=cut

sub calendar {
  my ($self, $options) = @_;
  my $path = $self->param('path');

  require HTML::CalendarMonth;

  my $year  = shift @$path;
  my $month = shift @$path;

  if (not ($year or $month)) {
    ($month, $year) = (localtime)[4,5];
    $month++;
    $year += 1900;
  }
  my $calendar = HTML::CalendarMonth->new(
    month => $month,
    year  => $year,
    full_days => 1
  );
  $calendar->item($calendar->year, $calendar->month)->attr(
    style => 'background-color: #EEEEEE'
  );
  $calendar->attr(class => 'calendar');
  $calendar->alldays->attr(class => 'day');
  my $num_span = HTML::Element->new('span', class => 'day_indicator');
  $calendar->alldays->attr(class => 'day');
  $calendar->alldays->wrap_content($num_span);
  $calendar->allheaders->attr(class => 'headers');

  my $start = DateTime->new(
    year   => $year,
    month  => $month,
    day    => 1,
    hour   => 0,
    minute => 0,
    second => 0,
    nanosecond => 0,
    time_zone => '-1700'
  )->epoch;

  my $end   = DateTime->new(
    year   => $year,
    month  => $month,
    day    => $calendar->lastday,
    hour   => 23,
    minute => 59,
    second => 59,
    nanosecond => 0,
    time_zone  => '-1700'
  )->epoch;

  my $entries = Rubric::Entry->retrieve_from_sql(qq{
      WHERE id NOT IN (SELECT entry FROM entrytags WHERE tag = '\@private')
        AND created > '$start'
        AND created < '$end'
   ORDER BY created}
  );

  while (my $entry = $entries->next) {
    my ($day) = $entry->created->day_of_month;
    my $a = HTML::Element->new('a');
    my $div = HTML::Element->new('div');
    my $title = $entry->title;
    $a->attr(title => $title);
    $a->attr(href  => Rubric::WebApp::URI->entry($entry));
    $title = elide($title, 18);
    $a->push_content($title);
    $div->push_content($a);
    $calendar->item($day)->push_content($div);
  }

  my $prev_month = $month;
  my $prev_year = $year;
  $prev_month --;
  if (not $prev_month) {
    $prev_month = 12;
    $prev_year--;
  }

  my $next_month = $month;
  my $next_year = $year;
  $next_month++;
  if ($next_month > 12) {
    $next_month = 1;
    $next_year++;
  }

  return $self->template('calendar' => {
    calendar => $calendar,
    prev_link => {
      month => sprintf("%02d", $prev_month),
      year  => $prev_year,
    },
    next_link => {
      month => sprintf("%02d", $next_month),
      year  => $next_year,
    },
    query_description => 'Calendar',
  });

}

=head2 login

If the user is logged in, this request is immediately redirected to the root of
the Rubric site.  Otherwise, a login form is provided.

=cut

sub login {
  my ($self) = @_;

  if ($self->param('current_user')) {
    my $goto = $self->query->param('then_goto') || Rubric::Config->uri_root;
    return $self->redirect($goto, "Logged in...");
  }

  my $note;
  if ($self->get_current_runmode ne 'login') {
    $note = "You must log in to use this feature.";
    $self->query->param('then_goto', $self->query->self_url);
  }

  $self->template('login' => {
    note      => $note,
    then_goto => scalar $self->query->param('then_goto'),
    user      => scalar $self->query->param('user'),
    user_pending => scalar $self->param('user_pending')
  });
}

=head2 logout

This run mode unsets the "current_user" parameter in the session and the WebApp
object, then redirects the user to the root of the Rubric site.

=cut

sub logout {
  my ($self) = @_;
  $self->session->clear('current_user');
  $self->param('current_user', undef);

  return $self->redirect_root("Logged out...");
}

=head2 reset_password

This run mode allows a user to request that his password be reset and emailled
to him.

=cut

sub reset_password {
  my ($self) = @_;
  my $user       = $self->get_user
                   || $self->query->param('user')
                   && Rubric::User->retrieve($self->query->param('user'));
  my $reset_code = $self->get_reset_code;

  return $self->template("reset_login") unless $user;

  return $self->setup_reset_code($user) unless $reset_code;

  if (my $password = $user->reset_password($reset_code)) {
    $self->template("reset", { password => $password });
  } else {
    return $self->template("reset_error");
  }

}

=head2 setup_reset_code

This routine gets a reset code for the user and emails it to him.

=cut

sub setup_reset_code {
  my ($self, $user) = @_;

  my $reset_code = $user->randomize_reset_code;

  $self->send_reset_email_to($user, $reset_code);
  $self->template("reset_sent");
}

=head2 preferences

This method displays account information for the current user.  Some account
settings may be changed.

=cut

sub preferences {
  my ($self) = @_;

  return $self->login unless $self->param('current_user');

  return $self->template("preferences")
    unless my %prefs = $self->_get_prefs_form;

  if (my %errors = $self->validate_prefs(\%prefs)) {
    return $self->template("preferences", { %prefs, %errors } );
  }

  $self->update_user(\%prefs);
}

=head2 update_user(\%prefs)

This method will update the current user object with the changes in C<%prefs>,
which is passed by the C<preferences> method.

=cut

sub update_user {
  my ($self, $prefs) = @_;
  for ($self->param('current_user')) {
    $_->password(md5_hex($prefs->{password_1})) if $prefs->{password_1};
    $_->email($prefs->{email});
    $_->update;
  }
  $self->redirect_root('updated');
}

sub _get_prefs_form {
  my ($self) = @_;

  my %form;
  for (qw(password password_1 password_2 email)) {
    $form{$_} = $self->query->param($_) if $self->query->param($_);
  }
  return %form;
}

=head2 validate_prefs(\%prefs)

Given a set of preference updates from a form submission, this method validates
them and returns a description of the validation results.  This method will
probably be redesigned (possibly with Data::FormValidator) in the future.
Don't count on its interface.

=cut

=begin future

sub validate_prefs {
  my ($self, $prefs) = @_;
  require Data::FormValidator;

  my $profile = {
    required     => [qw(password)],
    optional     => [qw(password_1 password_2 email)],
    constraints  => {
      email => 'email',
      password_1 => {
        params     => [qw(password_1 password_2)],
        constraint => sub { $_[0] eq $_[1] },
      }
    },
    dependency_groups => { new_password => [qw(password_1 password_2)] }
  };

  my $results = Data::FormValidator->check($prefs, $profile);
}

=end future

=cut

sub validate_prefs {
  my ($self, $prefs) = @_;
  my %errors;

  if (not $prefs->{email}) {
    $errors{email_missing} = 1;
  } elsif ($prefs->{email} and $prefs->{email} !~ $Email::Address::addr_spec) {
    undef $prefs->{email};
    $errors{email_invalid} = 1;
  }

  if (
    $prefs->{password_1} and $prefs->{password_2}
    and $prefs->{password_1} ne $prefs->{password_2}
  ) {
    undef $prefs->{password_1};
    undef $prefs->{password_2};
    $errors{password_mismatch} = 1;
  }

  unless ($prefs->{password}) {
    $errors{password_missing} = 1;
  } elsif (
    md5_hex($prefs->{password}) ne $self->param('current_user')->password
  ) {
    $errors{password_wrong} = 1;
  }

  return %errors;
}

=head2 newuser

If the proper form information is present, this runmode creates a new user
account.  If not, it presents a form.

If a user is already logged in, the user is redirected to the root of the
Rubric.

=cut

sub newuser {
  my ($self) = @_;

  return $self->redirect_root("registration is closed...")
    if Rubric::Config->registration_closed;

  return $self->redirect_root("Already logged in...")
    if $self->param('current_user');

  my %newuser;
  $newuser{$_} = $self->query->param($_)
    for qw(username password_1 password_2 email);

  my %errors = $self->validate_newuser_form(\%newuser);
  if (%errors) {
    $self->template('newuser' => { %newuser, %errors });
  } else {
    $self->create_newuser(%newuser);
  }
}

=head2 validate_newuser_form(\%newuser)

Given a set of user data from a form submission, this method validates them and
returns a description of the validation results.  This method will probably be
redesigned (possibly with Data::FormValidator) in the future.  Don't count on
its interface.

=cut

sub validate_newuser_form {
  my ($self, $newuser) = @_;
  my %errors;

  if ($newuser->{username} and $newuser->{username} !~ /^[\pL\d_.]+$/) {
    undef $newuser->{username};
    $errors{username_invalid} = 1;
  } elsif (Rubric::User->retrieve($newuser->{username})) {
    undef $newuser->{username};
    $errors{username_taken} = 1;
  }

  unless ($newuser->{email}) {
    $errors{email_missing} = 1;
  } elsif ($newuser->{email} and $newuser->{email} !~ $Email::Address::addr_spec) {
    undef $newuser->{email};
    $errors{email_invalid} = 1;
  }

  if (
    $newuser->{password_1} and $newuser->{password_2}
    and $newuser->{password_1} ne $newuser->{password_2}
  ) {
    undef $newuser->{password_1};
    undef $newuser->{password_2};
    $errors{password_mismatch} = 1;
  }
  return %errors;
}

=head2 create_newuser(\%newuser)

This method creates a new user account from the given description.  It sends
the user a validation email (if needed) and displays an account creation page.

=cut

sub create_newuser {
  my ($self, %newuser) = @_;

  my %user = (
    username => $newuser{username},
    password => md5_hex($newuser{password_1}),
    email    => $newuser{email},
  );

  my $user = Rubric::User->create(\%user);

  unless (Rubric::Config->skip_newuser_verification) {
    $user->randomize_verification_code;
    $self->send_verification_email_to($user);
  }

  $self->template("account_created");
}

=head2 send_reset_email_to($user)

This method sends an email to the given user with a URI to reset his password.

=cut

sub send_reset_email_to {
  my ($self, $user) = @_;

  my $message = Rubric::Renderer->process(
    'reset_mail',
    'txt',
    { user => $user, email_from => Rubric::Config->email_from }
  );

  # XXX: This now ignores the smtp_server config.
  sendmail($message);
}

=head2 send_verification_email_to($user)

This method sends a verification email to the given user.

=cut

sub send_verification_email_to {
  my ($self, $user) = @_;

  my $message = Rubric::Renderer->process(
    'newuser_mail',
    'txt',
    { user => $user, email_from => Rubric::Config->email_from }
  );

  # XXX: This now ignores the smtp_server config.
  sendmail($message);
}

=head2 verify

This runmode attempts to verify a user account.  It expects a request to be
in the form: C< /verify/username/verification_code >

=cut

sub verify {
  my ($self) = @_;

  return $self->redirect_root("Already logged in...")
    if $self->param('current_user');

  my $user = $self->get_user;
  my $code = $self->get_verification_code;

  return $self->redirect_root("no such user")
    if defined $user and $user eq '';

  return $user->verify($code) ? $self->template('verified')
                              : $self->redirect_root("BAD USER NO VALIDATION");
}

=head2 get_reset_code

This gets the next part of the path and puts it in the C<reset_code>
parameter.

=cut

sub get_reset_code {
  my ($self) = @_;

  $self->param(reset_code => $self->next_path_part);
}

=head2 get_verification_code

This gets the next part of the path and puts it in the C<verification_code>
parameter.

=cut

sub get_verification_code {
  my ($self) = @_;

  $self->param(verification_code => $self->next_path_part);
}

=head2 get_user

This gets the next part of the path and puts it in the C<user> parameter.

=cut

sub get_user {
  my ($self) = @_;

  $self->param(user => Rubric::User->retrieve($self->next_path_part) || '');
}

=head2 display_entries

This method searches (with Rubric::Entry) for entries matching the requested
user and tags.  It pages the result (with C<page_entries>) and renders the
resulting page with C<render_entries>.

=cut

sub display_entries {
  my ($self) = @_;

  return $self->redirect_root("no such user")
    if defined $self->param('user') and $self->param('user') eq '';

  $self->param('has_body', scalar $self->query->param('has_body'));
  $self->param('has_link', scalar $self->query->param('has_link'));

  my %search = (
    user => $self->param('user'),
    tags => $self->param('tags'),
    link => $self->param('link'),
    has_body => $self->param('has_body'),
    has_link => $self->param('has_link'),
  );

  my $entries = Rubric::Entry->by_tag(\%search);

  $self->page_entries($entries)->render_entries;
}

=head2 page_entries($iterator)

Given a Class::DBI::Iterator, this method sets up parameters describing the
current page.  Most importantly, it retrieves an Iterator for the slice of
entries representing the current page.  The following parameters are set:

 entries - a Class::DBI::Iterator for the current page's entries
 count   - the number of entries in the entire set
 pages   - the number of pages the set spans

=cut

sub page_entries {
  my ($self, $iterator) = @_;

  my $first =  $self->param('per_page') * ($self->param('page')  - 1);
  my $last  = ($self->param('per_page') *  $self->param('page')) - 1;
  my $slice = $iterator->slice($first, $last);
  $self->param('entries', $slice);
  $self->param('count', $iterator->count);

  my $pagecount = int($iterator->count / $self->param('per_page'));
     $pagecount++ if  $iterator->count % $self->param('per_page');
  $self->param('pages', $pagecount);

  return $self;
}

=head2 render_entries

This method renders a template to display the set of entries set up by
C<page_entries>.

=cut

sub render_entries {
  my ($self, $options) = @_;
  $options ||= {};

  $self->template('entries' => {
    count   => $self->param('count'),
    entries => $self->param('entries'),
    pages   => $self->param('pages'),
    %$options,
    remove       => sub { [ grep { $_ ne $_[0] } @{$_[1]} ] },
    self_url     => $self->query->self_url(),
    long_form    => scalar $self->query->param('long_form'),
    recent_tags  => $self->param('recent_tags'),
    related_tags => scalar (($options->{user} || 'Rubric::EntryTag')
                    ->related_tags_counted($options->{tags})),
    query_description => $self->param('query_description'),
  });
}

=head2 edit

If the user isn't logged in, it redirects to demand a login.  If he is, it
displays a post form, completed with the given entry's data.

=cut

sub edit {
  my ($self) = @_;

  return $self->template('no_entry', { reason => 'missing' })
    unless $self->get_entry;

  return $self->template('no_entry', { reason => 'access' })
    unless $self->param('entry')->user eq $self->param('current_user');

  $self->param('existing_entry', $self->param('entry'));
  $self->param('existing_link',  $self->param('entry')->link);
  return $self->post_form();
}

=head2 post

This method wants to be simplified.

If the user isn't logged in, it redirects to demand a login.  If he is, it
checks whether it can create a new entry.  If so, it tries to.  If not, it
displays a form for doing so.  If the user already has an entry for the given
URI, the existing entry is passed to the form renderer.

If a new entry is created, the user is redirected to his entry listing.

=cut

sub _post_form_contents {
  my ($self) = @_;
  my (%form, %error);

  $form{$_} = $self->query->param($_)
    for qw(entryid uri title description tags body);

  for (qw(uri title description body tags)) {
    my $decoded;
    my $ok = eval {
      $decoded = decode_utf8($form{$_}, Encode::FB_CROAK | Encode::LEAVE_SRC);
      1;
    };
    $error{$_} = "Invalid characters in $_." unless $ok;
    $form{$_} = $decoded if $ok;
  }

  eval { $form{uri} = URI->new($form{uri})->canonical; };
  $error{uri} = "Invalid URI" if $@;

  if (
    $form{uri}
    and not $error{uri}
    and defined Rubric::Config->allowed_schemes
    and not grep { $_ eq $form{uri}->scheme } @{ Rubric::Config->allowed_schemes }
  ) {
    $error{uri} = "Invalid URI; valid schemes are: "
                . "@{ Rubric::Config->allowed_schemes }";
  }

  eval { Rubric::Entry->tags_from_string($form{tags}) };
  $error{tags} = "Tags may only contain letters, numbers, dot, colon, and asterisk." if $@;

  $error{title} = "You must supply a title." if
    $self->query->param('submit') and not length $form{title};

  if ($form{uri} and Rubric::Config->one_entry_per_link) {
    if (my ($link) = Rubric::Link->search({uri => $form{uri}})) {
      $self->param(existing_link => $link);
      if (my ($entry) = $self->param('current_user')->entries(link => $link)) {
        $self->param(existing_entry => $entry);
        # why was this a desired error message?
        # $error{uri} = "This will replace your current entry for this URI."
        #  if not $form{entryid};
      }
    }
  }

  return (\%form, \%error);
}

sub post {
  my ($self) = @_;

  return $self->login unless my $user = $self->param('current_user');

  my ($form, $error) = $self->_post_form_contents;

  return $self->post_form($form, $error)
    if not $self->query->param('submit')
        or %$error
        or not my $entry = $self->param('current_user')->quick_entry($form);

  my $when_done = $self->query->param('when_done');
  my $goto;

     if ($when_done eq 'close')   { return $self->template('close_window')     }
  elsif ($when_done eq 'entry')   { $goto = Rubric::WebApp::URI->entry($entry) }
  elsif ($when_done eq 'go_back') { $goto = $form->{uri}                       }
   else                           { $goto = $self->query->param('then_goto')   }

  $goto ||= Rubric::WebApp::URI->entries({user=> $self->param('current_user')});

  $self->redirect( $goto, "Posted..." );
}

=head2 post_form

This method renders a form for the user to create a new entry.

=cut

sub post_form {
  my ($self, $form, $error) = @_;

  $self->template( 'post' => {
    form           => $form,
    error          => $error,
    user           => scalar $self->param('current_user'),
    existing_entry => scalar $self->param('existing_entry'),
    existing_link  => scalar $self->param('existing_link'),
    then_goto      => scalar $self->query->param('then_goto'),
    when_done      => scalar $self->query->param('when_done'),
  });
}

=head2 delete

This method wants to be simplified.  It's largely copied from C<post>.

If the user isn't logged in, it redirects to demand a login.  If he is, it
checks whether the user has an entry for the given URI.  If so, it's deleted.

Either way, the user is redirected to his entry listing.

=cut

sub delete {
  my ($self) = @_;

  return $self->login unless my $user = $self->param('current_user');

  return $self->redirect_root("No such entry...")
    unless $self->get_entry;

  return $self->redirect_root("Not your entry...")
    unless $self->param('entry')->user eq $user;

  $self->param('entry')->delete;

  my $goto = $self->query->param('then_goto')
           || Rubric::WebApp::URI->entries({ username => $user });

  return $self->redirect( $goto, "Deleted..." );
}

=head2 doc

This runmode returns a mostly-static document from the template path.

=cut

sub doc {
  my ($self) = @_;

  $self->get_doc;
  my $output = eval { $self->template("docs/" . $self->param('doc_page')); };

  # XXX: this should instead redirect to a 404-page
  return $output ? $output : $self->redirect_root("no such document");
}

=head2 get_doc

This gets the next part of the path and puts it in the C<doc_page> parameter.

=cut

sub get_doc {
  my ($self) = @_;

  my $doc_page = $self->next_path_part;
  return $doc_page =~ /^[\pL\d_]+$/ ? $self->param(doc_page => $doc_page)
                                    : ();
}

=head2 style

This runmode sends the named stylesheet from the CSS path.

=cut

sub style {
  my ($self) = @_;

  my $sheet = $self->next_path_part;

  my $file = File::Spec->catfile('style', $sheet);

  $self->header_add(-type => 'text/css');
  my $tt = Template->new({
    INCLUDE_PATH => [
      Rubric::Config->template_path,
      File::Spec->catdir(File::ShareDir::dist_dir('Rubric'), 'templates'),
    ],
  });

  my $output;
  $tt->process($file,  {}, \$output);
  return $output;
}

1;
