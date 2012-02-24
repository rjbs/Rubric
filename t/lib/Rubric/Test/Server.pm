package Rubric::Test::Server;

use strict;
use warnings;

use HTTP::Server::Simple 0.08 ();
use Test::HTTP::Server::Simple 0.02 ();
use base qw(Test::HTTP::Server::Simple HTTP::Server::Simple::CGI);
use Rubric::WebApp;

sub print_banner {
  my ($self) = @_;
  print "# RubricServer started on http://localhost:", $self->port, "/\n";
}

sub handle_request {
  my ($self, $cgi) = @_;

  my $output = eval {
    local $ENV{CGI_APP_RETURN_ONLY} = 1;
    Rubric::WebApp->new(QUERY => $cgi)->run;
  };

  if (my $error = $@) {
    print "HTTP/1.0 500\r\n";
    print "Content-type: text/plain\r\n\r\n";
    print $error;
    return;
  }

  my ($header, $body) = split /\r\n\r\n/, $output, 2;

  my %header = map { split /:\s*/, $_, 2 } split /\r\n/, $header;

  my $status = delete $header{Status} || "200 OK";
  $header{'Content-Type'} ||= 'text/plain';

  print "HTTP/1.0 $status\r\n";
  print "$_: $header{$_}\r\n" for keys %header;
  print "\r\n";

  print $body || "$status\r\n";
} 

1;
