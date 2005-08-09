package RubricServer;

use strict;
use warnings;

use base 'HTTP::Server::Simple::CGI';
use Rubric::WebApp;

sub print_banner {
  my ($self) = @_;
  print "# RubricServer started on http://localhost:", $self->port, "/\n";
}

sub handle_request {
  my ($self, $cgi) = @_;

  print "HTTP/1.0 200 OK\r\n";
  return Rubric::WebApp->new->run;
}

1;
