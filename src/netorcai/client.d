module netorcai.client;

import std.socket;
import std.stdio;
import std.utf;
import std.bitmanip;
import std.json;
import std.format;
import std.exception;

import netorcai.message;
import netorcai.json_util;

/// Netorcai metaprotocol client class (D version)
class Client
{
    /// Constructor. Initializes a TCP socket (AF_INET, STREAM)
    this()
    {
        sock = new Socket(AddressFamily.INET, SocketType.STREAM);
    }

    /// Destructor. Closes the socket if needed.
    ~this()
    {
        close();
    }

    /// Connect to a remote endpoint. Throw Exception on error.
    void connect(in string hostname = "localhost", in ushort port = 4242)
    {
        sock.connect(new InternetAddress(hostname, port));
    }

    /// Close the socket.
    void close()
    {
        sock.shutdown(SocketShutdown.BOTH);
        sock.close();
    }

    /// Reads a string message on the client socket. Throw Exception on error.
    string recvString()
    {
        // Read content size
        ubyte[2] contentSizeBuf;
        auto received = sock.receive(contentSizeBuf);
        checkSocketOperation(received, "Cannot read content size.");

        immutable ushort contentSize = littleEndianToNative!ushort(contentSizeBuf);

        // Read content
        ubyte[] contentBuf;
        contentBuf.length = contentSize;
        received = sock.receive(contentBuf);
        checkSocketOperation(received, "Cannot read content.");

        return cast(string) contentBuf;
    }

    /// Reads a JSON message on the client socket. Throw Exception on error.
    JSONValue recvJson()
    {
        return recvString.parseJSON;
    }

    /// Reads a LOGIN_ACK message on the client socket. Throw Exception on error.
    LoginAckMessage readLoginAck()
    {
        auto msg = recvJson();
        switch (msg["message_type"].str)
        {
        case "LOGIN_ACK":
            return LoginAckMessage();
        case "KICK":
            throw new Exception(format!"Kicked from netorai. Reason: %s"(msg["kick_reason"].str));
        default:
            throw new Exception(format!"Unexpected message received: %s"(msg["message_type"].str));
        }
    }

    /// Reads a GAME_STARTS message on the client socket. Throw Exception on error.
    GameStartsMessage readGameStarts()
    {
        auto msg = recvJson;
        switch (msg["message_type"].str)
        {
        case "GAME_STARTS":
            return parseGameStartsMessage(msg);
        case "KICK":
            throw new Exception(format!"Kicked from netorai. Reason: %s"(msg["kick_reason"]));
        default:
            throw new Exception(format!"Unexpected message received: %s"(msg["message_type"]));
        }
    }

    /// Reads a TURN message on the client socket. Throw Exception on error.
    TurnMessage readTurn()
    {
        auto msg = recvJson;
        switch (msg["message_type"].str)
        {
        case "TURN":
            return parseTurnMessage(msg);
        case "GAME_ENDS":
            throw new Exception("Game over!");
        case "KICK":
            throw new Exception(format!"Kicked from netorai. Reason: %s"(msg["kick_reason"]));
        default:
            throw new Exception(format!"Unexpected message received: %s"(msg["message_type"]));
        }
    }

    /// Reads a GAME_ENDS message on the client socket. Throw Exception on error.
    GameEndsMessage readGameEnds()
    {
        auto msg = recvJson;
        switch (msg["message_type"].str)
        {
        case "GAME_ENDS":
            return parseGameEndsMessage(msg);
        case "KICK":
            throw new Exception(format!"Kicked from netorai. Reason: %s"(msg["kick_reason"]));
        default:
            throw new Exception(format!"Unexpected message received: %s"(msg["message_type"]));
        }
    }

    /// Reads a DO_INIT message on the client socket. Throw Exception on error.
    DoInitMessage readDoInit()
    {
        auto msg = recvJson;
        switch (msg["message_type"].str)
        {
        case "DO_INIT":
            return parseDoInitMessage(msg);
        case "KICK":
            throw new Exception(format!"Kicked from netorai. Reason: %s"(msg["kick_reason"]));
        default:
            throw new Exception(format!"Unexpected message received: %s"(msg["message_type"]));
        }
    }

