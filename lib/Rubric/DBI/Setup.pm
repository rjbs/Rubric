use strict;
use warnings;
package Rubric::DBI::Setup;
# ABSTRACT: db initialization routines

=head1 SYNOPSIS

 use strict;
 use warnings;

 use Rubric::DBI::Setup;
 Rubric::DBI::Setup->setup_tables;

=head1 DESCRIPTION

=cut

use DBI;
use Rubric::Config;
use Rubric::Entry;
use Rubric::Renderer;

=head1 METHODS

=head2 dbh

This method returns a connection to the Rubric database.

=cut

my $dbh;

sub dbh {
	return $dbh if $dbh;

  return $dbh = DBI->connect(
		Rubric::Config->dsn,
		Rubric::Config->db_user,
		Rubric::Config->db_pass
	);
}

=head2 setup_tables

This method builds the tables in the database, if needed.

=cut

sub setup_tables {
	my ($class) = @_;

	local $/ = "\n\n";
  $class->dbh->do( $class->specialize_sql($_) ) for <DATA>;
}

=head2 specialize_sql

attempts to convert the given sql syntax to the given DBD Driver's

=cut

sub specialize_sql {
  my ($class, $query) = @_;

  my $db_type = $class->determine_db_type;

  if ($db_type eq 'Pg') {
    $query =~ s/(id\s*)integer/$1SERIAL/i;
  }

  return $query;
}

=head2 determine_version

This attempts to determine the version of the database schema to which the
given database conforms.  All recent schemata store their version number; for
older versions, some simple table attributes are checked.

=cut

sub _columns {
	my ($class, $query) = @_;
	return scalar(my @columns = $class->dbh->selectrow_array($query));
}

sub determine_version {
	my ($class) = @_;

	my ($version) = $class->dbh->selectrow_array("SELECT schema_version FROM rubric");

	if ($version) {
		if ($version == 6) {
			# some schemata are broken, and claim 6 on 7
			eval {
        $class->dbh->selectall_array("SELECT verification_code FROM users");
      };
			if ($@) {
        warn "your db schema label is incorrect; run rubric db -u"; return 7;
      } else {
        return 6;
      }
		} else {
			return $version;
		}
	}

	# v4 added body column;
	return 4 if $class->_columns("SELECT * FROM entries LIMIT 1") == 8;

	# v3 added email and validation_code;
	return 3 if $class->_columns("SELECT * FROM users LIMIT 1") == 4;

	# v2 added md5 column;
	return 2 if $class->_columns("SELECT * FROM links LIMIT 1") == 3;

	return 1 if $class->_columns("SELECT * FROM links LIMIT 1") == 2;

	return;
}

=head2 determine_db_type

Returns the type of db being used, based on the DSN's DBD driver.
SQLite and Pg support only right now.

=cut

sub determine_db_type {
	my ($class) = @_;

  Rubric::Config->dsn =~ /dbi:([^:]+):/;

  my $db_type = $1;

  return $db_type;
}

=head2 update_schema

This method will try to upgrade the database to the most recent schema.  It's
sort of ugly, but it works...

=cut

my %from;

# from 1 to 2
#  add md5 sum to links table

$from{1} = sub {
	require Digest::MD5;
	$dbh->func('md5hex', 1, \&Digest::MD5::md5_hex, 'create_function');

	my $sql = <<'END_SQL';
	CREATE TABLE new_links (
		id INTEGER PRIMARY KEY,
		uri varchar UNIQUE NOT NULL,
		md5 varchar NOT NULL
	);

	INSERT INTO new_links
	SELECT id, uri, md5hex(uri) FROM links;

	DROP TABLE links;

	CREATE TABLE links (
		id INTEGER PRIMARY KEY,
		uri varchar UNIQUE NOT NULL,
		md5 varchar NOT NULL
	);

	INSERT INTO links
	SELECT id, uri, md5 FROM new_links;

	DROP TABLE new_links;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 2 to 3
#  add email and validation_code
#  fill in email with garbage data

$from{2} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		validation_code
	);

	INSERT INTO new_users
	SELECT *, 'user@example.com', NULL FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		validation_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 3 to 4
