public Action Timer_MaintainBotQuota(Handle timer)
{
    char mode[32];
    g_ConVars[plugin_bot_quota_mode].GetString(mode, sizeof(mode));

    int humans = 0;
    int bots = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i))
            continue;
        
        if (GetClientTeam(i) <= 1)
            continue;
        
        if (IsFakeClient(i))
            bots++;
        else
            humans++;
    }

    int desiredBotCount = g_ConVars[plugin_bot_quota].IntValue - humans;

    // fill
    if (StrEqual(mode, "fill"))
    {
        if (bots < desiredBotCount)
        {
            char botType[32];
            g_ConVars[plugin_bot_type].GetString(botType, sizeof(botType));
            int spawnType = GetBotSpawnType(botType);
            if (spawnType != -1)
            {
                int needed = desiredBotCount - bots;
                for (int k = 0; k < needed; k++)
                    AddBot(spawnType);
            }
        }
        else if (bots > desiredBotCount)
        {
            int excess = bots - desiredBotCount;
            int kicked = 0;

            // Kick: Dead teammates
            for (int j = 1; j <= MaxClients && kicked < excess; j++)
            {
                if (!IsClientInGame(j) || IsFakeClient(j))
                    continue;
                int team = GetClientTeam(j);
                for (int i = 1; i <= MaxClients && kicked < excess; i++)
                {
                    if (!IsClientInGame(i) || !IsFakeClient(i) || IsPlayerAlive(i) || GetClientTeam(i) != team)
                        continue;
                    KickClient(i);
                    kicked++;
                }
            }

            // Kick: Any dead bots
            for (int i = 1; i <= MaxClients && kicked < excess; i++)
            {
                if (!IsClientInGame(i) || !IsFakeClient(i) || IsPlayerAlive(i))
                    continue;
                KickClient(i);
                kicked++;
            }

            // Kick: Alive teammates
            for (int j = 1; j <= MaxClients && kicked < excess; j++)
            {
                if (!IsClientInGame(j) || IsFakeClient(j))
                    continue;
                int team = GetClientTeam(j);
                for (int i = 1; i <= MaxClients && kicked < excess; i++)
                {
                    if (!IsClientInGame(i) || !IsFakeClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != team)
                        continue;
                    KickClient(i);
                    kicked++;
                }
            }

            // Kick: Any bots
            for (int i = 1; i <= MaxClients && kicked < excess; i++)
            {
                if (!IsClientInGame(i) || !IsFakeClient(i))
                    continue;
                KickClient(i);
                kicked++;
            }
        }
    }
    // balance
    else if (StrEqual(mode, "balance"))
    {
        int activeTeams[MAXPLAYERS + 1];
        int activeTeamCount = 0;
        for (int i = 2; i < g_TeamCount; i++)
            if (IsTeamActive(i))
                activeTeams[activeTeamCount++] = i;

        int humansPerTeam[MAXPLAYERS + 1];
        int botsPerTeam[MAXPLAYERS + 1];
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i))
                continue;
            int team = GetClientTeam(i);
            if (team <= 1)
                continue;
            if (IsFakeClient(i))
                botsPerTeam[team]++;
            else
                humansPerTeam[team]++;
        }

        int minHumans = MaxClients + 1;
        int maxHumans = 0;
        for (int i = 0; i < activeTeamCount; i++)
        {
            int team = activeTeams[i];
            if (humansPerTeam[team] < minHumans)
                minHumans = humansPerTeam[team];
            if (humansPerTeam[team] > maxHumans)
                maxHumans = humansPerTeam[team];
        }
        int target = (minHumans == maxHumans) ? maxHumans : (minHumans + 1);

        // Remove excess bots
        for (int i = 0; i < activeTeamCount; i++)
        {
            int team = activeTeams[i];
            int currentTotal = humansPerTeam[team] + botsPerTeam[team];
            if (currentTotal > target)
            {
                int excess = currentTotal - target;
                int kicked = 0;

                // Kick: Any dead bots
                for (int j = 1; j <= MaxClients && kicked < excess; j++)
                {
                    if (!IsClientInGame(j) || GetClientTeam(j) != team || !IsFakeClient(j) || IsPlayerAlive(j))
                        continue;
                    KickClient(j);
                    kicked++;
                }

                // Kick: Any alive bots
                for (int j = 1; j <= MaxClients && kicked < excess; j++)
                {
                    if (!IsClientInGame(j) || GetClientTeam(j) != team || !IsFakeClient(j) || !IsPlayerAlive(j))
                        continue;
                    KickClient(j);
                    kicked++;
                }
            }
        }

        // Fill gaps with bots
        for (int i = 0; i < activeTeamCount; i++)
        {
            int team = activeTeams[i];
            int currentTotal = humansPerTeam[team] + botsPerTeam[team];
            if (currentTotal < target)
            {
                int needed = target - currentTotal;
                char botType[32];
                g_ConVars[plugin_bot_type].GetString(botType, sizeof(botType));
                int spawnType = GetBotSpawnType(botType);
                if (spawnType != -1)
                {
                    for (int k = 0; k < needed; k++)
                        AddBot(spawnType);
                }
            }
        }
    }
    return Plugin_Continue;
}

public void Timer_SetNameFromModel(Handle timer, int client)
{
    if (!IsClientConnected(client) || IsClientSourceTV(client) || IsClientReplay(client))
        return;

    char path[PLATFORM_MAX_PATH], name[PLATFORM_MAX_PATH];

    GetClientModel(client, path, sizeof(path));

    if (JSON_GetBotName(path, name, sizeof(name)))
        SetClientName(client, name);
}