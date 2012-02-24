use strict;
use warnings;
package Rubric::Entry::Formatter::HTMLEscape;
# ABSTRACT: format into HTML by escaping entities

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

1;
