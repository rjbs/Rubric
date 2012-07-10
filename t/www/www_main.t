#!perl
use strict;
use warnings;

use Test::File::ShareDir -share => { -dist => { Rubric => 'share' } };

use Test::More 'no_plan';
use Test::WWW::Mechanize 1.04;

use lib 't/lib';
BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }

# setup the database a-fresh!
use Rubric::Test::DBSetup;

load_test_data_ok('basic');

# Setup Rubric Webserver
use Rubric::Test::Server;

my $server = Rubric::Test::Server->new;

my $root = $server->started_ok("start up my web server");

# Begin testing.
my $mech = Test::WWW::Mechanize->new;
$mech->get_ok($root, 'HTTP GET');

$mech->title_is('Rubric: entries', 'Correct <title>');

{ # general information-finding
  my @tag_links
    = $mech->find_all_links( url_regex => qr(\A\Q$root\E/entries/tags) );

  TODO: {
    local $TODO = "Why doesn't this work reliably yet?";
    is(@tag_links, 7, 'Count tag entry urls');
  }
}

{ # test all internal links
  my @links = $mech->find_all_links( url_regex => qr(\A\Q$root));
  $mech->link_status_is(\@links, 200, "the internal links are status 200");
}

for my $iteration (1 .. 2) { # login/logout
  my @links = $mech->find_all_links( url_regex => qr(\A\Q$root\E/login) );
  is(scalar(@links), 1, 'one login link');

  $mech->follow_link_ok({ text => "login" }, "follow login link");
  $mech->content_contains("<h2>login</h2>", "now we're on the login page");

  $mech->submit_form(
    form_number => 1,
    fields => { user => 'jjj', password => 'yellow' }
  );

  $mech->content_contains("you are: jjj", "you are logged in")
    or diag $mech->content;

  last if $iteration == 2;

  @links = $mech->find_all_links( url_regex => qr(\A\Q$root\E/logout) );
  is(scalar(@links), 1, 'one logout link');

  $mech->follow_link_ok(
    { n => 1, url_regex => qr(\A\Q$root\E/logout) },
    'follow logout link',
  );
}

$mech->get_ok("$root/~jjj", "go to user page with ~ notation");
$mech->title_is("Rubric: jjj's entries", "and we're on the right page");

$mech->get_ok("$root/~jjj/blog", "go to user page with ~ notation with tag");
$mech->title_is(
  "Rubric: jjj's entries filed under { blog }",
  "and we're on the right page"
);

$mech->get_ok("$root/huggalugga", "get a bogus url");
$mech->title_is("Rubric: entries", "we're redirected to root");

{ # entry view
  $mech->get_ok($root, "go back to the root");

  $mech->follow_link_ok(
    { text => '(body)', n => 1 },
    'follow a "view entry body" link',
  );

  # XXX: add tests that do something useful -- rjbs, 2006-02-12
}

{ # entry deletion
  $mech->get_ok("$root/~jjj", "go back to our entries");

  $mech->follow_link_ok(
    { text => '(edit)', n => 1 },
    'follow an "edit entry" link',
  );

  $mech->content_contains("revise entry", "we're on the 'edit entry' page");

  $mech->follow_link_ok(
    { text => 'delete this entry', n => 1 },
    "so let's delete an entry",
  );

  # XXX: better test that we're back at the root uri
  $mech->content_contains("entries", "and it sends us back to the root");
}

{ # entry posting
  $mech->get_ok("$root/post", "go to the new entry page");
  $mech->content_contains("new entry", "we're on the 'new entry' page");

  $mech->submit_form(
    form_number => 1,
    fields => {
      uri   => 'http://www.bugle.bz',
      title => 'The Daily Bugle',
      tags  => 'work news journalism',
    }
  );

  $mech->content_contains("The Daily Bugle", "our posted entry is there");
}
