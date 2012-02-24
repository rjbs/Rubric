use strict;
use warnings;
package Rubric::User;
# ABSTRACT: a Rubric user

=head1 DESCRIPTION

This class provides an interface to Rubric users.  It inherits from
Rubric::DBI, which is a Class::DBI class.

=cut

use base qw(Rubric::DBI);
use Digest::MD5 qw(md5_hex);
use Time::Piece;

__PACKAGE__->table('users');

=head1 COLUMNS

 username - the user's login name
 password - the hex md5sum of the user's password
 email    - the user's email address
 created  - the user's date of registration

 verification_code - the code sent to the user for verification
                     NULL if verified

=cut

__PACKAGE__->columns(
	All => qw(username password email created verification_code reset_code)
);

=head1 RELATIONSHIPS

=head2 entries

Every user has_many entries, which are Rubric::Entry objects.  They can be
retrieved with the C<entries> accessor, as usual.

=cut

__PACKAGE__->has_many(entries => 'Rubric::Entry' );

=head2 tags

A user has as "his" tags all the tags that occur on his entries.  There exist a
number of accessors for his tag list.

=head3 tags

This returns an arrayref of all the user's (non-system) tags in their database
colation order.

=cut

__PACKAGE__->set_sql(tags => <<'' );
SELECT DISTINCT tag
FROM entrytags
WHERE entry IN (SELECT id FROM entries WHERE username = ?)
  AND tag NOT LIKE '@%%'
ORDER BY tag

sub tags {
	my ($self) = @_;
	my $sth = $self->sql_tags;
	$sth->execute($self->username);
	my $tags = $sth->fetchall_arrayref;
	[ map { @$_ } @$tags ];
}

=head3 tags_counted

This returns an arrayref of arrayrefs, each containing a tag name and the
number of entries tagged with that tag.  The pairs are sorted in colation order
by tag name.

=cut

__PACKAGE__->set_sql(tags_counted => <<'' );
SELECT DISTINCT tag, COUNT(*) AS count
FROM entrytags
WHERE entry IN (SELECT id FROM entries WHERE username = ?)
  AND tag NOT LIKE '@%%'
GROUP BY tag
ORDER BY tag

sub tags_counted {
	my ($self) = @_;
	my $sth = $self->sql_tags_counted;
	$sth->execute($self->username);
	my $tags = $sth->fetchall_arrayref;
	return $tags;
}

=head3 related_tags(\@tags, \%context)

This method returns a reference to an array of tags related to all the given
tags.  Tags are related if they occur together on entries.  

=cut

