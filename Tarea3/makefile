all: server client

clean:
	rm nweb_threads
	rm client

server:
	gcc -Wall -lpthread nweb_threads.c -o nweb_threads
	chmod 700 nweb_threads

client:
	gcc -Wall -lpthread client.c -o client
	chmod 700 client
