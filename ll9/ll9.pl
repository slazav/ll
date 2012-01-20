#!/usr/bin/perl -w
use strict;

use CGI   ':standard';
use YAML::Tiny;
use auth;
use ll9;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

my $user=auth::login();

my $file  = defined(param('f')) ? param('f') : $ll8::files[0];
my $id    = defined(param('e')) ? param('e') : 0;
my $fmt   = defined(param('fmt')) ? param('fmt') : 0;

$file =~ s/^.*\///;
$file =~ s/[^a-z0-9_-]//g;
$id =~ s/[^0-9]//g;

print  ll8::html_head("Каталог походов: $file");


my $tags = ll9::read_tags();


my @tables;
### Печать записи -- вынести в pcat.pm
sub print_entry_htm{
  my $e = $_[0];
  my $t = ll8::txtconv($e->{text});

  my $r_scr = "$ll8::showscr?file=$file&id=$e->{id}";
  my $e_scr = "$ll8::editscr?file=$file&id=$e->{id}";
  my $g_scr = "$ll8::geoscr?file=$file&id=$e->{id}";
  my $b_scr = "$ll8::showscr?file=$file";

  my $displ = ($id==0) ? ' style="display: none"': '';
  my $ref1 =  ($id==0) ? "<a href=\"$r_scr\">[ссылка]</a> ": "<a href=\"$b_scr\">[на страницу $file]</a> ";
  my $ref2 =  ($user ne '') ? "<a href=\"$e_scr\">[редактировать]</a> <a href=\"$g_scr\">[добавить геоданные]</a>":'';

  my $tid=0;
  my $base=1;
  my $txt_tags = '';
  my $img_tags = '';
  foreach(@{$tags}){
    if ($e->{tags}=~/\b$_->{name}\b/){ 
      $tid+=$base;
      $txt_tags .= ', ' if ($txt_tags ne '');
      $txt_tags .= $_->{text};
      if ($_->{image} ne '') {
        $img_tags.="<img src=\"$_->{image}\" width=20 height=20> \n";
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
#    print "<p><font size=\"-1\">Метки: <b>$txt_tags</b></font>\n";
#  }
}


### read data
my @data;
if ($id){
  push @data, YAML::Tiny::LoadFile("$ll8::datadir/$file/$id.yml")
    or my_err("Can't read yaml: $!");
  $data[$#data]->{id} = $id;
}
else {
  opendir INDIR, "$ll8::datadir/$file" or
    ll8::my_err("не читается $file");
  while (my $datafile = readdir INDIR){
    next if ($datafile =~ /^\./);
    push @data, YAML::Tiny::LoadFile("$ll8::datadir/$file/$datafile")
      or my_err("Can't read yaml: $!");
    $datafile=~/^([0-9]+)/;
    $data[$#data]->{id} = $1;
  }
}

###

if ($id==0){
  my $auth_form=auth::form($user);
  print qq*
  <p><table cellpadding=0 cellspacing=0>
  <tr>
    <td><font size="+1"><b>Каталог походов: $file</d></font></td>
    <td><div align="right">$auth_form</div></td>
  </tr>
  </table>
  *;
  ll8::print_nav($file, $user);
}

# печать меток -- убрать??
if ($id==0){
#if (0){
  print qq*  <table>
  <tr><th onclick="toggle('tag_actions');" style="cursor: pointer;">
  Действия с метками...
  </th></tr>
  <tr><td id="tag_actions" style="display: none">
  <br><font size="-1" style="color: blue; cursor: pointer">
  <b id="a0" onclick="act(0)" style="color: blue">показать только записи с данной меткой</b><br>
  <b id="a1" onclick="act(1)" style="color: grey">показать все записи без данной метки</b><br>
  <b id="a2" onclick="act(2)" style="color: grey">добавить записи, содержащие метку</b><br>
  <b id="a3" onclick="act(3)" style="color: grey">убрать записи, содержащие метку</b><br>
  </font>
  <p><u>Выберете метку:</u>
  <br><font size="-1" style="color: blue; cursor: pointer">
  *;
  my $st=1;
  for(my $i=0;$i<=$#{$tags};$i++){
    if ($tags->[$i]->{br}) {print " <br>\n"; $st=1;}
    print qq*<b id="tag$i" onclick="tag_scr($i)">$tags->[$i]->{text}</b>, *;
  }
  print qq* 
  <p><b onclick="all_on()">[показать все записи]</b>
     <b onclick="all_off()">[убрать все записи]</b>
  </font>
  <p>
  </td></tr>
  </table>
  *;
}

ll8::print_srch($tags) if $id==0;

my $read=0;
my %entry;
my $prevdate='';

my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
$mon++; $year+=1900;
my $currdate = sprintf "%04d/%02d/%02d", $year, $mon, $mday;


foreach (@data){
  if (($prevdate ge $currdate)&&($currdate gt $entry{date})){
    print "<p><a name=\"now\"><h3>Сейчас: $currdate</a></h3>\n";
  }
  $prevdate=$_->{date};
  print_entry_htm($_);
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