    /// Reads a DO_TURN message on the client socket. Throw Exception on error.
    DoTurnMessage readDoTurn()
    {
        auto msg = recvJson;
        switch (msg["message_type"].str)
        {
        case "DO_TURN":
            return parseDoTurnMessage(msg);
        case "KICK":
            throw new Exception(format!"Kicked from netorai. Reason: %s"(msg["kick_reason"]));
        default:
            throw new Exception(format!"Unexpected message received: %s"(msg["message_type"]));
        }
    }

    /// Send a string message on the client socket. Throw Exception on error.
    void sendString(in string message)
    {
        string content = toUTF8(message ~ "\n");
        ushort contentSize = cast(ushort) content.length;
        ubyte[2] contentSizeBuf = nativeToLittleEndian(contentSize);

        auto sent = sock.send(contentSizeBuf);
        checkSocketOperation(sent, "Cannot send content size.");

        sent = sock.send(content);
        checkSocketOperation(sent, "Cannot send content.");
    }

    /// Send a JSON message on the client socket. Throw Exception on error.
    void sendJson(in JSONValue message)
    {
        sendString(message.toString);
    }

    /// Send a LOGIN message on the client socket. Throw Exception on error.
    void sendLogin(in string nickname, in string role)
    {
        JSONValue msg = ["message_type" : "LOGIN", "nickname" : nickname, "role" : role];

        sendJson(msg);
    }

    /// Send a TURN_ACK message on the client socket. Throw Exception on error.
    void sendTurnAck(in int turnNumber, in JSONValue actions)
    {
        JSONValue msg = ["message_type" : "TURN_ACK"];
        msg.object["turn_number"] = turnNumber;
        msg.object["actions"] = actions;

        sendJson(msg);
    }

    /// Send a DO_INIT_ACK message on the client socket. Throw Exception on error.
    void sendDoInitAck(in JSONValue initialGameState)
    {
        JSONValue msg = ["message_type" : "DO_INIT_ACK"];
        msg.object["initial_game_state"] = initialGameState;

        sendJson(msg);
    }

    /// Send a DO_TURN_ACK message on the client socket. Throw Exception on error.
    void sendDoTurnAck(in JSONValue gameState, in int winnerPlayerID)
    {
        JSONValue msg = ["message_type" : "DO_TURN_ACK"];
        msg.object["winner_player_id"] = winnerPlayerID;
        msg.object["game_state"] = gameState;

        sendJson(msg);
    }

    private void checkSocketOperation(in ptrdiff_t result, in string description)
    {
        if (result == Socket.ERROR)
            throw new Exception(description ~ "Socket error.");
        else if (result == 0)
            throw new Exception(description ~ "Socket closed by remote?");
    }

    private Socket sock;
}

unittest // Client/GL: Everything goes well.
{
    import std.process : wait;
    import netorcai.test : launchNetorcaiWaitListening;

    // Run netorcai
    auto n = launchNetorcaiWaitListening();

    // Run game logic
    auto gameLogic = new Client;
    scope(exit) destroy(gameLogic);
    gameLogic.connect();
    gameLogic.sendLogin("gl", "game logic");
    gameLogic.readLoginAck();

    // Run player
    auto player = new Client;
    scope(exit) destroy(player);
    player.connect();
    player.sendLogin("player", "player");
    player.readLoginAck();

    // Run game
    n.stdin.writeln("start");
    n.stdin.flush();

    const auto doInit = gameLogic.readDoInit();
    gameLogic.sendDoInitAck(`{"all_clients": {"gl": "D"}}`.parseJSON);
    player.readGameStarts();

    foreach (i; 1..doInit.nbTurnsMax)
    {
        gameLogic.readDoTurn();
        gameLogic.sendDoTurnAck(`{"all_clients": {"gl": "D"}}`.parseJSON, -1);

        auto turn = player.readTurn;
        player.sendTurnAck(turn.turnNumber, `[{"player": "D"}]`.parseJSON);
    }

    gameLogic.readDoTurn();
    gameLogic.sendDoTurnAck(`{"all_clients": {"gl": "D"}}`.parseJSON, -1);

    player.readGameEnds();
    wait(n.pid);
}

