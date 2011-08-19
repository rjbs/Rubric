#!/usr/local/bin/perl
use CGI::Application::PSGI;
use Encode;

use Rubric::Config qw(/home/rjbs/www/rjbs/rubric.yml);
use Rubric::WebApp;

my $handler = sub {
    my $env = shift;
    my $app = Rubric::WebApp->new({ QUERY => CGI::PSGI->new($env) });
    my $res = CGI::Application::PSGI->run($app);

    $res->[2][0] = encode('utf-8', $res->[2][0]);

    return $res;
};

