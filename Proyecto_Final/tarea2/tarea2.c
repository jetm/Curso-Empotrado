#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

extern void int2octet(unsigned);
void help(void);

int main(int argc, char *argv[]) {

	unsigned c, mask, network;
	unsigned ip=0;
	unsigned mask_size=0;	

	while ((c = getopt (argc, argv, "i:m:h")) != -1)
		switch (c) {
			case 'i': ip = strtoul(optarg,NULL,0);break;
			case 'm': mask_size = atoi(optarg);break;
			case '?': fprintf(stderr,"Invalid usage!\n"); help(); exit(1);break;
			case 'h': help();break;
			default: help(); break;
		}	
	
		switch (mask_size) {
			case  0: mask=0;break;
			case  8: mask=0xFF000000; break;
			case 16: mask=0xFFFF0000; break;
			case 24: mask=0xFFFFFF00; break;
			default: fprintf(stderr, "Warning: mask size %u makes no scense. Assuming 24. Valid sizes are 0 8, 16 and 24.\n", mask_size);
		}
	
		if (!ip) 
			fprintf(stderr, "Warning: ip omited. Assuming 0.\n");
		
		network = ip & mask;

		printf("\n");
		printf("\tip\t=\t"); int2octet(ip);
		printf("\tnetwork\t=\t");int2octet(network);
		printf("\tmask\t=\t");int2octet(mask);
		printf("\n");
		return 0;
}

void help() {
	printf("Usage: ./c -i <integer value> -m <network mask in bits>\n");
	exit(1);
}

