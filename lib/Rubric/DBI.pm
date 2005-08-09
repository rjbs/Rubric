package Rubric::DBI;

=head1 NAME

Rubric::DBI - Rubric's subclass of Class::DBI

=head1 VERSION

 $Id: DBI.pm,v 1.4 2005/05/30 02:24:25 rjbs Exp $

=head1 DESCRIPTION

Rubric::DBI subclasses Class::DBI.  It sets the connection by using the DSN
retrieved from Rubric::Config.

=cut

use strict;
use warnings;
use Rubric::Config;
use base qw(Class::DBI);

use Class::DBI::AbstractSearch;

my $dsn = Rubric::Config->dsn;
my $db_user = Rubric::Config->db_user;
my $db_pass = Rubric::Config->db_pass;

__PACKAGE__->connection(
	$dsn,
	$db_user,
	$db_pass,
	#{ AutoCommit => 0 }
);

=head1 METHODS

=head2 vacuum

This method performs periodic maintenance, cleaning up records that are no
longer needed.

=cut

sub vacuum {
	my $self = shift;
	my $dbh = $self->db_Main;
	my $pruned_links = $dbh->do(
		"DELETE FROM links WHERE id NOT IN ( SELECT link FROM entries )"
	);
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
