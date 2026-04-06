#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <regex>
#include <entitylump>

#include <serider/shared>

#undef REQUIRE_EXTENSIONS
#include <serider/tf2>
#define REQUIRE_EXTENSIONS

#include <serider/tf2classified>

#undef REQUIRE_PLUGIN
#include <tf2attributes>
#define REQUIRE_PLUGIN

#define PLUGIN_PREFIX           "[{#F69E1D}S{#5596CF}M\x01]"
#define PLUGIN_PREFIX_CONSOLE   "[SM Utilities]"

enum
{
    // Plugin
    auto_download,
    convert_vscript_vip,
    truce_active,

    MAX_CONVARS
}

ConVar g_ConVars[MAX_CONVARS];

bool g_ThirdPerson[MAXPLAYERS + 1];
bool g_bTF2Attributes;
char g_CreditsSelection[MAXPLAYERS + 1][256];

char g_GameDir[64];

public Plugin myinfo = 
{
    name = "SM Utilities | Essentials",
    author = "Heapons",
    description = "Tools and utilities for Source games",
    version = "26w15b",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    /* Variables */
    GetGameFolderName(g_GameDir, sizeof(g_GameDir));

    /* ConVars */
    g_ConVars[auto_download] = CreateConVar("sm_auto_download", "0", "Automatically add all server files to the downloads table.", _, true, 0.0, true, 1.0);

    if (StrEqual(g_GameDir, "tf2classified"))
    {
        g_ConVars[convert_vscript_vip] = CreateConVar("sm_convert_vscript_vip", "1", "Convert VScript VIP to TF2C VIP.", _, true, 0.0, true, 1.0);

        AddMultiTargetFilter("@vips", TargetFilter_Civilians, "VIPs", true);
    }
    
    if (FindSendPropInfo("CTFGameRulesProxy", "m_bTruceActive") > 0)
    {
        g_ConVars[truce_active] = CreateConVar("sm_truce_active", "0", "Toggle truce mode.", _, true, 0.0, true, 1.0);
    }

    /* Events */
    HookEvent("player_spawn", Event_PlayerSpawn);

    /* Commands */
    // @admins
    RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC);
    RegAdminCmd("sm_team",    Command_SetTeam, ADMFLAG_GENERIC);

    RegAdminCmd("sm_setclass", Command_SetClass, ADMFLAG_GENERIC);
    RegAdminCmd("sm_class",    Command_SetClass, ADMFLAG_GENERIC);

    RegAdminCmd("sm_fireinput", Command_FireInput, ADMFLAG_GENERIC);
    RegAdminCmd("sm_setcollision", Command_SetCollisionGroup, ADMFLAG_GENERIC);

    RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_GENERIC);

    RegAdminCmd("sm_health", Command_Health, ADMFLAG_GENERIC);
    RegAdminCmd("sm_maxhealth", Command_MaxHealth, ADMFLAG_GENERIC);
    RegAdminCmd("sm_currency", Command_Currency, ADMFLAG_GENERIC);
    RegAdminCmd("sm_scale", Command_Scale, ADMFLAG_GENERIC);

    RegAdminCmd("sm_addattr",         Command_AddAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_addattribute",    Command_AddAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removeattr",      Command_RemoveAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removeattribute", Command_RemoveAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_getattr",         Command_GetAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_getattribute",    Command_GetAttribute, ADMFLAG_GENERIC);

    RegAdminCmd("sm_hint", Command_HintSay, ADMFLAG_GENERIC);

    RegAdminCmd("sm_addcond",    Command_AddCondition, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removecond", Command_RemoveCondition, ADMFLAG_GENERIC);

    RegAdminCmd("sm_giveweapon",   Command_GiveWeapon, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removeweapon", Command_RemoveWeapon, ADMFLAG_GENERIC);
    RegAdminCmd("sm_stripweapons", Command_StripWeapons, ADMFLAG_GENERIC);

    // @everyone
    RegConsoleCmd("sm_fp", Command_FirstPerson);
    RegConsoleCmd("sm_firstperson", Command_FirstPerson);
    RegConsoleCmd("sm_tp", Command_ThirdPerson);
    RegConsoleCmd("sm_thirdperson", Command_ThirdPerson);
    RegConsoleCmd("sm_credits", Command_Credits);
}

public void OnAllPluginsLoaded()
{
    g_bTF2Attributes = TF2Attrib_IsReady();
}

// ConVars
void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
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
    if (g_ConVars[convert_vscript_vip].BoolValue)
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
    /* Target Filters */
    char teamName[32], targetFilter[64];
    int teamCount = GetTeamCount();
    for (int i = 0; i < teamCount; i++)
    {
        GetTeamName(i, teamName, sizeof(teamName));
        PrintToServer(PLUGIN_PREFIX_CONSOLE ... " Found team: '%s'", teamName);

        teamName[0] = CharToLower(teamName[0]);
        Format(targetFilter, sizeof(targetFilter), "@%s", teamName);
        AddMultiTargetFilter(targetFilter, TargetFilter_Team, teamName, false);
        PrintToServer(PLUGIN_PREFIX_CONSOLE ... " Added target filter: '%s'", targetFilter);
    }

    /* Items Schema */
    char path[PLATFORM_MAX_PATH] = "scripts/items/custom_items_game.txt";
    bool fileExists = FileExists(path);
    if (fileExists)
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

    // Search for materials, models, and sound directories
    if (!g_ConVars[auto_download].BoolValue)
        return;

    ArrayList dirs = new ArrayList(PLATFORM_MAX_PATH);
    char entry[PLATFORM_MAX_PATH];
    FileType fileType;
    char ext[16];
    char dir[PLATFORM_MAX_PATH];

    char searchDirs[3][32];
    strcopy(searchDirs[0], sizeof(searchDirs[]), "materials");
    strcopy(searchDirs[1], sizeof(searchDirs[]), "models");
    strcopy(searchDirs[2], sizeof(searchDirs[]), "sound");
    for (int i = 0; i < 3; i++)
    {
        DirectoryListing root = OpenDirectory(searchDirs[i]);
        if (root != null)
        {
            while (root.GetNext(entry, sizeof(entry), fileType))
            {
                if (StrEqual(entry, ".") || StrEqual(entry, ".."))
                    continue;

                Format(path, sizeof(path), "%s/%s", searchDirs[i], entry);
                if (fileType == FileType_Directory)
                {
                    dirs.PushString(path);
                }
                else if (FileExists(path))
                {
                    dirs.PushString(path);
                }
            }
            delete root;
        }
    }

    while (dirs.Length > 0)
    {
        dirs.GetString(dirs.Length - 1, dir, sizeof(dir));
        dirs.Erase(dirs.Length - 1);

        DirectoryListing listing = OpenDirectory(dir);
        if (listing == null)
        {
            continue;
        }

        while (listing.GetNext(entry, sizeof(entry), fileType))
        {
            if (StrEqual(entry, ".") || StrEqual(entry, ".."))
            {
                continue;
            }

            Format(path, sizeof(path), "%s/%s", dir, entry);

            if (fileType == FileType_Directory)
            {
                dirs.PushString(path);
                continue;
            }

            if (!FileExists(path))
            {
                continue;
            }

            AddFileToDownloadsTable(path);

            int maxlen = strlen(path);
            bool isModelFile, isDecalFile;

            isModelFile = StrEqual(path[maxlen - 4], ".mdl", false) ||
                          StrEqual(path[maxlen - 4], ".vcd", false) ||
                          StrEqual(path[maxlen - 4], ".vvd", false) ||
                          StrEqual(path[maxlen - 4], ".phy", false) ||
                          StrEqual(path[maxlen - 4], ".vtx", false) ||
                          StrEqual(path[maxlen - 7], ".sw.vtx", false) ||
                          StrEqual(path[maxlen - 9], ".dx80.vtx", false) ||
                          StrEqual(path[maxlen - 9], ".dx90.vtx", false);

            isDecalFile = StrEqual(path[maxlen - 4], ".vmt", false) ||
                          StrEqual(path[maxlen - 4], ".vtf", false);

            PrecacheGeneric(path);

            if (isModelFile)
            {
                PrecacheModel(path);
            }
            else if (isDecalFile)
            {
                PrecacheDecal(path);
            }
            else
            {
                ext[0] = '\0';
                int dotPos = FindCharInString(path, '.', true);
                if (dotPos != -1)
                {
                    strcopy(ext, sizeof(ext), path[dotPos + 1]);
                }

                if (StrEqual(ext, "wav", false) || StrEqual(ext, "mp3", false))
                {
                    PrecacheSound(path);
                }
            }
        }
        delete listing;
    }
    delete dirs;
}

// Events
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    TFPlayer player = TFPlayer(client);

    // Third-Person
    CreateTimer(0.1, Timer_Event_PlayerSpawn, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Event_PlayerSpawn(Handle timer, int client)
{
    TFPlayer player = TFPlayer(client);
    player.SetForcedTauntCam(g_ThirdPerson[client]);
    return Plugin_Stop;
}

// Clients
public void OnClientDisconnect(int client)
{
    g_ThirdPerson[client] = false;
}

/* Functions */
// Commands
public Action Command_SetTeam(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_setteam [target] <team>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char teamName[32];
    
    if (args == 1)
    {
        GetCmdArg(1, teamName, sizeof(teamName));
        GetCmdArgString(targetArg, sizeof(targetArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, teamName, sizeof(teamName));
    }

    // Find the team
    int teamIndex = FindTeamByName(teamName);
    if (teamIndex < 0)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Invalid team: {lightgreen}%s", teamName);
        return Plugin_Handled;
    }

    // Process target string
    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    GetTeamName(teamIndex, teamName, sizeof(teamName));

    TFPlayer target;
    if (targetCount > 1)
    {
        for (int i = 0; i < targetCount; i++)
        {
            target = TFPlayer(targets[i]);
            target.team = view_as<TFTeam>(teamIndex);
        }
        CReplyToCommand(client, PLUGIN_PREFIX ... " Changed \x04%d\x01 players to \x04%s", targetCount, teamName);
    }
    else
    {
        for (int i = 0; i < targetCount; i++)
        {
            target = TFPlayer(targets[i]);
            target.team = view_as<TFTeam>(teamIndex);
        }
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Changed \x03%N\x01 to \x04%s", target.index, teamName);
    }

    return Plugin_Handled;
}

public Action Command_AddAttribute(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_addattr [target] <attribute> [value] [duration]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];
    char valueArg[32] = "1.0";
    char durationArg[32] = "-1.0";

    switch (args)
    {
        case 2:
        {
            GetCmdArg(1, targetArg, sizeof(targetArg));
            GetCmdArg(2, attrName, sizeof(attrName));
        }
        case 3:
        {
            GetCmdArg(1, targetArg, sizeof(targetArg));
            GetCmdArg(2, attrName, sizeof(attrName));
            GetCmdArg(3, valueArg, sizeof(valueArg));
        }
        default:
        {
            GetCmdArg(1, targetArg, sizeof(targetArg));
            GetCmdArg(2, attrName, sizeof(attrName));
            GetCmdArg(3, valueArg, sizeof(valueArg));
            GetCmdArg(4, durationArg, sizeof(durationArg));
        }
    }

    float value = StringToFloat(valueArg);
    float duration = StringToFloat(durationArg);
    int attrDefIndex;
    bool useDefIndex = g_bTF2Attributes && StringToIntEx(attrName, attrDefIndex) > 0;

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        if (g_bTF2Attributes)
        {
            if (useDefIndex)
            {
                TF2Attrib_SetByDefIndex(target.index, attrDefIndex, value);
            }
            else
            {
                TF2Attrib_AddCustomPlayerAttribute(target.index, attrName, value, duration);
            }
        }
        else
        {
            target.AddAttribute(attrName, value, duration);
        }
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Applied \x05%s\x01 to \x04%d\x01 players", attrName, targetCount);
    }
    else
    {
        target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Applied \x05%s\x01 to \x03%N", attrName, target.index);
    }

    return Plugin_Handled;
}

