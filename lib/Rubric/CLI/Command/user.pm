use strict;
use warnings;
package Rubric::CLI::Command::user;
# ABSTRACT: Rubric user management commands

use parent qw(Rubric::CLI::Command);

use Digest::MD5 qw(md5_hex);
use Rubric::User;

sub usage_desc { "rubric user %o [username]" }

sub opt_spec {
  return (
    [ "new-user|n",        "add a user (requires --email and --password)" ],
    [ "activate|a",        "activate an existing user"                    ],
    [ "password|pass|p=s", "set user's password"                          ],
    [ "email|e=s",         "set user's email address"                     ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  die $self->usage->text unless @$args == 1;
}

sub run {
  my ($self, $opt, $args) = @_;

  my $username = $args->[0];

  die "--new-user and --activate are mutually exclusive"
    if $opt->{new_user} and $opt->{activate};

  if ($opt->{new_user}) {
    die "--new-user requries --email and --password"
      unless $opt->{email} and $opt->{password};

    my $user = Rubric::User->create({
      username => $username,
      password => md5_hex($opt->{password}),
      email    => $opt->{email},
    });

    die "couldn't create user" unless $user;

    print "created user $user";
    exit;
  }

  my $user = Rubric::User->retrieve($username);

  die "couldn't find user for '$username'" unless $user;

  if ($opt->{activate}) {
    $user->verification_code(undef);
    print "activated user account\n";
  }

  if ($opt->{email}) {
    $user->email($opt->{email});
    print "changed email\n";
  }

  if ($opt->{password}) {
    $user->password(md5_hex($opt->{password}));
    print "changed password\n";
  }

  $user->update;

  print "username: ", $user->username, "\n";
  print "email   : ", $user->email,    "\n";
}

1;
