use strict;
use warnings;
package Rubric::Entry::Formatter::Nil;
our $VERSION = '0.147';

=head1 NAME

Rubric::Entry::Formatter::Nil - format entries by formatting nearly not at all

=head1 VERSION

version 0.147

=head1 DESCRIPTION

This is the default formatter.  The only formatting it performs is done by
Template::Filters' C<html_para> filter.  Paragraph breaks will be
retained from plaintext into HTML, but nothing else will be done.

=cut

use Template::Filters;

=head1 METHODS

=cut

my $filter = Template::Filters->new->fetch('html_para');

sub as_html {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $filter->($arg->{text});
}

sub as_text {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $arg->{text};
}

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rubric@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>. I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
