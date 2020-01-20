public static int f(int ???) {
  return ??? <= 0 ? 1 :
      ??? >= 0x40000000 ? 0x40000000 :
      1 << (32 - Integer.numberOfLeadingZeros(???));
}