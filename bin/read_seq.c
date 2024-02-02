/* Parallel word count */
#include "common.c"
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int seq_read(char *filename);

int main(int argc, char *argv[]) {
  if (argc <= 1) {
    fprintf(stderr, "Usage: %s [filename] <[filename] ...>\n", argv[0]);
    return 1;
  }

  for (int i = 1; i < argc; i++) {
    int ret = seq_read(argv[i]);
    if (ret == -1)
      return 1;
    printf("read file %s pos:%d complete\n", argv[i], i);
  };
  return 0;
}

int seq_read(char *filename) {
  off_t sz;
  int fd = open(filename, O_RDONLY);
  if (fd < 0) {
    perror("open");
    return 1;
  };
  if (get_file_size(fd, &sz)) {
    return 1;
  }
  char *buf = malloc(sz);
  ssize_t r = read(fd, buf, sz);
  if (r == -1) {
    perror("read");
    return 1;
  };
  return 0;
}
