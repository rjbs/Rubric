use strict;
use warnings;
package Rubric::WebApp::Entries;
# ABSTRACT:  process the /entries run method

=head1 DESCRIPTION

Rubric::WebApp::Entries implements a URI parser that builds a query based
on a query URI, passes it to Rubric::Entries, and returns the rendered report
on the results.

=cut

use Date::Span 1.12;
use Digest::MD5 qw(md5_hex);

use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;
use Rubric::WebApp::URI;

=head1 METHODS

=head2 entries($webapp)

This method is called by Rubric::WebApp.  It returns the rendered template for
return to the user's browser.

=cut

sub entries {
	my ($self, $webapp) = @_;
	my %arg;

	while (my $param = $webapp->next_path_part) {
		my $value = $webapp->next_path_part;
		$arg{$param} = $self->get_arg($param, $value);
	}
	if (my $uri = $webapp->query->param('uri')) {
		$arg{urimd5} = md5_hex($uri) unless $arg{urimd5};
	}

	for (qw(like desc_like body_like)) {
		if (my $param = $webapp->query->param($_)) {
			$arg{$_} = $self->get_arg($_, $param);
		}
	}

	unless (%arg) {
		$webapp->param(recent_tags => Rubric::Entry->recent_tags_counted);
		$arg{first_only} = 1 unless %arg;
	}

	my $user     = $webapp->param('current_user');
	my $order_by = $webapp->query->param('order_by');

	my $entries = Rubric::Entry->query(\%arg,
	                                   { user => $user, order_by => $order_by });
	$webapp->param(query_description => $self->describe_query(\%arg));

	$webapp->page_entries($entries)->render_entries(\%arg);
}

=head2 describe_query(\%arg)

returns a human-readable description of the query described by C<%args>

=cut

sub describe_query {
	my ($self, $arg) = @_;
	my $desc;
	$desc .= "$arg->{user}'s " if $arg->{user};
	$desc .= "entries";
	for (qw(body link)) {
		if (defined $arg->{"has_$_"}) {
			$desc .= " with" . ($arg->{"has_$_"} ? "" : "out") . " a $_,";
		}
	}
	if ($arg->{exact_tags}) {
    if (%{ $arg->{exact_tags} }) {
      $desc .= " filed under { "
            .  join(', ',
               map { defined $arg->{exact_tags}{$_}
                   ? "$_:$arg->{exact_tags}{$_}"
                   : $_ }
               keys %{$arg->{exact_tags}}) . " } exactly";
    } else {
      $desc .= " without tags"
    }
	} elsif ($arg->{tags} and %{ $arg->{tags} }) {
		$desc .= " filed under { "
          .  join(', ',
             map { defined $arg->{tags}{$_} ?  "$_:$arg->{tags}{$_}" : $_ }
             keys %{$arg->{tags}}) . " }";
	}
	$desc =~ s/,\Z//;
	return $desc;
}

=head2 get_arg($param => $value)

Given a name/value pair from the path, this method will attempt to
generate part of hash to send to << Rubric::Entry->query >>.  To do this, it
looks for and calls a method called "arg_for_NAME" where NAME is the passed
value of C<$param>.  If no clause can be generated, it returns undef.

=cut

sub get_arg {
	my ($self, $param, $value) = @_;

	return unless my $code = $self->can("arg_for_$param");
	$code->($self, $value);
}

=head2 arg_for_NAME

Each of these functions returns the proper value to put in the hash passed to
C<< Rubric::Entries->query >>.  If given an invalid argument, they will return
undef.

=head3 arg_for_user($username)

Given a username, this method returns the associated Rubric::User object.

=cut

sub arg_for_user {
	my ($self, $user) = @_;
	return unless $user;
	return Rubric::User->retrieve($user) || ();
}

=head3 arg_for_tags($tagstring)

=head3 arg_for_exact_tags($tagstring)

Given "happy fuzzy bunnies" this returns C< [ qw(happy fuzzy bunnies) ] >

=cut

sub arg_for_tags {
	my ($self, $tagstring) = @_;

	my $tags;
	eval { $tags = Rubric::Entry->tags_from_string($tagstring) };
	return $tags;
}

sub arg_for_exact_tags { (shift)->arg_for_tags(@_) }

=head3 arg_for_desc_like

=cut

sub arg_for_desc_like {
	my ($self, $value) = @_;
	return $value;
}

=head3 arg_for_body_like

=cut

sub arg_for_body_like {
	my ($self, $value) = @_;
	return $value;
}

=head3 arg_for_like

=cut

sub arg_for_like {
	my ($self, $value) = @_;
	return $value;
}

=head3 arg_for_has_body($bool)

Returns the given boolean as 0 or 1.

=cut

sub arg_for_has_body {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

=head3 arg_for_has_link($bool)

Returns the given boolean as 0 or 1.

=cut

sub arg_for_has_link {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

=head3 arg_for_first_only($bool)

Returns the given boolean as 0 or 1.

=cut

sub arg_for_first_only {
	my ($self, $bool) = @_;
	return $bool ? 1 : 0;
}

=head3 arg_for_urimd5($md5sum)

This method returns the passed value, if that value is a valid 32-character
md5sum.

=cut

sub arg_for_urimd5 {
	my ($self, $md5) = @_;
	return unless $md5 =~ /\A[a-z0-9]{32}\Z/i;
	return $md5;
}

=head3 arg_for_{timefield}_{preposition}($datetime)

These methods correspond to those described in L<Rubric::Entry::Query>.

They return the passed string unchanged.

=cut

## more date-arg handling code
{
  ## no critic (ProhibitNoStrict)
	no strict 'refs';
	for my $field (qw(created modified)) {
		for my $prep (qw(after before on)) {
			*{"arg_for_${field}_${prep}"} = sub {
				my ($self, $datetime) = @_;
				return $datetime;
			}
		}
	}
}

1;
