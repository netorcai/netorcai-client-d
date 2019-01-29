module netorcai.message;

import std.json;
import std.exception;

import netorcai.json_util;

/// Stores information about one player
struct PlayerInfo
{
    int playerID; /// The player unique identifier (in [0..nbPlayers[)
    string nickname; /// The player nickname
    string remoteAddress; /// The player socket remote address
    bool isConnected; /// Whether the player is currently connected or not
}

/// Parses a player information (in GAME_STARTS and GAME_ENDS messages)
PlayerInfo parsePlayerInfo(JSONValue o)
{
    PlayerInfo info;
    info.playerID = o["player_id"].getInt;
    info.nickname = o["nickname"].str;
    info.remoteAddress = o["remote_address"].str;
    info.isConnected = o["is_connected"].getBool;

    return info;
}
unittest
{
    immutable string s = `{
      "player_id": 0,
      "nickname": "jugador",
      "remote_address": "127.0.0.1:59840",
      "is_connected": true
    }`;

    const PlayerInfo pinfo = parseJSON(s).parsePlayerInfo;
    assert(pinfo.playerID == 0);
    assert(pinfo.nickname == "jugador");
    assert(pinfo.remoteAddress == "127.0.0.1:59840");
    assert(pinfo.isConnected == true);
}

/// Parses several player information (in GAME_STARTS and GAME_ENDS messages)
PlayerInfo[] parsePlayersInfo(JSONValue[] array)
{
    PlayerInfo[] infos;
    infos.length = array.length;

    foreach (i, o; array)
    {
        infos[i] = o.parsePlayerInfo;
    }

    return infos;
}
unittest
{
    immutable string s = `[
      {
        "player_id": 0,
        "nickname": "jugador",
        "remote_address": "127.0.0.1:59840",
        "is_connected": true
      },
      {
        "player_id": 1,
        "nickname": "bot",
        "remote_address": "127.0.0.1:59842",
        "is_connected": false
      }
    ]`;

    const PlayerInfo[] pinfos = parseJSON(s).array.parsePlayersInfo;
    assert(pinfos.length == 2);

    assert(pinfos[0].playerID == 0);
    assert(pinfos[0].nickname == "jugador");
    assert(pinfos[0].remoteAddress == "127.0.0.1:59840");
    assert(pinfos[0].isConnected == true);

    assert(pinfos[1].playerID == 1);
    assert(pinfos[1].nickname == "bot");
    assert(pinfos[1].remoteAddress == "127.0.0.1:59842");
    assert(pinfos[1].isConnected == false);
}

/// Content of a LOGIN_ACK metaprotocol message
struct LoginAckMessage
{
    // ¯\_(ツ)_/¯
}

/// Content of a GAME_STARTS metaprotocol message
struct GameStartsMessage
{
    int playerID; /// Caller's player identifier. players: [0..nbPlayers+nbSpecialPlayers[. visu: -1
    int nbPlayers; /// Number of players in the game
    int nbSpecialPlayers; /// Number of special players in the game
    int nbTurnsMax; /// Maximum number of turns. Game can finish before it
    double msBeforeFirstTurn; /// Time before the first TURN is sent (in ms)
    double msBetweenTurns; /// Time between two consecutive TURNs (in ms)
    PlayerInfo[] playersInfo; /// (only for visus) Information about the players
    JSONValue initialGameState; /// Game-dependent object.
}

/// Parses a GAME_STARTS metaprotocol message
GameStartsMessage parseGameStartsMessage(JSONValue o)
{
    GameStartsMessage m;

    m.playerID = o["player_id"].getInt;
    m.nbPlayers = o["nb_players"].getInt;
    m.nbSpecialPlayers = o["nb_special_players"].getInt;
    m.nbTurnsMax = o["nb_turns_max"].getInt;
    m.msBeforeFirstTurn = o["milliseconds_before_first_turn"].getDouble;
    m.msBetweenTurns = o["milliseconds_between_turns"].getDouble;
    m.initialGameState = o["initial_game_state"].object;
    m.playersInfo = o["players_info"].array.parsePlayersInfo;

    return m;
}
unittest
{
    immutable string s = `{
      "message_type": "GAME_STARTS",
      "player_id": 0,
      "players_info": [
        {
          "player_id": 0,
          "nickname": "jugador",
          "remote_address": "127.0.0.1:59840",
          "is_connected": true
        }
      ],
      "nb_players": 4,
      "nb_special_players": 0,
      "nb_turns_max": 100,
      "milliseconds_before_first_turn": 1000,
      "milliseconds_between_turns": 1000,
      "initial_game_state": {}
    }`;

    const GameStartsMessage m = parseJSON(s).parseGameStartsMessage;
    assert(m.playerID == 0);
    assert(m.playersInfo.length == 1);
    assert(m.playersInfo[0] == `{"player_id":0,"nickname":"jugador",
        "remote_address":"127.0.0.1:59840",
        "is_connected":true}`.parseJSON.parsePlayerInfo);
    assert(m.nbPlayers == 4);
    assert(m.nbSpecialPlayers == 0);
    assert(m.nbTurnsMax == 100);
    assert(m.msBeforeFirstTurn == 1000);
    assert(m.msBetweenTurns == 1000);
    assert(m.initialGameState.object.length == 0);
}

