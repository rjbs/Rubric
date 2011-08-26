#!perl
#!perl

use Test::More 'no_plan';

BEGIN { use_ok("Rubric::Config", 't/config/rubric.yml'); }
BEGIN { use_ok("Rubric::User"); }

{
	my $user = Rubric::User->retrieve('eb');
	isa_ok($user, 'Rubric::User');
	isa_ok($user->tags, 'ARRAY', 'user tag list');
	isa_ok($user->tags_counted, 'ARRAY', 'tags_counted');
	isa_ok($user->tags_counted->[0], 'ARRAY', 'tags_counted->[0]');
	isa_ok($user->related_tags(['news']), 'ARRAY', 'related_tags');
	isa_ok(
		$user->related_tags_counted(['news']),
		'ARRAY',
		'related_tags_counted'
	);
	isa_ok(
		$user->related_tags_counted(['news'])->[0],
		'ARRAY',
		'related_tags_counted->[0]'
	);

	is($user->related_tags(), undef, "nothing relates to nothing");
	is($user->related_tags([]), undef, "nothing relates to nothingref");
	is(
		$user->related_tags_counted(),
		undef,
		"nothing relates to nothing (counted)"
	);
	is(
		$user->related_tags_counted([]),
		undef,
		"nothing relates to nothingref (counted)"
	);

	my $entry = $user->quick_entry({
		title => "Quick Entry!!",
		link  => "http://www.quick.com/",
		tags  => " quick entry test"
	});
  
  is($entry->title, 'Quick Entry!!', "got title we wanted");
  is_deeply(
    [ sort $entry->tags ],
    [ sort qw(quick entry test) ],
    "got the tags we entered",
  );
}

{
	my $user = Rubric::User->create({
		username => 'testy',
		password => '12345', # not an md5sum
		email    => 'test@example.com',
		verification_code => '12345'
	});

	isa_ok($user, 'Rubric::User', 'newly created user');

	$user->randomize_verification_code;

	ok(my $vcode = $user->verification_code, "user isn't verified");

	is($user->verify(),          undef, "verify w/o code");
	ok($user->verification_code,        "user still isn't verified");
	is($user->verify('54321'),   undef, "verify w/wrong code");
	ok($user->verification_code,        "user still isn't verified");
	is($user->verify($vcode),        1, "verify w/correct code");
	is($user->verification_code, undef, "user is verified");
	is($user->verify($vcode),    undef, "verify when already verified");

	my $pass_md5 = $user->password;

	is($user->reset_code, undef,  "user not waiting to reset pw");

	$user->randomize_reset_code;

	ok(my $rcode = $user->reset_code, "user is waiting to reset pw");

	is($user->reset_password(undef),   undef, "can't reset without code");
	is($user->reset_password('xyzzy'), undef, "can't reset with wrong code");

	ok(my $new_pass = $user->reset_password($rcode), "reset with reset code");

	ok($user->password, "user still has a password");
	cmp_ok($pass_md5, 'ne', $user->password, "new password is different than old");
	like(  $new_pass, qr/\A\w{15}\Z/,       "new password is 15 alphanumerics");

	$user->delete;
}

{
	my $user = Rubric::User->create({
		username => 'testo',
		password => '12345', # not an md5sum
		created  => 0,
		email    => 'stetson@example.com',
	});

	isa_ok($user, 'Rubric::User', 'newly created user');
	is($user->verification_code, undef, "user is verified");

	is($user->quick_entry({}), undef, "can't create title-less entry");
	isa_ok(
		$user->quick_entry({ title => 'foolink', uri => 'http://foo.com/' }),
		'Rubric::Entry',
		'quick entry with link'
	);
	
	my $entry = $user->quick_entry(
		{ title => 'foo-link', uri => 'http://foo.com/' }
	);
	isa_ok( $entry, 'Rubric::Entry', 'quick entry with link (update/uri)');

	isa_ok(
		$user->quick_entry({ entryid => $entry->id, title => 'fool ink' }),
		'Rubric::Entry',
		'quick entry with link (update/id)'
	);

	isa_ok(
		$user->quick_entry({ title => 'foo', body => 'snowdens of yesteryear' }),
		'Rubric::Entry',
		'quick entry without link'
	);

	$user->delete;
}
