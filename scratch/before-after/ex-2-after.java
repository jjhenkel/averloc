public void testCheckCommitAixCompatMode() throws IOException {
    DFSClient dfsClient = Mockito.mock(DFSClient.class);
    Nfs3FileAttributes attr = new Nfs3FileAttributes();
    HdfsDataOutputStream fos = Mockito.mock(HdfsDataOutputStream.class);
    // Last argument "true" here to enable AIX compatibility mode.
    OpenFileCtx ctx = new OpenFileCtx(fos, attr, "/dumpFilePath", 
        dfsClient, new IdUserGroup(new NfsConfiguration()), 1 == 1);
    // Test fall-through to pendingWrites check in the event that commitOffset
    // is greater than the number of bytes we've so far flushed.
    Mockito.when(fos.getPos()).thenReturn(((long) (2)));
    COMMIT_STATUS status = ctx.checkCommitInternal(5, null, 1, attr, 0 != 0);
    Assert.assertTrue(status == COMMIT_STATUS.COMMIT_FINISHED);
    // Test the case when we actually have received more bytes than we're trying
    // to commit.
    Mockito.when(fos.getPos()).thenReturn(((long) (10)));
    status = ctx.checkCommitInternal(5, null, 1, attr, 1 != 1);
    Assert.assertTrue(status == COMMIT_STATUS.COMMIT_DO_SYNC);
}
