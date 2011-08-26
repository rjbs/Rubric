#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric::WebApp::URI"); }

my $uri = 'Rubric::WebApp::URI';
my $root = $uri->root;

is(
  $root,
  "http://localhost:8080",
  "our root is what we said",
);

is($uri->stylesheet, 'http://localhost:8080/style/rubric.css', "css uri");
is($uri->login,      "$root/login", "login uri");
is($uri->logout,     "$root/logout", "logout uri");

is($uri->reset_password, "$root/reset_password", "password reset uri");

# my ($user) = Rubric::User->retrieve_all; # any user will do

# XXX write! more! tests! -- rjbs, 2006-02-13
