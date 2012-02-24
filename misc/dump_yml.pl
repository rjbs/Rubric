#!perl
# PODNAME: rubric-dump
use strict;
use warnings;

use Getopt::Long::Descriptive;
use Rubric::User;
use YAML::XS;

my ($opt, $usage) = describe_options(
  "rubric-dump %o <user>",
);

my $username = $ARGV[0] || $ENV{USER} || die $usage->text;

die "couldn't find user for username '$username'\n"
  unless my $user = Rubric::User->retrieve($username);

sub entry_to_hash {
  my ($entry) = @_;

  my $hash = {};
  for (qw(id link title description created modified body)) {
    $hash->{$_} = "" . $entry->$_ if $entry->$_;
  }

  my $time_piece;
  for (qw(created modified)) {
    $time_piece = Time::Piece->strptime($hash->{$_}, "%a %b %d %T %Y");
    $hash->{$_} = $time_piece->epoch;
  }

  for my $entrytag ($entry->entrytags) {
    $hash->{tags}->{ $entrytag->tag } = $entrytag->tag_value;
  }

  return $hash;
}

my $dbh = Rubric::User->db_Main;

my $entry_iterator = $user->entries;

my @entries;

while (my $entry = $entry_iterator->next) {
  push @entries, entry_to_hash($entry);
}

print Dump(\@entries);
