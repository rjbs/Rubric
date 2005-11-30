package Rubric::Entry::Formatter::HTMLEscape;

=head1 NAME

Rubric::Entry::Formatter::HTMLEscape - format into HTML by escaping entities

=head1 VERSION

 $Id: /my/rjbs/code/rubric/trunk/lib/Rubric/Renderer.pm 16679 2005-11-29T05:37:27.331642Z rjbs  $

=head1 DESCRIPTION

This formatter only handles formatting to HTML, and outputs the original
content with HTML-unsafe characters escaped and paragraphs broken.

This is equivalent to filtering with Template::Filters' C<html> and
C<html_para> filters.

=cut

use strict;
use warnings;

use Template::Filters;

=head1 METHODS

=cut

my $filter;
{
  my $filters = Template::Filters->new;
  my $html = $filters->fetch('html');
  my $para = $filters->fetc('html_para');

  $filter = sub {
    $para->( $html->($_[0]) );
  }
}

sub as_html {
  my ($class, $arg) = @_;
  return $filter->($arg->{text});
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
