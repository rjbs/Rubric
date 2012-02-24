use strict;
use warnings;
package Rubric::Entry::Formatter::Nil;
# ABSTRACT: format entries by formatting nearly not at all

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

1;
