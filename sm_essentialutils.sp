#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <regex>
#include <entitylump>

#include <serider/shared>

#undef REQUIRE_EXTENSIONS
#include <serider/tf2>
#include <ripext>
#define REQUIRE_EXTENSIONS

#include <serider/tf2classified>

#define PLUGIN_PREFIX "[\x03SM Utilities\x01]"

enum
{
    // Plugin
    /* Team Fortress 2 Classified */
    convert_vscript_vip,

    /* Team Fortress 2 */
    truce_active,
    thirdperson_enabled,
    setup_fastbuild,
    
    // Built-In
    /* Team Fortress 2 */
    tf_fastbuild,
    tf_cheapobjects,
    tf_obj_upgrade_per_hit,

    MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];

char g_CreditsSelection[MAXPLAYERS + 1][256];
char g_GameDir[64];

// TF2
bool g_TF2SDK = false;
bool g_ThirdPerson[MAXPLAYERS + 1];

public Plugin myinfo = 
{
    name = "SM Utilities | Essentials",
    author = "Heapons",
    description = "Tools and utilities for Source games",
    version = "26w32a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    /* Variables */
    GetGameFolderName(g_GameDir, sizeof(g_GameDir));

	if (GetEngineVersion() == Engine_SDK2013 && FileExists("resource/tf.ttf"))
	{
		g_TF2SDK = true;
	}
	else
	{
		KeyValues kv = new KeyValues("GameInfo");
		if (kv.ImportFromFile("gameinfo.txt") && kv.GetNum("DependsOnAppID") == 440)
		{
			g_TF2SDK = true;
		}
		delete kv;
	}

    /* ConVars */
    if (StrEqual(g_GameDir, "tf2classified"))
    {
        g_ConVars[convert_vscript_vip] = CreateConVar("sm_convert_vscript_vip", "1", "Convert VScript VIP to TF2C VIP.", _, true, 0.0, true, 1.0);
        AddMultiTargetFilter("@vips", TargetFilter_VIPs, "VIPs", false);
    }
    
    if (FindSendPropInfo("CTFGameRulesProxy", "m_bTruceActive") > 0)
    {
        g_ConVars[truce_active] = CreateConVar("sm_truce_active", "0", "Toggle truce mode.", _, true, 0.0, true, 1.0);
        g_ConVars[truce_active].AddChangeHook(OnConVarChanged);
    }

    if (g_TF2SDK)
    {
        g_ConVars[thirdperson_enabled] = CreateConVar("sm_thirdperson_enabled", "1", "Allow players to use third-person view.", _, true, 0.0, true, 1.0);
    }

    if (FindSendPropInfo("CTFGameRulesProxy", "m_bInSetup") > 0)
    {
        g_ConVars[setup_fastbuild] = CreateConVar("sm_setup_fastbuild", "0", "Enable fast building during setup time.", _, true, 0.0, true, 1.0);
    }

    AutoExecConfig(true, "sm_essentialutils");

    g_ConVars[tf_fastbuild] = FindConVar("tf_fastbuild");
    g_ConVars[tf_cheapobjects] = FindConVar("tf_cheapobjects");
    g_ConVars[tf_obj_upgrade_per_hit] = FindConVar("tf_obj_upgrade_per_hit");

    /* Events */
    HookEvent("player_spawn", Event_PlayerSpawn);
    if (HookEventEx("teamplay_round_start", Event_TeamplayRoundStart))
    {
        HookEvent("teamplay_setup_finished", Event_TeamplaySetupFinished);
    }

    /* Commands */
    // @admins
    RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC);
    RegAdminCmd("sm_team",    Command_SetTeam, ADMFLAG_GENERIC);

    if (FindSendPropInfo("CTFPlayer", "m_iClass") > 0)
    {
        RegAdminCmd("sm_setclass", Command_SetClass, ADMFLAG_GENERIC);
        RegAdminCmd("sm_class",    Command_SetClass, ADMFLAG_GENERIC);
    }

    RegAdminCmd("sm_fireinput", Command_FireInput, ADMFLAG_GENERIC);
    RegAdminCmd("sm_setcollision", Command_SetCollisionGroup, ADMFLAG_GENERIC);

    RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_GENERIC);

    RegAdminCmd("sm_health", Command_Health, ADMFLAG_GENERIC);
    RegAdminCmd("sm_maxhealth", Command_MaxHealth, ADMFLAG_GENERIC);

    RegAdminCmd("sm_scale", Command_Scale, ADMFLAG_GENERIC);

    if (FindSendPropInfo("CTFPlayer", "m_nCurrency") > 0)
    {
        RegAdminCmd("sm_currency", Command_Currency, ADMFLAG_GENERIC);
        RegAdminCmd("sm_money", Command_Currency, ADMFLAG_GENERIC);
    }

    if (FindSendPropInfo("CTFPlayer", "m_AttributeList") > 0)
    {
        RegAdminCmd("sm_addattr",         Command_AddAttribute, ADMFLAG_GENERIC);
        RegAdminCmd("sm_addattribute",    Command_AddAttribute, ADMFLAG_GENERIC);
        RegAdminCmd("sm_removeattr",      Command_RemoveAttribute, ADMFLAG_GENERIC);
        RegAdminCmd("sm_removeattribute", Command_RemoveAttribute, ADMFLAG_GENERIC);
        RegAdminCmd("sm_getattr",         Command_GetAttribute, ADMFLAG_GENERIC);
        RegAdminCmd("sm_getattribute",    Command_GetAttribute, ADMFLAG_GENERIC);
    }

	Event instructor = CreateEvent("instructor_server_hint_create", true);
	if (instructor != null)
	{
        RegAdminCmd("sm_hint", Command_HintSay, ADMFLAG_GENERIC);
		instructor.Cancel();
	}

    if (FindSendPropInfo("CTFPlayer", "m_ConditionList") > 0)
    {
        RegAdminCmd("sm_addcond",    Command_AddCondition, ADMFLAG_GENERIC);
        RegAdminCmd("sm_removecond", Command_RemoveCondition, ADMFLAG_GENERIC);
    }

    RegAdminCmd("sm_giveweapon",   Command_GiveWeapon, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removeweapon", Command_RemoveWeapon, ADMFLAG_GENERIC);
    RegAdminCmd("sm_stripweapons", Command_StripWeapons, ADMFLAG_GENERIC);

    // @everyone
    if (g_TF2SDK)
    {
        RegConsoleCmd("sm_fp", Command_FirstPerson);
        RegConsoleCmd("sm_firstperson", Command_FirstPerson);
        RegConsoleCmd("sm_tp", Command_ThirdPerson);
        RegConsoleCmd("sm_thirdperson", Command_ThirdPerson);
    }
    RegConsoleCmd("sm_credits", Command_Credits);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("JSONObject.FromFile");
    MarkNativeAsOptional("JSONObject.Get");
    MarkNativeAsOptional("JSONObject.GetString");
    MarkNativeAsOptional("JSONObject.Keys");
    MarkNativeAsOptional("JSONObjectKeys.ReadKey");
    MarkNativeAsOptional("JSONArray.Get");
    MarkNativeAsOptional("JSONArray.GetType");
    MarkNativeAsOptional("JSONArray.GetString");
    MarkNativeAsOptional("JSONArray.Length.get");
    return APLRes_Success;
}

