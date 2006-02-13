#!perl
#!perl -T
package Rubric::Test::DBSetup;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(init_test_db_ok load_test_data_ok);

use Test::More;

use Digest::MD5 qw(md5_hex);
use File::Path qw(rmtree mkpath);
use Rubric::DBI::Setup;
use YAML;

sub init_test_db_ok {
  rmtree("t/db");
  mkpath("t/db");

  eval { Rubric::DBI::Setup->setup_tables; };
  if ($@) {
    fail "couldn't init test database: $@";
  } else {
    pass "initialized test database";
  }
}

sub load_test_data_ok {
  my ($filename) = @_;
  return unless -r $filename;
  my $data = YAML::LoadFile($filename);

  eval {
    _load_users($data->{users});
    _load_entry($_) for @{ $data->{entries} };
  };
  if ($@) {
    fail "couldn't load test data in $filename: $@";
  } else {
    pass "loaded test data in $filename: $@";
  }
}

sub _load_users {
  my ($user) = @_;

  for my $username (keys %$user) {
    my $user = $user->{ $username };

    #Rubric::User->db_Main->trace(2);

    Rubric::User->create({
      username => $username,
      password => md5_hex($user->{password}),
      email    => $user->{email},
    });
  }
}

sub _load_entry {
  my ($entry) = @_;

  for my $username (@{ $entry->{users} }) {
    my $user = Rubric::User->retrieve($username);

    my $user_entry = $user->quick_entry({
      uri   => $entry->{uri},
      title => $entry->{title},
      body  => $entry->{body},
      tags  => $entry->{tags},
      description => $entry->{description},
    });

    if ($entry->{created}) {
      my $now = ($entry->{created} eq 'now');
      my $ctime = $now ? time : $entry->{created};

      if (my $var = $entry->{created_variance}) {
        if ($now) {
          $ctime -= int(rand($var));
        } else {
          $ctime += int(rand($var/2 + 1)) - $var / 2;
        }
      }

      $user_entry->created($ctime);
      $user_entry->update;
    }

  }
}

1;
