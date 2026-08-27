#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>

int main(void) {
    if (mount(NULL, "/", NULL, MS_REMOUNT, NULL) != 0) {
        fprintf(stderr, "remount: %s\n", strerror(errno));
        return 1;
    }
    return 0;
}
