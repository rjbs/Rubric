#!perl
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 5;

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }

BEGIN { use_ok('Rubric::Test::DBSetup') };

init_test_db_ok;

cmp_ok(Rubric::DBI::Setup->determine_version, '==', 11, "got current schema");

cmp_ok(Rubric::DBI::Setup->update_schema, '==', 11, "update (nop) to current");
