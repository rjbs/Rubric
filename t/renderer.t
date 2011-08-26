#!perl

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric::Renderer"); }

my @output = Rubric::Renderer->process(login => html => {});
is($output[0], 'text/html; charset="utf-8"', "content-type of html output");
like( $output[1], qr(loginform), "template at least sort of works");

like(
	scalar Rubric::Renderer->process(login => html => {}),
	qr(loginform),
	"template at least sort of works"
);

is(
	Rubric::Renderer->process(login => jpeg => {}),
	undef,
	"can't process to unknown type"
);

eval { Rubric::Renderer->process(pants => html => {}) };
like($@, qr/Couldn't render template/, "can't render unknown template");
