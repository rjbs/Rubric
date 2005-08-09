package Rubric;

=head1 NAME

Rubric - a notes and bookmarks manager with tagging

=head1 VERSION

version 0.11_02

 $Id: Rubric.pm,v 1.37 2005/06/25 01:14:53 rjbs Exp $

=cut

our $VERSION = '0.11_02';

=head1 DESCRIPTION

This module is currently just a placeholder and a container for documentation.
You don't want to actually C<use Rubric>, even if you want to use Rubric.

Rubric is a note-keeping system that also serves as a bookmark manager.  Users
store entries, which are small (or large) notes with a set of categorizing
"tags."  Entries may also refer to URIs.

Rubric was inspired by the excellent L<http://del.icio.us/> service and the
Notational Velocity note-taking software for Mac OS.

=head1 WARNING

This is young software, likely to have bugs and likely to change in strange
ways.  I will try to keep the documented API stable, but not if it makes
writing Rubric too inconvenient.

Basically, just take note that this software works, but it's still very much
under construction.

=head1 INSTALLING AND UPGRADING

Consult the README file in this distribution for instructions on installation
and upgrades.

=head1 TODO

For now, consult the C<todo.html> template for future milestones, or check
L<http://rjbs.manxome.org/rubric/docs/todo>.

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rubric@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

You can also find some support on the #rubric channel on Freenode IRC.

=head1 SEE ALSO

=over

=item * L<http://del.icio.us/>

one of my original inspirations

=item * L<http://pubweb.nwu.edu/~zps869/nv.html>

Notational Velocity, another of my inspirations

=item * L<http://unalog.com/>

a social bookmarks system, written in Python

=item * L<http://www.tecknik.net/scuttle/>

a social bookmarks system, written in PHP

=back

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
