#!/usr/bin/perl 
# PODNAME: rubric-loadyml
use YAML::XS;
use Rubric::Link;
use Rubric::User;

my $user = Rubric::User->retrieve(shift @ARGV || $ENV{USER});

my $yaml;
{ local $/; $yaml = <>; }
my $links = Load($yaml);

foreach (@$links) {
	my $link = Rubric::Link->find_or_create({uri => $_->{link}});
  $link ||= '';
	my $entry = $user->add_to_entries({
		link  => $link,
		title => $_->{title},
		description => $_->{description},
		body     => $_->{body},
		created  => $_->{created},
		modified => $_->{modified},
	});
	$entry->add_to_tags({tag => $_}) for keys %{$_->{tags}};
}

$user->update;
