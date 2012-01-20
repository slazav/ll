#!/usr/bin/perl -w
use strict;
use CGI   ':standard';
use ll9;
#use locale;
#setlocale(LC_ALL, "ru_RU.KOI8-R");

my $group  = param('group') || ll9::default_group();
my $entry  = param('entry') || 0;

my $fmt  = param('fmt') || 'yaml';
my $obj  = param('obj') || 'entry';

$group =~ s/^.*\///;
$group =~ s/[^a-z0-9_-]//g;
$entry =~ s/[^0-9]//g;

if ($fmt eq 'yaml')   { print "Content-Type: text/plain\n\n"; }
elsif ($fmt eq 'json'){ print "Content-Type: application/json\n\n"; }
elsif ($fmt eq 'html'){ print "Content-Type: text/html\n\n"; }
elsif ($fmt eq 'text'){ print "Content-Type: text/plain\n\n"; }
else {
  print "Content-Type: text/html\n\n";
  ll9::html_head('Error');
  ll9::html_err("Unknown fmt\n");
}


if ($obj eq 'entry'){
  if ($fmt eq 'yaml'){
    ll9::yaml_entry($group, $entry);
  }
  elsif ($fmt eq 'json'){
    ll9::json_entry($group, $entry);
  }
  elsif ($fmt eq 'html'){
    ll9::html_head();
    ll9::html_entry($group, $entry);
    ll9::html_tail();
  }
  else {
    print("Unsupported fmt\n");
  }
}
elsif ($obj eq 'tags'){
  if ($fmt eq 'yaml'){
    ll9::yaml_tags();
  }
  elsif ($fmt eq 'json'){
    ll9::json_tags();
  }
  elsif ($fmt eq 'text'){
    ll9::text_tags();
  }
  else {
    print("Unsupported fmt\n");
  }
}
elsif ($obj eq 'groups'){
  if ($fmt eq 'yaml'){
    ll9::yaml_groups();
  }
  elsif ($fmt eq 'json'){
    ll9::json_groups();
  }
  elsif ($fmt eq 'text'){
    ll9::text_groups();
  }
  else {
    print("Unsupported fmt\n");
  }
}
else{
  print("Unknown obj\n");
}
