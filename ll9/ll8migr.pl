#!/usr/bin/perl -w

# преобразование из старого формата в новый
# (yaml, отдельные записи для треков)

use strict;
use YAML::Tiny;

opendir DATADIR, "./data"
  or die "can't open ./data dir: $!\n";
-d "./data_new" or mkdir "./data_new"
  or die "can't create ./data_new dir: $!\n";

while (my $f = readdir DATADIR){
  next if ($f =~ /^\./) || -d "./data/$f";

  unless (open IN, "./data/$f"){
    warn "skipping file ./data/$f: $!\n";
    next;
  };

  print "processing $f\n";

  my $read=0;
  my %entry;

  -d "./data_new/$f" or mkdir "./data_new/$f"
    or die "can't create ./data_new/$f dir: $!\n";

  foreach (<IN>){
    if ($read==0){
      if (/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/){
        $read=1;
        %entry=();
        $entry{id}=$1;
        $entry{cuser} = $2;
        $entry{ctime} = $3;
        next;
      }
    }
    if ($read==1){
      if (/^title:\s+(.*)/){ $entry{title} = $1; next; }
      if (/^date:\s+(.*)/){  $entry{date} = $1; next; }
      if (/^tags:\s+(.*)/){  push @{$entry{tags}}, split /\s+/, $1; next; }
      # strict geodata:
      if ((m|^>\s+([гГ]еоданные[,:]?)\s+\(\((http://slazav\.mccme\.ru/gps/[0-9a-z_-]+\.zip)([^)]*)\)\)\s+\.?$|) ||
          (m|^>()\s+\(\((http://slazav\.mccme\.ru/gps/[0-9a-z_-]+\.zip)([^)]*)\)\)\s+\.?$|)){
        my $text=($1||'').($3||'').' '.($4||'');
        my $url=$2;
        $text =~ s/^\s+[Гг]еоданные[,:]\s+//;
        $text =~ s/\s+/ /g;
        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
        push @{$entry{gps}}, {url=>$url, text=>$text};
#        print "-- $text\n";
        next;
      }
      if (/^> (.*)$/){
         my $text = $1;
         my $text_org = $1;

         while ($text =~ s|\(\((http://slazav\.mccme\.ru/gps/[0-9a-z_-]+\.zip)\s+([^)]+)\)\)|$2|){
           my $gtext=$2;
           my $url=$1;
           $gtext =~ s/\s+/ /g;
           $gtext =~ s/^\s+//;
           $gtext =~ s/\s+$//;
           push @{$entry{gps}}, {url=>$url, text=>$gtext};
#           print "-- $gtext\n";
         }
         if ($text ne $text_org){
#           print ">>>> $text_org\n";
#           print "<<<< $text\n";
           next if $text=~/^\s+$/;
         }
         push @{$entry{text}}, $text;
         next;
      }

      if (/<!-- \/entry -->/){
        foreach (@{$entry{gps}}){
          my $t=$_->{text};
          my $a;
          if ($t=~s/[,\s:]*(В.Завьялов)[а]?//){ $a=$1;}
          if ($t=~s/[,\s:]*(А.Тонис)[а]?//){ $a=$1;}
          if ($t=~s/[,\s:]*(А.Веретенников)[а]?//){ $a=$1;}
          if ($t=~s/[,\s:]*(А.Чупикин)[а]?//){ $a=$1;}
          if ($t=~s/[,\s:]*(О.Волков)[а]?//){ $a=$1;}
          if ($t=~s/[,\s:]*([АО].Чхетиани)//){ $a=$1;}
          delete($_->{text});
          $_->{text} = $t if $t;
          $_->{auth} = $a if $a;

#          print (($t||'')." -- ".($a||'')."\n");
        }
        open OUT, "> ./data_new/$f/$entry{id}.yml"
          or err("Can't open file ./data_new/$entry{id}.yml: $!");
        delete($entry{id});
        print OUT YAML::Tiny::Dump(\%entry)
          or err("Can't write yaml: $!");
        close OUT;
        $read=0; next;
      }
    }
  }
  close IN;
}

