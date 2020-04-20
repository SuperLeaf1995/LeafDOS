#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <lib/io.h>

uint16_t * tty = (uint16_t *)0xB8000;

uint16_t tx; uint16_t ty;
uint16_t tw; uint16_t th;
uint8_t tc;

static inline uint8_t inportb(uint16_t port) {
	uint8_t value;
	asm volatile("in %%dx, %%al":"=a"(value):"d"(port));
	return value;
}

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

static inline unsigned char kgetc(void) {
	unsigned char c;
	c = inportb(0x60);
	return c;
}

void kmain(void) {
	ktty();
	kprintf("bruh\nur not ight");
	for(;;) {
		kputc(kgetc());
	}
}
