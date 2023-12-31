/* Parallel word count */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <error.h>
#include <errno.h>
#include <liburing.h>

#define QUEUE_DEPTH 5

int prep_read_request(char filename[], int id, struct io_uring *ring);
int get_completion(struct io_uring *ring);

int main(int argc, char *argv[]){
    if (argc <= 1) {
        fprintf(stderr, "Usage: %s [filename] <[filename] ...>\n", argv[0]);
        return 1;
    };

    /* Init io_uring */
    struct io_uring ring;
    int ret = io_uring_queue_init(QUEUE_DEPTH, &ring, 0);
    if (ret != 0){
        perror("io_uring_queue_init");
        return -1;
    }

    /* Queue read operations */
    for (int i = 1; i < argc; i++) {
        int ret = prep_read_request(argv[i], i, &ring);
        if (ret != 0) {
            fprintf(stderr, "Error preparing read request: %s\n", argv[i]);
            return -1;
        }
    };
    io_uring_submit(&ring);
    /* Would expect out of order return when reading a small file but
       that doensn't happen */

    for (int i = 1; i < argc; i++) {
        int ret = get_completion(&ring);
        if (ret == -1) return -1;
    };

    /* Clean up */
    io_uring_queue_exit(&ring);
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

struct file_info {
    char* filename;
    char* data;
    int id;
};

int prep_read_request(char *filename, int id, struct io_uring *ring){
    int fd = open(filename, O_RDONLY);
    if (fd < 0){
        perror("open");
        return -1;
    };
    off_t sz = get_file_size(fd);
    struct io_uring_sqe *sqe = io_uring_get_sqe(ring);
    struct file_info* fi = malloc(sizeof(struct file_info));
    fi->filename = filename;
    fi->id = id;
    fi->data = malloc(sz);
    if (fi->data == NULL){
        perror("malloc");
        return -1;
    }
    io_uring_prep_read(sqe, fd, fi->data, sz, 0);
    io_uring_sqe_set_data(sqe, fi);
    return 0;
}

int get_completion(struct io_uring *ring) {
    struct io_uring_cqe *cqe;
    int ret = io_uring_wait_cqe(ring, &cqe);
    if (ret < 0) {
        perror("io_uring_wait_cqe");
        return -1;
    };
    if (cqe->res < 0){
        fprintf(stderr, "Async read failed.\n");
        return -1;
    };

    /* Retrieve user data */
    struct file_info* fi = io_uring_cqe_get_data(cqe);
    printf("read file %s pos:%d complete\n", fi->filename, fi->id);

    /* Mark this completion as seen */
    io_uring_cqe_seen(ring, cqe);
    return 0;
}
