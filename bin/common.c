#include <linux/fs.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/ioctl.h>

static int get_file_size(int fd, off_t *size) {
    struct stat st;

    if(fstat(fd, &st) < 0) {
        perror("fstat");
        return -1;
    }
    if (S_ISBLK(st.st_mode)) {
        unsigned long long bytes;

        if (ioctl(fd, BLKGETSIZE64, &bytes) != 0) {
            perror("ioctl");
            return -1;
        }
        *size = bytes;
        return 0;
    } else if (S_ISREG(st.st_mode)) {
        *size = st.st_size;
        return 0;
    }

    return -1;
}
