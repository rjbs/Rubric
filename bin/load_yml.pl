use YAML;
use Rubric::Link;
use Rubric::User;

my $user = Rubric::User->retrieve(shift @ARGV || $ENV{USER});

my $yaml;
{ local $/; $yaml = <>; }
my $links = YAML::Load($yaml);

foreach (@$links) {
	my $link = Rubric::Link->find_or_create({uri => $_->{href}});
	my $entry = $user->add_to_entries({
		link  => $link,
		title => $_->{description},
		description => $_->{extended},
		body     => $_->{body},
		created  => $_->{created} || $_->{datetime},
		modified => $_->{modified} || $_->{datetime},
	});
	$entry->add_to_tags({tag => $_}) for @{$_->{tags}};
}

$user->update;
