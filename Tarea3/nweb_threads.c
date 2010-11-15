#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <ctype.h>

#define MAX_THREADS 500
#define BUFSIZE 8096
#define ERROR 42
#define SORRY 43
#define LOG   44
#define MAX_PORT 60000
#define THREAD_SLEEP 1

void* attendClient(void* param);
void nwebLog(int type, char *s1, char *s2, int num);

struct {
	char *ext;
	char *filetype;
} extensions [] = {
	{"gif", "image/gif" },
	{"jpg", "image/jpeg"},
	{"jpeg","image/jpeg"},
	{"png", "image/png" },
	{"zip", "image/zip" },
	{"gz",  "image/gz"  },
	{"tar", "image/tar" },
	{"htm", "text/html" },
	{"html","text/html" },
	{0,0}
};

pthread_t* thrArray;
int *descArr;

int main(int argc, char **argv) {
	int i, ex, listenfd, socketfd, port = -1, thrAvail, xThreads = 10; // Default N Threads
	size_t length;
	static struct sockaddr_in cli_addr; /* static = initialised to zeros */
	static struct sockaddr_in serv_addr; /* static = initialised to zeros */
	static char *sPort;
	char *directory = NULL;
	
	if( argc == 2 && !strcmp(argv[1], "-?") ) {
		(void)printf("hint: nweb -p Port-Number -d Top-Directory -t Number-Threads\n\n"
                    "\tnweb is a small and very safe mini web server\n"
		            "\tnweb only servers out file/web pages with extensions named below\n"
		            "\t and only from the named directory or its sub-directories.\n"
		            "\tThere is no fancy features = safe and secure.\n\n"
		            "\tExample: nweb 8181 /home/nwebdir &\n\n"
		            "\tOnly Supports:");
			
        for (i=0; extensions[i].ext != 0; i++)
			(void)printf(" %s",extensions[i].ext);

		(void)printf("\n\tNot Supported: URLs including \"..\", Java, Javascript, CGI\n"
		            "\tNot Supported: directories / /etc /bin /lib /tmp /usr /dev /sbin \n"
		            "\tNo warranty given or implied\n\tNigel Griffiths nag@uk.ibm.com\n");
		exit(0);
	}

	while ((i = getopt (argc, argv, "p:d:t:")) != -1)
		switch (i) {
			case 'p':
				port = atoi(optarg);

				if (port < 1 || port > MAX_PORT)
					nwebLog(ERROR,"Invalid port number",optarg,0);

				sPort = optarg;
				break;
			case 'd':
				directory = optarg;

				if( !strncmp(directory,"/"   ,2 ) || !strncmp(directory,"/etc", 5 ) ||
					!strncmp(directory,"/bin",5 ) || !strncmp(directory,"/lib", 5 ) ||
					!strncmp(directory,"/tmp",5 ) || !strncmp(directory,"/usr", 5 ) ||
					!strncmp(directory,"/dev",5 ) || !strncmp(directory,"/sbin",6) ){
					(void)printf("ERROR: Bad top directory %s, see nweb -?\n",directory);
					exit(3);
				}

				if(chdir(directory) == -1){
					(void)printf("ERROR: Can't Change to directory %s\n",directory);
					exit(4);
				}

				break;
			case 't': 
				xThreads = atoi(optarg);

				if (xThreads < 1 || xThreads> MAX_THREADS )
					nwebLog(ERROR,"Invalid number of threads",optarg,0);

				break;
			case '?':
				if (optopt == 'p' || optopt == 'd' || optopt == 't')
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option `-%c'.\n", optopt);
				else
					fprintf (stderr,"Unknown option character `\\x%x'.\n", optopt);
				return 1;
			default:
				abort ();
		}

	if (port < 1)
		nwebLog(ERROR,"Port not defined","",0);

	if (NULL == directory)
		nwebLog(ERROR,"Directory not defined","",0);

	/* Become deamon + unstopable and no zombies children (= no wait()) */
	if (fork() != 0)
		return 0; /* parent returns OK to shell */

	(void)signal(SIGCLD, SIG_IGN); /* ignore child death */
	(void)signal(SIGHUP, SIG_IGN); /* ignore terminal hangups */

	//close open files
	for (i=0; i<32; i++)
		(void)close(i);

	// break away from process group
	(void)setpgrp();

    // if (sPort != '0')
	    nwebLog(LOG,"nweb starting",sPort,getpid());

	// Threads array
	thrArray = (pthread_t*) calloc (xThreads, sizeof(pthread_t));
	assert(thrArray != NULL);

	// Descriptors
	descArr = (int*)calloc (xThreads, sizeof(int));
	assert(descArr != NULL);

    // Create Threads 
	for (i = 0; i < xThreads; i++) {
		descArr[i] = -1;

		if (pthread_create( &thrArray[i], NULL, &attendClient, &descArr[i] ) != 0)
			nwebLog(ERROR,"system call","pthread_create",0);
	}

	// Setup the network socket
	if ((listenfd = socket(AF_INET, SOCK_STREAM,0)) <0)
		nwebLog(ERROR, "system call","socket",0);

	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	serv_addr.sin_port = htons(port);

	if (bind(listenfd, (struct sockaddr *)&serv_addr,sizeof(serv_addr)) <0)
		nwebLog(ERROR,"system call","bind",0);

	if (listen(listenfd,64) <0)
		nwebLog(ERROR,"system call","listen",0);

	for (ex=1; ; ex++) {
		length = sizeof(cli_addr);

		if ((socketfd = accept(listenfd, (struct sockaddr *)&cli_addr, &length)) < 0)
			nwebLog(ERROR,"system call","accept",0);

		thrAvail = -1;
		for(i = 0; i < xThreads; i++) {
			if (-1 == descArr[i]) {
				thrAvail = i;
				break;
			}
		}

		if (-1 == thrAvail) {
			nwebLog(LOG,"NO thread AVAILABLE","",0);
			(void)close(socketfd);
		} else {
			descArr[thrAvail] = socketfd;
		}

	}
}


