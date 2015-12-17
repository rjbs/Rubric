use strict;
use warnings;
package Rubric::WebApp::Session;
# ABSTRACT: the Rubric session plugin

use CGI::Cookie;
use Crypt::CBC;
use JSON 2 ();
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

  Carp::croak "no session_cipher_key key set"
    unless Rubric::Config->session_cipher_key;

  $caller->add_callback(init    => 'get_cookie_payload');
  $caller->add_callback(postrun => 'set_cookie_payload');
  $self->_import({ into => $caller });
}

=head1 METHODS

These methods are imported into the using class and should be called on an
object of that type -- here, a Rubric::WebApp.

=head2 session

This returns the session, a hashref.

=cut

sub session {
  my ($self) = @_;
  return $self->{__PACKAGE__}{session} ||= $self->get_cookie_payload;
}

my $COOKIE_NAME   = 'RubricSession';

sub __empty { Rubric::WebApp::Session::Object->new({}) }

=head2 session_cipherer

This returns a Crypt::CBC object for handling ciphering.

=cut

sub session_cipherer {
  my ($self) = @_;

  $self->{__PACKAGE__}{cipherer} ||= Crypt::CBC->new(
    -key    => Rubric::Config->session_cipher_key,
    -cipher => 'Rijndael',
    -padding => 'standard',
  );
}

=head2 get_cookie_payload

This gets the cookie and returns the payload as a R::WA::Session::Object.

=cut

sub get_cookie_payload {
  my ($self) = @_;

  return __empty unless my $cookie_value = $self->query->cookie($COOKIE_NAME);

  my $cipherer = $self->session_cipherer;

  my $data = eval {
    JSON->new->utf8->decode(
      $cipherer->decrypt(decode_base64($cookie_value))
    );
  };

  my $session = $data ? Rubric::WebApp::Session::Object->new($data) : __empty;
}

=head2 set_cookie_payload

This method writes the session data back out to a cookie entry.

=cut

sub set_cookie_payload {
  my ($self) = @_;

  my $cookie_value = eval {
    my $json = JSON->new->utf8->encode($self->session->as_hash);

    encode_base64($self->session_cipherer->encrypt($json));
  };

  my $cookie = CGI::Cookie->new(
    -name     => $COOKIE_NAME,
    -expires  => '+30d',
    -value    => $cookie_value,
    -secure   => Rubric::Config->cookie_secure,
    -httponly => Rubric::Config->cookie_httponly,
  );

  $self->header_add(-cookie => [ $cookie ]);
}

=head1 SESSION OBJECT METHODS

=cut

package Rubric::WebApp::Session::Object;

=head2 new

This makes a new session object.  You don't need this.

=cut

sub new {
  my ($class, $data) = @_;
  bless $data => $class;
}

=head2 param

  $obj->param('foo');        # get
  $obj->param('foo', 'val'); # set

=cut

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

=head2 clear

  $obj->clear('name');

Clear the entry (delete it entirely) from the session.

=cut

sub clear {
  my ($self, $param) = @_;
  delete $self->{$param};
}

=head2 delete

  $session->delete;

Removes all data from the session.

=cut

sub delete {
  my ($self) = @_;
  %$self = ();
}

=head2 as_hash

This returns a hashref containing the session data.

=cut

sub as_hash {
  return { %{ $_[0] } };
}

1;
