package Rubric::CLI;

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

sub commands {
  keys %plugin;
}

sub plugin_for {
  my ($self, $command) = @_;
  return unless exists $plugin{ $command };

  my $plugin = $plugin{ $command };
  $plugin->require or die $@;

  return $plugin;
}

1;
