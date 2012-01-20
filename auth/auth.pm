package auth;

use strict;
use warnings;
use CGI   ':standard';
use CGI::Session;
use Digest::MD5 'md5_hex';

our $myauth="/usr/home/slazav/auth/myauth";
my $session;

sub login{
  $session = new CGI::Session();
  $session->expire('+48h');  
  print $session->header('charset' => 'koi8-r');

  if (defined param('LogIn')) {
    my $name=param('name');
    my $pass=md5_hex(param('pass'));
    return '' unless defined($name) && defined($pass);

    if (system($myauth, "check", "$name", "$pass") == 0){
      $session->param('name', $name);
      $session->param('pass', $pass);
      $session->flush();
      return $name;
    } else {
      $session->delete();
      return '';
    }
  }
  elsif (defined param('LogOut')) {
    $session->delete();
    return '';
  }
  else{
    my $name=$session->param('name');
    $name='' unless defined $name;
    return $name;
  }
}

sub form{
  my $name=shift;
  my $url=shift;
  if ($name eq ''){
    return qq*<form method="post" action="">
    имя: <input name="name" type="text" maxlength="15" size="10"/>
    пароль: <input name="pass" type="password" maxlength="15" size="10"/>
    <input type="submit" value="войти" name="LogIn"/>
    </form>*;
  } else {
    return qq*<form method="post" action="">
    <b>$name</b>
    <input type="submit" value="выйти" name="LogOut"/>
    </form>*;
  }
}

sub open_w{
    my $fh=shift;
    my $file=shift;
    my $name=$session->param('name');
    my $pass=$session->param('pass');
    return 0 if (!defined($name)) || (!defined($pass));
    return open(${$fh}, "| $myauth write \"$name\" \"$pass\" \"$file\"");
}

sub open_a{
    my $fh=shift;
    my $file=shift;
    my $name=$session->param('name');
    my $pass=$session->param('pass');
    return 0 if (!defined($name)) || (!defined($pass));
    return open(${$fh}, "| $myauth append \"$name\" \"$pass\" \"$file\"");
}

1;
