package Rubric::CLI::Command::commands;

=head1 NAME

Rubric::CLI::Command::command - command to list Rubric commands

=head1 VERSION

 $Id$

=cut

use Getopt::Long::Descriptive;

sub execute {
  my ($class) = @_;

  for (keys %main::plugin) {
    printf "%10s: %s\n", $_, $main::plugin{$_};
  }
}

1;
