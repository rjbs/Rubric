use Test::More;
use Test::WWW::Mechanize;

use lib 't/lib';

use strict;
use warnings;

# unless ($ENV{RUBRIC_TEST_WWW}) {
#   plan skip_all => "these just don't work yet";
#   exit;
# }

plan 'no_plan';

# Setup Rubric Webserver
use RubricServer;

my $server = RubricServer->new;

my $root = $server->started_ok("start up my web server");

# Begin testing.
my $mech = Test::WWW::Mechanize->new;
$mech->get_ok($root, 'HTTP GET');

$mech->title_is('Rubric: entries', 'Correct <title>');

{ # general information-finding
  my @tag_links
    = $mech->find_all_links( url_regex => qr(\A\Q$root\E/entries/tags) );

  is(@tag_links, 26, 'Count tag entry urls');
}

{ # test all internal links
  my @links = $mech->find_all_links( url_regex => qr(\A\Q$root));
  $mech->link_status_is(\@links, 200, "the internal links are status 200");
}

for my $iteration (1 .. 2) { # login/logout
  my @links = $mech->find_all_links( url_regex => qr(\A\Q$root\E/login) );
  is(scalar(@links), 1, 'one login link');

  $mech->follow_link_ok({ text => "login" }, "follow login link");
  $mech->content_contains("<h2>login</h2>");

  $mech->submit_form(
    form_number => 1,
    fields => { user => 'jjj', password => 'yellow' }
  );

  $mech->content_contains("you are: jjj", "you are logged in");

  last if $iteration == 2;

  @links = $mech->find_all_links( url_regex => qr(\A\Q$root\E/logout) );
  is(scalar(@links), 1, 'one logout link');

  $mech->follow_link_ok({ n => 1, url_regex => qr(\A\Q$root\E/logout) });
}

{ # entry deletion
  $mech->follow_link_ok({ text => '(edit)', n => 1 });

  $mech->content_contains("revise entry");

  $mech->follow_link_ok({ text => 'delete this entry', n => 1 });

  # XXX: better test that we're back at the root uri
  $mech->content_contains("entries");
}
