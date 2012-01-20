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
  next if ($f =~ /^\./) || -d $f;

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

          print (($t||'')." -- ".($a||'')."\n");
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


__END__

use CGI   ':standard';
use auth;
use ll8t;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

my $user=auth::login();

my $file  = defined(param('file')) ? param('file') : $ll8::files[0];
my $id    = defined(param('id')) ? param('id') : 0;
$file =~ s/^.*\///;

print  ll8::html_head("Каталог походов: $file");
ll8::my_err("id is not a number ($id)") if ($id !~/^\d+$/);

### Чтение тэгов -- вынести в pcat.pm, убрать %tbreaks
my @tags;
my %tbreaks;
open T, $ll8::tagfile or
  ll8::my_err("не читается файл со списком тэгов $ll8::tagfile");
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

### Печать записи -- вынести в pcat.pm
sub print_entry{
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
#    print "<p><font size=\"-1\">Метки: <b>$txt_tags</b></font>\n";
#  }
}

open IN, "$ll8::datadir/$file" or
  ll8::my_err("не читается файл $file");

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
  for(my $i=0;$i<=$#tags;$i++){
    if (exists $tbreaks{$i}) {print " <br>\n"; $st=1;}
    print qq*<b id="tag$i" onclick="tag_scr($i)">$tags[$i]->{v}</b>, *;
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
        print "<p><a name=\"now\"><h3>Сейчас: $currdate</a></h3>\n";
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
