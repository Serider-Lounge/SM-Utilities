#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <regex>
#include <ripext/json>
#include <keyvalues>

#undef REQUIRE_PLUGIN
#include <trainingmsg>
#define REQUIRE_PLUGIN

#include <serider/shared>

#undef REQUIRE_EXTENSIONS
#include <serider/tf2>
#include <navbot>
#include <rcbot2>
#define REQUIRE_EXTENSIONS

#define PLUGIN_PREFIX "[\x03Bots Fun\x01]"

enum
{
	trainingmsg,
    navbot,
	rcbot2,
    ripext,

	MAX_LIBRARIES
}

bool g_Libraries[MAX_LIBRARIES];

enum
{
    // Plugin
    plugin_bot_autoteambalance,
    plugin_bot_quota_interval,
    plugin_bot_quota_mode,
    plugin_bot_quota,
    plugin_bot_type,
    plugin_humans_only,
    plugin_nav_generate_auto,

    // NavBot
    sm_navbot_tf_teammates_are_enemies,

    // Built-In
    bot_difficulty,
    bot_quota,
    mp_friendlyfire,
    tf_bot_reevaluate_class_in_spawnroom,
    tf_mvm_defenders_team_size,
    tf_mvm_max_invaders,
    tf2c_allow_special_classes,

    MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];

enum
{
    BOT_TYPE_VALVE,
    BOT_TYPE_NAVBOT,
    BOT_TYPE_RCBOT2,

    BOT_TYPE_COUNT
}

Handle g_hQuotaTimer;
char g_GameDir[32];
bool g_IsDedicatedServer;
bool g_IsServerHibernating;
int g_TeamCount;
bool g_IsTF2SDK;

public Plugin myinfo = 
{
    name = "SM Utilities | Bots Fun",
    author = "Heapons",
    description = "An all-in-one bot manager",
    version = "26w31b",
    url = "https://github.com/Heapons/SM-Utilities"
};

