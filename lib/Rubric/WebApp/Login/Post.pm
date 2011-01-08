use strict;
use warnings;
package Rubric::WebApp::Login::Post;
use base qw(Rubric::WebApp::Login);

use Digest::MD5 qw(md5_hex);

=head1 NAME

Rubric::WebApp::Login::Post - process web login from query parameters

=head1 VERSION

version 0.146

=cut

our $VERSION = '0.146';

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

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rubric@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
