use Test::More;
use Test::WWW::Mechanize;

use lib 't/lib';

use strict;
use warnings;

unless ($ENV{RUBRIC_TEST_WWW}) {
  plan skip_all => "these just don't work yet";
  exit;
}

plan 'no_plan';

# Setup Rubric Webserver
use RubricServer;

my $server = RubricServer->new;
my $pid    = $server->background;
my $root   = "http://localhost:8080/";

ok($pid, 'HTTP Server Started');

END { kill(9, $pid) if $pid }

# Begin testing.
my $mech = Test::WWW::Mechanize->new;
$mech->get_ok($root, 'HTTP GET');

$mech->title_is('Rubric: entries', 'Correct <title>');

{ # general information-finding
  my @tag_links = $mech->find_all_links( url_regex => qr/\A\Q$root\Eentries\/tags/ );
  is(scalar(@tag_links), 23, 'Count tag entry urls');
}

{ # test all internal links
  my @links = $mech->find_all_links( url_regex => qr/\A\Q$root/);
  $mech->link_status_is(\@links, 200, "the internal links are status 200");
}

{ # login/logout
  my @links = $mech->find_all_links( url_regex => qr/\A\Q$root\Elogin/ );
  is(scalar(@links), 1, 'one login link');

  $mech->follow_link_ok({ text => "login" }, "follow login link");
  $mech->content_contains("<h2>login</h2>");

  $mech->submit_form(
    form_number => 1,
    fields => { user => 'jjj', password => 'yellow' }
  );

#  @links = $mech->find_all_links( url_regex => qr/\A\Q$root\Elogout/ );
#  is(scalar(@links), 1, 'one login link');

#  $mech->content_contains("you are: jjj");

}
