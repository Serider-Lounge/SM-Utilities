#include <sourcemod>
#include <sdktools>
#include <multicolors>

#undef REQUIRE_EXTENSIONS
#include <heapons/tf2>
#define REQUIRE_EXTENSIONS

#define PLUGIN_PREFIX "{#4C4C4C}[{#F69E1D}S{#5596CF}M{#4C4C4C} {#F8FBFF}Utilities\x01]\x01"

bool g_ThirdPerson[MAXPLAYERS + 1];

public Plugin myinfo = 
{
    name = "SM Utilities | TF2 Classified Tools",
    author = "Heapons",
    description = "Tools and utilities for Team Fortress 2 Classified",
    version = "26w06a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public void OnPluginStart()
{
    /* Events */
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    /* Commands */
    // @admins
    RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC);
    RegAdminCmd("sm_team",    Command_SetTeam, ADMFLAG_GENERIC);

    RegAdminCmd("sm_setclass", Command_SetClass, ADMFLAG_GENERIC);
    RegAdminCmd("sm_class",    Command_SetClass, ADMFLAG_GENERIC);

    RegAdminCmd("sm_fireinput", Command_FireInput, ADMFLAG_GENERIC);

    RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_GENERIC);

    RegAdminCmd("sm_health", Command_Health, ADMFLAG_GENERIC);
    RegAdminCmd("sm_maxhealth", Command_MaxHealth, ADMFLAG_GENERIC);
    RegAdminCmd("sm_currency", Command_Currency, ADMFLAG_GENERIC);
    RegAdminCmd("sm_scale", Command_Scale, ADMFLAG_GENERIC);

    RegAdminCmd("sm_addattr", Command_AddAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_addattribute", Command_AddAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removeattr", Command_RemoveAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_removeattribute", Command_RemoveAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_getattr", Command_GetAttribute, ADMFLAG_GENERIC);
    RegAdminCmd("sm_getattribute", Command_GetAttribute, ADMFLAG_GENERIC);

    RegAdminCmd("sm_hint", Command_HintSay, ADMFLAG_GENERIC);

    // @everyone
    RegConsoleCmd("sm_fp", Command_FirstPerson);
    RegConsoleCmd("sm_firstperson", Command_FirstPerson);
    RegConsoleCmd("sm_tp", Command_ThirdPerson);
    RegConsoleCmd("sm_thirdperson", Command_ThirdPerson);

    /* Target Filters */
    AddMultiTargetFilter("@red",    TargetFilter_RedTeam,    "Red",    false);
    AddMultiTargetFilter("@blue",   TargetFilter_BlueTeam,   "Blue",   false);
    AddMultiTargetFilter("@green",  TargetFilter_GreenTeam,  "Green",  false);
    AddMultiTargetFilter("@yellow", TargetFilter_YellowTeam, "Yellow", false);
    AddMultiTargetFilter("@vips",   TargetFilter_Civilians,  "Civilians", true);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    TFEntity player = TFEntity(client);

    // Third-Person
    player.SetForcedTauntCam(g_ThirdPerson[client]);
    CreateTimer(0.1, Timer_Event_PlayerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Event_PlayerSpawn(Handle timer, int client)
{
    TFEntity player = TFEntity(client);
    player.SetForcedTauntCam(g_ThirdPerson[client]);
    return Plugin_Stop;
}

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
        ReplyToCommand(client, "Usage: sm_setteam [target] <team>");
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
    if (StrEqual(teamName, "Red"))
    {
        teamName = "\x07FF4040RED\x01";
    }
    else if (StrEqual(teamName, "Blue"))
    {
        teamName = "\x0799CCFFBLU\x01";
    }
    else if (StrEqual(teamName, "Green"))
    {
        teamName = "\x0799FF99GRN\x01";
    }
    else if (StrEqual(teamName, "Yellow"))
    {
        teamName = "\x07FFB200YLW\x01";
    }
    else
    {
        Format(teamName, sizeof(teamName), "\x07CCCCCC%s\x01", teamName);
    }

    TFEntity target;
    if (targetCount > 1)
    {
        for (int i = 0; i < targetCount; i++)
        {
            target = TFEntity(targets[i]);
            target.team = view_as<TFTeam>(teamIndex);
        }
        CReplyToCommand(client, PLUGIN_PREFIX ... " Changed \x04%d\x01 players to %s", targetCount, teamName);
    }
    else
    {
        for (int i = 0; i < targetCount; i++)
        {
            target = TFEntity(targets[i]);
            target.team = view_as<TFTeam>(teamIndex);
        }
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Changed \x03%N\x01 to %s", target.index, teamName);
    }

    return Plugin_Handled;
}

