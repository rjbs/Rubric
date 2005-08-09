use Rubric::User;
use Digest::MD5 qw(md5_hex);
my ($username, $password, $email) = @ARGV;

die "usage: adduser.pl username password email"
	unless (@ARGV == 3);

Rubric::User->create({
	username => $username,
	password => md5_hex($password),
	email    => $email
});
