package Rubric::Entry::Formatter;

=head1 NAME

Rubric::Entry::Formatter - a base class for entry body formatters

=head1 VERSION

 $Id: /my/rjbs/code/rubric/trunk/lib/Rubric/Renderer.pm 16679 2005-11-29T05:37:27.331642Z rjbs  $

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Carp ();
use Rubric::Config;
use Template::Filters;

=head1 METHODS

=cut

my $filter = Temlate::Filters->new->fetch('html_line_break');

my $markup_formatter = Rubric::Config->markup_formatter;

$markup_formatter->{_default} = 'Rubric::Entry::Formatter::Raw'
  unless $markup_formatter->{_default};

sub format {
  my ($class, $arg) = @_;
  
  my $formatter = $markup_formatter->{ $arg->{markup} }
    or Carp::croak "no formatter is registered for $arg->{markup} markup";
  
  eval "require $formatter" or Carp::croak $@;

  my $formatter_code = $formatter->can("as_$arg->{format}")
    or Carp::croak "$formatter does not implement formatting to $arg->{format}";

  $formatter_code->($formatter, $arg);
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