public Action Command_AddAttribute(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_addattr [target] <attribute> [value] [duration]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];
    char valueArg[32] = "1.0";
    char durationArg[32] = "-1.0";

    switch (args)
    {
        case 1:
        {
            GetCmdArg(1, attrName, sizeof(attrName));
            strcopy(targetArg, sizeof(targetArg), "@me");
        }
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.AddAttribute(attrName, value, duration);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Applied \x05%s\x01 to \x04%d\x01 players", attrName, targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Applied \x05%s\x01 to \x03%N", attrName, target.index);
    }

    return Plugin_Handled;
}

public Action Command_RemoveAttribute(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_removeattr [target] <attribute>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];

    if (args == 1)
    {
        GetCmdArg(1, attrName, sizeof(attrName));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, attrName, sizeof(attrName));
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.RemoveAttribute(attrName);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Removed \x05%s\x01 from \x04%d\x01 players", attrName, targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Removed \x05%s\x01 from \x03%N", attrName, target.index);
    }

    return Plugin_Handled;
}

public Action Command_GetAttribute(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_getattr [target] <attribute>");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];

    if (args == 1)
    {
        GetCmdArg(1, attrName, sizeof(attrName));
        strcopy(targetArg, sizeof(targetArg), "@me");
    }
    else
    {
        GetCmdArg(1, targetArg, sizeof(targetArg));
        GetCmdArg(2, attrName, sizeof(attrName));
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        float value = target.GetAttribute(attrName);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Attribute \x05%s\x01 for \x03%N: \x04%.3f", attrName, target.index, value);
    }

    return Plugin_Handled;
}

