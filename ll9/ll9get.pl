#!/usr/bin/perl -w
use strict;
use CGI   ':standard';
use ll9;
#use locale;
#setlocale(LC_ALL, "ru_RU.KOI8-R");

if (!param('group') && !param('obj')){
  print "Content-Type: text/html\n\n";
  ll9::html_head('Help');
  print qq*
  <p>Parameters:
  <ul>
  <li>obj = (entry | tags | groups | group_idx | group) -- output object;
  <li>fmt = (jaml | json | html | text) -- output format;
      Html and text formats are not supported by some object types.
  <li>group = &lt;id&gt; -- group id (used for entry, group_idx, group objects).
  <li>entry = &lt;id&gt; -- entry id (used for entry objects).
  </ul>
  *;
  ll9::html_tail();
}

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

if    ($obj eq 'entry')    { ll9::print_entry($fmt, $group, $entry); }
elsif ($obj eq 'tags')     { ll9::print_tags($fmt); }
elsif ($obj eq 'groups')   { ll9::print_groups($fmt); }
elsif ($obj eq 'group_idx'){ ll9::print_group_idx($fmt, $group); }
elsif ($obj eq 'group')    { ll9::print_group($fmt, $group); }
else { print("Unknown obj\n"); }
