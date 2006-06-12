#!perl -T

use Test::More 'no_plan';
use strict;
use warnings;

BEGIN { use_ok("Rubric::Config", 'etc/rubric.yml'); }

use YAML;

my $config = YAML::LoadFile("etc/rubric.yml");

for (keys %{Rubric::Config->_template}) {
	my $expected = exists $config->{$_} ? $config->{$_}
	                                   : Rubric::Config->_template->{$_};
	is_deeply(Rubric::Config->$_, $expected, "value of $_");
}

