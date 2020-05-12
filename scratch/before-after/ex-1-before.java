public static void quoteHtmlChars(
    OutputStream output, byte[] buffer, int off, int len
) throws IOException {
    for (int i = off; i < (off + len); i++) {
        switch (buffer[i]) {
            case '&' :
                output.write(ampBytes);
                break;
            case '<' :
                output.write(ltBytes);
                break;
            case '>' :
                output.write(gtBytes);
                break;
            case '\'' :
                output.write(aposBytes);
                break;
            case '"' :
                output.write(quotBytes);
                break;
            default :
                output.write(buffer, i, 1);
        }
    }
}
