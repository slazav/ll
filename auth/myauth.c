#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>

#define PWD_FILE "/usr/home/slazav/auth/pwd.txt"
#define LOG_FILE "/usr/home/slazav/auth/log.txt"

const char *allowed_dirs[] = {
  "/home/slazav/sti/",
  "/home/slazav/CH/ll8/data/",
  "/home/slazav/CH/ll8/log/",
  "/home/slazav/CH/gps/",
NULL};

void __attribute__ ((noreturn))
usage(){
  printf("myauth - suid program to be used in cgi-scripts for password handling\n");
  printf("usage: myauth check <user> <passwd>\n");
  printf("       myauth write  <user> <passwd> <file>\n");
  printf("       myauth append <user> <passwd> <file>\n");
  exit(1);
}

///
void __attribute__ ((format (printf, 1, 2)))
mylog(char *format, ...){
  FILE *LOG;
  va_list args;

  LOG=fopen(LOG_FILE, "a");
  if (LOG==NULL){
    fprintf(stderr, "can't log password file\n");
    exit(1);
  }

  va_start(args, format);
  vfprintf(LOG, format, args);
  va_end(args);
  close(LOG);
}

/// check password
int mycheck(const char *user, const char *pass){
  FILE *PW;
  int res = -1;
  char buf[1024], *c;

  PW=fopen(PWD_FILE, "r");
  if (PW==NULL){
    fprintf(stderr, "can't open password file\n");
    exit(1);
  }

  while (!feof(PW)){
    fgets(buf, sizeof(buf), PW);

    if (buf[0]=='#') continue; // skipping comments

    c=strchr(buf, '\n');
    if (c!=NULL) *c='\0'; // removing newline

    c=strchr(buf, ':');
    if (c==NULL) continue; // skipping lines without ':' separator

    *c='\0'; c++; /* now buf points to username, c points to password*/

    if (!strcmp(user,buf) && !strcmp(pass,c)) {
      res=0;
      break;
    }
  }
  fclose(PW);
  if (res!=0) sleep(2);
  return res;
}

///
int mywrite(const char *user, const char *pass,
            const char *file, const char *mode){

  if (mycheck(user,pass)!=0) exit(-1);

  int i=0;
  int res=-2;
  const char *dir;

  while ((dir=allowed_dirs[i++]) != NULL){
    if ((strlen(file)>strlen(dir)) &&
        (strncmp(dir, file, strlen(dir)) == 0) &&
        (strchr(file+strlen(dir), '/') == NULL)){ // check for / in filename
      res=0;
      break;
    }
  }
  if (res!=0) return res;

  FILE *F;
  char buf[1024];
  F=fopen(file, mode);
  if (F==NULL) return -3;

  int sum=0;
  while (!feof(stdin)){
    int count=fread(buf, 1, sizeof(buf), stdin);
    if (ferror(stdin)) return -4;
    fwrite(buf, 1, count, F);
    if (ferror(F)) return -4;
    sum+=count;
  }
  fclose(F);
  return sum;
}


///
int main(int argc, char *argv[]){
  if (argc<4) usage();

  const char *action=argv[1];
  const char *user=argv[2];
  const char *pass=argv[3];

  // create time string for logging
  char tstr[20] = "";
  time_t t=time(NULL);
  struct tm *tmp = localtime(&t);
  if (tmp != NULL) {
    if (strftime(tstr, sizeof(tstr), "%F %T", tmp) == 0)
      strncpy(tstr,"",strlen(tstr));
  }

  // check password
  if (!strcmp(action, "check")){
    int res=mycheck(user,pass);
    mylog("%19s %6s %s = %i\n", tstr, action, user, res);
    exit(res);
  }

  // write/append file
  if (!strcmp(action, "write") ||
      !strcmp(action, "append")){
    if (argc<5) usage();
    const char *file=argv[4];
    char mode[3]; mode[0]=action[0]; mode[1]='\0';
    int res=mywrite(user, pass, file, mode);
    mylog("%19s %6s %s by %s = %i\n", tstr, action, file, user, res);
    exit(res<0 ? res:0);
  }

  usage();
}

