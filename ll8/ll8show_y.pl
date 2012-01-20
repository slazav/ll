#!/usr/bin/perl -w
use strict;

use CGI   ':standard';
use YAML::Tiny;
use ll8;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

my $file  = defined(param('file')) ? param('file') : $ll8::files[0];
$file =~ s/^.*\///;

print "Content-Type: text/plain\n\n";

if (!open(IN, "$ll8::datadir/$file")){
  print "не читается файл $file\n";
  exit(0);
}

my @all;
my $read=0;
my %entry;
foreach (<IN>){
  if ($read==0){
    if (/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/){
      $read=1;
      %entry=();
      $entry{id}=$1;
      $entry{user} = $2;
      $entry{time} = $3;
      next;
    }
  }
  if ($read==1){
    if (/^title: (.*)/){ $entry{title} = $1; next; }
    if (/^date: (.*)/){  $entry{date} = $1; next; }
    if (/^tags: (.*)/){  $entry{tags} = $1; next; }
    if (/^> (.*)$/){
      $entry{text}.="\n" if defined($entry{text});
      $entry{text}.=$1;
      next;
    }
    if (/<!-- \/entry -->/){
      push @all, {%entry};
      $read=0; next;
    }
  }
}

print YAML::Tiny::Dump(@all);