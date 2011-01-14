#include <stdio.h>
#include <stdlib.h>

typedef	struct {
	unsigned char a, b, c, d;
} ip_octets;

typedef union {
	ip_octets o;
	unsigned all;
} ip_type;

void int2octet(unsigned x) {
	ip_type ip;
	ip.all = x;
	printf("%i.%i.%i.%i\n", ip.o.d, ip.o.c, ip.o.b, ip.o.a);
}
