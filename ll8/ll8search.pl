#!/usr/bin/perl -w-
use strict;

use CGI   ':standard';
use ll8;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

print header(-charset=>'koi8-r'), ll8::html_head("search results");

my $text   = defined(param('text')) ? param('text'):'';
my $tag    = defined(param('tag'))  ? param('tag'):'';

$text =~ s/\n/ /g;   # в тексте не должно быть переносов строк!
$text =~ s/</&lt;/g; # и html нам тут не нужен!
$text =~ s/>/&gt;/g;
$text=lc($text);

$tag =~ s/\n/ /g;   # в метках не должно быть переносов строк!
$tag =~ s/</&lt;/g; # и html нам тут не нужен!
$tag =~ s/>/&gt;/g;


###############################################################
my @tags;
my %tbreaks;
open T, $ll8::tagfile or
  ll8::my_err("не читается файл со списком тэгов $ll8::tagfile");;

my $t=0;
foreach(<T>){
  if (/^(\w+)\s+(.*)$/) {
    $t++; 
    my $image = "$ll8::tagurl/$1.png";
    $image = '' unless -f "$ll8::tagdir/$1.png";
    push @tags, {k=>$1, v=>$2, i=>$image};
  }
  if (/^\s+$/){$tbreaks{$t}='';}
}
###############################################################

sub print_entry{
  my $e = $_[0];
  my $t = ll8::txtconv($e->{text});

  my $img_tags = '';
  foreach(@tags){
    if (($e->{tags}=~/\b$_->{k}\b/) && ($_->{i} ne '')) {
      $img_tags.="<img src=\"$_->{i}\" width=20 height=20> \n";
    }
  }

  print qq*
    <table><tr><th onclick="toggle('$e->{file}_$e->{id}');" style="cursor: pointer;">
    <i>$e->{date}</i>&nbsp;&nbsp; 
    $img_tags
    $e->{title}
    </th></tr> <tr id="$e->{file}_$e->{id}" style="display: none"><td>
    $t
    <div align=right>
      <a href="$ll8::showscr?file=$e->{file}&id=$e->{id}">[ссылка]</a>
      <a href="$ll8::editscr?file=$e->{file}&id=$e->{id}">[редактировать]</a> <i>($e->{user}, $e->{time})</i>
    </div>
    </td></tr></table>
  *;
}

###############################################################

my $tag_t='';
foreach (@tags){$tag_t=$_->{v} if $_->{k} eq $tag;}

print "<h2>Результаты поиска ";
if ($tag_t ne '') {print "по метке: <u>", $tag_t, "</u> ";}
if ($text  ne '') {print "по тексту: <u>", $text, "</u> ";}
print "</h2>\n";


ll8::print_nav('','');
ll8::print_srch(\@tags);

foreach my $file (@ll8::files){

  open IN, "$ll8::datadir/$file" or
    ll8::my_err("не читается файл $file");

  my $read=0;
  my %entry=();
  my $prevdate='';

  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  $mon++; $year+=1900;
  my $currdate = sprintf "%04d/%02d/%02d", $year, $mon, $mday;

  foreach (<IN>){
    if ($read==0){
      if (/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/){
        $read=1;
        %entry=();
        $entry{id}=$1;
        $entry{user} = $2;
        $entry{time} = $3;
        $entry{file} = $file;
        $entry{title}='';
        $entry{date}='';
        $entry{tags}='';
        $entry{text}='';
        next;
      }
    }
    if ($read==1){
      if (/^title: (.*)/){ $entry{title} = $1; next; }
      if (/^date: (.*)/){  $entry{date} = $1; next; }
      if (/^tags: (.*)/){  $entry{tags} = $1; next; }
      if (/^> (.*)$/){
        $entry{text}.="\n" if $entry{text} ne '';
        $entry{text}.=$1;
        next;
      }
      if (/<!-- \/entry -->/){
        if (($prevdate gt $currdate)&&($currdate gt $entry{date})){
          print "<p><a name=\"now\"><h3>Сейчас: $currdate</a></h3>\n";
        }
        $prevdate=$entry{date};

        my $e_text=lc($entry{text});
        my $e_title=lc($entry{title});
        if (($tag ne '')  &&  (index($entry{tags}, $tag)>=0)){ print_entry(\%entry);}
        elsif (($text ne '') && ((index($e_title, $text)>=0)||
                              (index($e_text, $text)>=0))){ print_entry(\%entry);}

        $read=0; next;
      }
    }
  }
}

print qq*
<script language="JavaScript">
  function toggle(id){ 
    v = document.getElementById(id).style.display;
    document.getElementById(id).style.display = (v=='none'?'':'none');}
</script>
*;

ll8::print_nav('','');

print ll8::html_tail();
