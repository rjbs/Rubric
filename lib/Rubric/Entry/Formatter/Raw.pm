package Rubric::Entry::Formatter::Raw;

=head1 NAME

Rubric::Entry::Formatter::Raw - format entries by formatting nearly not at all

=head1 VERSION

 $Id: /my/rjbs/code/rubric/trunk/lib/Rubric/Renderer.pm 16679 2005-11-29T05:37:27.331642Z rjbs  $

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Template::Filters;

=head1 METHODS

=cut

my $filter = Template::Filters->new->fetch('html_line_break');

sub as_html {
  my ($class, $arg) = @_;
  return $filter->($arg->{text});
}

sub as_text {
  my ($class, $arg) = @_;

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