void nwebLog(int type, char *s1, char *s2, int num) {
	int fd;
	char logbuffer[BUFSIZE*2];

	switch (type) {
		case ERROR:
			(void)sprintf(logbuffer,"ERROR: %s:%s Errno=%d exiting pid=%d",s1, s2, errno,getpid());
			break;
		case SORRY:
			(void)sprintf(logbuffer, "<HTML><BODY><H1>nweb Web Server Sorry: %s %s</H1></BODY></HTML>\r\n", s1, s2);
			(void)write(num,logbuffer,strlen(logbuffer));
			(void)sprintf(logbuffer,"SORRY: %s:%s",s1, s2);
			break;
		case LOG:
			(void)sprintf(logbuffer," INFO: %s:%s:%d",s1, s2,num);
			break;
	}

	/* no checks here, nothing can be done a failure anyway */
	if((fd = open("nweb.log", O_CREAT| O_WRONLY | O_APPEND,0644)) >= 0) {
		(void)write(fd,logbuffer,strlen(logbuffer));
		(void)write(fd,"\n",1);
		(void)close(fd);
	}

    if(type == ERROR || type == SORRY) exit(3);
}


void* attendClient(void* param) {
	int *fd = (int*)param;

	int j, file_fd, buflen, len;
	long i, ret;
	char * fstr;
	char ok = 1;
	char buffer[BUFSIZE+1]; // static so zero filled

	while (1) {
		if (-1 == *fd) {
			sleep(THREAD_SLEEP);
		} else {
			ok = 1;

			//read Web request in one go
			ret = read(*fd,buffer,BUFSIZE);

			if(ret == 0 || ret == -1) {
				nwebLog(LOG,"failed to read browser request","",*fd); // read failure stop now
				ok = 0;
			}

			if (ok) {
				// Return code is valid chars
				if(ret > 0 && ret < BUFSIZE)
					buffer[ret]=0;		//terminate the buffer
				else
					buffer[0]=0;

				for(i=0;i<ret;i++)	/* remove CF and LF characters */
					if(buffer[i] == '\r' || buffer[i] == '\n')
						buffer[i]='*';

				if( strncmp(buffer,"GET ",4) && strncmp(buffer,"get ",4) ) {
					nwebLog(LOG,"Only simple GET operation supported",buffer,*fd);
					ok = 0;
				}
			}

			if (ok) {
				// null terminate after the second space to ignore extra stuff
				for(i=4;i<BUFSIZE;i++) {
					if(buffer[i] == ' ') { /* string is "GET URL " +lots of other stuff */
						buffer[i] = 0;
						break;
					}
				}

				// check for illegal parent directory use ..
				for(j=0;j<i-1;j++)
					if(buffer[j] == '.' && buffer[j+1] == '.') {
						nwebLog(LOG,"Parent directory (..) path names not supported",buffer,*fd);
						ok = 0;
						break;
					}
			}

			if (ok) {
				// convert no filename to index file
				if( !strncmp(&buffer[0],"GET /\0",6) || !strncmp(&buffer[0],"get /\0",6) )
					(void)strcpy(buffer,"GET /index.html");

				// work out the file type and check we support it
				buflen=strlen(buffer);
				fstr = (char *)0;
				for(i=0;extensions[i].ext != 0;i++) {
					len = strlen(extensions[i].ext);
					if( !strncmp(&buffer[buflen-len], extensions[i].ext, len)) {
						fstr =extensions[i].filetype;
						break;
					}
				}

				if(fstr == 0) {
					nwebLog(LOG,"file extension type not supported",buffer,*fd);
					ok = 0;
				}
			}

			if (ok) {
				// open the file for reading
				if(( file_fd = open(&buffer[5],O_RDONLY)) == -1) {
					nwebLog(LOG, "failed to open file",&buffer[5],*fd);
					ok = 0;
				}
			}

			if (ok) {
				(void)sprintf(buffer,"HTTP/1.0 200 OK\r\nContent-Type: %s\r\n\r\n", fstr);
				(void)write(*fd,buffer,strlen(buffer));

				// send file in 8KB block - last block may be smaller
				while (	(ret = read(file_fd, buffer, BUFSIZE)) > 0 ) {
					(void)write(*fd,buffer,ret);
				}

				//to allow socket to drain
				sleep(1);
			}

			//Make the thread available again
			(void)close(*fd);
			*fd = -1;
		}
	}
}
