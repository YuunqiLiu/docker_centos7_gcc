#include <stdio.h>
#include <gnu/libc-version.h>

int main() {
    printf("Hello from C program!\n");
    printf("GNU libc version: %s\n", gnu_get_libc_version());
    return 0;
}