public Action Command_Currency(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_currency [target] <amount>");
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.currency = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set currency to \x05%d\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set currency to \x05%d\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_Scale(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_scale [target] <amount>");
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.scale = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set scale to \x05%.2f\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set scale to \x05%.2f\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_Health(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_health [target] <amount>");
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.health = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set health to \x05%d\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set health to \x05%d\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_MaxHealth(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_maxhealth [target] <amount>");
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.max_health = value;
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Set max health to \x05%d\x01 for \x04%d\x01 players", value, targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Set max health to \x05%d\x01 for \x03%N", value, target.index);
    }

    return Plugin_Handled;
}

public Action Command_SetClass(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_setclass [target] <class>");
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

    TFClassType classType;
    if (StrContains(className, "sc", false) == 0)
    {
        classType = TFClass_Scout;
        className = "Scout";
    }
    else if (StrContains(className, "sn", false) == 0)
    {
        classType = TFClass_Sniper;
        className = "Sniper";
    }
    else if (StrContains(className, "so", false) == 0)
    {
        classType = TFClass_Soldier;
        className = "Soldier";
    }
    else if (StrContains(className, "d", false) == 0)
    {
        classType = TFClass_DemoMan;
        className = "Demoman";
    }
    else if (StrContains(className, "m", false) == 0)
    {
        classType = TFClass_Medic;
        className = "Medic";
    }
    else if (StrContains(className, "h", false) == 0)
    {
        classType = TFClass_Heavy;
        className = "Heavy";
    }
    else if (StrContains(className, "p", false) == 0)
    {
        classType = TFClass_Pyro;
        className = "Pyro";
    }
    else if (StrContains(className, "sp", false) == 0)
    {
        classType = TFClass_Spy;
        className = "Spy";
    }
    else if (StrContains(className, "e", false) == 0)
    {
        classType = TFClass_Engineer;
        className = "Engineer";
    }
    else if (StrContains(className, "c", false) == 0)
    {
        classType = TFClass_Civilian;
        className = "Civilian";
    }
    else
    {
        classType = TFClass_Unknown;
        className = "Undefined";
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

    TFEntity target;
    if (targetCount > 1)
    {
        for (int i = 0; i < targetCount; i++)
        {
            target = TFEntity(targets[i]);
            target.class = classType;
        }
        CReplyToCommand(client, PLUGIN_PREFIX ... " Changed \x04%d\x01 players into \x05%s", targetCount, className);
    }
    else
    {
        for (int i = 0; i < targetCount; i++)
        {
            target = TFEntity(targets[i]);
            target.class = classType;
            CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Changed \x03%N\x01 into \x05%s", target.index, className);
        }
    }

    target.ForceRespawn();

    float origin[3];
    GetClientAbsOrigin(target.index, origin);
    TeleportEntity(target.index, origin);

    return Plugin_Handled;
}

public Action Command_FireInput(int client, int args)
{
    if (args < 3)
    {
        ReplyToCommand(client, "Usage: sm_fireinput <target> <input> <value>");
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
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
        target = TFEntity(targets[0]);
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

    TFEntity target;
    for (int i = 0; i < targetCount; i++)
    {
        target = TFEntity(targets[i]);
        target.ForceRespawn();
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Respawned \x04%d\x01 players", targetCount);
    }
    else
    {
        target = TFEntity(targets[0]);
        CReplyToCommandEx(client, target.index, PLUGIN_PREFIX ... " Respawned \x03%N", target.index);
    }

    return Plugin_Handled;
}

public Action Command_FirstPerson(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;
        
    g_ThirdPerson[client] = false;
    TFEntity player = TFEntity(client);
    player.SetForcedTauntCam(false);
    
    CReplyToCommand(client, PLUGIN_PREFIX ... " Set view to \x04First-Person");
    return Plugin_Handled;
}

public Action Command_ThirdPerson(int client, int args)
{
    if (!client || !IsClientInGame(client))
        return Plugin_Handled;
        
    g_ThirdPerson[client] = true;
    TFEntity player = TFEntity(client);
    player.SetForcedTauntCam(true);
    
    CReplyToCommand(client, PLUGIN_PREFIX ... " Set view to \x04Third-Person");
    return Plugin_Handled;
}

public Action Command_HintSay(int client, int args)
{
    if (args < 3)
    {
        ReplyToCommand(client, "Usage: sm_hint <target> <message> <duration> [icon]");
        return Plugin_Handled;
    }

    char targetArg[64];
    GetCmdArg(1, targetArg, sizeof(targetArg));

    char message[256];
    GetCmdArg(2, message, sizeof(message));
    
    if (message[0] == '\0')
    {
        ReplyToCommand(client, "Usage: sm_hint <target> <message> <duration> [icon]");
        return Plugin_Handled;
    }

    char durationArg[32];
    GetCmdArg(3, durationArg, sizeof(durationArg));
    float duration = StringToFloat(durationArg);
    
    if (duration <= 0.0)
    {
        ReplyToCommand(client, "Usage: sm_hint <target> <message> <duration> [icon]");
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
        int hint = CreateEntityByName("env_instructor_hint");
        if (hint == -1)
        {
            ReplyToCommand(client, "Failed to create instructor hint.");
            continue;
        }

        char playerIndex[16];
        IntToString(targets[i], playerIndex, sizeof(playerIndex));

        DispatchKeyValue(hint, "hint_replace_key", "sm_hint");
        DispatchKeyValue(hint, "hint_caption", message);
        DispatchKeyValue(hint, "hint_icon_onscreen", icon);
        DispatchKeyValue(hint, "hint_icon_offscreen", icon);
        DispatchKeyValue(hint, "hint_static", "1");
        DispatchKeyValue(hint, "hint_target", playerIndex);
        char durationValue[32];
        FloatToString(duration, durationValue, sizeof(durationValue));
        DispatchKeyValue(hint, "hint_timeout", durationValue);
        DispatchSpawn(hint);
        AcceptEntityInput(hint, "ShowHint", targets[i], targets[i]);

        DataPack dp = new DataPack();
        dp.WriteCell(EntIndexToEntRef(hint));
        CreateTimer(duration, Timer_KillInstructorHint, dp, TIMER_FLAG_NO_MAPCHANGE);
    }

    return Plugin_Handled;
}

public Action Timer_KillInstructorHint(Handle timer, DataPack dp)
{
    dp.Reset();
    int hint = EntRefToEntIndex(dp.ReadCell());
    delete dp;

    if (hint != -1)
    {
        AcceptEntityInput(hint, "Kill");
    }

    return Plugin_Stop;
}

// Target Filters
public bool TargetFilter_RedTeam(const char[] pattern, ArrayList clients, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Red)
        {
            clients.Push(i);
        }
    }
    return true;
}

public bool TargetFilter_BlueTeam(const char[] pattern, ArrayList clients, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
        {
            clients.Push(i);
        }
    }
    return true;
}

public bool TargetFilter_GreenTeam(const char[] pattern, ArrayList clients, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Green)
        {
            clients.Push(i);
        }
    }
    return true;
}

public bool TargetFilter_YellowTeam(const char[] pattern, ArrayList clients, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Yellow)
        {
            clients.Push(i);
        }
    }
    return true;
}

public bool TargetFilter_Civilians(const char[] pattern, ArrayList clients, int client)
{
    int entity = FindEntityByClassname(-1, "tf2c_logic_vip");
	if (entity != -1)
	{
		return false;
	}

    TFEntity target;
    for (int i = 1; i <= MaxClients; i++)
    {
        target = TFEntity(i);
        if (IsClientInGame(i) && target.class == TFClass_Civilian)
        {
            clients.Push(i);
        }
    }
    return true;
}