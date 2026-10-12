public Action Command_NavGenerate(int args)
{
    g_IsNavGenerating = true;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i))
            continue;
        
        if (IsFakeClient(i))
            KickClient(i);
    }

    char mapName[PLATFORM_MAX_PATH], mapDisplayName[PLATFORM_MAX_PATH];
    GetCurrentMap(mapName, sizeof(mapName));
    GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));

    SetNextMap(mapDisplayName);

    CPrintToChatAll(PLUGIN_PREFIX ... " Generating Navigation Mesh...", mapDisplayName);

    Event event = CreateEvent("instructor_server_hint_create", true);
    if (event != null)
	{
        int target = CreateEntityByName("info_target");
        if (target != -1)
        {
            float origin[3] = {0.0, 0.0, 0.0};
            TeleportEntity(target, origin, NULL_VECTOR, NULL_VECTOR);
            DispatchSpawn(target);
            
            event.SetString("hint_replace_key", "nav_generate");
            event.SetString("hint_caption", "Generating Navigation Mesh...");
            event.SetString("hint_icon_onscreen", "icon_tip");
            event.SetString("hint_icon_offscreen", "icon_tip");
            event.SetString("hint_static", "1");
            event.SetInt("hint_timeout", 0);
            event.SetInt("hint_target", target);
            event.Fire();
        }
        else
        {
            event.Cancel();
        }
	}
	else if (g_Libraries[trainingmsg])
	{
		char title[256];
		GetConVarString(g_ConVars[hostname], title, sizeof(title));
		SendTrainingMessageToAll(title, "Generating Navigation Mesh...", TMSG_NOFLAGS);
	}

    return Plugin_Continue;
}

public Action Command_PuppetAdd(int client, int args)
{
    char name[MAX_NAME_LENGTH] = "Bot";
    GetCmdArg(1, name, sizeof(name));
    CreateFakeClient(name);
    return Plugin_Handled;
}

// jointeam
public Action Command_JoinTeam(int client, const char[] command, int args)
{
    char mode[32];
    g_ConVars[plugin_bot_quota_mode].GetString(mode, sizeof(mode));
    if (strcmp(mode, "balance") != 0)
        return Plugin_Continue;

    char teamArg[32];
    GetCmdArg(1, teamArg, sizeof(teamArg));

    int team = 0;
    char teamName[32];
    for (int i = 2; i < g_TeamCount; i++)
    {
        GetTeamName(i, teamName, sizeof(teamName));
        teamName[0] = CharToLower(teamName[0]);
        if (strcmp(teamArg, teamName) == 0)
        {
            team = i;
            break;
        }
    }

    if (team < 2)
        return Plugin_Continue;

    int humansPerTeam[MAXPLAYERS + 1];
    int botsPerTeam[MAXPLAYERS + 1];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i))
            continue;
        int clientTeam = GetClientTeam(i);
        if (clientTeam <= 1)
            continue;
        if (IsFakeClient(i))
            botsPerTeam[clientTeam]++;
        else
            humansPerTeam[clientTeam]++;
    }

    int minHumans = MaxClients + 1;
    int maxHumans = 0;
    for (int i = 2; i < g_TeamCount; i++)
    {
        if (!IsTeamActive(i))
            continue;
        if (humansPerTeam[i] < minHumans)
            minHumans = humansPerTeam[i];
        if (humansPerTeam[i] > maxHumans)
            maxHumans = humansPerTeam[i];
    }
    int desired = (minHumans == maxHumans) ? maxHumans : (minHumans + 1);

    if (humansPerTeam[team] + botsPerTeam[team] + 1 <= desired)
        return Plugin_Continue;

    for (int i = 2; i < g_TeamCount; i++)
    {
        if (i == team || !IsTeamActive(i))
            continue;

        int total = humansPerTeam[i] + botsPerTeam[i];
        if (total < desired || (total == desired && botsPerTeam[i] > 0))
        {
            ChangeClientTeam(client, i);
            return Plugin_Handled;
        }
    }

    return Plugin_Continue;
}