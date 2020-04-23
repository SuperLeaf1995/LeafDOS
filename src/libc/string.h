#ifndef __STRING_H__
#define __STRING_H__ 1

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#if defined(__cplusplus)
extern "C" {
#endif /* __cplusplus */

void * memcpy(void * __dest, const void * __src, size_t __n);
void * memccpy(void * __dest, const void * __src, int __c, size_t __n);
void * memchr(const void * __s, int __c, size_t __n);
int memcmp(const void * __s1, const void * __s2, size_t __n);
void * memmove(void * __dest, const void * __src, size_t __n);
void * memset(void * __s, int __c, size_t __n);

char * strchr(char * __s, int __c);
char * strcpy(char * __dest, const char * __src);
size_t strlen(const char * __s);
char * strcat(char * __dest, const char * __src);
int strcmp(const char * __s1, const char * __s2);
char * strset(char * __s, int __c);

char * strncpy(char * __dest, const char * __src, size_t __n);
char * strncat(char * __dest, const char * __src, size_t __n);
int strncmp(const char * __s1, const char * __s2, size_t __n);

#if defined(__cplusplus)
}
#endif /* __cplusplus */
#endif /* __STRING_H__ */
