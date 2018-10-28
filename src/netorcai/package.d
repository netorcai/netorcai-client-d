module netorcai;

public import netorcai.client;
public import netorcai.message;

// Write coverage results to /tmp instead of current directory
version(D_Coverage) shared static this()
{
    import core.runtime : dmd_coverDestPath;
    import std.file : exists, mkdir;
    import std.format : format;

    // The coverage directory must be created manually before executing the tests.
    enum COVPATH = "/tmp/cover-netorcai-d";
    dmd_coverDestPath(COVPATH);

    assert(COVPATH.exists, format!"Coverage output directory '%s' does not exist. Please create it manually."(COVPATH));
}
