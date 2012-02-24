#!/usr/bin/perl
# PODNAME: rubric-entries
use strict;
use warnings;
use Rubric::User;
use Rubric::Entry;
use Getopt::Long;
use Template;

GetOptions(
	"a|allusers"   => \(my $all),
	"u|user=s"     => \(my $uname),
	"t|template=s" => \(my $template = "templates/links.txt")
);

my @users = $all
	? Rubric::User->retrieve_all
	: Rubric::User->retrieve($uname || $ENV{USER});

my $tags = [ grep /^\w+$/, @ARGV ] if @ARGV;
for my $user (@users) {
	my %search = ( user => $user, tags => $tags );
	my @entries = Rubric::Entry->query(\%search);
	Template->new->process($template => { %search, entries => \@entries });
}