// ConVars
public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    for (int i = 0; i < MAX_CONVARS; i++)
    {
        if (g_ConVars[i] == null)
            continue;

        if (convar == g_ConVars[i])
        {
            switch (i)
            {
                case truce_active:
                {
                    GameRules_SetProp("m_bTruceActive", g_ConVars[truce_active].BoolValue);
                }
            }
            break;
        }
    }
}

// Forwards
public void OnMapInit()
{
    int lumpLength = EntityLump.Length();
    EntityLumpEntry entry;
    char classname[64];

    // VIP VScript
    if (g_ConVars[convert_vscript_vip] != null && g_ConVars[convert_vscript_vip].BoolValue)
    {
        lumpLength = EntityLump.Length();
        bool isVScriptVIP = false;
        char buffer[256];
        for (int i = lumpLength - 1; i >= 0; i--)
        {
            entry = EntityLump.Get(i);
            if (entry.GetNextKey("classname", classname, sizeof(classname), -1) != -1 && StrEqual(classname, "logic_script", false))
            {
                if (entry.GetNextKey("vscripts", buffer, sizeof(buffer), -1) != -1 && StrContains(buffer, "vip.nut", false) != -1)
                {
                    isVScriptVIP = true;
                    EntityLump.Erase(i);
                    CloseHandle(entry);
                    continue;
                }
            }
            int pos = -1;
            while ((pos = entry.GetNextKey("OnMapSpawn", buffer, sizeof(buffer), pos)) != -1)
            {
                if (StrContains(buffer, "cane", false) != -1)
                {
                    EntityLump.Erase(i);
                    break;
                }
            }
            CloseHandle(entry);
        }
        if (isVScriptVIP)
        {
            int index = EntityLump.Append();
            entry = EntityLump.Get(index);
            entry.Append("classname", "tf2c_logic_vip");
            entry.Append("blue_escort", "1");
            entry.Append("show_escort_progress", "1");
            entry.Append("hud_type", "1");
            entry.Append("vehicle_type", "2");
            CloseHandle(entry);
        }
    }
}

public void OnMapStart()
{    
    /* Configs */
    ProcessDownloadsConfig();
    
    /* Target Filters */
    char teamName[32], targetFilter[64];
    int teamCount = GetTeamCount();
    for (int i = 0; i < teamCount; i++)
    {
        GetTeamName(i, teamName, sizeof(teamName));
        strcopy(targetFilter, sizeof(targetFilter), teamName);
        targetFilter[0] = CharToLower(targetFilter[0]);
        Format(targetFilter, sizeof(targetFilter), "@%s", targetFilter);
        AddMultiTargetFilter(targetFilter, TargetFilter_Team, teamName, false);
    }

    /* Items Schema */
    if (StrEqual(g_GameDir, "tf2classified"))
    {
        char path[PLATFORM_MAX_PATH] = "scripts/items/custom_items_game.txt";
        if (FileExists(path))
        {
            if (PrecacheGeneric(path))
            {
                AddFileToDownloadsTable(path);
            }
            char mapName[64];
            GetCurrentMap(mapName, sizeof(mapName));
            Format(path, sizeof(path), "scripts/items/%s_items_game.txt", mapName);
            if (FileExists(path) && PrecacheGeneric(path))
            {
                AddFileToDownloadsTable(path);
            }
        }

        static const char paths[][PLATFORM_MAX_PATH] = 
        {
            "scripts/items/custom_level_sounds.txt",
            "scripts/items/custom_particles.txt"
        };
        for (int i = 0; i < sizeof(paths); i++)
        {
            if (FileExists(paths[i]) && PrecacheGeneric(paths[i]))
            {
                AddFileToDownloadsTable(paths[i]);
            }
        }
    }
}

#include "sm_essentialutils/clients.sp"
#include "sm_essentialutils/commands.sp"
#include "sm_essentialutils/events.sp"
#include "sm_essentialutils/menus.sp"
#include "sm_essentialutils/stocks.sp"
#include "sm_essentialutils/targets.sp"