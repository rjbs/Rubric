use strict;
use warnings;
package Rubric::WebApp::Login::HTTP;
use base qw(Rubric::WebApp::Login);

=head1 NAME

Rubric::WebApp::Login::HTTP - process web login from HTTP authentication

=head1 VERSION

version 0.146

=cut

our $VERSION = '0.146';

=head1 DESCRIPTION

This module checks for information needed to confirm that a user is logged into
the Rubric.

=head1 METHODS

=head2 get_login_username

This method returns the REMOTE_USER environment variable.

=cut

sub get_login_username { $ENV{REMOTE_USER} }

=head2 authenticate_login

This method always returns true.  (The assumption, here, is that the HTTP
server has already taken care of authentication.)

=cut

sub authenticate_login { 1 }

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
