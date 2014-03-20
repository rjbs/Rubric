use strict;
use warnings;
package Rubric::WebApp::Login::HTTP;
# ABSTRACT: process web login from HTTP authentication

use parent qw(Rubric::WebApp::Login);

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

1;
