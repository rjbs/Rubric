#!perl

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Link"); }

{
	my $link = Rubric::Link->retrieve(2);
	isa_ok($link, 'Rubric::Link');
	is(
		$link,
		"http://rjbs.manxome.org/bryar/",
		"proper stringification"
	);
	cmp_ok($link->entry_count, '>', 0, "some entries for this link");

	is_deeply(
		$link->tags_counted,
		[ [ qw(blog 3) ]],
		"tags counted"
	);

	my $md5 = $link->md5;
	$link->_set_md5, 
	is($link->md5, $md5, "md5 doesn't change on recalc");
}
