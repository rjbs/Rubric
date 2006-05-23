#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }

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
