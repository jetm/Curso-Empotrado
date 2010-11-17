all: server client

clean:
	rm nweb_threads
	rm client_threads

server:
	gcc -Wall -lpthread nweb_threads.c -o nweb_threads
	chmod 700 nweb_threads

client:
	gcc -Wall -lpthread client_threads.c -o client_threads
	chmod 700 client_threads
