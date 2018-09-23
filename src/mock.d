module mock;

import types;

extern(C):
nothrow:
@nogc:
pure:

size_t strlen(immutable char *s) {
    size_t len = 0;
    while (*(s+len)) {
        len++;
    }
    return len;
}

int strcmp(immutable char *s1, immutable char *s2) {
    size_t i = 0;
    while (*(s1+i) != 0 && *(s2+i) != 0 && *(s1+i) == *(s2+i)) {
        i++;
    }
    return *(s1+i) - *(s2+i);
}

void *memset(void *s, int c, size_t n) {
    for (size_t i = 0; i < n; i++) {
        *cast(char*)(s+i) = cast(char)c;
    }
    return s;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    size_t i = 0;
    while (i < n && *cast(char*)(s1+i) == *cast(char*)(s2+i)) {
        i++;
    }
    return *cast(char*)(s1+i) - *cast(char*)(s2+i);
}

void *memcpy(void *d, const void *s, size_t n) {
    for (size_t i = 0; i < n; i++) {
        *cast(char*)(d+i) = *cast(char*)(s+i);
    }
    return d;
}
