#!perl
#!perl -T

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Entry"); }

# XXX: ugly, relies on guts -- rjbs, 2006-02-11
Rubric::Config->markup_formatter->{test} = 'Rubric::Entry::Formatter::TEST';

my $entry = Rubric::Entry->retrieve(1);
isa_ok($entry, 'Rubric::Entry');

{ # when we start, there is no body
  my $body = $entry->body;
  ok(!$body, "our first entry is bodiless");
  TODO: {
    local $TODO = "body should be NOT NULL and use ''";
    is($body, '', "our first entry is empty string");
  }

  my $html = $entry->body_as('html');
  is($html, '', "its body as html is ''");

  my $text = $entry->body_as('text');
  is($text, '', "its body as text is ''");
}

# so let's create a body
my $boilerplate = 'This is a test body.';
$entry->body($boilerplate);
$entry->update;

{
  my $body = $entry->body;
  is($body, $boilerplate, "we have the body we just stored");

  my $html = $entry->body_as('html');
  like(
    $html,
    qr{<p>\s*$boilerplate\s*</p>},
    'the body is normally htmlified'
  );

  my $text = $entry->body_as('text');
  is($text, $boilerplate, "the text is returned normally");
}

{ # now let's try with a custom formatter
  $entry->add_to_tags({ tag => '@markup', tag_value => 'test' });

  my $body = $entry->body;
  is($body, $boilerplate, "we have the body we had stored");

  my $html = $entry->body_as('html');
  is($html, "_FOO_ $boilerplate _BAR_", "our test formatter is used");

  my $text = $entry->body_as('text');
  is($text, "_FOO_ $boilerplate _BAR_", "our test formatter handles text too");
}

BEGIN {
  package Rubric::Entry::Formatter::TEST;
  sub as_html {
    my ($class, $arg) = @_;
    return '' unless $arg->{text};
    return "_FOO_ $arg->{text} _BAR_";
  }

  sub as_text {
    my ($class, $arg) = @_;
    return '' unless $arg->{text};
    return "_FOO_ $arg->{text} _BAR_";
  }
}
