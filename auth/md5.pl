#!/usr/bin/perl
use strict;
use CGI   ':standard';
use Digest::MD5 'md5_hex';

my $pwd='';
$pwd.=${['0'..'9','a'..'z','A'..'Z']}[rand(58)] foreach (1..6);

my $md5 = md5_hex($pwd);

print <<EOF
Content-Type: text/html; charset=koi8-r

<html>
<body>	
  <p>password: <b>$pwd</b>
  <p>md5: <b>$md5</b>
</body>
</html>
EOF

