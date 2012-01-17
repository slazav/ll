#!/usr/bin/perl -w
use strict;

use CGI   ':standard';
use Digest::MD5 'md5_hex';
use HTTP::Tiny;
use JSON;

# set $widget_id and $secret here:
use mysecret;

print "Content-Type: text/html\n\n";

my $token = param('token') || '';
my $sig = md5_hex($token.$secret);
my $test_url = "http://loginza.ru/api/authinfo?".
  "token=$token&id=$widget_id&sig=$sig";

my $http = HTTP::Tiny->new();
my $answer=$http->get($test_url)->{content};

my $data  = decode_json $answer;

print "<html><body>\n";

if (exists($data->{error_type})){
  print "<h2>$data->{error_type} error: $data->{error_message}</h2>\n";
  exit 0;
}

print "<ul>\n";
foreach (keys %{$data}){
  print "<li>$_: $data->{$_}\n";
}
print "</ul>\n";
#print "$test_url\n";
#print "$answer\n";

print "</body></html>\n";
