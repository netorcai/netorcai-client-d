import std.json;
import std.format;
import std.stdio;

import netorcai;

void main()
{
    try
    {
        auto c = new Client;

        write("Connecting to netorcai... "); stdout.flush();
        c.connect();
        writeln("done");

        write("Logging in as a player... "); stdout.flush();
        c.sendLogin("D-player", "player");
        c.readLoginAck();
        writeln("done");

        write("Waiting for GAME_STARTS... "); stdout.flush();
        const auto gameStarts = c.readGameStarts();
        writeln("done");

        foreach (i; 1..gameStarts.nbTurnsMax)
        {
            write("Waiting for TURN... "); stdout.flush();
            const auto turn = c.readTurn();
            c.sendTurnAck(turn.turnNumber, `[{"player": "D"}]`.parseJSON);
            writeln("done");
        }

        write("Waiting for GAME_ENDS... "); stdout.flush();
        auto gameEnds = c.readGameEnds();
        writeln("done");
    }
    catch(Exception e)
    {
        writeln("Failure: ", e.msg);
    }
}
