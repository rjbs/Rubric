use strict;
use warnings;
package Rubric::EntryTag;
our $VERSION = '0.144';

use String::TagString;

=head1 NAME

Rubric::EntryTag - a tag on an entry

=head1 VERSION

version 0.144

=head1 DESCRIPTION

This class provides an interface to tags on Rubric entries.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=cut

use base qw(Rubric::DBI);

__PACKAGE__->table('entrytags');

=head1 COLUMNS

 id        - a unique identifier
 entry     - the tagged entry
 tag       - the tag itself
 tag_value - the value of the tag (for tags in "tag:value" form)

=cut

__PACKAGE__->columns(All => qw(id entry tag tag_value));

=head1 RELATIONSHIPS

=head2 entry

The entry attribute returns a Rubric::Entry.

=cut

__PACKAGE__->has_a(entry => 'Rubric::Entry');

=head1 TRIGGERS

=cut

__PACKAGE__->add_trigger(before_create => \&_nullify_values);
__PACKAGE__->add_trigger(before_update => \&_nullify_values);

sub _nullify_values {
	my $self = shift;
  $self->tag_value(undef)
    unless defined $self->{tag_value} and length $self->{tag_value};
}

=head1 METHODS

=head2 related_tags(\@tags)

This method returns a reference to an array of tags related to all the given
tags.  Tags are related if they occur together on entries.  

=cut

sub related_tags {
	my ($self, $tags) = @_;
	return unless $tags and my @tags = @$tags;

  # or maybe we should throw an exception? -- rjbs, 2006-02-13
  return [] if grep { $_ eq '@private' } @tags;

	my $query = q|
	SELECT DISTINCT tag FROM entrytags
	WHERE
    tag NOT IN (| . join(',',map { $self->db_Main->quote($_) } @tags) . q|)
    AND tag NOT LIKE '@%'
	  AND | .
		join ' AND ',
      map { "entry IN (SELECT entry FROM entrytags WHERE tag=$_)" }
      map { $self->db_Main->quote($_) }
      @tags;

	$self->db_Main->selectcol_arrayref($query, undef);
}

=head3 related_tags_counted(\@tags)

This is the obvious conjunction of C<related_tags> and C<tags_counted>.  It
returns an arrayref of arrayrefs, each a pair of tag/occurance values.

=cut

sub related_tags_counted {
	my ($self, $tags) = @_;
  return unless $tags;
  $tags = [ keys %$tags ] if ref $tags eq 'HASH';
	return unless my @tags = @$tags;

  # or maybe we should throw an exception? -- rjbs, 2006-02-13
  return [] if grep { $_ eq '@private' } @tags;

	my $query = q|
		SELECT DISTINCT tag, COUNT(*) AS count
		FROM entrytags
		WHERE tag NOT IN (|
      . join(',',map { $self->db_Main->quote($_) } @tags) . q|)
		AND tag NOT LIKE '@%'
    AND | .
		join ' AND ',
		map { "entry IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { $self->db_Main->quote($_) }
		@tags;

	$query .= " GROUP BY tag";

	$self->db_Main->selectall_arrayref($query, undef);
}

=head2 stringify_self

=cut

sub stringify_self {
  my ($self) = @_;
  String::TagString->string_from_tags({
    $self->tag => $self->tag_value
  });
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

Copyright 2004 Ricardo SIGNES.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
