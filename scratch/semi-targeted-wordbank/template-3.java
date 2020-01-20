int f(Item item) {
  int ???=0;
  for (Iterator<Item> i=item.getParent().getItemIterator();
    i.hasNext(); ) {
      Item child=i.next();
      if (item==child) {
          return ???;
      }
      ???++;
  }
  return -1;
}