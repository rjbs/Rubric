#!perl -T
use Test::More tests => 4;
use File::Path qw(mkpath);

use_ok('Rubric::DBI::Setup');

unlink("t/db/rubric.db") if -e "t/db/rubric.db";
mkpath("t/db") unless -d "t/db/";

eval { Rubric::DBI::Setup->setup_tables };

ok(not($@), "set up empty rubric testing db");

cmp_ok(Rubric::DBI::Setup->determine_version, '==', 9, "got current schema");

cmp_ok(Rubric::DBI::Setup->update_schema, '==', 9, "update (nop) to current");