#  link becomes null-ok
#  add body column

$from{3} = sub {
	my $sql = <<END_SQL;
	CREATE TABLE new_entries (
		id INTEGER PRIMARY KEY,
		link integer,
		user varchar NOT NULL,
		title varchar NOT NULL,
		created NOT NULL,
		modified NOT NULL,
		description varchar,
		body TEXT
	);

	INSERT INTO new_entries
	SELECT *, NULL FROM entries;

	DROP TABLE entries;

	CREATE TABLE entries (
		id INTEGER PRIMARY KEY,
		link integer,
		user varchar NOT NULL,
		title varchar NOT NULL,
		created NOT NULL,
		modified NOT NULL,
		description varchar,
		body TEXT
	);

	INSERT INTO entries
	SELECT * FROM new_entries;

	DROP TABLE new_entries;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 4 to 5
#  add rubric table and schema number

$from{4} = sub {
	my $sql = <<END_SQL;
	CREATE TABLE rubric (
		schema_version NOT NULL
	);

	INSERT INTO rubric (schema_version) VALUES (5);
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 5 to 6
#  add "created" column to users

$from{5} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		validation_code
	);

	INSERT INTO new_users
	SELECT username, password, email, 0, validation_code
	FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		validation_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;

	UPDATE rubric SET schema_version = 6;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 6 to 7
#  validation_code is now verification_code

$from{6} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		verification_code
	);

	INSERT INTO new_users
	SELECT username, password, email, created, validation_code
	FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		verification_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;

	UPDATE rubric SET schema_version = 7;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

# from 7 to 8
#  add reset_code

$from{7} = sub {
	my $sql = <<'END_SQL';
	CREATE TABLE new_users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		verification_code,
		reset_code
	);

	INSERT INTO new_users
	SELECT username, password, email, created, verification_code, NULL
	FROM users;

	DROP TABLE users;

	CREATE TABLE users (
		username PRIMARY KEY,
		password NOT NULL,
		email NOT NULL,
		created NOT NULL,
		verification_code,
		reset_code
	);

	INSERT INTO users
	SELECT * FROM new_users;

	DROP TABLE new_users;

	UPDATE rubric SET schema_version = 8;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

