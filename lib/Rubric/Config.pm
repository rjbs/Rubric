use strict;
use warnings;
package Rubric::Config;
# ABSTRACT: the configuration data for a Rubric

use parent qw(Class::Accessor);

=head1 DESCRIPTION

Rubric::Config provides access to the configuration data for a Rubric.  The
basic implementation stores its configuration in YAML in a text file in the
current working directory.  By default, Rubric::Config looks for C<rubric.yml>,
but an alternate filename may be passed when using the module:

 use Rubric::Config ".rubric_yml";

=cut

use YAML::XS ();

my $config_filename = $ENV{RUBRIC_CONFIG_FILE} || 'rubric.yml';

sub import {
	my ($class) = shift;
	$config_filename = shift if @_;
}

=head1 SETTINGS

These configuration settings can all be retrieved by methods of the same name.

=over 4

=item * dsn

the DSN to be used by Rubric::DBI to connect to the Rubric's database

=item * db_user

the username to be used by Rubric::DBI to connect to the Rubric's database

=item * db_pass

the password to be used by Rubric::DBI to connect to the Rubric's database

=item * dbi_trace_level

level of debug output for DBI 

=item * dbi_trace_file

Where to send DBI debug output if dbi_trace_level

=item * session_cipher_key

The key to use to encrypt sessions, which are stored in user cookies.  This
must be set.

=item * cookie_secure

If true, secure cookie are used. Defaults to false.

=item * cookie_httponly

If true, HTTP only cookies are used.  Defaults to false.

=item * secure_login

If true, login should only be done via secure means.  The login URI will be
https, and loading the login page on an insecure connection will redirect.

=item * uri_root

the absolute URI for the root of the Rubric::WebApp install

=item * css_href

the absolute URI for the stylesheet to be used by Rubric::WebApp pages

=item * basename

This is the text to display as the name of this Rubric instance.  It defaults
to "Rubric".

=item * template_path

the INCLUDE_PATH passed to Template when creating the template renderers

=item * email_from

the email address from which Rubric will send email

=item * smtp_server

the SMTP server used to send email

=item * entries_query_class

This is the class used to process the C<entries> run method.  It defaults to
C<Rubric::WebApp::Entries>.

=item * login_class

This is the class used to check for logins; it should subclass
Rubric::WebApp::Login.  If not supplied, the default is
Rubric::WebApp::Login::Post.

=item * skip_newuser_verification

If true, users will be created without verification codes, and won't get
verification emails.

=item * registration_closed

true if registration new users can't register for accounts via the web

=item * private_system

true value if users must have an account to view entries

=item * private_tag

A tag which, if attached to an entry, makes it private.  The default value is
C<@private>, and I strongly advise against changing it, since I may change the
way these "system tags" work in the future.

=item * markup_formatter

This entry, if given, should be a mapping of markup names to formatter plugins.
For example:

  markup_formatter:
    kwid: Rubric::Entry::Formatter::Kwid
    tex:  Rubric::Entry::Formatter::TeX

(No.  Neither of those exist.)

If it is not specified in the config file, an entry for C<_default> is set to
the built-in, extremely simple entry formatter.

=item * one_entry_per_link

if true, each user can have only one entry per link (default: true)

=item * allowed_schemes

If undef, all URI schemes are allowed in entries.  If it's an array reference,
it's the list of allowed schemes.

=item * display_localtime

If true, the local time (of the server) will be displayed for entry
create/modify times.  Otherwise, all times will be UTC.  (This option is
probably temporary, until per-user timezones are implemented.)

=item * default_page_size

The number of entries that are displayed on a page of entries, by default.

=item * max_page_size

The maximum number of entries that will be displayed on a page of entries.  If
more are requested, this many will be displayed.

=back

=head1 METHODS

These methods are used by the setting accessors, internally:

=head2 _read_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut

my $config;
sub _read_config {
	return $config if $config;

	my $config_file = $config_filename;
	$config = YAML::XS::LoadFile($config_file);
}

=head2 _default

This method returns the default configuration has a hashref.

=cut

my $default = {
	basename    => 'Rubric',
	css_href    => undef,
	db_user     => undef,
	db_pass     => undef,
	dsn         => undef,
	cookie_httponly => 0,
	cookie_secure   => 0,
	dbi_trace_level => 0,
	dbi_trace_file  => undef,
	secure_login    => 0,
	email_from  => undef,
	login_class => 'Rubric::WebApp::Login::Post',
	smtp_server => undef,
	uri_root    => '',
	private_tag => '@private',
	private_system => undef,
	template_path  => undef,
	allowed_schemes     => undef,
	default_page_size   => 25,
	display_localtime   => 0,
	entries_query_class => 'Rubric::WebApp::Entries',
	max_page_size       => 100,
  markup_formatter    => {},
	one_entry_per_link  => 1,
	registration_closed => undef,
  session_cipher_key  => undef,
	skip_newuser_verification => undef,
};
sub _default { $default }

=head2 make_ro_accessor

Rubric::Config isa Class::Accessor, and uses this sub to build its setting
accessors.  For a given field, it returns the value of that field in the
configuration, if it exists.  Otherwise, it returns the default for that field.

=cut

sub make_ro_accessor {
	my ($class, $field) = @_;
	sub {
		exists $class->_read_config->{$field}
			? $class->_read_config->{$field}
			: $class->_default->{$field}
	}
}

__PACKAGE__->mk_ro_accessors(keys %$default);

1;
