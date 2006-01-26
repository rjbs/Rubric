package Rubric::CLI::Command::commands;

=head1 NAME

Rubric::CLI::Command::commands - list the rubric commands

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use base qw(Rubric::CLI::Command);

# stolen from ExtUtils::MakeMaker
sub _parse_abstract {
  my ($module) = @_;
  my $result;

  (my $pm_file = $module) =~ s!::!/!g;
  $pm_file .= '.pm';
  $pm_file = $INC{$pm_file};
  open my $fh, "<", $pm_file or return "(unknown)";

  local $/ = "\n";
  my $inpod = 0;
  while (<$fh>) {
    $inpod = /^=(?!cut)/ ? 1
           : /^=cut/     ? 0
           :               $inpod;
    next unless $inpod;
    chomp;
    next unless /^($module\s-\s)(.*)/;
    $result = $2;
    last;
  }
  return $result || "(unknown)";
} 

sub execute {
  my ($class) = @_;

  for my $command (sort Rubric::CLI->commands) {
    my $abstract = _parse_abstract(Rubric::CLI->plugin_for($command));
    printf "%10s: %s\n", $command, $abstract;
  }
}

1;
