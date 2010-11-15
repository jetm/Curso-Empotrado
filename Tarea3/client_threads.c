#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <pthread.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <ctype.h>

#define BUFSIZE 8196

/*
 * @TODO Port and IP Address parameters
 *
 */
		
#define IP_ADDRESS "127.0.0.1"
int PORT = 8181;
clock_t startm, stopm;
#define START if ( (startm = clock()) == -1) { printf("Error calling clock"); exit(1); }
#define STOP if ( (stopm = clock()) == -1) { printf("Error calling clock"); exit(1); }
#define PRINTTIME printf("%7.4f seconds used by the processor.\n", ((double)stopm-startm)/CLOCKS_PER_SEC);

int putConsole(pthread_t idThread, const char* msg);
void* doNewThread(void* Iterations);

pthread_mutex_t console;

int main(int argc, char **argv) {
	pthread_t* thrArr;
	int i,paramThreads = 1, paramIterations = 1;
	

/* 
 * -n paramThreads Numbers (N) 
 * -m paramIterations Numbers (M) each threads
 * -p port number
 *  
*/
	while ((i = getopt (argc, argv, "n:m:p:")) != -1)
		switch (i){
			case 'n': 
			    paramThreads = atoi(optarg);
				break;
			case 'm': 
				paramIterations = atoi(optarg);
				break;
			case 'p': 
				PORT = atoi(optarg);
				break;
			case '?':
				if (optopt == 'n' || optopt == 'm' )
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option `-%c'.\n", optopt);
				else
					fprintf (stderr,"Unknown option character `\\x%x'.\n", optopt);
				return 1;
			default:
				abort ();
		}

	pthread_mutex_init (&console, NULL);

	// Threads Creations
	thrArr = (pthread_t*) calloc (paramThreads, sizeof(pthread_t));
	assert(thrArr != NULL);

	fprintf(stderr, "paramThreads %d  \n", paramThreads);
	fprintf(stderr, "paramIterations %d  \n", paramIterations);

	// Initial Time
    START;

	// Execute each Thread
	for(i=0; i<paramThreads; i++) {
		if (pthread_create(&thrArr[i], NULL, doNewThread,(void*) &paramIterations)) {
		    fprintf(stderr, "error creating a new thread \n");
			exit(1);
		}
	}

	for(i=0; i<paramThreads; i++)
		pthread_join(thrArr[i], NULL);

	free(thrArr);

	// Final Execution
    STOP;
    PRINTTIME;
    return 0;
}

void* doNewThread(void* Iterations) {

	int i, sockfd, nIterations = *((int*)Iterations); // void* to int* and value
	char buffer[BUFSIZE];
	struct sockaddr_in serv_addr;

	pthread_t idThread = pthread_self();

	while (nIterations--) {
        // AF_INET remote o local access
		if ((sockfd = socket(AF_INET, SOCK_STREAM,0)) <0) 
			putConsole(idThread, "socket() failed");
		else {

			serv_addr.sin_family = AF_INET;
			serv_addr.sin_addr.s_addr = inet_addr(IP_ADDRESS);
			serv_addr.sin_port = htons(PORT);

			if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) <0)
				putConsole(idThread, "connect() failed");
			else {
				// now the sockfd can be used to communicate to the server
				write(sockfd, "GET /index.html \r\n", 18);
				// note second space is a delimiter and important

				// this displays the raw HTML file as received by the browser
				while( (i=read(sockfd,buffer,BUFSIZE)) > 0) {
					buffer[i] = 0;
					putConsole(idThread,buffer);
				}

				close(sockfd);
			}
		}
	} // nIterations

    return 0;
}

// Put Info Console 
int putConsole(pthread_t idThread, const char* mesg) {
	pthread_mutex_lock(&console);
	printf("[%ld] %s\n", idThread, mesg);
    pthread_mutex_unlock(&console);
    return 0;
}
