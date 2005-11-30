package Rubric::Entry::Formatter;

=head1 NAME

Rubric::Entry::Formatter - a base class for entry body formatters

=head1 VERSION

 $Id: /my/rjbs/code/rubric/trunk/lib/Rubric/Renderer.pm 16679 2005-11-29T05:37:27.331642Z rjbs  $

=head1 DESCRIPTION

This class serves as a single point of dispatch for attempts to format entry
bodies from their native format into rendered output.

=cut

use strict;
use warnings;

use Carp ();
use Rubric::Config;

=head1 METHODS

=head2 C< format >

  my $formatted = Rubric::Entry::Formatter->format(\%arg);

This method accepts a set of named arguments and returns formatted output in
the requested format.  If it is unable to do so, it throws an exception.

Valid arguments are:

 markup - the markup format used to mark up the text (default: _default)
 text   - the text that has been marked up and should be formatted (required)
 format - the requested output format (required)

Formatting requests are dispatched according to the configuration in
C<markup_formatter>.  

=cut

my $markup_formatter = Rubric::Config->markup_formatter;

$markup_formatter->{_default} = 'Rubric::Entry::Formatter::Nil'
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

=head1 WRITING FORMATTERS

Writing a formatter should be very simple; the interface is very simple,
although it's also very young and so it may change when I figure out the
problems in the current implementation.

A formatter must implement an C<as_FORMAT> method for each format to which it
claims to be able to output formatted text.  When Rubric::Entry::Formatter
wants to dispatch text for formatting, it will call that method as follows:

  my $formatted = Formatter->as_whatever(\%arg);

The arguments in C<%arg> will be the same as those passed to
Rubric::Entry::Formatter.

Actually, the method is found and called via C<can>, so a suitably programmed
module can respond to C<can> to allow it to render into all the format it likes
-- or at least to claim to.

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
