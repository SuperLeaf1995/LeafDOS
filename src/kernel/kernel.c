#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <lib/io.h>

uint16_t * tty = (uint16_t *)0xB8000;

uint16_t tx; uint16_t ty;
uint16_t tw; uint16_t th;
uint8_t tc;

static inline size_t strlen(const char * __s) {
	size_t s = 0;
	while(__s[s] != '\0') { s++; }
	return s;
}

static inline void ktty(void) {
	tw = 80; th = 25;
	ty = 0; tx = 0;
	tc = 0x1B;
	return;
}

static inline void kputc(unsigned char __c) {
	tty[((ty*tw)+tx)] = ((__c)+(tc<<8)); tx++;
	if(tx > 80) {
		ty++; tx = 0;
	}
	return;
}

static inline void ksetcolor(unsigned char __c) {
	tc = __c;
	return;
}

static inline void kprintf(const char * __s) {
	size_t i;
	for(i = 0; i < strlen(__s); i++) {
		if(__s[i] < 0x20) {
			switch(__s[i]) {
				case 0x0D:
					tx = 0;
					break;
				case 0x0A:
					ty++; tx = 0;
					break;
				case 0x08:
					tx--;
					break;
				default:
					break;
			}
		} else {
			kputc(__s[i]);
		}
	}
	return;
}

static inline char * kitoa(int num, char * str, int base) {
	signed int i = 0,rem;
	unsigned char isNeg = false;

	if(!num) {
		str[i++] = '0'; str[i] = '\0';
		return str;
	}
	
	if(num < 0 && base == 10) {
		num = -num;
	}
	
	while(num != 0) {
		rem = (num%base);
		str[i++] = (rem>9) ? (rem-10)+'a' : rem+'0';
		num = (num/base);
	}
	
	if(isNeg) {
		str[i++] = '-';
	}
	str[i] = '\0';
	return str;
}

void kmain(void) {
	ktty();
	
	/*Probe for PCI devices*/
}