sub related_tags {
	my ($self, $tags, $context) = @_;
  $tags = [ keys %$tags ] if ref $tags eq 'HASH';
	return unless $tags and my @tags = @$tags;

  # or an exception?
  return [] if  (grep { $_ eq '@private' } @$tags)
         and (($context->{user}||'') ne $self->username);

	my $query = q|
	SELECT DISTINCT tag FROM entrytags
	WHERE entry IN (SELECT id FROM entries WHERE username = ?)
    AND tag NOT IN (| . join(',',map { $self->db_Main->quote($_) } @tags) . q|)
    AND tag NOT LIKE '@%'
	  AND | .
		join ' AND ',
		map { "entry IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { $self->db_Main->quote($_) }
		@tags;

	$self->db_Main->selectcol_arrayref($query, undef, $self->username);
}

=head3 related_tags_counted(\@tags, \%context)

This is the obvious conjunction of C<related_tags> and C<tags_counted>.  It
returns an arrayref of arrayrefs, each a pair of tag/occurance values.

=cut

sub related_tags_counted {
	my ($self, $tags, $context) = @_;
  return unless $tags;
  $tags = [ keys %$tags ] if ref $tags eq 'HASH';
	return unless my @tags = @$tags;

  # or an exception?
  return [] if  (grep { $_ eq '@private' } @$tags)
         and (($context->{user}||'') ne $self->username);

	my $query = q|
		SELECT DISTINCT tag, COUNT(*) AS count
		FROM entrytags
		WHERE entry IN (SELECT id FROM entries WHERE username = ?)
    AND tag NOT IN (| . join(',',map { $self->db_Main->quote($_) } @tags) . q|)
		AND tag NOT LIKE '@%'
    AND | .
		join ' AND ',
		map { "entry IN (SELECT entry FROM entrytags WHERE tag=$_)" }
		map { $self->db_Main->quote($_) }
		@tags;

	$query .= " GROUP BY tag";

	$self->db_Main->selectall_arrayref($query, undef, $self->username);
}

=head1 INFLATIONS

=head2 created

The created column is stored as seconds since epoch, but inflated to
Time::Piece objects.

=cut

__PACKAGE__->has_a(created => 'Time::Piece', deflate => 'epoch');

__PACKAGE__->add_trigger(before_create => \&_create_times);

sub _create_times {
	my $self = shift;
	$self->created(scalar gmtime) unless defined $self->{created};
}

=head1 METHODS

=head2 quick_entry(\%entry)

This method creates or updates an entry for the user.  The passed entry should
include the following data:

 uri         - the URI for the entry
 tags        - the tags for the entry, as a space delimited string
 title       - the title for the entry
 description - the description for the entry
 body        - the body for the entry

If an entry for the link exists, it is updated.  Existing tags are replaced
with the new tags.  If no entry exists, the Rubric::Link is created if needed,
and a new entry is then created.

The Rubric::Entry object is returned.

=cut

sub quick_entry {
	my ($self, $entry) = @_;

	return unless $entry->{title};
	$entry->{tags} = Rubric::Entry->tags_from_string($entry->{tags});

	my $link;
	if ($entry->{uri}) {
		$link = eval { Rubric::Link->find_or_create({ uri => $entry->{uri} }) };
		return unless $link;
	}

	my $new_entry = $entry->{entryid}
		? Rubric::Entry->retrieve($entry->{entryid})
		: $link
			? Rubric::Entry->find_or_create({ link => $link, username => $self })
			: Rubric::Entry->create({ username => $self });

	$new_entry->link($link);
	$new_entry->title($entry->{title});
	$new_entry->description($entry->{description});
	$new_entry->body($entry->{body} || undef);
	$new_entry->update;
	$new_entry->set_new_tags($entry->{tags});

	return $new_entry;
}

=head2 verify($code)

If the given code matches this user's C<verification_code>, the user will be
verified; that is, his C<verification_code> will be undefined.

=cut

sub verify {
	my ($self, $code) = @_;

	return unless $self->verification_code;

	if ($code and $code eq $self->verification_code) {
		$self->verification_code(undef);
		$self->update;
		return 1;
	}
	return;
}

=head2 reset_password($code)

If the given code matches this user's C<reset_code>, the user's password will be
reset via C<randomize_password> and his reset code will be undefined.  If
successful, the new password is returned.  Otherwise, the routine returns
false.

=cut

sub reset_password {
	my ($self, $code) = @_;

	return unless $self->reset_code;

	if ($code and $code eq $self->reset_code) {
		my $password = $self->randomize_password;
		$self->reset_code(undef);
		$self->update;
		return $password;
	}
	return;
}

=head2 randomize_password

This method resets the user's password to a pseudo-random string and returns
the new password.

=cut

sub __random_string {
	my $length = 15;
	my @legal  = ('a'..'z', 'A'..'Z', 0..9);
	my $string = join '', map { @legal[rand @legal] } 1 .. $length;

	return wantarray ? (md5_hex($string), $string) : md5_hex($string);
}

sub randomize_password {
	my ($self) = @_;
	my ($pass_md5, $password) = $self->__random_string;
	
	$self->password($pass_md5);
	$self->update;

	return $password;
}

=head2 randomize_reset_code

This method resets the user's reset code to the md5sum of a pseudo-random
string.

=cut

sub randomize_reset_code {
	my ($self) = @_;
	my $reset_code = $self->__random_string;
	$self->reset_code($reset_code);
	$self->update;
}

=head2 randomize_verification_code

This method resets the user's verification code to the md5sum of a
pseudo-random string.

=cut

sub randomize_verification_code {
	my ($self) = @_;
	my $verification_code = $self->__random_string;
	$self->verification_code($verification_code);
	$self->update;
}

1;
