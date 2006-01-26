package Rubric::CLI::Command::db;
use base qw(Rubric::CLI::Command);

=head1 NAME

Rubric::CLI::Command::db - database management

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use Rubric::DBI::Setup;

sub describe_options {
  my ($opt, $usage) = Getopt::Long::Descriptive::describe_options(
    "rubric database %o",
    [ mode => hidden => {
      one_of => [
        [ "setup|s",  "set up a new database"       ],
        [ "update|u", "update your database schema" ],
      ],
      }
    ],
  );

  die $usage->text unless $opt->{mode};
  return ($opt, $usage);
}

sub execute {
  my ($class) = @_;
  my ($opt, $usage) = $class->describe_options;

  if ($opt->{mode} eq 'super') {
    Rubric::DBI::Setup->setup_tables;
  } elsif ($opt->{update} eq 'update') {
    Rubric::DBI::Setup->update_schema;
  }
}

1;
