#!perl -T

use Test::More;
use Rubric::Config 't/config/rubric.yml';

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

all_pod_coverage_ok(
  {
    coverage_class => 'Pod::Coverage::CountParents',
    trustme => [
      qr/_for_(?:created|modified)_(?:on|after|before)\Z/,
      'describe_options',
      'as_html',
      'as_text',
      'accessor_name_for',
    ]
  },
);
