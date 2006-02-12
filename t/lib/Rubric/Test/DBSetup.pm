#!perl
#!perl -T
package Rubric::Test::DBSetup;

use strict;
use warnings;

use Test::More;
use File::Path qw(rmtree mkpath);
use Rubric::DBI::Setup;

sub init_test_db {
  rmtree("t/db");
  mkpath("t/db");

  return unless eval { Rubric::DBI::Setup->setup_tables; 1; };

  return 1;
}

1;
