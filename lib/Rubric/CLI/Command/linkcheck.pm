package Rubric::CLI::Command::linkcheck;
use base qw(Rubric::CLI::Command);

=head1 NAME

Rubric::CLI::Command::linkcheck - check validity of links in the database

=head1 VERSION

 $Id: /my/cs/projects/rubric/trunk/lib/Rubric/CLI/Command/db.pm 21614 2006-05-23T16:33:47.947111Z jcap  $

=cut

use strict;
use warnings;

use LWP::Simple ();
use Rubric::DBI::Setup;

sub run {
  my ($self, $opt, $args) = @_;

  my $links = Rubric::Link->retrieve_all;

  while (my $link = $links->next) {
    my $uri = $link->uri;
    if ($uri->scheme ne 'http') {
      print "unknown scheme on link $link\n";
      next;
    }

    unless (LWP::Simple::head($uri)) {
      print "couldn't get headers for $uri\n";
    }
  }
}

1;
