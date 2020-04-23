#ifndef __IO_H__
#define __IO_H__

#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

#define cli() ({ asm volatile("cli"); })
#define sti() ({ asm volatile("sti"); })
#define iowait() ({ outportb(0x80, 0x00); })

#define outportb(port,data) ({										\
	asm volatile("out %%al, %%dx"::"a"(data),"d"(port));			\
})

#define outportw(port,data) ({										\
	asm volatile("out %%ax, %%dx"::"a"(data),"d"(port));			\
})

#define outportd(port,data) ({										\
	asm volatile("out %%eax, %%dx"::"a"(data),"d"(port));			\
})

#define inportb(port) ({											\
	uint8_t value;													\
	asm volatile("in %%dx, %%al":"=a"(value):"d"(port)); value;		\
})

#define inportw(port) ({											\
	uint16_t value;													\
	asm volatile("in %%dx, %%ax":"=a"(value):"d"(port)); value;		\
})

#define inportd(port) ({											\
	uint32_t value;													\
	asm volatile("in %%dx, %%eax":"=a"(value):"d"(port)); value;	\
})

#if defined(__cplusplus)
}
#endif

#endif
