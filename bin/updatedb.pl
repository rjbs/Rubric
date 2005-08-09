#!/usr/bin/perl
use strict;
use warnings;

use Rubric::Config;
use Rubric::DBI::Setup;

Rubric::DBI::Setup->update_schema;