public Action Command_RemoveAttribute(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_removeattr [target] <attribute>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];

    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, attrName, sizeof(attrName));

    int attrDefIndex;
    bool useDefIndex = g_bTF2Attributes && StringToIntEx(attrName, attrDefIndex) > 0;

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFPlayer(targets[i]);
        if (g_bTF2Attributes)
        {
            if (useDefIndex)
            {
                TF2Attrib_RemoveByDefIndex(target.index, attrDefIndex);
            }
            else
            {
                TF2Attrib_RemoveCustomPlayerAttribute(target.index, attrName);
            }
        }
        else
        {
            target.RemoveAttribute(attrName);
        }
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Removed \x05%s\x01 from \x04%d\x01 players", attrName, targetCount);
    }
    else
    {
            target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Removed \x05%s\x01 from \x03%N", attrName, target.index);
    }

    return Plugin_Handled;
}

public Action Command_GetAttribute(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_getattr [target] <attribute>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];

    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, attrName, sizeof(attrName));

    int attrDefIndex;
    bool useDefIndex = g_bTF2Attributes && StringToIntEx(attrName, attrDefIndex) > 0;

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFPlayer(targets[i]);
        float value;
        if (g_bTF2Attributes)
        {
            Address attr;
            if (useDefIndex)
            {
                attr = TF2Attrib_GetByDefIndex(target.index, attrDefIndex);
            }
            else
            {
                attr = TF2Attrib_GetByName(target.index, attrName);
            }
            if (attr != Address_Null)
            {
                value = TF2Attrib_GetValue(attr);
            }
            else
            {
                value = target.GetAttribute(attrName);
            }
        }
        else
        {
            value = target.GetAttribute(attrName);
        }
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Attribute \x05%s\x01 for \x03%N: \x04%.3f", attrName, target.index, value);
    }

    return Plugin_Handled;
}

