use strict;
use warnings;

package Rubric::WebApp::Session;

use JSON::XS ();
use Sub::Exporter -setup => {
  -as => '_import',
  exports => [ qw(session get_cookie_payload set_cookie_payload) ],
  groups  => [ default => [ -all ] ],
};

sub import {
  my ($self) = @_;
  my $caller = caller;
  $caller->add_callback(init    => 'get_cookie_payload');
  $caller->add_callback(postrun => 'set_cookie_payload');
  $self->_import({ into => $caller });
}

sub session {
  my ($self) = @_;
  return $self->{__PACKAGE__}{session};
}

my $COOKIE_NAME = 'RubricSession';

sub get_cookie_payload {
  my ($self) = @_;

  my $cookie  = $self->query->cookie($COOKIE_NAME);
  my $data = eval { JSON::XS->new->decode($cookie->value) } || {};

  $self->{__PACKAGE__}{session} = Rubric::WebApp::Session::Object->new($data);
}

sub set_cookie_payload {
  my ($self) = @_;

  my $session = $self->session->as_hash;
  my $payload = JSON::XS->new->encode($session);

  my $cookie = CGI::Cookie->new(
    -name  => $COOKIE_NAME,
    -value => $payload,
  );

  $self->header_add(-cookie => [ $cookie ]);
}

package Rubric::WebApp::Session::Object;

sub new {
  my ($class, $data) = @_;
  bless $data => $class;
}

sub param {
  my $self = shift;

  if (@_ == 1) {
    return $self->{$_[0]} if exists $self->{$_[0]};
    return;
  } 

  if (@_ == 2) {
    return $self->{$_[0]} = $_[1];
  } 

  die "invalid number of args to session->param";
}

sub clear {
  my ($self, $param) = @_;
  delete $self->{$param};
}

sub delete {
  my ($self) = @_;
  %$self = ();
}

sub as_hash {
  return { %{ $_[0] } };
}

1;
