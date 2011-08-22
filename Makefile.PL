use strict;
use warnings;

use inc::Module::Install;
use File::Find;

name          ('Rubric');
module_name   ('Rubric');
author        ('Ricardo SIGNES <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/Rubric.pm');

requires('App::Cmd'          => 0.000);
requires('CGI::Application'  => 3.00);
requires('CGI::Application::PSGI' => 0);
requires('CGI::Carp'         => 0.00);
requires('Class::DBI'        => 0.96);
requires('Crypt::CBC'        => 0); # min version unknown
requires('Crypt::Rijndael'   => 0); # min version unknown
requires('DateTime'          => 0.00);
requires('Date::Span'        => 1.12);
requires('DBD::SQLite'       => 1.08);
requires('Digest::MD5'       => 0.00);
requires('Email::Address'    => 0.00);
requires('Email::Send'       => 0.00);
requires('Encode'            => 2.00);
requires('JSON'              => 2); # min version unknown
requires('File::ShareDir'    => 0); # min version unknown
requires('MIME::Base64'      => 0); # min version unknown
requires('Plack::Builder'    => 0); # min version unknown
requires('String::TagString' => 0.00);
requires('String::Truncate'  => 0.00);
requires('Sub::Exporter'     => 0); # min version unknown
requires('Template'          => 2.00);
requires('Time::Local'       => 0.00);
requires('Time::Piece'       => 0.00);
requires('YAML'              => 0.00);
requires('Class::DBI::AbstractSearch' => 0);
requires('HTML::CalendarMonth'        => 0.00);
requires('HTML::TagCloud'             => 0.00);
requires('HTML::Widget::Factory'      => '0.03'); # 0.03: links w/classes
requires('HTTP::Server::Simple'       => '0.09');
requires('Getopt::Long::Descriptive'  => '0.03');
requires('Template::Plugin::Class'    => '0.12');
requires('Test::HTTP::Server::Simple' => '0.02');
requires('Test::WWW::Mechanize'       => '1.04');

install_script('bin/rubric');

install_share;

tests_recursive;

WriteAll();
