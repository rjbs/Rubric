#!perl
#!perl -T
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 4;

BEGIN { use_ok('Rubric::Test::DBSetup') };

ok(Rubric::Test::DBSetup::init_test_db, "setup Rubric tables");

cmp_ok(Rubric::DBI::Setup->determine_version, '==', 10, "got current schema");

cmp_ok(Rubric::DBI::Setup->update_schema, '==', 10, "update (nop) to current");