public Action Command_AddCondition(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_addcond [target] <condition> [duration]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char condArg[16];
    char durationArg[32] = "-1.0";

    switch (args)
    {
        case 1:
        {
            GetCmdArg(1, condArg, sizeof(condArg));
            strcopy(targetArg, sizeof(targetArg), "@me");
        }
        case 2:
        {
            GetCmdArg(1, targetArg, sizeof(targetArg));
            GetCmdArg(2, condArg, sizeof(condArg));
        }
        default:
        {
            GetCmdArg(1, targetArg, sizeof(targetArg));
            GetCmdArg(2, condArg, sizeof(condArg));
            GetCmdArg(3, durationArg, sizeof(durationArg));
        }
    }

    int condition = StringToInt(condArg);
    float duration = StringToFloat(durationArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        target.AddCond(view_as<TFCond>(condition), duration);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Added condition \x05%d\x01 to \x04%d\x01 players", condition, targetCount);
    }
    else
    {
            target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Added condition \x05%d\x01 to \x03%N", condition, target.index);
    }

    return Plugin_Handled;
}

public Action Command_RemoveCondition(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_removecond [target] <condition>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char condArg[16];

    if (args == 1)
    {
        GetCmdArg(1, condArg, sizeof(condArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, condArg, sizeof(condArg));
    }

    int condition = StringToInt(condArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFPlayer(targets[i]);
        target.RemoveCond(view_as<TFCond>(condition));
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Removed condition \x05%d\x01 from \x04%d\x01 players", condition, targetCount);
    }
    else
    {
        target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Removed condition \x05%d\x01 from \x03%N", condition, target.index);
    }

    return Plugin_Handled;
}

public Action Command_Currency(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_currency [target] <amount>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char valueArg[16];

    if (args == 1)
    {
        GetCmdArg(1, valueArg, sizeof(valueArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, valueArg, sizeof(valueArg));
    }

    int value = StringToInt(valueArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
            target = TFPlayer(targets[i]);
        target.currency = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set currency to \x05%d\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
            target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set currency to \x05%d\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_Scale(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_scale [target] <amount>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char valueArg[16];

    if (args == 1)
    {
        GetCmdArg(1, valueArg, sizeof(valueArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, valueArg, sizeof(valueArg));
    }

    float value = StringToFloat(valueArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
            target = TFPlayer(targets[i]);
        target.scale = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set scale to \x05%.2f\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
            target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set scale to \x05%.2f\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_Health(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_health [target] <amount>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char valueArg[16];

    if (args == 1)
    {
        GetCmdArg(1, valueArg, sizeof(valueArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, valueArg, sizeof(valueArg));
    }

    int value = StringToInt(valueArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
            target = TFPlayer(targets[i]);
        target.health = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set health to \x05%d\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
            target = TFPlayer(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set health to \x05%d\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_MaxHealth(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_maxhealth [target] <amount>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char valueArg[16];

    if (args == 1)
    {
        GetCmdArg(1, valueArg, sizeof(valueArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, valueArg, sizeof(valueArg));
    }

    int value = StringToInt(valueArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        target.max_health = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set max health to \x05%d\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
        target = view_as<TFPlayer>(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set max health to \x05%d\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_SetClass(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_setclass [target] <class>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char className[32];

    if (args == 1)
    {
        GetCmdArg(1, className, sizeof(className));
        GetCmdArgString(targetArg, sizeof(targetArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, className, sizeof(className));
    }

    TFClassType classType = TFClass_Unknown;
    int classId;
    if (StringToIntEx(className, classId) > 0)
    {
        classType = view_as<TFClassType>(classId);
    }
    else if (StrContains(className, "sc", false) == 0)
    {
        classType = TFClass_Scout;
    }
    else if (StrContains(className, "sn", false) == 0)
    {
        classType = TFClass_Sniper;
    }
    else if (StrContains(className, "so", false) == 0)
    {
        classType = TFClass_Soldier;
    }
    else if (StrContains(className, "d", false) == 0)
    {
        classType = TFClass_DemoMan;
    }
    else if (StrContains(className, "m", false) == 0)
    {
        classType = TFClass_Medic;
    }
    else if (StrContains(className, "h", false) == 0)
    {
        classType = TFClass_Heavy;
    }
    else if (StrContains(className, "p", false) == 0)
    {
        classType = TFClass_Pyro;
    }
    else if (StrContains(className, "sp", false) == 0)
    {
        classType = TFClass_Spy;
    }
    else if (StrContains(className, "e", false) == 0)
    {
        classType = TFClass_Engineer;
    }
    else if (StrContains(className, "c", false) == 0)
    {
        classType = TFClass_Civilian;
    }

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    char classDisplayName[32] = "Undefined";
    Regex classNameRegex = new Regex("models/player/([^/]+)\\.mdl", PCRE_CASELESS);
    bool hasClassDisplayName;

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        float origin[3];
        GetClientAbsOrigin(target.index, origin);

        target.class = classType;
        target.ForceRespawn();
        TeleportEntity(target.index, origin);

        if (!hasClassDisplayName && classNameRegex != null)
        {
            char modelPath[PLATFORM_MAX_PATH];
            GetClientModel(target.index, modelPath, sizeof(modelPath));

            if (classNameRegex.Match(modelPath) >= 2 && classNameRegex.GetSubString(1, classDisplayName, sizeof(classDisplayName)))
            {
                classDisplayName[0] = CharToUpper(classDisplayName[0]);
                hasClassDisplayName = true;
            }
        }
    }
    delete classNameRegex;

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Changed \x04%d\x01 players into \x05%s", targetCount, classDisplayName);
    }
    else
    {
        target = view_as<TFPlayer>(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Changed \x03%N\x01 into \x05%s", target.index, classDisplayName);
    }

    return Plugin_Handled;
}

public Action Command_FireInput(int client, int args)
{
    if (args < 3)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_fireinput <target> <input> <value>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char entityInput[64];
    char entityValue[64];

    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, entityInput, sizeof(entityInput));
    GetCmdArg(3, entityValue, sizeof(entityValue));

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        int intValue;
        if (entityValue[0] != '\0' && StringToIntEx(entityValue, intValue) > 0)
        {
            SetVariantInt(intValue);
        }
        else
        {
            SetVariantString(entityValue);
        }
        AcceptEntityInput(target.index, entityInput);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Fired \x05%s\x01 on \x04%d\x01 players", entityInput, targetCount);
    }
    else
    {
        target = view_as<TFPlayer>(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Fired \x05%s\x01 on \x03%N", entityInput, target.index);
    }

    return Plugin_Handled;
}

public Action Command_Respawn(int client, int args)
{
    char targetArg[64];
    if (args == 0)
    {
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
    }

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        target.ForceRespawn();
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Respawned \x04%d\x01 players", targetCount);
    }
    else
    {
        target = view_as<TFPlayer>(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Respawned \x03%N", target.index);
    }

    return Plugin_Handled;
}

public Action Command_FirstPerson(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;
        
    g_ThirdPerson[client] = false;
    TFPlayer player = TFPlayer(client);
    player.SetForcedTauntCam(false);
    
    CReplyToCommand(client, PLUGIN_PREFIX ... " Set view to \x04First-Person");
    return Plugin_Handled;
}

public Action Command_ThirdPerson(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;
        
    g_ThirdPerson[client] = true;
    TFPlayer player = TFPlayer(client);
    player.SetForcedTauntCam(true);
    
    CReplyToCommand(client, PLUGIN_PREFIX ... " Set view to \x04Third-Person");
    return Plugin_Handled;
}

public Action Command_Credits(int client, int args)
{
    if (!client || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    ShowCreditsMenu(client);
    return Plugin_Handled;
}

void ShowCreditsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Credits);
    menu.SetTitle("Credits");

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.cfg");

    KeyValues kv = new KeyValues("Credits");
    if (!kv.ImportFromFile(path))
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits config.");
        delete kv;
        delete menu;
        return;
    }

    if (!kv.GotoFirstSubKey())
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " No credits entries were found.");
        delete kv;
        delete menu;
        return;
    }

    do
    {
        char contributor[256];
        kv.GetSectionName(contributor, sizeof(contributor));
        menu.AddItem(contributor, contributor);
    }
    while (kv.GotoNextKey());

    delete kv;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowCreditsContributorMenu(int client, const char[] contributor)
{
    Menu menu = new Menu(MenuHandler_CreditsContributor);
    menu.SetTitle("Credits | %s", contributor);
    menu.ExitBackButton = true;

    strcopy(g_CreditsSelection[client], sizeof(g_CreditsSelection[]), contributor);

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.cfg");

    KeyValues kv = new KeyValues("Credits");
    if (!kv.ImportFromFile(path) || !kv.JumpToKey(contributor, false))
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits entry for \x05%s\x01.", contributor);
        delete kv;
        delete menu;
        return;
    }

    char steamId[32];
    kv.GetString("steam", steamId, sizeof(steamId));

    if (steamId[0] != '\0')
    {
        menu.AddItem("steam", "Steam Profile");
    }
    menu.AddItem("contributions", "Contributions");

    delete kv;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowCreditsContributionsMenu(int client)
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.cfg");

    KeyValues kv = new KeyValues("Credits");
    if (!kv.ImportFromFile(path) || !kv.JumpToKey(g_CreditsSelection[client], false))
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits entry for \x05%s\x01.", g_CreditsSelection[client]);
        delete kv;
        return;
    }

    Menu menu = new Menu(MenuHandler_CreditsContributions);
    menu.SetTitle("Contributions | %s", g_CreditsSelection[client]);
    menu.ExitBackButton = true;

    if (kv.JumpToKey("contributions") && kv.GotoFirstSubKey())
    {
        do
        {
            char contributionId[16];
            kv.GetSectionName(contributionId, sizeof(contributionId));

            char contributionName[128];
            kv.GetString("name", contributionName, sizeof(contributionName), "Unnamed contribution");

            char contributionUrl[256];
            kv.GetString("url", contributionUrl, sizeof(contributionUrl));

            char itemInfo[32];
            Format(itemInfo, sizeof(itemInfo), "contrib:%s", contributionId);

            if (contributionUrl[0] != '\0')
            {
                menu.AddItem(itemInfo, contributionName);
            }
            else
            {
                char noUrlDisplay[160];
                Format(noUrlDisplay, sizeof(noUrlDisplay), "%s (no link)", contributionName);
                menu.AddItem(itemInfo, noUrlDisplay, ITEMDRAW_DISABLED);
            }
        }
        while (kv.GotoNextKey());
    }
    else
    {
        menu.AddItem("", "No contributions found", ITEMDRAW_DISABLED);
    }

    delete kv;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Credits(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        int client = param1;
        char contributor[64];
        menu.GetItem(param2, contributor, sizeof(contributor));
        ShowCreditsContributorMenu(client, contributor);
    }
    return 0;
}

public int MenuHandler_CreditsContributor(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowCreditsMenu(param1);
    }
    else if (action == MenuAction_Select)
    {
        int client = param1;
        char itemInfo[32];
        menu.GetItem(param2, itemInfo, sizeof(itemInfo));

        if (StrEqual(itemInfo, "contributions"))
        {
            ShowCreditsContributionsMenu(client);
            return 0;
        }

        if (!StrEqual(itemInfo, "steam"))
        {
            return 0;
        }

        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.cfg");

        KeyValues kv = new KeyValues("Credits");
        if (!kv.ImportFromFile(path) || !kv.JumpToKey(g_CreditsSelection[client], false))
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits entry for \x05%s\x01.", g_CreditsSelection[client]);
            delete kv;
            return 0;
        }

        char url[256] = "";
        char steamId[32];
        kv.GetString("steam", steamId, sizeof(steamId));
        if (steamId[0] != '\0')
        {
            Format(url, sizeof(url), "https://steamcommunity.com/profiles/%s", steamId);
        }

        delete kv;

        if (url[0] == '\0')
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " No URL is set for that credits entry.");
            return 0;
        }

        CPrintToChat(client, "\x03%s", url);
    }
    return 0;
}

public int MenuHandler_CreditsContributions(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowCreditsContributorMenu(param1, g_CreditsSelection[param1]);
    }
    else if (action == MenuAction_Select)
    {
        int client = param1;
        char itemInfo[32];
        menu.GetItem(param2, itemInfo, sizeof(itemInfo));

        if (StrContains(itemInfo, "contrib:", false) != 0)
        {
            return 0;
        }

        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.cfg");

        KeyValues kv = new KeyValues("Credits");
        if (!kv.ImportFromFile(path) || !kv.JumpToKey(g_CreditsSelection[client], false))
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits entry for \x05%s\x01.", g_CreditsSelection[client]);
            delete kv;
            return 0;
        }

        char url[256] = "";
        if (kv.JumpToKey("contributions"))
        {
            char contributionId[16];
            strcopy(contributionId, sizeof(contributionId), itemInfo[8]);
            if (kv.JumpToKey(contributionId, false))
            {
                kv.GetString("url", url, sizeof(url));
            }
        }

        delete kv;

        if (url[0] == '\0')
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " No URL is set for that contribution.");
            return 0;
        }

        CPrintToChat(client, "\x03%s", url);
    }
    return 0;
}

public Action Command_HintSay(int client, int args)
{
    if (args < 3)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_hint <target> <message> <duration> [icon]");
        return Plugin_Handled;
    }

    char targetArg[64];
    GetCmdArg(1, targetArg, sizeof(targetArg));

    char message[256];
    GetCmdArg(2, message, sizeof(message));
    
    if (message[0] == '\0')
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_hint <target> <message> <duration> [icon]");
        return Plugin_Handled;
    }

    char durationArg[32];
    GetCmdArg(3, durationArg, sizeof(durationArg));
    int duration = StringToInt(durationArg);
    if (duration <= 0)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_hint <target> <message> <duration> [icon]");
        return Plugin_Handled;
    }

    char icon[64];
    if (args >= 4)
    {
        GetCmdArg(4, icon, sizeof(icon));
    }

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        TFPlayer target = TFPlayer(targets[i]);
        if (!IsClientInGame(target.index))
        {
            continue;
        }

        Event event = CreateEvent("instructor_server_hint_create", true);
        if (event == null)
        {
            continue;
        }

        char hintName[64];
        Format(hintName, sizeof(hintName), "sm_hint_%N", target);
        event.SetString("hint_name", hintName);
        event.SetString("hint_replace_key", "sm_hint");
        event.SetInt("hint_activator_userid", GetClientUserId(target));
        event.SetInt("hint_timeout", duration);
        event.SetString("hint_activator_caption", message);
        if (icon[0] != '\0')
        {
            event.SetString("hint_icon_onscreen", icon);
            event.SetString("hint_icon_offscreen", icon);
        }
        event.SetBool("hint_local_player_only", true);
        event.FireToClient(target);
    }
    return Plugin_Handled;
}

