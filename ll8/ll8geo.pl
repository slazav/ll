#!/usr/bin/perl -w
use strict;

use CGI   ':standard';
use ll8;
use auth;

use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "ru_RU.KOI8-R");

my $user=auth::login();
ll8::my_err("�� ��� �� �����!") if ($user eq '');

my $id    = defined(param('id')) ? param('id') : '';
my $file  = defined(param('file')) ? param('file') : ''; $file =~ s/^.*\///;
my $desc    = defined(param('desc')) ? param('desc'):'';
my $auth    = defined(param('auth')) ? param('auth'):'';
my $geofile = defined(param('geofile')) ? param('geofile'):'';

my $err     = defined(param('err')) ? param('err'):'0';
my $action  = defined(param('action')) ? param('action'):'';

# ������ ������. ���� �� ��� ���� �������!
ll8::my_err("id is not a number ($id)")
  if ($id !~/^\d+$/);

$desc =~ s/\n/ /g;   # �� ������ ���� ��������� �����!
$desc =~ s/</&lt;/g; # � html ��� ��� �� �����!
$desc =~ s/>/&gt;/g;

$auth =~ s/\n/ /g;   # �� ������ ���� ��������� �����!
$auth =~ s/</&lt;/g; # � html ��� ��� �� �����!
$auth =~ s/>/&gt;/g;

$geofile =~ s/\n/ /g;   # �� ������ ���� ��������� �����!
$geofile =~ s/</&lt;/g; # � html ��� ��� �� �����!
$geofile =~ s/>/&gt;/g;

my $ctime = ll8::strtime();

my @errors = ( '', # 0
'<font color="#000088">����� ������ ���� �� ������!</font>',     # 1
'<font color="#008800">��������� ���� ������� ��������! ������ �������� ���-������ ���.</font>', # 2
'<font color="#008800">��������� ���� ������� ��������! ������ �������� ���-������ ���.</font>', # 3
'<font color="#880000">����� ������ ���� �� ������!</font>',        # 4
'<font color="#880000">������: �� ������� ��������!</font>',     # 5
'<font color="#880000">������: �� ������� ��� �����!</font>',    # 6
'<font color="#880000">����� ������ ���� �� ������!</font>',         # 7
'<font color="#880000">������: �������� ����� ������ ����� ���: 20060121aa.zip!</font>', # 8
'<font color="#880000">������ ��� �������� �����!</font>',       # 9
'<font color="#880000">���� � ����� ������ ��� ����������. ��������� ��������, ����� ������������ ���, ��� ��������� ��������.</font>',   # 10
'<font color="#880000">������: �� ���� �������� ���� ���������!</font>',   # 11
'<font color="#880000">������: �� ���� ������� $file ��� ������!</font>',   # 13
'<font color="#880000">������: �� ���� ������� $file ��� ������!</font>',   # 14
);

# �������� ����, ���� �����, ������� ������ ������� � ����� ������
if ($err  == 0)                         {goto SKIP;};
if ($geofile eq '')                     {$err=6; goto SKIP;};
if ($geofile!~/(\d\d\d\d)(\d\d)(\d\d)([a-z][a-z]).zip$/) {$err=8; goto SKIP;}
my $fn = "$1$2$3$4.zip";

if ((-f "$ll8::geodir/$fn")&&($err!=10)){$err=10; goto SKIP;}
my $fh = upload('geofile');
if (!$fh) {$err=9; goto SKIP;}

my $O;
if (!auth::open_w(\$O, "$ll8::geodir/$fn")) {$err=11; goto SKIP;}
foreach (<$fh>) { print $O $_; } close $O;

my $text = "> (($ll8::geourl/$fn ���������".
 (($desc eq '')?'':": $desc").
 (($auth eq '')?'':", $auth")."))\n";

if (!open I, "$ll8::datadir/$file")  {$err=13; goto SKIP;};
my @in_lines=<I>; close I;

if (!auth::open_w(\$O, "$ll8::datadir/$file")) {$err=14; goto SKIP;};
my $mode = 0;
foreach (@in_lines){
  if (/<!-- entry\s+$id\s+/){$mode = 1;}
  if (($mode==1)&&(/<!--\s+\/entry\s+-->/)) {$mode=0; print $O $text;}
  print $O $_;
}
close $O;


if ($err == 10) {
  ll8::log($ctime, $user, $file, $id, "geo_rpl", "$fn: $desc, $auth");
  $err=3;
} else{
  ll8::log($ctime, $user, $file, $id, "geo_add", "$fh: $desc, $auth");
  $err=2;
}

$desc='';
$auth='';

SKIP:

my $newerr=$err;
$newerr=1 if $err==0;


if (($err==2)||($err==3)) {
  print qq*
  <h3>��������� ��������!</h3>
  <p>������: <a href="$ll8::geourl/$fn">$ll8::geourl/$fn</a>
  <p><a href="$ll8::showscr?file=$file">[�� �������� $file]</a>
     <a href="$ll8::showscr?file=$file&id=$id">[���������� ������]</a>
  *;
  print ll8::html_tail();
  exit();
}

my $cgi_err = cgi_error();

print qq%
  <h3>������������ ���������</h3>
  <h3>$errors[$err]</h3>
  <h3>$cgi_err</h3>
  <p><form name="gettrack" method="post" action="" enctype="multipart/form-data">
     <input name="err"   type="hidden"   value="$newerr">
     <input name="file"  type="hidden"   value="$file">
     <input name="id"    type="hidden"   value="$id">
  <p><font color="#FF0000">*</font>ZIP-����� � ����������:
     <input name="geofile" type="file" maxlength="255" size="47" value="$geofile">
  <p>�������� (������� � �.�.):<br>
     <textarea name="desc" rows=3 cols=85 wrap=soft>$desc</textarea>
  <p>��� ������:  <input name="auth" type="text" maxlength="255" size="32" value="$auth">
     <input type="submit" name="Send" value="OK">
     <input type="reset"  value="Clear">
  </form>
  <p> ��������� �������������� �������� ���:
  <ul>
  <li>Zip-�����: 20060910wz.zip (� �������� ����� - ���� � �������� (2 �����) ������ ���������)
  <li>��������: ��������� ������� - �������, 45 ��
  <li>��� ������: �.��������
  </ul>
  <p> html-���� �� ���� ���� ����� �� ��������.
%;

print ll8::html_tail();
