use strict;
use warnings;
package Rubric::Link;
# ABSTRACT: a link (URI) against which entries have been made

=head1 DESCRIPTION

This class provides an interface to links in the Rubric.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=cut

use base qw(Rubric::DBI);

use Digest::MD5 qw(md5_hex);

__PACKAGE__->table('links');

=head1 COLUMNS

 id    - a unique identifier
 uri   - the link itself
 md5   - the hex md5sum of the link's URI (set automatically)

=cut

__PACKAGE__->columns(All => qw(id uri md5));

__PACKAGE__->add_constraint('scheme', uri => \&_check_schema);
sub _check_schema {
	my ($uri) = @_;
	return 1 unless $uri;
	return 1 unless Rubric::Config->allowed_schemes;
	$uri = URI->new($uri) unless ref $uri;
	return scalar grep { $_ eq $uri->scheme } @{ Rubric::Config->allowed_schemes }
}

=head1 RELATIONSHIPS

=head2 entries

Every link has_many Rubric::Entries, available with the normal methods,
including C<entries>.

=cut

__PACKAGE__->has_many(entries => 'Rubric::Entry');

=head3 entry_count

This method returns the number of entries that refer to this link.

=cut

__PACKAGE__->set_sql(
	entry_count => "SELECT COUNT(*) FROM entries WHERE link = ?"
);

sub entry_count {
	my ($self) = @_;
	my $sth = $self->sql_entry_count;
	$sth->execute($self->id);
	$sth->fetchall_arrayref->[0][0];
}

=head3 tags_counted

This returns an arrayref of arrayrefs, each containing a tag name and the
number of entries for this link tagged with that tag.  The pairs are sorted in
colation order by tag name.

=cut

__PACKAGE__->set_sql(tags_counted => <<'' );
SELECT DISTINCT tag, COUNT(*) AS count
FROM entrytags
WHERE entry IN (SELECT id FROM entries WHERE link = ?)
GROUP BY tag
ORDER BY tag

sub tags_counted {
	my ($self) = @_;
	my $sth = $self->sql_tags_counted;
	$sth->execute($self->id);
	my $tags = $sth->fetchall_arrayref;
	return $tags;
}

=head1 INFLATIONS

=head2 uri

The uri column inflates to a URI object.

=cut

__PACKAGE__->has_a(
	uri => 'URI',
	deflate => sub { (shift)->canonical->as_string }
);

=head1 METHODS

=head2 stringify_self

This method returns the link's URI as a string, and is teh default
stringification for Rubric::Link objects.

=cut

sub stringify_self { $_[0]->uri->as_string }

__PACKAGE__->add_trigger(before_create => \&_set_md5);

sub _set_md5 {
	my ($self) = @_;
	$self->_attribute_store(md5 => md5_hex("$self->{uri}"));
}

1;
