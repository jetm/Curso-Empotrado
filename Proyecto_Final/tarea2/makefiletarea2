all: tarea2
	@echo -e Tarea2 Compilada... \
			Proceda a instalar:\\n\\n \
			\\tmake DESTDIR\=\<Destino\> install \

clean:
	rm -f libtarea2.so
	rm -f tarea2lib.o
	rm -f tarea2
	rm -f $(DESTDIR)/usr/lib/libtarea2.so
	rm -f $(DESTDIR)/usr/bin/tarea2

install: tarea2 libtarea2.so
	cp libtarea2.so $(DESTDIR)/usr/lib
	cp ./tarea2 $(DESTDIR)/usr/bin
	# sudo ldconfig
	
tarea2: tarea2.c libtarea2.so
	gcc -o tarea2 tarea2.c -ltarea2	-L.
	
libtarea2.so: tarea2lib.o
	gcc -o libtarea2.so -shared tarea2lib.o

tarea2lib.o: tarea2lib.c
	gcc -Wall -fPIC -c -o tarea2lib.o tarea2lib.c

