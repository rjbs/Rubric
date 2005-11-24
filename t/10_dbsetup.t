#!perl -T
use Test::More tests => 4;
use File::Path qw(rmtree mkpath);

use_ok('Rubric::DBI::Setup');

rmtree("t/db");
mkpath("t/db");

eval { Rubric::DBI::Setup->setup_tables };

ok(not($@), "set up empty rubric testing db");

cmp_ok(Rubric::DBI::Setup->determine_version, '==', 10, "got current schema");

cmp_ok(Rubric::DBI::Setup->update_schema, '==', 10, "update (nop) to current");
