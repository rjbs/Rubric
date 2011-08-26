#!perl
#!perl
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric::EntryTag"); }
BEGIN { use_ok("Rubric::User"); }

use lib 't/lib';
use Rubric::Test::DBSetup;
load_test_data_ok('basic');

# entrytag->related_tags
{ # global entrytag query
  my $related_tags = Rubric::EntryTag->related_tags([ '@private' ]);

  is_deeply(
    $related_tags,
    [ ],
    'nothing is globally related to @private without a login',
  );
}

# entrytag->related_tags_counted
{ # global entrytag query
  my $related_tags = Rubric::EntryTag->related_tags_counted([ '@private' ]);

  is_deeply(
    $related_tags,
    [ ],
    'nothing is globally related_counted to @private',
  );
}


# user->related_tags
{ # user query, with no context of logged in user
  my $user = Rubric::User->retrieve('mxlptlyk');
  my $related_tags = $user->related_tags([ '@private' ]);

  is_deeply(
    $related_tags,
    [ ],
    'nothing is related to @private without a login',
  );
}

{ # user query, with other user asking
  my $user = Rubric::User->retrieve('mxlptlyk');
  my $related_tags = $user->related_tags([ '@private' ], { user => 'jjj' });

  is_deeply(
    $related_tags,
    [ ],
    q(nothing is related to @private if you're the wrong user),
  );
}

{ # user query, with user himsefl asking
  my $user = Rubric::User->retrieve('mxlptlyk');
  my $related_tags = $user->related_tags([ '@private' ], {user => 'mxlptlyk'});

  is_deeply(
    $related_tags,
    [ qw(plans) ],
    q(if you ask about your own @private entries, you may know),
  );
}

# user->related_tags_counted
{ # user query, with no context of logged in user
  my $user = Rubric::User->retrieve('mxlptlyk');
  my $related_tags = $user->related_tags_counted([ '@private' ]);

  is_deeply(
    $related_tags,
    [ ],
    'nothing is related to @private without a login',
  );
}

{ # user query, with other user asking
  my $user = Rubric::User->retrieve('mxlptlyk');
  my $related_tags = $user->related_tags_counted(
    [ '@private' ],
    { user => 'jjj' }
  );

  is_deeply(
    $related_tags,
    [ ],
    q(nothing is related to @private if you're the wrong user),
  );
}

{ # user query, with user himsefl asking
  my $user = Rubric::User->retrieve('mxlptlyk');
  my $related_tags = $user->related_tags_counted(
    [ '@private' ],
    {user => 'mxlptlyk'}
  );

  is_deeply(
    $related_tags,
    [ [ plans => 1 ] ],
    q(if you ask about your own @private entries, you may know),
  );
}

# entry->recent_tags_counted
{
  my $related_tags = Rubric::Entry->recent_tags_counted;

  ok(
    !(grep { $_->[0] eq 'plans' } @$related_tags),
    q(tags contained only in private entries are not leaked)
  );
}
