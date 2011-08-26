#!perl
#!perl

use Test::More 'no_plan';
use Time::Piece ();

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric::Entry"); }

use lib 't/lib';
use Rubric::Test::DBSetup;
load_test_data_ok('basic');


{
  my $now = Time::Piece->new(time);
  my $last_month = $now  -  86400 * 365;
  my $next_week  = $now  +  86400 *   7;

	my $entries = Rubric::Entry->query({
		user => Rubric::User->retrieve('eb'),
		tags => { 'news' => undef },
		created_after  => $last_month->strftime('%Y-%m'),
		created_on     => $now->strftime('%Y'),
		created_before => $next_week->strftime('%Y-%m-%d'),
		has_link => 1,
		has_body => 0
	});

	isa_ok($entries, 'Class::DBI::Iterator', '1st query result');
	cmp_ok($entries->count, '>', 0, "more than zero entries found");
}

{
	my $entries = Rubric::Entry->query({
		urimd5 => '3c57773b70f9678ed974b5eca73e2137',
		tags   => {}, # empty tags list imposes no constriant
	});

	isa_ok($entries, 'Class::DBI::Iterator', 'all entries for a URI (by md5)');
	cmp_ok($entries->count, '==', 3, "three entries found");
}

{
	my $entries = Rubric::Entry->query({
		urimd5 => '3c57773b70f9678ed974b5eca73e2137',
		tags   => {}, # empty tags list imposes no constriant
		first_only => 1,
	});

	isa_ok($entries, 'Class::DBI::Iterator', 'first entry for a URI');
	cmp_ok($entries->count, '==', 1, "one entry found");
}

{
	my $entries = Rubric::Entry->query({
		tags => { 'perl' => undef },
		femptons => 10**2
	});
	isa_ok($entries, 'Class::DBI::Iterator', 'unknown query param');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({
		exact_tags => { 'news' => undef },
	});
	isa_ok($entries, 'Class::DBI::Iterator', 'exact_tags query');
	cmp_ok($entries->count, '==', 1, "one entry found");
}

{
	my $entries = Rubric::Entry->query({});

	isa_ok($entries, 'Class::DBI::Iterator', 'universal query result');
	cmp_ok($entries->count, '>', 0, "more than zero entries found");
}

{
	my $entries = Rubric::Entry->query({ urimd5 => 'not_an_md5sum' });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (md5)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({ tags => undef });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (tags 1)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({ tags => 'foo' });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (tags 2)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({ created_on => 'last week' });

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (date)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query({
		user => undef,
		has_link => 0,
		has_body => 1,
	});

	isa_ok($entries, 'Class::DBI::Iterator', 'impossible query result (user)');
	cmp_ok($entries->count, '==', 0, "zero entries found");
}

{
	my $entries = Rubric::Entry->query(
		{ user => 'mxlptlyk' }
	);

	isa_ok($entries, 'Class::DBI::Iterator', 'context-less query for mxlptlyk');
	cmp_ok($entries->count, '==', 3, "three entries found");
}

{
	my $entries = Rubric::Entry->query(
		{ user => 'mxlptlyk' },
		{ user => 'eb'       }
	);

	isa_ok($entries, 'Class::DBI::Iterator', 'eb querying for mxlptlyk');
	cmp_ok($entries->count, '==', 2, "two entries found");
}

{
	my $entries = Rubric::Entry->query(
		{ user => 'mxlptlyk' },
		{ user => 'mxlptlyk' }
	);

	isa_ok($entries, 'Class::DBI::Iterator', 'mxlptlyk querying for himself');
	cmp_ok($entries->count, '==', 3, "three entries found");
}

{
	my $entries = Rubric::Entry->query({ like => 'lies' });

	isa_ok($entries, 'Class::DBI::Iterator', 'query for "lies"');
	cmp_ok($entries->count, '==', 1, "1 entry found");
}

{
	my $entries = Rubric::Entry->query({ body_like => 'lies' });

	isa_ok($entries, 'Class::DBI::Iterator', 'query bodies for "lies"');
	cmp_ok($entries->count, '==', 0, "no entries found");
}

{
	my $entries = Rubric::Entry->query({ desc_like => 'lies' });

	isa_ok($entries, 'Class::DBI::Iterator', 'query descs for "lies"');
	cmp_ok($entries->count, '==', 1, "one entry found");
}
