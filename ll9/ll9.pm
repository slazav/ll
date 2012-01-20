package ll9;
use strict;
use YAML::Tiny;
use JSON;

our $basedir = '.'; # absolute path needed for myauth!
our $baseurl = '../ll8';

our $datadir = "$basedir/data_new";
our $geodir  = "/home/slazav/CH/gps";
our $tagdir  = "$basedir/tags";
our $tagfile = "$tagdir/tags.txt";
our $logfile = "$basedir/log/log.txt";

our $tagurl  = "$baseurl/tags";
our $geourl  = 'http://slazav.mccme.ru/gps';
our $logurl  = "$baseurl/log/log.txt";

our $editscr="ll9edit.pl";
our $showscr="ll9.pl";
our $geoscr="ll9geo.pl";
our $searchscr="ll9search.pl";

my $groups=['2012','2011','2010','2009','2008','2007','2006','2005','2004','2003','2002','2001','2000','1999','1998','old'];


### read one entry
sub read_entry{
  my ($group, $entry) = @_;
  $entry=~s/[^0-9]//g;
  $group=~s/[^a-z0-9_-]//g;
  -f "$datadir/$group/$entry.yml" or return {};
  my $data = YAML::Tiny::LoadFile("$datadir/$group/$entry.yml")
    or return {};
  $data->{id} = $entry;
  return $data;
}

### read a group of entries
sub read_group{
  my $group = $_[0];
  $group=~s/[^a-z0-9_-]//g;
  my $data;
  opendir INDIR, "$ll9::datadir/$group" or return [];
  while (my $f = readdir INDIR){
    next if ($f =~ /^\./);
    $f=~/^([0-9]+)/;
    my $entry = $1;
    push @{$data}, read_entry($group, $entry);
  }
  closedir INDIR;
  return $data;
}

