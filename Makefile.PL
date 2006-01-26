use strict;
use warnings;

use inc::Module::Install;
use File::Find;

name          ('Rubric');
author        ('Ricardo SIGNES <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/Rubric.pm');

requires('CGI::Application' => 3.00);
requires('CGI::Carp'        => 0.00);
requires('Class::DBI'       => 0.96);
requires('Config::Auto'     => 0.11);
requires('Date::Span'       => 1.12);
requires('DBD::SQLite'      => 1.08);
requires('Digest::MD5'      => 0.00);
requires('Email::Address'   => 0.00);
requires('Email::Send'      => 0.00);
requires('Encode'           => 2.00);
requires('Template'         => 2.00);
requires('Time::Local'      => 0.00);
requires('Time::Piece'      => 0.00);
requires('YAML'             => 0.00);
requires('Class::DBI::AbstractSearch' => 0);
requires('HTML::Widget::Factory'      => '0.03'); # 0.03: links w/classes
requires('HTTP::Server::Simple'       => '0.09');
requires('Getopt::Long::Descriptive'  => '0.03');
requires('Template::Plugin::Class'    => '0.12');
requires('Test::WWW::Mechanize'       => '1.04');
requires('CGI::Application::Plugin::Session' => 0);

my $files = '';
find( sub { $files .= " $File::Find::name" if -f && /\.t$/ }, "t" );

tests         ($files);

sign(1);

WriteAll();
