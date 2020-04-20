#ifndef __IO_H__
#define __IO_H__

#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif

#define cli() ({ asm volatile("cli"); })
#define sti() ({ asm volatile("sti"); })
#define iowait() ({ outportb(0x80, 0x00); })

#if defined(__cplusplus)
}
#endif

#endif
