#!perl -T
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }

BEGIN {
  use_ok('Rubric::Link');
  use_ok('Rubric::User');
}

use Digest::MD5 qw(md5_hex);
use lib 't/lib';

use Rubric::Test::DBSetup;

load_test_data_ok('basic');
