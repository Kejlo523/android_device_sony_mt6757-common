#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <sys/types.h>
#include <unistd.h>

static void log_line(int fd, const char *stage, int rc) {
    char buf[256];
    int saved_errno = errno;
    int len = snprintf(buf, sizeof(buf),
                       "bootbridge: %s rc=%d errno=%d (%s)\n",
                       stage, rc, saved_errno, strerror(saved_errno));
    if (len > 0) {
        write(fd, buf, (size_t)len);
        fsync(fd);
    }
}

static void run_kmsg_logger(int input, int output) {
    char buf[4096];
    ssize_t count;

    for (;;) {
        count = read(input, buf, sizeof(buf));
        if (count > 0) {
            write(output, buf, (size_t)count);
            fsync(output);
        } else {
            usleep(50000);
        }
    }
}

static void run_logcat_logger(void) {
    if (chroot("/newroot") != 0 || chdir("/") != 0) {
        _exit(1);
    }

    /* Wait until second-stage init has mounted APEX and started logd. */
    sleep(6);
    execl("/system/bin/logcat", "logcat", "-b", "all", "-v", "threadtime",
          "-f", "/data/bootbridge-logcat.log", "*:V", (char *)NULL);
    _exit(1);
}

int main(void) {
    char drain_buf[16384];
    ssize_t drain_count;
    int drained;
    int i;
    int fd;
    int kmsg_fd;
    int kmsg_log_fd;
    int rc;

    mkdir("/proc", 0755);
    mkdir("/sys", 0755);
    mkdir("/dev", 0755);
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);

    mknod("/dev/mmcblk0p38", S_IFBLK | 0600, makedev(259, 6));
    mknod("/dev/mmcblk0p39", S_IFBLK | 0600, makedev(259, 7));

    mkdir("/diagdata", 0755);
    rc = -1;
    for (i = 0; i < 60; ++i) {
        rc = mount("/dev/mmcblk0p38", "/diagdata", "ext4", 0, NULL);
        if (rc == 0 || errno == EBUSY) {
            break;
        }
        sleep(1);
    }

    fd = open("/diagdata/bootbridge.log",
              O_WRONLY | O_CREAT | O_TRUNC | O_SYNC, 0644);
    if (fd < 0) {
        for (;;) pause();
    }

    log_line(fd, "userdata_mount", rc);
    log_line(fd, "emmc_wait_loops", i);

    mkdir("/newroot", 0755);
    /*
     * Create mount points in the system-as-root filesystem before handing it
     * to Android.  The stock ramdisk used to provide these directories, but
     * bootbridge chroots directly into the system partition.  If it is mounted
     * read-only from the outset, init cannot create them and fs_mgr consequently
     * skips nvdata/nvcfg/persist.
     */
    rc = mount("/dev/mmcblk0p39", "/newroot", "ext4", 0, NULL);
    log_line(fd, "system_mount", rc);
    if (rc != 0) {
        for (;;) pause();
    }

    /*
     * The kernel mounted the same ext4 superblock read-only as its temporary
     * root.  A second mount inherits that superblock state, so explicitly
     * remount this view writable before creating the missing mount points.
     */
    rc = mount(NULL, "/newroot", NULL, MS_REMOUNT, NULL);
    log_line(fd, "system_remount_rw", rc);

    mkdir("/newroot/nvdata", 0771);
    mkdir("/newroot/nvcfg", 0771);
    mkdir("/newroot/persist", 0771);
    mkdir("/newroot/protect_f", 0771);
    mkdir("/newroot/protect_s", 0771);
    mkdir("/newroot/custom", 0755);
    mkdir("/newroot/storage", 0755);
    mkdir("/newroot/storage/usbotg", 0700);

    rc = mount(NULL, "/newroot", NULL, MS_REMOUNT | MS_RDONLY, NULL);
    log_line(fd, "system_remount_ro", rc);

    kmsg_fd = open("/proc/kmsg", O_RDONLY | O_NONBLOCK);
    kmsg_log_fd = open("/diagdata/bootbridge-kmsg.log",
                       O_WRONLY | O_CREAT | O_TRUNC | O_SYNC, 0644);
    log_line(fd, "kmsg_open", kmsg_fd);
    log_line(fd, "kmsg_log_open", kmsg_log_fd);
    drained = 0;
    if (kmsg_fd >= 0) {
        while ((drain_count = read(kmsg_fd, drain_buf,
                                   sizeof(drain_buf))) > 0) {
            drained += (int)drain_count;
        }
    }
    log_line(fd, "kmsg_backlog_drained", drained);
    rc = fork();
    log_line(fd, "kmsg_logger_fork", rc);
    if (rc == 0) {
        close(fd);
        run_kmsg_logger(kmsg_fd, kmsg_log_fd);
    } else {
        close(kmsg_fd);
        close(kmsg_log_fd);
    }

    rc = fork();
    log_line(fd, "logcat_logger_fork", rc);
    if (rc == 0) {
        close(fd);
        run_logcat_logger();
    }

    close(fd);
    mkdir("/newroot/data", 0755);
    mkdir("/newroot/dev", 0755);
    mkdir("/newroot/proc", 0755);
    mkdir("/newroot/sys", 0755);

    mount("/diagdata", "/newroot/data", NULL, MS_MOVE, NULL);
    /*
     * Android FirstStageMain mounts fresh tmpfs/proc/sysfs instances and
     * treats EBUSY as fatal.  The bridge only needs these temporary mounts
     * to discover and mount eMMC, so leave the target root directories empty.
     * The logger keeps its already-open /proc/kmsg and /data file descriptors.
     */
    umount2("/dev", MNT_DETACH);
    umount2("/proc", MNT_DETACH);
    umount2("/sys", MNT_DETACH);

    rc = chroot("/newroot");
    if (rc == 0) {
        rc = chdir("/");
    }
    if (rc == 0) {
        execl("/init", "init", (char *)NULL);
    }

    fd = open("/data/bootbridge.log",
              O_WRONLY | O_APPEND | O_SYNC, 0644);
    if (fd >= 0) {
        log_line(fd, "chroot_init_exec", -1);
        close(fd);
    }
    for (;;) pause();
}
