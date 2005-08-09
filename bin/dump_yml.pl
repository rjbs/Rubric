use strict;
use warnings;
use YAML;
use DBI;
use Rubric::Config;

my $user = shift @ARGV || $ENV{USER} || die "usage: dump_yml username";

my $dbh = DBI->connect(Rubric::Config->dsn, undef, undef);

my $entries = $dbh->selectall_hashref("
	SELECT entries.id AS id, uri, title, description, created, modified
	FROM entries
	JOIN links ON entries.link=links.id
	WHERE user=?", 'id', undef, $user
);

for (keys %$entries) {
	my $t = $dbh->selectall_arrayref("SELECT tag FROM entrytags WHERE entry=$_");
	$entries->{$_}{tags} = [ map { @$_ } @$t ];
}

print YAML::Dump([ values %$entries ]);
