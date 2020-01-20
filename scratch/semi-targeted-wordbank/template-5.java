int f(Object target) {
  int i = 0;
  for (Object ???: this.elements) {
      if (???.equals(target)) {
          return i;
      }
      i++;
  }
  return -1;
}