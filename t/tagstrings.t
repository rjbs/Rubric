#!perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }

use Rubric::Entry;

my @tagstrings = (
  [ ''                   => {} ],
  [ 'foo'                => { foo => undef } ],
  [ 'foo bar'            => { foo => undef, bar => undef } ],
  [ 'foo baz:peanut bar' => { foo => undef, bar => undef, baz => 'peanut' } ],
  [ 'foo baz: bar'       => { foo => undef, bar => undef, baz => ''       } ],
  [ 'bad()tag foo bar'   => undef ],
  [ 'bad:tag|value foo'  => undef ],
);

for (@tagstrings) {
  my ($string, $expected_tags) = @$_;

  my $tags = eval { Rubric::Entry->tags_from_string($string); };

  is_deeply(
    $tags,
    $expected_tags,
    "tags from <$string>" . (! defined $expected_tags ? ' (invalid)' : ''),
  );
}
