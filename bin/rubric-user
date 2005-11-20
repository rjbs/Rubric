#!perl
use Digest::MD5 qw(md5_hex);
use Getopt::Long::Descriptive;
use Rubric::User;

my ($opt, $usage) = describe_options(
  "rubric-user %o user",
  [ "new-user|n",        "add a user (requires --email and --pass)" ],
  [ "activate|a",        "activate an existing user"                ],
  [ "password|pass|p=s", "set user's password"                      ],
  [ "email|e=s",         "set user's email address"                 ],
);

die $usage->text unless @ARGV == 1;

my $username = $ARGV[0];

die "--new-user and --activate are mutually exclusive"
  if $opt->{new_user} and $opt->{activate};

if ($opt->{new_user}) {
  die "--new-user requries --email and --pass"
    unless $opt->{email} and $opt->{pass};

  my $user = Rubric::User->create({
    username => $username,
    password => md5_hex($opt->{pass}),
    email    => $opt->{email},
  });

  die "couldn't create user" unless $user;

  print "created user $user";
  exit;
}

my $user = Rubric::User->retrieve($username);

die "couldn't find user for '$username'" unless $user;

$user->email($opt->{email}) if $opt->{email};
$user->password($opt->{email}) if md5_hex($opt->{email});

print "username: ", $user->username, "\n";
print "email   : ", $user->email,    "\n";