unittest // Kicked instead of expected message
{
    import std.process : kill, wait;
    import netorcai.test : launchNetorcaiWaitListening;
    import core.sys.posix.signal : SIGTERM;
    import std.exception : assertThrown;

    auto n = launchNetorcaiWaitListening;
    scope(exit) {
        kill(n.pid, SIGTERM);
        wait(n.pid);
    }

    auto kickedClient()
    {
        auto c = new Client;
        c.connect();
        c.sendString(`¿qué?`);
        return c;
    }

    assertThrown(kickedClient.readLoginAck());
    assertThrown(kickedClient.readGameStarts());
    assertThrown(kickedClient.readTurn());
    assertThrown(kickedClient.readGameEnds());
    assertThrown(kickedClient.readDoInit());
    assertThrown(kickedClient.readDoTurn());
}

unittest // Unexpected message received (and not KICK)
{
    import std.process : kill, wait;
    import netorcai.test : launchNetorcaiWaitListening;
    import core.sys.posix.signal : SIGTERM;
    import std.exception : assertThrown;

    auto n = launchNetorcaiWaitListening;
    scope(exit) {
        kill(n.pid, SIGTERM);
        wait(n.pid);
    }

    auto loggedClient()
    {
        auto c = new Client;
        c.connect();
        c.sendLogin("I", "player");
        return c;
    }

    // LOGIN_ACK instead of something else
    assertThrown(loggedClient.readGameStarts());
    assertThrown(loggedClient.readTurn());
    assertThrown(loggedClient.readGameEnds());
    assertThrown(loggedClient.readDoInit());
    assertThrown(loggedClient.readDoTurn());

    // Start a game.
    auto player1 = loggedClient; // Unexpected msg while reading LOGIN_ACK
    auto player2 = loggedClient; // GAME_ENDS while reading TURN
    auto gl = new Client;
    gl.connect();
    gl.sendLogin("gl", "game logic");

    gl.readLoginAck;
    player1.readLoginAck;
    player2.readLoginAck;

    // Run game
    n.stdin.writeln("start");
    n.stdin.flush();

    const auto doInit = gl.readDoInit();
    gl.sendDoInitAck(`{"all_clients": {"gl": "D"}}`.parseJSON);
    assertThrown(player1.readLoginAck);
    player2.readGameStarts();

    foreach (i; 1..doInit.nbTurnsMax)
    {
        gl.readDoTurn();
        gl.sendDoTurnAck(`{"all_clients": {"gl": "D"}}`.parseJSON, -1);

        auto turn = player2.readTurn;
        player2.sendTurnAck(turn.turnNumber, `[{"player": "D"}]`.parseJSON);
    }

    gl.readDoTurn();
    gl.sendDoTurnAck(`{"all_clients": {"gl": "D"}}`.parseJSON, -1);

    assertThrown(player2.readTurn);
}

unittest // Socket errors
{
    import std.datetime : dur;
    import std.exception : assertThrown;
    import std.process : kill, wait;
    import netorcai.test : launchNetorcaiWaitListening;
    import core.sys.posix.signal : SIGTERM;
    import core.thread : Thread;

    auto n = launchNetorcaiWaitListening;
    scope(exit) {
        kill(n.pid, SIGTERM);
        wait(n.pid);
    }

    // Never connected
    auto c = new Client;
    assertThrown(c.sendString(`Hello!`));

    // Disconnected
    c.connect();
    c.sendLogin("I", "superplayer");
    assertThrown(c.readLoginAck);
    Thread.sleep(dur!"seconds"(2));
    assertThrown(c.readLoginAck);
}
