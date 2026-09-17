#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

int main(void) {
    static const char socket_path[] = "/dev/socket/adb_atci_socket";
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        perror("socket");
        return EXIT_FAILURE;
    }

    struct sockaddr_un address = { .sun_family = AF_UNIX };
    if (strlen(socket_path) >= sizeof(address.sun_path)) {
        fputs("socket path too long\n", stderr);
        return EXIT_FAILURE;
    }
    strcpy(address.sun_path, socket_path);
    /* Refuse to replace a running daemon's endpoint. */
    if (bind(fd, (struct sockaddr*)&address, sizeof(address)) != 0) {
        perror("bind");
        return EXIT_FAILURE;
    }
    if (chmod(socket_path, 0660) != 0 || listen(fd, 4) != 0) {
        perror("prepare socket");
        return EXIT_FAILURE;
    }

    char fd_value[16];
    snprintf(fd_value, sizeof(fd_value), "%d", fd);
    setenv("ANDROID_SOCKET_adb_atci_socket", fd_value, 1);
    setenv("LD_PRELOAD", "/system/lib64/libshim_atcid_radio.so", 1);
    execl("/system/bin/atcid", "atcid", (char*)NULL);
    fprintf(stderr, "exec atcid: %s\n", strerror(errno));
    return EXIT_FAILURE;
}
