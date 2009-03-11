use strict;
use warnings;
package Rubric::CLI::Command::db;
use base qw(Rubric::CLI::Command);
our $VERSION = '0.144';

=head1 NAME

Rubric::CLI::Command::db - database management

=head1 VERSION

version 0.144

=cut

use Rubric::DBI::Setup;

sub usage_desc { "rubric database %o" }

sub opt_spec {
  return (
    [ mode => hidden => {
      one_of => [
        [ "setup|s",  "set up a new database"       ],
        [ "update|u", "update your database schema" ],
      ],
      }
    ],
  );
}

sub validate_args {
  my ($self, $opt, $arg) = @_;

  die $self->usage->text unless $opt->{mode};
}

sub run {
  my ($self, $opt, $arg) = @_;

  if ($opt->{mode} eq 'setup') {
    Rubric::DBI::Setup->setup_tables;
  } elsif ($opt->{mode} eq 'update') {
    Rubric::DBI::Setup->update_schema;
  }
}

1;
