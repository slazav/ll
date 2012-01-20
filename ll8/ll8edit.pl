#!/usr/bin/perl -w
use strict;
use locale;

use CGI   ':standard';
use ll8;
use auth;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

#   ?file=f      -- вывести форму добавления записи
#   ?file=f&id=i -- вывести форму редактирования записи
#   ?file=f&id=i&action=... -- реальное изменение файла

my $user = auth::login();
ll8::my_err("мы вас не знаем!") if ($user eq '');

my $id    = defined(param('id')) ? param('id') : 0;
my $file  = defined(param('file')) ? param('file') : '';   $file =~ s/^.*\///;
my $title   = defined(param('title')) ? param('title'):'';
my $text    = defined(param('text')) ? param('text'):'';
my $tags    = defined(param('tags')) ? param('tags'):'';
my $date    = defined(param('date')) ? param('date'):'';
my $action  = defined(param('delete')) ? 'delete':
                defined(param('edit')) ? 'edit': '';

# Уберем лишнее. Мало ли что люди напишут!
ll8::my_err("id is not a number ($id)")
  if ($id !~/^\d+$/);

$title =~ s/\n/ /g;   # в заголовке не должно быть переносов строк!
$title =~ s/</&lt;/g; # и html нам тут не нужен!
$title =~ s/>/&gt;/g;

$date =~ s/\n/ /g;   # в дате не должно быть переносов строк!
$date =~ s/</&lt;/g; # и html нам тут не нужен!
$date =~ s/>/&gt;/g;

$tags =~ s/\n/ /g;   # в метках не должно быть переносов строк!
$tags =~ s/</&lt;/g; # и html нам тут не нужен!
$tags =~ s/>/&gt;/g;

$text =~ s/</&lt;/g; # text может состоять из нескольких строк, но тоже
$text =~ s/>/&gt;/g; # без html

my $ctime = ll8::strtime();

my @tags;
open T, $ll8::tagfile or
  ll8::error("не читается файл со списком тэгов");
foreach(<T>){
  if (/^(\w+)\s+(.*)$/) {
    push @tags, {k=>$1, v=>$2};
    if ((defined param("tag_$1"))&&(param("tag_$1") eq 'on')){
      $tags.=" $1";
    }
  }
  if (/^\s+$/){push @tags, undef;}
}


if ($action eq ''){
  # пишем форму и выходим
  # значения по умолчанию берем из файла.
  $title =''; $date=''; $tags=''; $text='';

  open IN, "$ll8::datadir/$file" or
    ll8::my_err("не читается файл $file");

  my $read=0;
  foreach (<IN>){
    if (($read==0) && (/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/)&&($id eq $1)){
      $read=1; next;
    }
    if ($read==1){
      if (/^title: (.*)/){ $title = $1; next; }
      if (/^date: (.*)/) { $date = $1; next;}
      if (/^tags: (.*)/) { $tags = $1; next;}
      if (/^> (.*)$/){
        $text.="\n" if defined($text);
        $text.=$1;
         next;
      }
      if (/<!-- \/entry -->/){ last; }
    }
  }

  print qq*
    <p><form name="edit_entry" method="post" enctype="multipart/form-data">
    <input name="file"  type="hidden"   value="$file">
    <input name="id"    type="hidden"   value="$id">
    <p>Заголовок:         <input name="title" type="text" maxlength="255" size="70" value="$title">
    <p>Даты (yyyy/mm/dd): <input name="date" type="text" maxlength="255" size="60" value="$date"><br>
    <p>Текст:<br>
    <textarea name="text" rows=10 cols=85 wrap=soft>$text</textarea>
    <p>
    <p>Метки:<br>
  *;

  foreach (@tags){
    if (!defined($_)){ print "<br>\n"; }
    else {
      my $val = (($tags =~ /\b$_->{k}\b/) ? 'checked':'');
      print "<input type=\"checkbox\" name = \"tag_$_->{k}\" $val> $_->{v}<br>\n";
    }
  }

  print qq*
    <p><input type="submit" name="edit" value="edit">
    <input type="submit" name="delete" value="delete">
    </form>
    <p>Порядок записей на странице определяется датами. Так что если криво введете дату - запись попадет непонятно куда!
    Формат даты - самый естественный с точки зрения сортировки: 2006/11/30 или 2005/01/22-02/23 и.т.п. Если захочется
    другой формат - можно попробовать сделать...
    <p>html во всех полях запрещен. В тексте пока есть только одна нетривиальная функция разметки - ссылки 
    записываются так: ((http://ref.ru/ текст ссылки)) или же просто ((http://ref.ru/))
  *;
  print ll8::html_tail();
  exit();
}


# открываем нужный файл

my $fh;
open $fh, "$ll8::datadir/$file" or ll8::my_err("не читается файл $file");

# смотрим, какого id еще не было, смотрим, каким id соответствуют какие даты
my %dates;
my $maxid=0;
my $lastid=0;
foreach(<$fh>){
  if (/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/){
    $lastid=$1;
    if ($maxid<$1) {$maxid=$1;}
    next;
  }
  if (/!-- \/entry -->/){$lastid=0;}
  if (($lastid!=0)&&(/^date: (.*)$/)){$dates{$lastid}=$1;}
}
if ($id==0){
  $id=$maxid+1;
  $action='new';
}

seek ($fh, 0, 0);

# считаем, что файл отсортирован по датам
# перекидываем все в tmp,  пропускаем запись с $id,
# вставляем (если action ne 'delete') новую запись в
# соответствии с сортировкой

sub getentry{
  my $ret = '';
  $ret.= "<!-- entry $id $user $ctime -->\n";
  $ret.= "title: $title\n";
  $ret.= "tags: $tags\n";
  $ret.= "date: $date\n";
  foreach(split /\n/, $text) {s/\r//g; $ret.= "> $_\n";}
  $ret.= "<!-- /entry -->\n";
  return $ret;
}

my $skip=0;
my $done=0;

my @in_lines=<$fh>;

my $outh;
auth::open_w(\$fh, "$ll8::datadir/$file")
   or ll8::my_err("не могу записать файл $file");

foreach(@in_lines){
  if (/<!-- entry (\d+)\s+(\S+)\s+(\S+\s+\S+)\s+-->/){
    if ($1 == $id){$skip=1; next;}
    if (($dates{$1} lt $date)&&($done==0)&&($action ne 'delete')){
      print $fh getentry();
      $done=1;
    }
  }
  if ($skip==1){
    $skip = 0 if /<!-- \/entry -->/;
    next;
  }
  print $fh $_;
}
if (($done==0)&&($action ne 'delete')){
  print $fh getentry();
}

close($fh) or ll8::my_err("can't close data file");

if ($action eq 'delete'){  print "<p><b>Запись удалена!</b>\n"; }
elsif ($action eq 'new'){  print "<p><b>Запись добавлена!</b>\n"; }
else {                     print "<p><b>Запись отредактирована!</b>\n"; }

print "<p><a href=\"$ll8::showscr?file=$file\">[на страницу $file]</a>\n";
print "   <a href=\"$ll8::showscr?file=$file&id=$id\">[посмотреть запись]</a>\n" if ($action ne 'delete');

ll8::log($ctime, $user, $file, $id, $action, $title);

print ll8::html_tail();
