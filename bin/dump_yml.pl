#!perl

use strict;
use warnings;

use Getopt::Long::Descriptive;
use Rubric::User;
use YAML;

my ($opt, $usage) = describe_options(
  "rubric-dump %o <user>",
);

my $username = $ARGV[0] || $ENV{USER} || die $usage->text;

my $user = Rubric::User->retrieve($username);

die "couldn't find user for username '$username'\n" unless $user;

my $dbh = Rubric::User->db_Main;

my $entries = $user->entries;

my %entry;

while (my $entry = $entries->next) {
  $entry{ $entry->id } = $entry;

	my $t = $dbh->selectall_arrayref("SELECT tag FROM entrytags WHERE entry=$_");
	$entries->{$_}{tags} = [ map { @$_ } @$t ];
}

print YAML::Dump([ values %$entries ]);
