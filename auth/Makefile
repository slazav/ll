all: myauth

push_files=myauth.c pwd.txt Makefile
pull_files=pwd.txt log.txt

myauth: myauth.c
	$(CC) $< -o $@
	strip $@
	chmod 4711 $@
	chmod 600 pwd.txt

push:
	scp $(push_files) mccme:auth/
	ssh mccme scp $(patsubst %, auth/%, $(push_files)) www:auth/
	ssh mccme ssh www make -C auth

pull:
	ssh mccme mkdir -p auth
	ssh mccme scp $(patsubst %, www:auth/%, $(pull_files)) auth/
	scp $(patsubst %, mccme:auth/%, $(pull_files)) .
