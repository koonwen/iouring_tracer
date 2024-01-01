/* Parallel word count */
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <error.h>
#include <errno.h>
#include <sys/stat.h>
#include <liburing.h>

int seq_read(char *filename);

int main(int argc, char *argv[]){
    if (argc <= 1) {
        fprintf(stderr, "Usage: %s [filename] <[filename] ...>\n", argv[0]);
        return 1;
    }

    for (int i = 1; i < argc; i++) {
        int ret = seq_read(argv[i]);
        if (ret == -1) return -1;
        printf("read file %s pos:%d complete\n", argv[i], i);
    };
    return 0;
}

off_t get_file_size(int fd) {
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
        return bytes;
    } else if (S_ISREG(st.st_mode))
        return st.st_size;

    return -1;
}

int seq_read(char *filename){
    int fd = open(filename, O_RDONLY);
    if (fd < 0){
        perror("open");
        return -1;
    };
    off_t sz = get_file_size(fd);
    char *buf = malloc(sz);
    ssize_t r = read(fd, buf, sz);
    if (r == -1){
        perror("read");
        return -1;
    };
    return 0;
}
