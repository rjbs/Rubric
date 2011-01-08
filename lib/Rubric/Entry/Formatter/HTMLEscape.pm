use strict;
use warnings;
package Rubric::Entry::Formatter::HTMLEscape;
our $VERSION = '0.146';

=head1 NAME

Rubric::Entry::Formatter::HTMLEscape - format into HTML by escaping entities

=head1 VERSION

version 0.146

=head1 DESCRIPTION

This formatter only handles formatting to HTML, and outputs the original
content with HTML-unsafe characters escaped and paragraphs broken.

This is equivalent to filtering with Template::Filters' C<html> and
C<html_para> filters.

=cut

use Template::Filters;

=head1 METHODS

=cut

my ($filter, $html, $para);
{
  my $filters = Template::Filters->new;
  $html = $filters->fetch('html');
  $para = $filters->fetch('html_para');

  $filter = sub {
    $para->( $html->($_[0]) );
  }
}

sub as_html {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $filter->($arg->{text});
}

sub as_text {
  my ($class, $arg) = @_;
  return '' unless $arg->{text};
  return $html->($arg->{text});
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
