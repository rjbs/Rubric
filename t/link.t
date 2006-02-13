#!perl
#!perl -T

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric::Link"); }

{
	my ($link)
    = Rubric::Link->search({ uri => 'http://rjbs.manxome.org/journal/'});

	isa_ok($link, 'Rubric::Link');
	is(
		$link,
		"http://rjbs.manxome.org/journal/",
		"proper stringification"
	);
	cmp_ok($link->entry_count, '>', 0, "some entries for this link");

	is_deeply(
		$link->tags_counted,
		[ [ qw(@markup 1) ], [ qw(blog 3) ] ],
		"tags counted"
	);

	my $md5 = $link->md5;
	$link->_set_md5, 
	is($link->md5, $md5, "md5 doesn't change on recalc");
}
