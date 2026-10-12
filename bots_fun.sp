#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <regex>
#include <keyvalues>
#include <navmesh>

#include <smutils/clients>

#undef REQUIRE_PLUGIN
#include <trainingmsg>

#undef REQUIRE_EXTENSIONS
#include <smutils/tf2>
#include <ripext/json>
#include <navbot>
#include <rcbot2>

#define PLUGIN_PREFIX "[\x03Bots Fun\x01]"

enum
{
    // Plugins
	trainingmsg,

    // Extensions
    navbot,
	rcbot2,
    ripext,

	MAX_LIBRARIES
}

static const char libraries[][] =
{
    // Plugins
    "trainingmsg",

    // Extensions
    "navbot.ext",
    "rcbot2.ext",
    "rip.ext"
};

bool g_Libraries[MAX_LIBRARIES];

enum
{
    // Plugin
    plugin_bot_autoteambalance,
    plugin_bot_names,
    plugin_bot_quota_interval,
    plugin_bot_quota_mode,
    plugin_bot_quota_mvm,
    plugin_bot_quota,
    plugin_bot_type_random,
    plugin_bot_type,
    plugin_humans_only,
    plugin_nav_generate_auto,

    // NavBot
    sm_navbot_tf_teammates_are_enemies,

    // Rafmod
    sig_etc_allow_civilian_class,