### read tags (with caching)
my $tags; # cache
sub read_tags{
  return $tags if $tags;
  open T, $tagfile or return [];
  foreach(<T>){
    if (/^(\w+)\s+(.*)$/){
      my $image = "$tagurl/$1.png";
      $image = '' unless -f "$tagdir/$1.png";
      push @{$tags}, {name=>$1, text=>$2, image=>$image};
    }
    elsif ((/^\s+$/) && ($#{$tags}>=0)) {
      ${$tags}[$#{$tags}]->{br}=1;
    }
  }
  close T;
  return $tags;
}

### YAML, JSON entries
sub yaml_entry{ print YAML::Tiny::Dump(read_entry(@_)); }
sub json_entry{ print encode_json(read_entry(@_)); }

sub yaml_tags{ print YAML::Tiny::Dump(read_tags()); }
sub json_tags{ print encode_json(read_tags()); }
sub text_tags{
  foreach (@{read_tags()}){
    print $_->{name}."\t".$_->{text}."\t".$_->{image}.($_->{br}?"\n\n":"\n");
  }
}

sub yaml_groups{ print YAML::Tiny::Dump($groups); }
sub json_groups{ print encode_json($groups); }
sub text_groups{ print join "\n", @{$groups}; }

sub default_group{ return @{$groups}[0]; }


### HTML entry
sub html_entry{
  my $group=$_[0];
  my $entry=$_[1];
  my $gr = $_[2] || 0; # "group" style
  my $an = $_[3] || 1; # "anonimous" style

  my $e = read_entry($group, $entry);

  my $tags = read_tags();

  my $r_scr = "$showscr?g=$group&e=$entry";
  my $e_scr = "$editscr?g=$group&e=$entry";
  my $g_scr = "$geoscr?g=$group&e=$entry";
  my $b_scr = "$showscr?g=$group";

  my $displ = $gr ? ' style="display: none"': '';
  my $ref1 =  $gr ? "<a href=\"$r_scr\">[������]</a> ": "<a href=\"$b_scr\">[�� �������� $group]</a> ";
  my $ref2 =  $an ? '':"<a href=\"$e_scr\">[�������������]</a> <a href=\"$g_scr\">[�������� ���������]</a>";

  my $tid=0;
  my $base=1;
  my $txt_tags = '';
  my $img_tags = '';
  foreach my $etag (@{$e->{tags}}){
    foreach my $tag (@{$tags}){
      if ($etag eq $tag->{name}){
        $txt_tags .= ($txt_tags?'':', ') . $tag->{text};
        if ($tag->{image} ne '') {
          $img_tags.="\n    <img src=\"$tag->{image}\" width=20 height=20>";
        }
      }
    }
  }

#  foreach(@{$tags}){
#    if ($e->{tags}=~/\b$_->{name}\b/){
#      $tid+=$base;
#    }
#    $base*=2;
#  }
#  $tables[$entry] = $tid;
  print qq*
    <table id="t$entry"><tr><th onclick="toggle('$entry');" style="cursor: pointer;">
    <i>$e->{date}</i>&nbsp;&nbsp;$img_tags
    $e->{title}
    </th></tr> <tr id="$entry"$displ><td><p>
  *;
  foreach (@{$e->{text}}){
    print "   ", txtconv($_), "<br>\n";
  }
  if ($#{$e->{gps}}>=0){
    print "    <p><hr><ul>";
    foreach (@{$e->{gps}}){
      my $t = $_->{text} || "���������";
      my $a = $_->{auth}; $a="$a: " if $a;
      print qq*
        <li>$a<a href="$_->{url}">$t</a>*;
    }
    print "\n    </ul>";
  }
  print qq*
    <div align=right>$ref1 $ref2
    <i>($e->{cuser}, $e->{ctime})</i></div>
    </td></tr></table>
  *;
#  if ($entry!=0){
#    print "<p><font size=\"-1\">�����: <b>$txt_tags</b></font>\n";
#  }
}


sub ljuser{return "<a href='http://$_[0].livejournal.com/profile'><img src='http://stat.livejournal.sup.com/img/userinfo.gif' alt='[info]' width='17' height='17' style='vertical-align: bottom; border: 0;' /></a><a href='http://$_[0].livejournal.com/'><b>$_[0]</b></a>"}
sub ljcomm{return "<a href='http://community.livejournal.com/$_[0]/profile'><img src='http://stat.livejournal.sup.com/img/community.gif' alt='[info]' width='16' height='16' style='vertical-align: bottom; border: 0;' /></a><a href='http://community.livejournal.com/$_[0]/'><b>$_[0]</b></a>"}

my $lju_image = '<img src="http://stat.livejournal.sup.com/img/userinfo.gif" alt="[info]" width="17" height="17" style="vertical-align: bottom; border: 0;"/>';
my $ljc_image = '<img src="http://stat.livejournal.sup.com/img/community.gif" alt="[info]" width="16" height="16" style="vertical-align: bottom; border: 0;"/>';

### substitutions in text
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

### string representation of current time
sub strtime{
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  return sprintf "%04d/%02d/%02d %02d:%02d:%02d",
     $year+1900, $mon+1, $mday, $hour, $min, $sec;
}

### do log
sub log{
  my ($ctime, $user, $group, $entry, $action, $title) = @_;
  my $fh;
  auth::open_a(\$fh, "$logfile")
    or pcat::my_err("�� ����������� ���� log.txt");
  printf $fh "%19s %-10s %8s %4d %8s %s\n", $ctime, $user, $group, $entry, $action, $title;
  close $fh;
}

### html head
sub html_head{
my $title = $_[0] || 'LL9';
print qq*
<html>
  <head>
    <title>$title</title>
    <meta http-equiv="no-cache">
    <base target="_top">
    <style type="TEXT/CSS">
      BODY {font-family: sans-serif;}
      TH {font-size:15px; background-color: #C0C0C0; text-align: left; padding: 2 1 0 5; margin: 0;}
      TD {font-size:15px; background-color: #E0E0E0; text-align: left; padding: 2 1 0 10; margin: 0;}
      TABLE {border: 0 0 0 0; width: 100%; margin: 1 0 0 0; padding: 0; border-collapse: collapse;}
    </style>
    </head>
  <body>
*;
}

### html tail
sub html_tail{
print qq*
</body></html>
*;
}

### html error message
sub html_err{
  print "<h2><font color=\"\#FF0000\">������: $_[0]</font></h2>\n";
  print html_tail();
  exit();
}

### html navigation bar
sub html_nav{
  my $curr=$_[0] || '';
  my $an=$_[1] || 1; # anonimous mode
  my $scr_a  = "$editscr?g=$curr";
  print "<p><a href=\"$scr_a\">[�������� ������]</a>\n" unless $an || $curr;
  foreach (@{$groups}){
    my $scr_b  = "$showscr?g=$_";
    print (($_ eq $curr)? " [$_]\n": "<a href=\"$scr_b\">[$_]</a>\n");
  }
}

### html search and history forms
sub html_search{
  my $tags=shift;
  print qq*
  <p>
    <form name="search_tag" method="post"
      action="$searchscr" enctype="multipart/form-data">
      <u>������ �����</u> <input name="text" type="text" maxlength="255" size="15">
      <u>��� �����</u> <select name="tag">
      <option>\n*;

  foreach(@{$tags}) {
    print "    <option value=\"$_->{name}\"> $_->{text}"
  }

  print qq*
      </select><input type="submit" name="action" value="ok">
      &nbsp;&nbsp;&nbsp;<a href="$logurl">[������� ���������...]</a>
    </form>
  </p>
  *;
}

1;
