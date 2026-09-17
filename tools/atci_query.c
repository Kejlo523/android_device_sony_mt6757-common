/* Read-only SIM/modem diagnostics; never submit PINs or change radio state. */
#include <errno.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc != 2 || (strcmp(argv[1], "AT+CPIN?") &&
                      strcmp(argv[1], "AT+ESIMS?") &&
                      strcmp(argv[1], "AT+CFUN?"))) {
        fprintf(stderr, "usage: %s 'AT+CPIN?'|'AT+ESIMS?'|'AT+CFUN?'\n", argv[0]);
        return EXIT_FAILURE;
    }
    int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (fd < 0) { perror("socket"); return EXIT_FAILURE; }
    struct sockaddr_un address = { .sun_family = AF_UNIX };
    strcpy(address.sun_path, "/dev/socket/adb_atci_socket");
    if (connect(fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("connect"); close(fd); return EXIT_FAILURE;
    }
    char command[32];
    int length = snprintf(command, sizeof(command), "%s\r\n", argv[1]);
    if (send(fd, command, length, MSG_NOSIGNAL) != length) {
        perror("send"); close(fd); return EXIT_FAILURE;
    }
    char response[4096] = {0};
    size_t used = 0;
    for (int attempt = 0; attempt < 20; attempt++) {
        struct pollfd p = { .fd = fd, .events = POLLIN };
        int ready = poll(&p, 1, 500);
        if (ready < 0 && errno == EINTR) continue;
        if (ready < 0) { perror("poll"); break; }
        if (ready == 0) continue;
        ssize_t count = read(fd, response + used, sizeof(response) - used - 1);
        if (count <= 0) break;
        used += count;
        response[used] = '\0';
        if (strstr(response, "OK") || strstr(response, "ERROR") ||
            used == sizeof(response) - 1) break;
    }
    close(fd);
    if (!used) { fputs("ATCI response timed out\n", stderr); return EXIT_FAILURE; }
    for (size_t i = 0; i < used; i++) {
        unsigned char c = response[i];
        if (c == '\r') continue;
        if (c == '\n' || (c >= 32 && c < 127)) putchar(c);
        else printf("\\x%02x", c);
    }
    putchar('\n');
    return strstr(response, "OK") ? EXIT_SUCCESS : EXIT_FAILURE;
}
