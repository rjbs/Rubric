#!perl

use Test::More 'no_plan';
use strict;
use warnings;

BEGIN { use_ok("Rubric::Config", 'etc/rubric.yml'); }

use YAML::XS qw(LoadFile);

my $config = LoadFile("etc/rubric.yml");

for (keys %{Rubric::Config->_default}) {
	my $expected = exists $config->{$_} ? $config->{$_}
	                                   : Rubric::Config->_default->{$_};
	is(Rubric::Config->$_, $expected, "value of $_");
}

