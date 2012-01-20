package ll8;
use strict;

our $basedir = '/home/slazav/CH/ll8'; # absolute path needed for myauth!
our $datadir = "$basedir/data";
our $geodir  = "/home/slazav/CH/gps";
our $tagdir  = "$basedir/tags";
our $tagfile = "$tagdir/tags.txt";
our $logfile = "$basedir/log/log.txt";

our $tagurl  = "../ll8/tags";
our $geourl  = 'http://slazav.mccme.ru/gps';
our $logurl  = "../ll8/log/log.txt";

our $editscr="ll8edit.pl";
our $showscr="ll8show.pl";
our $geoscr="ll8geo.pl";
our $searchscr="ll8search.pl";

our @files=('2012','2011','2010','2009','2008','2007','2006','2005','2004','2003','2002','2001','2000','1999','1998','old');

sub html_head{
return qq*
<html>
<head>
<title>$_[0]</title>
<meta http-equiv="no-cache">
<base target="_top">
<style type="TEXT/CSS">
BODY {font-family: sans-serif;}
TH {font-size:15px; background-color: #C0C0C0; text-align: left; padding: 2 1 0 5; margin: 0;}
TD {font-size:15px; background-color: #E0E0E0; text-align: left; padding: 2 1 0 10; margin: 0;}
TABLE {border: 0 0 0 0; width: 100%; margin: 1 0 0 0; padding: 0; border-collapse: collapse;}
</STYLE>
</head>
<body>
*;
}

sub html_tail{
return qq*
</body></html>
*;
}

sub my_err{
  print "<h2><font color=\"\#FF0000\">Ошибка: $_[0]</font></h2>\n";
  print html_tail();
  exit();
}


sub ljuser{return "<a href='http://$_[0].livejournal.com/profile'><img src='http://stat.livejournal.sup.com/img/userinfo.gif' alt='[info]' width='17' height='17' style='vertical-align: bottom; border: 0;' /></a><a href='http://$_[0].livejournal.com/'><b>$_[0]</b></a>"}
sub ljcomm{return "<a href='http://community.livejournal.com/$_[0]/profile'><img src='http://stat.livejournal.sup.com/img/community.gif' alt='[info]' width='16' height='16' style='vertical-align: bottom; border: 0;' /></a><a href='http://community.livejournal.com/$_[0]/'><b>$_[0]</b></a>"}

my $lju_image = '<img src="http://stat.livejournal.sup.com/img/userinfo.gif" alt="[info]" width="17" height="17" style="vertical-align: bottom; border: 0;"/>';
my $ljc_image = '<img src="http://stat.livejournal.sup.com/img/community.gif" alt="[info]" width="16" height="16" style="vertical-align: bottom; border: 0;"/>';

sub txtconv{
  my $ret='';
  return $ret if !defined($_[0]);
  foreach(split /\n/, $_[0]){
    my $l=$_;
    $l=~s/\(\(([^\s\)]+)\s+([^\)]+)\)\)/<a href="$1">$2<\/a>/g;
    $l=~s/\(\(([^\s\)]+)\)\)/<a href="$1">$1<\/a>/g;
    $l=~s/\[\[([^\s\)]+)\s+([^\)]+)\]\]/<table><tr><td><img src="$1" alt=$2><br><i>$2<\/i><\/td><\/tr><\/table>/g;
    $l=~s/\[\[([^\s\)]+)\]\]/<img src="$1">/g;
    $l=~s*&lt;lj user=(\w+)&gt;*<a href='http://user.livejournal.com/$1/profile'>$lju_image</a><a href='http://user.livejournal.com/$1/'><b>$1</b></a>*g;
    $l=~s*&lt;lj community=(\w+)&gt;*<a href='http://community.livejournal.com/$1/profile'>$ljc_image</a><a href='http://community.livejournal.com/$1/'><b>$1</b></a>*g;
    $ret.="<br>\n" if $ret ne '';
    $ret.=$l;
  }
  return $ret;
}

sub strtime{
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  return sprintf "%04d/%02d/%02d %02d:%02d:%02d",
     $year+1900, $mon+1, $mday, $hour, $min, $sec;
}

sub log{
  my ($ctime, $user, $file, $id, $action, $title) = @_;
  my $fh;
  auth::open_a(\$fh, "$logfile")
    or pcat::my_err("не открывается файл log.txt");
  printf $fh "%19s %-10s %8s %4d %8s %s\n", $ctime, $user, $file, $id, $action, $title;
  close $fh;
}

sub print_nav{
  my $file=shift;
  my $user=shift;
  my $scr_a  = "$editscr?file=$file";
  print "<p><a href=\"$scr_a\">[добавить запись]</a>\n" if $user ne '';
  foreach (@files){
    my $scr_b  = "$showscr?file=$_";
    print (($_ eq $file)? " [$_]\n": "<a href=\"$scr_b\">[$_]</a>\n");
  }
}

sub print_srch{
  my $tags=shift;
  print qq*
  <p>
    <form name="search_tag" method="post"
      action="$searchscr" enctype="multipart/form-data">
      <u>Искать текст</u> <input name="text" type="text" maxlength="255" size="15">
      <u>или метку</u> <select name="tag">
      <option>\n*;

  foreach(@{$tags}) {
    print "    <option value=\"$_->{k}\"> $_->{v}"
  }

  print qq*
      </select><input type="submit" name="action" value="ok">
      &nbsp;&nbsp;&nbsp;<a href="$logurl">[История изменений...]</a>
    </form>
  </p>
  *;
}

1;
