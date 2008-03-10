use strict;
use warnings;

package Rubric::WebApp::Session;

use Crypt::CBC;
use JSON::XS ();
use MIME::Base64;
use Sub::Exporter -setup => {
  -as => '_import',
  exports => [
    qw(session session_cipherer get_cookie_payload set_cookie_payload)
  ],
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
  return $self->{__PACKAGE__}{session} ||= $self->get_cookie_payload;
}

my $COOKIE_NAME   = 'RubricSession';
my $COOKIE_SECRET = 'FolgersCrystals';

sub __empty { Rubric::WebApp::Session::Object->new({}) }

sub session_cipherer {
  my ($self) = @_;

  $self->{__PACKAGE__}{cipherer} ||= Crypt::CBC->new(
    -key    => $COOKIE_SECRET,
    -cipher => 'Rijndael',
    -padding => 'standard',
  );
}

sub get_cookie_payload {
  my ($self) = @_;

  return __empty unless my $cookie_value = $self->query->cookie($COOKIE_NAME);

  my $data = eval {
    JSON::XS->new->utf8->decode(
      $self->session_cipherer->decrypt(decode_base64($cookie_value))
    );
  };

  my $session = $data ? Rubric::WebApp::Session::Object->new($data) : __empty;
}

sub set_cookie_payload {
  my ($self) = @_;

  my $cookie_value = eval {
    my $json = JSON::XS->new->utf8->encode($self->session->as_hash);

    encode_base64($self->session_cipherer->encrypt($json));
  };

  my $cookie = CGI::Cookie->new(
    -name    => $COOKIE_NAME,
    -expires => '+30d',
    -value   => $cookie_value,
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
