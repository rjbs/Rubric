use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Rubric',
	AUTHOR              => 'Ricardo SIGNES <rjbs@cpan.org>',
	VERSION_FROM        => 'lib/Rubric.pm',
	PL_FILES            => {},
	PREREQ_PM => {
		'CGI::Application' => 3.00,
		'CGI::Carp'        => 0.00,
		'Class::DBI'       => 0.96,
		'Config::Auto'     => 0.11,
		'Date::Span'       => 1.12,
		'DBD::SQLite'      => 1.08,
		'Digest::MD5'      => 0.00,
		'Email::Address'   => 0.00,
		'Email::Send'      => 0.00,
		'Encode'           => 2.00,
		'Template'         => 2.00,
		'Time::Local'      => 0.00,
		'Time::Piece'      => 0.00,
		'YAML'             => 0.00,
		'CGI::Application::Session'  => 0,
		'Class::DBI::AbstractSearch' => 0,
    'HTTP::Server::Simple'       => '0.09',
		'Template::Plugin::Class'    => '0.12',
    'Test::WWW::Mechanize'       => '1.04',
	},
  test => {
    TESTS => join " ", do {
      my $w; $w = sub {
        map { -d $_ ? $w->($_) : /\.t\Z/ ? $_ : () } grep { ! /^\./ } <$_[0]/*>
      };
      $w->("t");
    }
  },
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Rubric-*' },
);