/// Content of a GAME_ENDS metaprotocol message
struct GameEndsMessage
{
    int winnerPlayerID; /// Unique identifier of the player that won the game. Or -1.
    JSONValue gameState; /// Game-dependent object.
}

/// Parses a GAME_ENDS metaprotocol message
GameEndsMessage parseGameEndsMessage(JSONValue o)
{
    GameEndsMessage m;
    m.winnerPlayerID = o["winner_player_id"].getInt;
    m.gameState = o["game_state"].object;

    return m;
}
unittest
{
    immutable string s = `{
      "message_type": "GAME_ENDS",
      "winner_player_id": 0,
      "game_state": {}
    }`;

    const GameEndsMessage m = s.parseJSON.parseGameEndsMessage;
    assert(m.winnerPlayerID == 0);
    assert(m.gameState.object.length == 0);
}

/// Content of a TURN metaprotocol message
struct TurnMessage
{
    int turnNumber; /// In [0..nbTurnsMax[
    PlayerInfo[] playersInfo; /// (only for visus) Information about the players
    JSONValue gameState; /// Game-dependent object.
}

/// Parses a TURN metaprotocol message
TurnMessage parseTurnMessage(JSONValue o)
{
    TurnMessage m;
    m.turnNumber = o["turn_number"].getInt;
    m.playersInfo = o["players_info"].array.parsePlayersInfo;
    m.gameState = o["game_state"].object;

    return m;
}
unittest
{
    immutable string s = `{
      "message_type": "TURN",
      "turn_number": 0,
      "game_state": {},
      "players_info": [
        {
          "player_id": 0,
          "nickname": "jugador",
          "remote_address": "127.0.0.1:59840",
          "is_connected": true
        }
      ]
    }`;

    const TurnMessage m = s.parseJSON.parseTurnMessage;
    assert(m.turnNumber == 0);
    assert(m.gameState.object.length == 0);
    assert(m.playersInfo == `[{"player_id":0,"nickname":"jugador",
        "remote_address":"127.0.0.1:59840",
        "is_connected":true}]`.parseJSON.array.parsePlayersInfo);
}

/// Content of a DO_INIT metaprotocol message
struct DoInitMessage
{
    int nbPlayers; /// The number of players of the game
    int nbSpecialPlayers; /// Number of special players in the game
    int nbTurnsMax; /// The maximum number of turns of the game
}

/// Parses a DO_INIT metaprotocol message
DoInitMessage parseDoInitMessage(JSONValue o)
{
    DoInitMessage m;
    m.nbPlayers = o["nb_players"].getInt;
    m.nbSpecialPlayers = o["nb_special_players"].getInt;
    m.nbTurnsMax = o["nb_turns_max"].getInt;

    return m;
}
unittest
{
    immutable string s = `{
      "message_type": "DO_INIT",
      "nb_players": 4,
      "nb_special_players": 0,
      "nb_turns_max": 100
    }`;

    immutable DoInitMessage m = s.parseJSON.parseDoInitMessage;
    assert(m.nbPlayers == 4);
    assert(m.nbSpecialPlayers == 0);
    assert(m.nbTurnsMax == 100);
}

/// Convenient struct for the player actions of a DO_TURN metaprotocol message
struct PlayerActions
{
    int playerID; /// The identifier of the player that issued the actions
    int turnNumber; /// The turn number the actions come from
    JSONValue actions; /// The actions themselves
}

/// Parses the playerActions field of a DO_TURN metaprotocol message
PlayerActions parsePlayerActions(JSONValue o)
{
    PlayerActions pa;
    pa.playerID = o["player_id"].getInt;
    pa.turnNumber = o["turn_number"].getInt;
    pa.actions = o["actions"].array;

    return pa;
}
unittest
{
    immutable string s = `{
      "player_id": 2,
      "turn_number": 4,
      "actions": []
    }`;

    immutable PlayerActions pa = s.parseJSON.parsePlayerActions;
    assert(pa.playerID == 2);
    assert(pa.turnNumber == 4);
    assert(pa.actions.array.length == 0);
}

/// Content of a DO_TURN metaprotocol message
struct DoTurnMessage
{
    PlayerActions[] playerActions; /// The ordered list of player actions
}

/// Parses a DO_TURN metaprotocol message
DoTurnMessage parseDoTurnMessage(JSONValue v)
{
    DoTurnMessage m;

    auto actions = v["player_actions"].array;
    m.playerActions.length = actions.length;

    foreach (i, o; actions)
    {
        m.playerActions[i] = o.parsePlayerActions;
    }

    return m;
}
unittest
{
    immutable string s = `{
      "message_type": "DO_TURN",
      "player_actions": [
        {
          "player_id": 1,
          "turn_number": 2,
          "actions": []
        },
        {
          "player_id": 0,
          "turn_number": 3,
          "actions": [ 4 ]
        }
      ]
    }`;

    DoTurnMessage m = s.parseJSON.parseDoTurnMessage;
    assert(m.playerActions.length == 2);
    assert(m.playerActions[0].playerID == 1);
    assert(m.playerActions[0].turnNumber == 2);
    assert(m.playerActions[0].actions.array.length == 0);
    assert(m.playerActions[1].playerID == 0);
    assert(m.playerActions[1].turnNumber == 3);
    assert(m.playerActions[1].actions.array.length == 1);
    assert(m.playerActions[1].actions.array[0].getInt == 4);
}
