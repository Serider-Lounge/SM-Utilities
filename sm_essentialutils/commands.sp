// Shared
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

public Action Command_Credits(int client, int args)
{
    if (!client || !IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    ShowCreditsMenu(client);
    return Plugin_Handled;
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

// Team Fortress 2
public Action Command_AddAttribute(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_addattr <target> <attribute> [value] [duration] [slot]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];
    char valueArg[32] = "1.0";
    char durationArg[32] = "-1.0";
    char slotArg[16];

    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, attrName, sizeof(attrName));
    if (args >= 3)
        GetCmdArg(3, valueArg, sizeof(valueArg));
    if (args >= 4)
        GetCmdArg(4, durationArg, sizeof(durationArg));
    if (args >= 5)
        GetCmdArg(5, slotArg, sizeof(slotArg));

    float value = StringToFloat(valueArg);
    float duration = StringToFloat(durationArg);

    int slot = -1;
    bool hasSlot = false;
    if (slotArg[0] != '\0')
    {
        slot = StringToInt(slotArg);
        hasSlot = true;
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

    if (StrContains(valueArg, "models/", false) == 0)
    {
        PrecacheModel(valueArg, true);
    }

    TFPlayer target;
    for (int i = 0; i < targetCount; i++)
    {
        target = view_as<TFPlayer>(targets[i]);
        if (hasSlot)
        {
            target.GetWeaponBySlot(slot);
        }

        target.AddAttribute(attrName, value, duration);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Applied \x05%s\x01 to \x04%d\x01 targets", attrName, targetCount);
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
    if (args < 2)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_removeattr <target> <attribute> [slot]");
        return Plugin_Handled;
    }

    char targetArg[64];
    char attrName[64];
    char slotArg[16];

    GetCmdArg(1, targetArg, sizeof(targetArg));
    GetCmdArg(2, attrName, sizeof(attrName));
    if (args >= 3)
    {
        GetCmdArg(3, slotArg, sizeof(slotArg));
    }

    int slot = -1;
    bool hasSlot = false;
    if (slotArg[0] != '\0')
    {
        slot = StringToInt(slotArg);
        hasSlot = true;
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
        target = TFPlayer(targets[i]);
        if (hasSlot)
        {
            target.GetWeaponBySlot(slot);
        }

        target.RemoveAttribute(attrName);
    }

    if (targetCount > 1)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Removed \x05%s\x01 from \x04%d\x01 targets", attrName, targetCount);
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
        float value = target.GetAttribute(attrName);
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

    if (!g_ConVars[thirdperson_enabled].BoolValue)
        return Plugin_Handled;
        
    g_ThirdPerson[client] = true;
    TFPlayer player = TFPlayer(client);
    player.SetForcedTauntCam(true);
    
    CReplyToCommand(client, PLUGIN_PREFIX ... " Set view to \x04Third-Person");
    return Plugin_Handled;
}

public Action Command_GiveWeapon(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, PLUGIN_PREFIX ... " Usage: sm_giveweapon [target] <itemdefindex> [classname]");
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
    if (slot < 0 || slot > 48)
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
        int weapon = player.GetWeaponBySlot(slot);
        
        if (weapon != -1 && IsValidEntity(weapon))
        {
            player.RemoveWeaponBySlot(slot);
            removed++;
        }
    }

    switch (removed)
    {
        case 0:  CReplyToCommandEx(client, targets[0], PLUGIN_PREFIX ... " Failed to remove weapons for \x03%N", targets[0]);
        case 1:  CReplyToCommandEx(client, targets[0], PLUGIN_PREFIX ... " Removed weapon in slot \x05%d\x01 from \x03%N", slot, targets[0]);
        default: CReplyToCommand(client, PLUGIN_PREFIX ... " Removed weapon in slot \x05%d\x01 from \x04%d\x01 players", slot, removed);
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