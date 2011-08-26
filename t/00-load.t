#!perl

use Test::More tests => 16;

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric"); }
BEGIN { use_ok("Rubric::Config"); }
BEGIN { use_ok("Rubric::DBI"); }
BEGIN { use_ok("Rubric::Entry"); }
BEGIN { use_ok("Rubric::Entry::Query"); }
BEGIN { use_ok("Rubric::EntryTag"); }
BEGIN { use_ok("Rubric::Link"); }
BEGIN { use_ok("Rubric::Renderer"); }
BEGIN { use_ok("Rubric::User"); }
BEGIN { use_ok("Rubric::WebApp"); }
BEGIN { use_ok("Rubric::WebApp::Entries"); }
BEGIN { use_ok("Rubric::WebApp::Login"); }
BEGIN { use_ok("Rubric::WebApp::Login::HTTP"); }
BEGIN { use_ok("Rubric::WebApp::Login::Post"); }
BEGIN { use_ok("Rubric::WebApp::URI"); }
