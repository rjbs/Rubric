#!perl
#!perl -T
package Rubric::Test::DBSetup;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT = qw(init_test_db_ok load_test_data_ok tests_for_dataset);

use Test::More;

use Digest::MD5 qw(md5_hex);
use File::Copy;
use File::Spec;
use File::Path qw(rmtree mkpath);
use Rubric::DBI::Setup;
use YAML::XS qw(LoadFile);

sub init_test_db_ok {
  mkpath("t/db");
  unlink("t/db/rubric.db");

  eval { Rubric::DBI::Setup->setup_tables; };
  if ($@) {
    fail "couldn't init test database: $@";
  } else {
    pass "initialized test database";
  }
}

sub _cache_db    { "t/db/$_[0].db"; }
sub _have_cached { return -r _cache_db($_[0]); }

sub tests_for_dataset {
  my ($dataset_name) = @_;

  my $tests = 1; # to copy to/from the cache
  # just copy the cached, if we can
  return $tests if _have_cached($dataset_name);

  # otherwise, let's figure this out...
  $tests += 1; # to initialize the database

  my $filename = "t/dataset/$dataset_name.yml";
  my $data = LoadFile($filename);

  for my $user (values %{ $data->{users} }) {
    $tests += 1; # to load the user
    $tests += @{ $user->{entries} };
  }

  return $tests;
}

sub load_test_data_ok {
  my ($dataset_name) = @_;
  my $filename = "t/dataset/$dataset_name.yml";
  die "$filename doesn't exist or isn't readable" unless -r $filename;

  my $cached_db = _cache_db($dataset_name);

  if (_have_cached($dataset_name)) {
    return ok(
      (copy $cached_db => 't/db/rubric.db'),
      "restored $dataset_name dataset from cache"
    );
  }

  init_test_db_ok;

  my $data = LoadFile($filename);

  eval {
    _load_users($data->{users});
  };
  if ($@) {
    fail "couldn't load test data in $filename: $@";
  } else {
    copy 't/db/rubric.db' => $cached_db;
    pass "loaded test data in $filename";
  }
}

sub _load_users {
  my ($user) = @_;

  for my $username (keys %$user) {
    my $user = $user->{ $username };

    my $user_obj = Rubric::User->create({
      username => $username,
      password => md5_hex($user->{password}),
      email    => $user->{email},
    });

    isa_ok($user_obj, 'Rubric::User', "created user ($username)");
    _load_entry($user_obj, $_) for @{ $user->{entries} };
  }
}

sub _load_entry {
  my ($user, $entry) = @_;

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

  isa_ok(
    $user_entry,
    'Rubric::Entry',
    (sprintf "entry (%u) for user (%s)", $user_entry->id, $user->username),
  );
}

1;
