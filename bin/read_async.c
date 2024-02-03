/* Parallel word count */
#include "common.c"
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <liburing.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>

#define QUEUE_DEPTH 10

int prep_read_request(char filename[], int id, struct io_uring *ring);
int get_completion(struct io_uring *ring);
static int setup_context(unsigned queue_depth, struct io_uring *ring);

struct file_info {
  char *filename;
  char *data;
  int id;
};

int main(int argc, char *argv[]) {
  /* Init io_uring */
  struct io_uring ring;
  // int ret;

  if (argc <= 1) {
    fprintf(stderr, "Usage: %s [filename] <[filename] ...>\n", argv[0]);
    return 1;
  };

  if (setup_context(QUEUE_DEPTH, &ring)) {
    return 1;
  }

  /* Prepare read operations */
  for (int i = 1; i < argc; i++) {
    int ret = prep_read_request(argv[i], i, &ring);
    if (ret != 0) {
      fprintf(stderr, "Error preparing read request: %s\n", argv[i]);
      return 1;
    }
  };
  /* Would expect out of order return when reading a small file but
   that doensn't happen */
  io_uring_submit(&ring);

  for (int i = 1; i < argc; i++) {
    int ret = get_completion(&ring);
    if (ret == -1)
      return -1;
  };

  /* Clean up */
  io_uring_queue_exit(&ring);
  return 0;
}

static int setup_context(unsigned queue_depth, struct io_uring *ring) {
  int ret;
  ret = io_uring_queue_init(queue_depth, ring, 0);
  if (ret < 0) {
    fprintf(stderr, "queue_init: %s\n", strerror(-ret));
    return -1;
  }

  return 0;
}

int prep_read_request(char *filename, int id, struct io_uring *ring) {
  off_t sz;
  int fd = open(filename, O_RDONLY);
  if (fd < 0) {
    perror("open");
    return 1;
  };
  if (get_file_size(fd, &sz)) {
    return 1;
  }
  struct io_uring_sqe *sqe = io_uring_get_sqe(ring);
  assert(sqe);

  struct file_info *fi = malloc(sizeof(struct file_info));
  fi->filename = filename;
  fi->id = id;
  fi->data = malloc(sz);
  if (fi->data == NULL) {
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
  if (cqe->res < 0) {
    fprintf(stderr, "Async read failed.\n");
    return -1;
  };

  /* Retrieve user data */
  struct file_info *fi = io_uring_cqe_get_data(cqe);
  printf("read file %s pos:%d complete\n", fi->filename, fi->id);
  fflush(stdout);

  /* Mark this completion as seen */
  io_uring_cqe_seen(ring, cqe);
  return 0;
}
