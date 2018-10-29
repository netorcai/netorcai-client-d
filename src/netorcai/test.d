module netorcai.test;

import std.algorithm;
import std.format;
import std.process;

/// Launch a netorcai process and wait for it to listen on its socket.
auto launchNetorcaiWaitListening()
{
    auto netorcai = pipeProcess(["netorcai",
        "--simple-prompt",
        "--delay-first-turn=50",
        "--delay-turns=50",
        "--nb-turns-max=2",
        "--nb-players-max=16"],
        Redirect.stdin | Redirect.stdout);

    // Wait for connection to be possible
    foreach (line; netorcai.stdout.byLine)
    {
        assert(line.canFind(`Listening incoming connections`),
            format!"First message is not the one expected: %s"(line));
        break;
    }

    return netorcai;
}