$from{8} = sub {
	my $sql = <<'END_SQL';
    CREATE TABLE new_entrytags (
    id          INTEGER PRIMARY KEY,
    entry       NOT NULL,
    tag         NOT NULL,
    tag_value,
    UNIQUE(entry, tag)
	);

	INSERT INTO new_entrytags
	SELECT id, entry, tag, NULL
	FROM entrytags;

	DROP TABLE entrytags;

	CREATE TABLE entrytags (
    id          INTEGER PRIMARY KEY,
    entry       NOT NULL,
    tag         NOT NULL,
    tag_value,
    UNIQUE(entry, tag)
	);

	INSERT INTO entrytags
	SELECT * FROM new_entrytags;

	DROP TABLE new_entrytags;

	UPDATE rubric SET schema_version = 9;
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

$from{9} = sub {
	my $sql = <<'END_SQL';
  CREATE TABLE new_users (
    username    varchar PRIMARY KEY,
    password    varchar NOT NULL,
    email       varchar NOT NULL,
    created     integer NOT NULL,
    verification_code varchar,
    reset_code varchar
  );

	INSERT INTO new_users
	SELECT username, password, email, created, verification_code, reset_code
	FROM users;

	DROP TABLE users;

  CREATE TABLE users (
    username    varchar PRIMARY KEY,
    password    varchar NOT NULL,
    email       varchar NOT NULL,
    created     integer NOT NULL,
    verification_code varchar,
    reset_code varchar
  );

	INSERT INTO users
	SELECT username, password, email, created, verification_code, reset_code
	FROM new_users;

	DROP TABLE new_users;

  CREATE TABLE new_entries (
    id          integer PRIMARY KEY,
    link        integer,
    user        varchar NOT NULL,
    title       varchar NOT NULL,
    created     integer NOT NULL,
    modified    integer NOT NULL,
    description varchar,
    body                TEXT
  );

  INSERT INTO new_entries
  SELECT id, link, user, title, created, modified, description, body
  FROM entries;

  DROP TABLE entries;

  CREATE TABLE entries (
    id          integer PRIMARY KEY,
    link        integer,
    user        varchar NOT NULL,
    title       varchar NOT NULL,
    created     integer NOT NULL,
    modified    integer NOT NULL,
    description varchar,
    body                TEXT
  );

  INSERT INTO entries
  SELECT id, link, user, title, created, modified, description, body
  FROM new_entries;

  DROP TABLE new_entries;

  CREATE TABLE new_entrytags (
    id          INTEGER PRIMARY KEY,
    entry       integer NOT NULL,
    tag         varchar NOT NULL,
    tag_value   varchar,
    UNIQUE(entry, tag)
  );

  INSERT INTO new_entrytags
  SELECT id, entry, tag, tag_value
  FROM entrytags;

  DROP TABLE entrytags;

  CREATE TABLE entrytags (
    id          INTEGER PRIMARY KEY,
    entry       integer NOT NULL,
    tag         varchar NOT NULL,
    tag_value   varchar,
    UNIQUE(entry, tag)
  );

  INSERT INTO entrytags
  SELECT id, entry, tag, tag_value
  FROM new_entrytags;

  DROP TABLE new_entrytags;

  DROP TABLE rubric;

  CREATE TABLE rubric (
    schema_version integer NOT NULL
  );

  INSERT INTO rubric (schema_version) VALUES (10);
END_SQL

	$dbh->do($_) for split /\n\n/, $sql;
};

$from{10} = sub {
	my $sql = <<'END_SQL';
  CREATE TABLE new_entries (
    id          integer PRIMARY KEY,
    link        integer,
    username    varchar NOT NULL,
    title       varchar NOT NULL,
    created     integer NOT NULL,
    modified    integer NOT NULL,
    description varchar,
    body                TEXT
  );

  INSERT INTO new_entries (id, link, username, title, created, modified, description, body)
    SELECT id, link, user, title, created, modified, description, body
      FROM entries;

  DROP TABLE entries;

  CREATE TABLE entries (
    id          integer PRIMARY KEY,
    link        integer,
    username    varchar NOT NULL,
    title       varchar NOT NULL,
    created     integer NOT NULL,
    modified    integer NOT NULL,
    description varchar,
    body                TEXT
  );

  INSERT INTO entries
    SELECT id, link, username, title, created, modified, description, body
      FROM new_entries;

  DROP TABLE new_entries;

  UPDATE rubric SET schema_version = 11;
END_SQL

  $dbh->do($_) for split /\n\n/, $sql;
};

$from{11} = undef;

sub update_schema {
	my ($class) = @_;

	while ($_ = $class->determine_version) {
		die "no update path from schema version $_" unless exists $from{$_};
		last unless defined $from{$_};
		print "updating from version $_...\n";
		$from{$_}->();
	}
	return $class->determine_version;
}

1;

__DATA__
CREATE TABLE links (
	id  integer PRIMARY KEY,
	uri varchar UNIQUE NOT NULL,
	md5 varchar NOT NULL
);

CREATE TABLE users (
	username    varchar PRIMARY KEY,
	password    varchar NOT NULL,
	email       varchar NOT NULL,
	created     integer NOT NULL,
	verification_code varchar,
	reset_code varchar
);

CREATE TABLE entries (
	id          integer PRIMARY KEY,
	link        integer,
	username    varchar NOT NULL,
	title       varchar NOT NULL,
	created     integer NOT NULL,
	modified    integer NOT NULL,
	description varchar,
	body                TEXT
);

CREATE TABLE entrytags (
	id          INTEGER PRIMARY KEY,
	entry       integer NOT NULL,
	tag         varchar NOT NULL,
  tag_value   varchar,
	UNIQUE(entry, tag)
);

CREATE TABLE rubric (
	schema_version integer NOT NULL
);

INSERT INTO rubric (schema_version) VALUES (11);
