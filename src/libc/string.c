#include <string.h>

void * memcpy(void * __dest, const void * __src, size_t __n) {
	size_t i;
	unsigned char * dest = (unsigned char *)__dest;
	unsigned char * src = (unsigned char *)__src;
	while(i < __n) {
		*(dest+i) = *(src+i);
		i++;
	} *dest = 0;
	return __dest;
}

void * memccpy(void * __dest, const void * __src, int __c, size_t __n) {
	size_t i;
	unsigned char * dest = (unsigned char *)__dest;
	unsigned char * src = (unsigned char *)__src;
	while(i < __n && *(src+i) != (unsigned char)__c) {
		*(dest+i) = *(src+i);
		i++;
	} *dest = 0;
	if(*(src+i) == (unsigned char)__c) { return (src+i); }
	return __dest;
}

void * memchr(const void * __s, int __c, size_t __n) {
	unsigned char * s = (unsigned char *)__s;
	size_t i;
	for(i = 0; i < __n; i++) {
		if(*(s+i) == __c) {
			return s+i;
		}
	}
	return NULL;
}

int memcmp(const void * __s1, const void * __s2, size_t __n) {
	size_t i;
	unsigned char * s1 = (unsigned char *)__s1;
	unsigned char * s2 = (unsigned char *)__s2;
	for(i = 0; i < __n; i++) {
		if(s1[i] != s2[i]) {
			if(s1[i] > s2[i]) {
				return ((s1[i])-(s2[i]));
			} else if (s1[i] < s2[i]) {
				return ((s2[i])-(s1[i]));
			} else {
				return -1;
			}
		}
	}
	return 0;
}

void * memset(void * __s, int __c, size_t __n) {
	size_t i;
	unsigned char * s = (unsigned char *)__s;
	for(i = 0; i < __n; i++) {
		*(s+i) = __c;
	}
	return s;
}

char * strchr(char * __s, int __c) {
	size_t i = 0;
	while(__s[i] != 0) {
		if(__s[i] == __c) {
			return __s+i;
		}
	}
	return NULL;
}

char * strcpy(char * __dest, const char * __src) {
	size_t i = 0;
	while(__src[i] != 0) {
		__dest[i] = __src[i];
	}
	return __dest;
}

size_t strlen(const char * __s) {
	size_t i = 0;
	while(__s[i] != 0) { i++; }
	return i;
}

char * strcat(char * __dest, const char * __src) {
	size_t i = 0;
	size_t i2 = 0;
	while(__dest[i] != 0) {
		i++;
	}
	while(__src[i2] != 0) {
		__dest[i] = __src[i2];
	}
	return __dest;
}

int strcmp(const char * __s1, const char * __s2) {
	size_t i = 0;
	while(__s1[i] != 0 && __s2[i] != 0) {
		if(__s1[i] != __s2[i]) {
			if(__s1[i] > __s2[i]) {
				return ((__s1[i])-(__s2[i]));
			} else if (__s1[i] < __s2[i]) {
				return ((__s2[i])-(__s1[i]));
			} else {
				return -1;
			}
		} i++;
	}
	return 0;
}

char * strset(char * __s, int __c) {
	size_t i = 0;
	while(__s[i] != 0) {
		__s[i] = __c;
		i++;
	}
	return __s;
}

char * strncpy(char * __dest, const char * __src, size_t __n) {
	size_t i = 0;
	while(__src[i] != 0 && !(i >= __n)) {
		__dest[i] = __src[i];
	}
	return __dest;
}

char * strncat(char * __dest, const char * __src, size_t __n) {
	size_t i = 0;
	size_t i2 = 0;
	while(__dest[i] != 0) {
		i++;
	}
	while(__src[i2] != 0 && !(i2 >= __n)) {
		__dest[i] = __src[i2];
	}
	return __dest;
}

int strncmp(const char * __s1, const char * __s2, size_t __n) {
	size_t i;
	for(i = 0; i < __n; i++) {
		if(__s1[i] != __s2[i]) {
			if(__s1[i] > __s2[i]) {
				return ((__s1[i])-(__s2[i]));
			} else if (__s1[i] < __s2[i]) {
				return ((__s2[i])-(__s1[i]));
			} else {
				return -1;
			}
		}
	}
	return 0;
}
