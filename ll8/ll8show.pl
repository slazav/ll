#!/usr/bin/perl -w
use strict;

use CGI   ':standard';
use auth;
use ll8;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

my $user=auth::login();

my $file  = defined(param('file')) ? param('file') : $ll8::files[0];
my $id    = defined(param('id')) ? param('id') : 0;
$file =~ s/^.*\///;

print  ll8::html_head("������� �������: $file");
ll8::my_err("id is not a number ($id)") if ($id !~/^\d+$/);

### ������ ����� -- ������� � pcat.pm, ������ %tbreaks
my @tags;
my %tbreaks;
open T, $ll8::tagfile or
  ll8::my_err("�� �������� ���� �� ������� ����� $ll8::tagfile");
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
###

my @tables;

### ������ ������ -- ������� � pcat.pm
sub print_entry{
  my $e = $_[0];
  my $t = ll8::txtconv($e->{text});

  my $r_scr = "$ll8::showscr?file=$file&id=$e->{id}";
  my $e_scr = "$ll8::editscr?file=$file&id=$e->{id}";
  my $g_scr = "$ll8::geoscr?file=$file&id=$e->{id}";
  my $b_scr = "$ll8::showscr?file=$file";

  my $displ = ($id==0) ? ' style="display: none"': '';
  my $ref1 =  ($id==0) ? "<a href=\"$r_scr\">[������]</a> ": "<a href=\"$b_scr\">[�� �������� $file]</a> ";
  my $ref2 =  ($user ne '') ? "<a href=\"$e_scr\">[�������������]</a> <a href=\"$g_scr\">[�������� ���������]</a>":'';

  my $tid=0;
  my $base=1;
  my $txt_tags = '';
  my $img_tags = '';
  foreach(@tags){
    if ($e->{tags}=~/\b$_->{k}\b/){ 
      $tid+=$base;
      $txt_tags .= ', ' if ($txt_tags ne '');
      $txt_tags .= $_->{v};
      if ($_->{i} ne '') {
        $img_tags.="<img src=\"$_->{i}\" width=20 height=20> \n";
      }
    } 
    $base*=2;
  }
  $tables[$e->{id}] = $tid;
  print qq*
    <table id="t$e->{id}"><tr><th onclick="toggle('$e->{id}');" style="cursor: pointer;">
    <i>$e->{date}</i>&nbsp;&nbsp; 
    $img_tags
    $e->{title}
    </th></tr> <tr id="$e->{id}"$displ><td>
    $t
    <div align=right>$ref1 $ref2
    <i>($e->{user}, $e->{time})</i></div>
    </td></tr></table>
  *;
#  if ($id!=0){
#    print "<p><font size=\"-1\">�����: <b>$txt_tags</b></font>\n";
#  }
}

open IN, "$ll8::datadir/$file" or
  ll8::my_err("�� �������� ���� $file");

###

if ($id==0){
  my $auth_form=auth::form($user);
  print qq*
  <p><table cellpadding=0 cellspacing=0>
  <tr>
    <td><font size="+1"><b>������� �������: $file</d></font></td>
    <td><div align="right">$auth_form</div></td>
  </tr>
  </table>
  *;
  ll8::print_nav($file, $user);
}

# ������ ����� -- ������??
if ($id==0){
#if (0){
  print qq* <p><u>�������� �������� � �������:</u>
  <br><font size="-1" style="color: blue; cursor: pointer">
  <b id="a0" onclick="act(0)" style="color: blue">�������� ������ ������ � ������ ������</b><br>
  <b id="a1" onclick="act(1)" style="color: grey">�������� ��� ������ ��� ������ �����</b><br>
  <b id="a2" onclick="act(2)" style="color: grey">�������� ������, ���������� �����</b><br>
  <b id="a3" onclick="act(3)" style="color: grey">������ ������, ���������� �����</b><br>
  </font>
  <p><u>�������� �����:</u>
  <br><font size="-1" style="color: blue; cursor: pointer">
  *;
  my $st=1;
  for(my $i=0;$i<=$#tags;$i++){
    if (exists $tbreaks{$i}) {print " <br>\n"; $st=1;}
    print qq*<b id="tag$i" onclick="tag_scr($i)">$tags[$i]->{v}</b>, *;
  }
  print qq* 
  <p><b onclick="all_on()">[�������� ��� ������]</b>
     <b onclick="all_off()">[������ ��� ������]</b>
  </font>
  <p>
  *;
}

ll8::print_srch(\@tags) if $id==0;

my $read=0;
my %entry;
my $prevdate='';

my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
$mon++; $year+=1900;
my $currdate = sprintf "%04d/%02d/%02d", $year, $mon, $mday;


foreach (<IN>){
  if ($read==0){
    if ((/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/)
        &&(($id == 0)||($id eq $1))){
      $read=1;
      %entry=();
      $entry{id}=$1;
      $entry{user} = $2;
      $entry{time} = $3;
      next;
    }
    print if ($id == 0);
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
      if (($prevdate ge $currdate)&&($currdate gt $entry{date})){
        print "<p><a name=\"now\"><h3>������: $currdate</a></h3>\n";
      }
      $prevdate=$entry{date};
      print_entry(\%entry);
      $read=0; next;
    }
  }
}

my $tarray='';
foreach (@tables){
  $tarray.=',' if $tarray ne '';
  $tarray.=((defined($_))&&($_ ne ''))? $_:'0';
}

print qq*
<script language="JavaScript">
  function toggle(id){ 
    v = document.getElementById(id).style.display;
    document.getElementById(id).style.display = (v=='none'?'':'none');}
  var a = 0;
  var tmax = $#tables;
  function act(n){ a=n; for (var i=0;i<4;i++) {document.getElementById('a'+i).style.color = ((i==a)?'blue':'grey');} }
  var tarr = new Array($tarray);
  function all_on() { for (var i=0;i<=tmax;i++) {if (tarr[i]==0) {continue;}; document.getElementById('t'+i).style.display = '';} }
  function all_off(){ for (var i=0;i<=tmax;i++) {if (tarr[i]==0) {continue;}; document.getElementById('t'+i).style.display = 'none';} }
  function tag_scr(t){
    for (var i=0;i<=tmax;i++) {
      if (tarr[i]==0) {continue;};
      if (a==0) { document.getElementById('t'+i).style.display = (tarr[i] & (1<<t)) ? '':'none'; }
      if (a==1) { document.getElementById('t'+i).style.display = (tarr[i] & (1<<t)) ? 'none':''; }
      if ((a==2)&&(tarr[i] & (1<<t))) { document.getElementById('t'+i).style.display = ''; }
      if ((a==3)&&(tarr[i] & (1<<t))) { document.getElementById('t'+i).style.display = 'none'; }
    }
  }
</script>
*;

ll8::print_nav($file, $user) if $id==0;

print ll8::html_tail();
