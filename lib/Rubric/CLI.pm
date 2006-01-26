package Rubric::CLI;

=head1 NAME

Rubric::CLI - the Rubric command line interface

=head1 VERSION

 $Id$

=cut

use strict;
use warnings;

use Module::Pluggable search_path => qw(Rubric::CLI::Command);
use UNIVERSAL::moniker;
use UNIVERSAL::require;

my @plugins = __PACKAGE__->plugins;

my %plugin;
for (@plugins) {
  my $command = lc $_->moniker;

  die "two plugins exist for command $command: $_ and $plugin{$command}\n"
    if exists $plugin{$command};
  
  $plugin{$command} = $_;
}

=head1 METHODS

=head2 C< commands >

This returns the commands currently provided by Rubric::CLI plugins.

=cut

sub commands {
  keys %plugin;
}

=head2 C< plugin_for >

  my $plugin = Rubric::CLI->plugin_for($command);

This method requires and returns the plugin (module) for the given command.  If
no plugin implements the command, it returns false.

=cut

sub plugin_for {
  my ($self, $command) = @_;
  return unless exists $plugin{ $command };

  my $plugin = $plugin{ $command };
  $plugin->require or die $@;

  return $plugin;
}

1;
