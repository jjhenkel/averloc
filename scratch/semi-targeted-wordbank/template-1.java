boolean f(Set<String> set, String value) {
  for (String ??? : set) {
    if (???.equalsIgnoreCase(value)) {
      return true;
    }
  }
  return false;
}