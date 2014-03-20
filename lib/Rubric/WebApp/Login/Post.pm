use strict;
use warnings;
package Rubric::WebApp::Login::Post;
# ABSTRACT: process web login from query parameters

use parent qw(Rubric::WebApp::Login);

use Digest::MD5 qw(md5_hex);

=head1 DESCRIPTION

This module checks the submitted query for information needed to confirm that a
user is logged into the Rubric.

=head1 METHODS

=head2 get_login_username

This checks for the username in a current login request.  First it checks
whether there is a C<current_user> value in this session.  If not, it looks for
a C<user> query parameter.

=cut

sub get_login_username {
	my ($class, $webapp) = @_;

	$webapp->session->param('current_user') || $webapp->query->param('user');
}

=head2 authenticate_login($webapp, $user)

This returns true if the username came from the session.  Otherwise, it checks
for a C<password> query parameter and compares its md5sum against the user's
stored password md5sum.

=cut

sub authenticate_login {
	my ($self, $webapp, $user) = @_;

	return 1 if
		$webapp->session->param('current_user') and
		$webapp->session->param('current_user') eq $user;

	my $password = $webapp->query->param('password');

	return (md5_hex($password) eq $user->password);
}

=head2 set_current_user($webapp, $user)

This method sets the current user in the session and then calls the superclass
C<set_current_user>.

=cut

sub set_current_user {
	my ($self, $webapp, $user) = @_;

	$webapp->session->param(current_user => $user->username);
	$self->SUPER::set_current_user($webapp, $user);
}

1;
