all: c
	@echo Done..
	
clean:
	rm -f liblibreria.so
	rm -f libreria.o
	rm -f c
	rm -f /usr/local/lib/liblibreria.so
	rm -f /usr/local/bin/c

install: c liblibreria.so
	cp liblibreria.so /usr/local/lib
	cp ./c /usr/local/bin
	ldconfig
	
c: c.c liblibreria.so
	gcc -o c c.c -llibreria -L.
	
liblibreria.so: libreria.o
	gcc -o liblibreria.so -shared libreria.o

libreria.o: libreria.c
	gcc -Wall -fPIC -c -o libreria.o libreria.c
	
	
