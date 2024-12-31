// src/init.c
// Minimal init system that only:
// 1. Sets up network
// 2. Runs PPPwn
// 3. Shutdowns

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <sys/mount.h>
#include <fcntl.h>

// Mount points to set up
static const struct {
    const char *source;
    const char *target;
    const char *type;
    unsigned long flags;
} mount_points[] = {
    { "proc", "/proc", "proc", MS_NOSUID | MS_NOEXEC | MS_NODEV },
    { "sysfs", "/sys", "sysfs", MS_NOSUID | MS_NOEXEC | MS_NODEV },
    { "devtmpfs", "/dev", "devtmpfs", MS_NOSUID },
    { NULL, NULL, NULL, 0 }
};

// Setup basic system mounts
static void setup_mounts(void) {
    for (int i = 0; mount_points[i].source != NULL; i++) {
        mount(mount_points[i].source,
              mount_points[i].target,
              mount_points[i].type,
              mount_points[i].flags,
              NULL);
    }
}

// Signal handler for shutdown
static void handle_signal(int sig) {
    if (sig == SIGTERM) {
        sync();
        reboot(LINUX_REBOOT_CMD_RESTART);
    }
}

int main(void) {
    // Set up signal handler for SIGTERM only
    signal(SIGTERM, handle_signal);

    // Mount essential filesystems
    setup_mounts();

    // Create console device
    if (access("/dev/console", F_OK) != 0) {
        mknod("/dev/console", S_IFCHR | 0600, makedev(5, 1));
    }

    // Run network setup script
    system("/etc/network/setup.sh");

    // Main loop - simplified
    while (1) {
        pause();
    }

    return 0;
}