// Forwards
public void OnPluginStart()
{
    /* Variables */
    GetGameFolderName(g_GameDir, sizeof(g_GameDir));
    
    g_IsDedicatedServer = IsDedicatedServer();
    g_IsServerHibernating = false;

    EngineVersion engine = GetEngineVersion();
	if (engine == Engine_TF2 || (engine == Engine_SDK2013 && FileExists("resource/tf.ttf")))
	{
		g_IsTF2SDK = true;
	}
	else
	{
		KeyValues kv = new KeyValues("GameInfo");
		if (kv.ImportFromFile("gameinfo.txt"))
		{
			kv.Rewind();
			if (kv.JumpToKey("FileSystem") && kv.GetNum("DependsOnAppID") == 440)
			{
				g_IsTF2SDK = true;
			}
		}
		delete kv;
	}

    /* ConVars */
    g_ConVars[plugin_bot_autoteambalance] = CreateConVar(
        "sm_bot_autoteambalance",
        "1",
        "Whether bots are affected by auto-balance.", _, true, 0.0, true, 1.0);
    
    g_ConVars[plugin_bot_quota_interval] = CreateConVar(
        "sm_bot_quota_interval",
        "1.0",
        "The interval at which to maintain the bot quota.", _, true, 0.0);
    g_ConVars[plugin_bot_quota_interval].AddChangeHook(OnConVarChanged);
    
    g_ConVars[plugin_bot_quota_mode] = CreateConVar(
        "sm_bot_quota_mode",
        "fill",
        "Determines the type of quota.\nAllowed values: 'fill', 'balance'.\nIf 'fill', the server will adjust bots to keep sm_bot_quota total players in the game.\nIf 'balance', the server will adjust bots to keep teams balanced at bare minimum.");
    g_ConVars[plugin_bot_quota_mode].AddChangeHook(OnConVarChanged);
    
    g_ConVars[plugin_bot_quota] = CreateConVar(
        "sm_bot_quota",
        "12",
        "Determines the total number of bots in the game.", _, true, 0.0, true, float(MAXPLAYERS));
    g_ConVars[plugin_bot_quota].AddChangeHook(OnConVarChanged);
    
    g_ConVars[plugin_bot_type] = CreateConVar(
        "sm_bot_type",
        "valve",
        "The type of bot to spawn.\nAllowed values: 'valve', 'random', 'rcbot2', 'navbot'.");
    g_ConVars[plugin_bot_type].AddChangeHook(OnConVarChanged);
    
    if (g_IsTF2SDK)
    {
        g_ConVars[plugin_humans_only] = CreateConVar(
            "sm_bot_humans_only",
            "1",
            "Whether to pre-maturely end the round when all humans are dead in Arena Mode or Sudden Death mode.", _, true, 0.0, true, 1.0);
    }
    
    if (CommandExists("nav_generate"))
    {
        g_ConVars[plugin_nav_generate_auto] = CreateConVar(
            "nav_generate_auto",
            "0",
            "Whether to automatically generate navmeshes for the current map if none exist. Only triggers when the server is empty.", _, true, 0.0, true, 1.0);
        g_ConVars[plugin_nav_generate_auto].AddChangeHook(OnConVarChanged);
    }

    AutoExecConfig(true, "bots_fun");

    if (g_IsTF2SDK)
    {
        g_ConVars[bot_difficulty] = FindConVar("tf_bot_difficulty");
        g_ConVars[bot_quota]      = FindConVar("tf_bot_quota");
    }
    else if (StrEqual(g_GameDir, "hl2mp"))
    {
        g_ConVars[bot_difficulty] = FindConVar("hl2mp_bot_difficulty");
        g_ConVars[bot_quota]      = FindConVar("hl2mp_bot_quota");
    }
    else
    {
        g_ConVars[bot_difficulty] = FindConVar("bot_difficulty");
        g_ConVars[bot_quota]      = FindConVar("bot_quota");
    }
    
    g_ConVars[mp_friendlyfire] = FindConVar("mp_friendlyfire");
    g_ConVars[mp_friendlyfire].AddChangeHook(OnConVarChanged);
    
    g_ConVars[sm_navbot_tf_teammates_are_enemies] = FindConVar("sm_navbot_tf_teammates_are_enemies");
    
    g_ConVars[tf_bot_reevaluate_class_in_spawnroom] = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
    g_ConVars[tf_mvm_defenders_team_size] = FindConVar("tf_mvm_defenders_team_size");
    g_ConVars[tf_mvm_defenders_team_size].AddChangeHook(OnConVarChanged);
    g_ConVars[tf_mvm_max_invaders] = FindConVar("tf_mvm_max_invaders");
    
    g_ConVars[tf2c_allow_special_classes] = FindConVar("tf2c_allow_special_classes");

    /* Commands */
    RegAdminCmd("sm_puppet_add", Command_PuppetAdd, ADMFLAG_CHEATS, "Add a puppet bot.");

	RegServerCmd("nav_generate", Command_NavGenerate);
    RegServerCmd("nav_generate_incremental", Command_NavGenerate);
    RegServerCmd("sm_nav_generate", Command_NavGenerate);
    RegServerCmd("sm_nav_generate_incremental", Command_NavGenerate);

    int flags;
    static const char cheatCommands[][] = {
        "nav_generate",
        "nav_generate_incremental",
        "nav_mark_walkable",
        "bot_kick"
    };
    for (int i = 0; i < sizeof(cheatCommands); i++)
    {
        flags = GetCommandFlags(cheatCommands[i]);
        if (flags & FCVAR_CHEAT)
        {
            SetCommandFlags(cheatCommands[i], flags & ~FCVAR_CHEAT);
        }
    }

    /* Events */
    if (g_IsTF2SDK)
    {
        HookEvent("post_inventory_application", Event_PlayerUpdate);
        HookEvent("teamplay_flag_event", Event_PlayerUpdate);
        HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
    }
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // trainingmsg
    MarkNativeAsOptional("SendTrainingMessageToAll");

    // Rest In Pawn
    MarkNativeAsOptional("JSONObject.FromFile");
    MarkNativeAsOptional("JSONObject.HasKey");
    MarkNativeAsOptional("JSONObject.Get");
    MarkNativeAsOptional("JSONObject.GetString");
    return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
    /* Variables */
    g_Libraries[trainingmsg] = g_IsTF2SDK && LibraryExists("trainingmsg");
    g_Libraries[navbot]      = LibraryExists("navbot");
    g_Libraries[rcbot2]      = LibraryExists("RCBot2");
    g_Libraries[ripext]      = LibraryExists("REST in Pawn");
    
    /* Target Filters */
    if (g_Libraries[rcbot2])
    {
        AddMultiTargetFilter("@rcbots", TargetFilter_RCBots, "RCBots", false);

        ServerCommand("rcbot%s config min_bots 0", g_IsDedicatedServer ? "d" : "");
        ServerCommand("rcbot%s config max_bots 0", g_IsDedicatedServer ? "d" : "");
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (g_IsTF2SDK && StrEqual(name, "trainingmsg"))
    {
        g_Libraries[trainingmsg] = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (g_IsTF2SDK && StrEqual(name, "trainingmsg"))
    {
        g_Libraries[trainingmsg] = false;
    }
    else if (StrEqual(name, "navbot"))
    {
        g_Libraries[navbot] = false;
    }
    else if (StrEqual(name, "RCBot2"))
    {
        g_Libraries[rcbot2] = false;
    }
    else if (StrEqual(name, "REST in Pawn"))
    {
        g_Libraries[ripext] = false;
    }
}

public void OnMapStart()
{
    /* Variables */
    g_TeamCount = GetTeamCount();
}

public void OnConfigsExecuted()
{    
    /* Functions */
    NavGenerate();
    MaintainBotQuota();

    /* RCBot2 */
    char mapName[96], mapDisplayName[64], mapPath[PLATFORM_MAX_PATH];
    
    GetCurrentMap(mapName, sizeof(mapName));
    GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));
    
    Format(mapPath, sizeof(mapPath), "addons/rcbot2/waypoints/%s/%s.rcw", g_GameDir, mapDisplayName);

    char botType[32];
    g_ConVars[plugin_bot_type].GetString(botType, sizeof(botType));

    // https://github.com/APGRoboCop/rcbot2/issues/49
    if (g_Libraries[rcbot2] && (StrEqual(botType, "rcbot2") || StrEqual(botType, "random")) &&
        !RCBot2_IsWaypointAvailable() && FileExists(mapPath))
    {
        ServerCommand("rcbot%s waypoint load %s", g_IsDedicatedServer ? "d" : "", mapDisplayName);
    }
}

public void OnServerEnterHibernation()
{
    g_IsServerHibernating = true;
}

public void OnServerExitHibernation()
{
    g_IsServerHibernating = false;
}

#include "bots_fun/clients.sp"
#include "bots_fun/commands.sp"
#include "bots_fun/convars.sp"
#include "bots_fun/events.sp"
#include "bots_fun/json.sp"
#include "bots_fun/sdkhooks.sp"
#include "bots_fun/stocks.sp"
#include "bots_fun/targets.sp"
#include "bots_fun/timers.sp"