public Action Command_GiveWeapon(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_give [target] <itemdefindex> [classname]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char indexArg[16];
    char classArg[64] = "";

    if (args == 1)
    {
        GetCmdArg(1, indexArg, sizeof(indexArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else if (args == 2)
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, indexArg, sizeof(indexArg));
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, indexArg, sizeof(indexArg));
        GetCmdArg(3, classArg, sizeof(classArg));
    }

    int itemIndex = StringToInt(indexArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    int given = 0;
    for (int i = 0; i < targetCount; i++)
    {
        if (!IsClientInGame(targets[i]) || !IsPlayerAlive(targets[i]))
            continue;

        TFPlayer player = TFPlayer(targets[i]);
        if (player.GiveWeapon(itemIndex, classArg))
            given++;
    }

    switch (given)
    {
        case 0:  CReplyToCommand(client, PLUGIN_PREFIX ... " Failed to give weapon to target.");
        case 1:  CReplyToCommandEx(client, targets[0], PLUGIN_PREFIX ... " Gave weapon \x05%d\x01 to \x03%N", itemIndex, targets[0]);
        default: CReplyToCommand(client, PLUGIN_PREFIX ... " Gave weapon \x05%d\x01 to \x04%d\x01 players", itemIndex, given);
    }

    return Plugin_Handled;
}

public Action Command_RemoveWeapon(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_removeweapon [target] [slot]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char slotArg[16];

    if (args == 1)
    {
        GetCmdArg(1, slotArg, sizeof(slotArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, slotArg, sizeof(slotArg));
    }

    int slot = StringToInt(slotArg);
    if (slot < TFWeaponSlot_Primary || slot > TFWeaponSlot_Item2)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Invalid weapon slot specified.");
        return Plugin_Handled;
    }

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    int removed = 0;
    for (int i = 0; i < targetCount; i++)
    {
        if (!IsClientInGame(targets[i]) || !IsPlayerAlive(targets[i]))
            continue;
        TFPlayer player = TFPlayer(targets[i]);
        int weapon = player.GetWeapon(slot);
        if (weapon != -1 && IsValidEntity(weapon))
        {
            player.RemoveWeapon(slot);
            removed++;
        }
    }

    switch (removed)
    {
        case 0:
            CReplyToCommand(client, PLUGIN_PREFIX ... " Failed to remove weapons.");
        case 1:
            CReplyToCommandEx(client, targets[0], PLUGIN_PREFIX ... " Removed weapon in slot \x05%d\x01 from \x03%N", slot, targets[0]);
        default:
            CReplyToCommand(client, PLUGIN_PREFIX ... " Removed weapon in slot \x05%d\x01 from \x04%d\x01 players", slot, removed);
    }
    
    return Plugin_Handled;
}

public Action Command_StripWeapons(int client, int args)
{
    char targetArg[64];
    if (args == 0)
    {
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
    }

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;
    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    int stripped = 0;
    for (int i = 0; i < targetCount; i++)
    {
        if (!IsClientInGame(targets[i]) || !IsPlayerAlive(targets[i]))
            continue;
        TFPlayer player = TFPlayer(targets[i]);
        player.RemoveAllWeapons();
        stripped++;
    }

    switch (stripped)
    {
        case 0:
            CReplyToCommand(client, PLUGIN_PREFIX ... " Failed to strip weapons.");
        case 1:
            CReplyToCommandEx(client, targets[0], PLUGIN_PREFIX ... " Stripped weapons from \x03%N", targets[0]);
        default:
            CReplyToCommand(client, PLUGIN_PREFIX ... " Stripped weapons from \x04%d\x01 players", stripped);
    }
    
    return Plugin_Handled;
}

public Action Command_SetCollisionGroup(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_setcollision [target] <collisiongroup>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char groupArg[16];

    if (args == 1)
    {
        GetCmdArg(1, groupArg, sizeof(groupArg));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, groupArg, sizeof(groupArg));
    }

    int group = StringToInt(groupArg);

    int targets[MAXPLAYERS];
    int targetCount;
    char targetName[MAX_TARGET_LENGTH];
    bool tn_is_ml;

    targetCount = ProcessTargetString(targetArg, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);

    if (targetCount <= 0)
    {
        ReplyToTargetError(client, targetCount);
        return Plugin_Handled;
    }

    for (int i = 0; i < targetCount; i++)
    {
        SetEntProp(targets[i], Prop_Data, "m_CollisionGroup", group);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set collision group to \x05%d\x01 for \x04%d\x01 players", group, targetCount);
    }
    else
    {
        CReplyToCommandEx(client, targets[0], PLUGIN_PREFIX ... " Set collision group to \x05%d\x01 for \x03%N", group, targets[0]);
    }

    return Plugin_Handled;
}

// Target Filters
public bool TargetFilter_Team(const char[] pattern, ArrayList clients, int client)
{
    bool negate = (pattern[1] == '!');
    int offset = negate ? 2 : 1;

    char teamPattern[32];
    strcopy(teamPattern, sizeof(teamPattern), pattern[offset]);

    int teamIndex = FindTeamByName(teamPattern);

    char teamName[32];
    GetTeamName(teamIndex, teamName, sizeof(teamName));

    if (!StrEqual(teamPattern, teamName, false))
    {
        return true;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        bool isTeam = (GetClientTeam(i) == teamIndex);
        if ((negate && !isTeam) || (!negate && isTeam))
        {
            clients.Push(i);
        }
    }
    return true;
}

public bool TargetFilter_Civilians(const char[] pattern, ArrayList clients, int client)
{
    TFPlayer target;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        target = TFPlayer(i);
        if (target.class == TFClass_Civilian)
        {
            clients.Push(i);
        }
    }
    return true;
}