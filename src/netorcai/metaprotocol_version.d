module netorcai.metaprotocol_version;

int majorVersion = 2;
int minorVersion = 0;
int patchVersion = 0;

string metaprotocolVersion()
{
    import std.format;
    return format!"%d.%d.%d"(majorVersion, minorVersion, patchVersion);
}
