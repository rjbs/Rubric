#!perl
use strict;
use warnings;

use Test::More;
use Digest::MD5 qw(md5_hex);
use Rubric::Config 't/config/rubric.yml'; 

use lib 't/lib';
use Rubric::Test::DBSetup;

plan tests => tests_for_dataset('basic');

load_test_data_ok('basic');