    // Built-In
    bot_difficulty,
    bot_quota,
    hostname,
    mp_friendlyfire,
    mp_teams_unbalance_limit,
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

char g_BotTypes[][] =
{
    "valve",
    "navbot",
    "rcbot2"
};

bool g_IsDedicatedServer;
bool g_IsMVM;
bool g_IsNavGenerating;
bool g_IsReverseMVM;
bool g_IsServerHibernating;
bool g_IsTF2SDK;
char g_GameDir[32];
Handle g_hQuotaTimer;
JSONObject g_BotConfig;
ArrayList g_PlayerClasses;
int g_BotTypeCount;
int g_BotTypeOrder[BOT_TYPE_COUNT];
int g_TeamCount;

public Plugin myinfo = 
{
    name = "SM Utilities | Bots Fun",
    author = "Heapons",
    description = "An all-in-one bot manager",
    version = "26w32a",
    url = "https://github.com/Heapons/SM-Utilities"
};

// Forwards
public void OnPluginStart()
{
    /* Variables */
    GetGameFolderName(g_GameDir, sizeof(g_GameDir));

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/bots_fun.json");
    if (FileExists(path))
        g_BotConfig = JSONObject.FromFile(path);
    
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

    if (g_IsTF2SDK)
    {
        g_PlayerClasses = new ArrayList();
        DirectoryListing dir = OpenDirectory("scripts/playerclasses", true);
        if (dir != null)
        {
            char fileName[64];
            FileType type;
            while (dir.GetNext(fileName, sizeof(fileName), type))
            {
                if (type == FileType_Directory)
                    continue;

                int dot = FindCharInString(fileName, '.');
                if (dot != -1)
                    fileName[dot] = '\0';

                g_PlayerClasses.PushString(fileName);
            }
            delete dir;
        }
    }

    /* ConVars */
    g_ConVars[plugin_bot_autoteambalance] = CreateConVar(
        "sm_bot_autoteambalance",
        "1",
        "Whether bots are affected by auto-balance.",
        _, true, 0.0, true, 1.0);
    
    g_ConVars[plugin_bot_quota_interval] = CreateConVar(
        "sm_bot_quota_interval",
        "1.0",
        "The interval at which to maintain the bot quota.",
        _, true, 0.0);

    g_ConVars[plugin_bot_names] = CreateConVar(
        "sm_bot_names",
        "2",
        "Whether to use custom bot names.\nAllowed values: '0', '1', '2'.\nIf '0', no custom names are used.\nIf '1', only 'default' names are used.\nIf '2', rename bots based on their models.",
        _, true, 0.0, true, 2.0);

    g_ConVars[plugin_bot_quota_mode] = CreateConVar(
        "sm_bot_quota_mode",
        "balance",
        "Determines the type of quota.\nAllowed values: 'fill', 'layer', 'balance'.\nIf 'fill', the server will adjust bots to keep sm_bot_quota total players in the game.\nIf 'layer', the server will adjust bots to keep teams balanced at bare minimum.\nIf 'balance', the server will adjust bots to keep teams balanced and force players to replace remaining bots.");

    g_ConVars[plugin_bot_quota] = CreateConVar(
        "sm_bot_quota",
        "12",
        "Determines the total number of bots in the game.",
        _, true, 0.0, true, float(MAXPLAYERS));
    
    g_ConVars[plugin_bot_type] = CreateConVar(
        "sm_bot_type",
        "navbot,rcbot2,valve",
        "The type of bot to spawn.\nAllowed values: 'valve', 'rcbot2', 'navbot'.\nIf bot types are sequenced (separated by commas), the priority order will be read from left to right.");
    
    g_ConVars[plugin_bot_type_random] = CreateConVar(
        "sm_bot_type_random",
        "0",
        "Whether to randomly select a bot type from sm_bot_type.\nIf a bot type is blacklisted, it won't be accounted for.",
        _, true, 0.0, true, 1.0);

    if (g_IsTF2SDK)
    {
        g_ConVars[plugin_humans_only] = CreateConVar(
            "sm_bot_humans_only",
            "1",
            "Whether to pre-maturely end the round when all humans are dead in Arena Mode or Sudden Death mode.",
            _, true, 0.0, true, 1.0);

        g_ConVars[plugin_bot_quota_mvm] = CreateConVar(
            "sm_bot_quota_mvm",
            "1",
            "Whether to manage the bot quota in Mann Vs. Machine.",
            _, true, 0.0, true, 1.0);
    }
    
    g_ConVars[plugin_nav_generate_auto] = CreateConVar(
        "sm_nav_generate_auto",
        "0",
        "Whether to automatically generate navmeshes for the current map if none exist. Only triggers when the server is empty.",
        _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "bots_fun");

    if (g_IsTF2SDK)
    {
        g_ConVars[bot_difficulty] = FindConVar("tf_bot_difficulty");
        g_ConVars[bot_quota]      = FindConVar("tf_bot_quota");
    }
    else if (strcmp(g_GameDir, "hl2mp") == 0)
    {
        g_ConVars[bot_difficulty] = FindConVar("hl2mp_bot_difficulty");
        g_ConVars[bot_quota]      = FindConVar("hl2mp_bot_quota");
    }
    else
    {
        g_ConVars[bot_difficulty] = FindConVar("bot_difficulty");
        g_ConVars[bot_quota]      = FindConVar("bot_quota");
    }
    g_ConVars[bot_quota].SetInt(0);
    
    g_ConVars[mp_friendlyfire]          = FindConVar("mp_friendlyfire");
    g_ConVars[mp_teams_unbalance_limit] = FindConVar("mp_teams_unbalance_limit");
    g_ConVars[hostname]                 = FindConVar("hostname");
    
    g_ConVars[sm_navbot_tf_teammates_are_enemies] = FindConVar("sm_navbot_tf_teammates_are_enemies");
    
    if (g_IsTF2SDK)
    {
        g_ConVars[tf_bot_reevaluate_class_in_spawnroom] = FindConVar("tf_bot_reevaluate_class_in_spawnroom");
        g_ConVars[tf_mvm_defenders_team_size]           = FindConVar("tf_mvm_defenders_team_size");
        g_ConVars[tf_mvm_max_invaders]                  = FindConVar("tf_mvm_max_invaders");
        g_ConVars[tf2c_allow_special_classes]           = FindConVar("tf2c_allow_special_classes");
        g_ConVars[sig_etc_allow_civilian_class]         = FindConVar("sig_etc_allow_civilian_class");
    }

    /* Commands */
    AddCommandListener(Command_JoinTeam, "jointeam");

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
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
    HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    static const char natives[][] =
    {
        // trainingmsg
        "SendTrainingMessageToAll",

        // Rest In Pawn
        "JSONObject.FromFile",
        "JSONObject.HasKey",
        "JSONObject.Get",
        "JSONObject.GetString"
    };

    for (int i = 0; i < sizeof(natives); i++)
    {
        MarkNativeAsOptional(natives[i]);
    }

    return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
    /* Variables */
    for (int i = 0; i < MAX_LIBRARIES; i++)
    {
        switch (i)
        {
            case trainingmsg:
            {
                g_Libraries[i] = g_IsTF2SDK && LibraryExists(libraries[i]);
            }
            default:
            {
                if (strncmp(libraries[i][strlen(libraries[i]) - 4], ".ext", 4) == 0)
                    g_Libraries[i] = GetExtensionFileStatus(libraries[i]) > 0;
                else
                    g_Libraries[i] = LibraryExists(libraries[i]);
            }
        }
    }

    /* ConVars */
    for (int i = 0; i < MAX_CONVARS; i++)
    {
        if (g_ConVars[i] != null)
        {
            g_ConVars[i].AddChangeHook(OnConVarChanged);
        }
    }

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
    if (g_IsTF2SDK)
    {
        if (strcmp(name, "trainingmsg") == 0)
        {
            g_Libraries[trainingmsg] = true;
        }
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (g_IsTF2SDK)
    {
        if (strcmp(name, "trainingmsg") == 0)
        {
            g_Libraries[trainingmsg] = false;
        }
    }
    else if (strcmp(name, "navbot") == 0)
    {
        g_Libraries[navbot] = false;
    }
    else if (strcmp(name, "RCBot2") == 0)
    {
        g_Libraries[rcbot2] = false;
    }
    else if (strcmp(name, "REST in Pawn") == 0)
    {
        g_Libraries[ripext] = false;
    }
}

public void OnMapStart()
{
    /* Variables */
    if (g_TeamCount == 0)
    {
        g_TeamCount = GetTeamCount();
    }
    g_IsNavGenerating = false;

    /* Functions */
    NavGenerate();
    MaintainBotQuota();
}

public void OnMapEnd()
{
    g_hQuotaTimer = null;
}

public void OnConfigsExecuted()
{
    /* Variables */
    g_IsMVM = FindEntityByClassname(-1, "tf_logic_mann_vs_machine") != -1;
    if (g_IsMVM)
    {
        char popfile[PLATFORM_MAX_PATH];
        if (TF2_GetPopFileName(popfile, sizeof(popfile)) != 0)
        {
            KeyValues kv = new KeyValues("WaveSchedule");
            if (kv.ImportFromFile(popfile) && kv.JumpToKey("WaveSchedule"))
            {
                g_IsReverseMVM = view_as<bool>(kv.GetNum("ReverseWinConditions"));
            }
            delete kv;
        }
    }

    /* RCBot2 */
    char mapName[96], mapDisplayName[64], mapPath[PLATFORM_MAX_PATH];
    
    GetCurrentMap(mapName, sizeof(mapName));
    GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));
    
    FormatEx(mapPath, sizeof(mapPath), "addons/rcbot2/waypoints/%s/%s.rcw", g_GameDir, mapDisplayName);

    // https://github.com/APGRoboCop/rcbot2/issues/49
    if (g_Libraries[rcbot2] && IsBotTypeEnabled(BOT_TYPE_RCBOT2) &&
        !RCBot2_IsWaypointAvailable() && FileExists(mapPath))
    {
        ServerCommand("rcbot%s waypoint load %s", g_IsDedicatedServer ? "d" : "", mapDisplayName);
    }

    /* Functions */
    UpdateBotTypes();
}

public void OnServerEnterHibernation()
{
    g_IsServerHibernating = true;
    if (g_ConVars[plugin_nav_generate_auto].BoolValue && !g_IsNavGenerating && !NavMesh_Exists())
    {
        ServerCommand("nav_generate");
    }
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