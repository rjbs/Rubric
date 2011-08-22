#!/usr/local/bin/perl
use CGI::Application::PSGI;
use Encode;

use Plack::Builder;

our $x;
BEGIN { $x = `pwd`; chomp $x; }
use Rubric::Config qq($x/rubric.yml);
use Rubric::WebApp;

my $handler = sub {
    my $env = shift;
    my $app = Rubric::WebApp->new({ QUERY => CGI::PSGI->new($env) });
    my $res = CGI::Application::PSGI->run($app);

    $res->[2][0] = encode('utf-8', $res->[2][0]);

    return $res;
};

builder {
  enable 'Plack::Middleware::ContentLength';
  $handler;
};
