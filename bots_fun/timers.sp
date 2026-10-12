public Action Timer_MaintainBotQuota(Handle timer)
{
    if (g_IsNavGenerating || (g_IsMVM && !g_ConVars[plugin_bot_quota_mvm].BoolValue))
    {
        g_hQuotaTimer = null;
        return Plugin_Stop;
    }

    int invadersTeam = g_IsReverseMVM ? 2 : 3;

    // Quota Manager
    char mode[32];
    g_ConVars[plugin_bot_quota_mode].GetString(mode, sizeof(mode));

    bool[] managed = new bool[MaxClients + 1];
    int[] managedBots = new int[MaxClients + 1];

    int humans = 0;
    int bots = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i))
            continue;

        if (GetClientTeam(i) <= 1)
            continue;

        if (g_IsMVM && GetClientTeam(i) == invadersTeam)
            continue;

        managed[i] = true;

        if (IsFakeClient(i))
        {
            managedBots[bots] = i;
            bots++;
        }
        else
        {
            humans++;
        }
    }

    int desiredBotCount = g_ConVars[plugin_bot_quota].IntValue - humans;
    if (g_IsMVM)
    {
        desiredBotCount = g_ConVars[tf_mvm_defenders_team_size].IntValue - humans - 1;
        if (desiredBotCount < 0)
            desiredBotCount = 0;
    }

    int spawnType = GetBotSpawnType();

    // fill
    if (strcmp(mode, "fill") == 0 || (g_IsMVM && mode[0] != '\0'))
    {
        if (bots == desiredBotCount)
        {
            g_hQuotaTimer = null;
            return Plugin_Stop;
        }

        if (bots < desiredBotCount)
        {
            if (spawnType == -1)
            {
                g_hQuotaTimer = null;
                return Plugin_Stop;
            }

            // Keep the timer running so bots are added one at a time until the quota is met.
            AddBot(spawnType);
            return Plugin_Continue;
        }
        else
        {
            int excess = bots - desiredBotCount;
            int kicked = 0;

            // Kick: Dead teammates
            for (int j = 1; j <= MaxClients && kicked < excess; j++)
            {
                if (!managed[j] || IsFakeClient(j))
                    continue;

                for (int b = 0; b < bots && kicked < excess; b++)
                {
                    int i = managedBots[b];
                    if (i == 0 || !IsPlayerAlive(i) || GetClientTeam(i) != GetClientTeam(j))
                        continue;
                    KickClient(i);
                    managedBots[b] = 0;
                    kicked++;
                }
            }

            // Kick: Any dead bots
            for (int b = 0; b < bots && kicked < excess; b++)
            {
                int i = managedBots[b];
                if (i == 0 || IsPlayerAlive(i))
                    continue;
                KickClient(i);
                managedBots[b] = 0;
                kicked++;
            }

            // Kick: Alive teammates
            for (int j = 1; j <= MaxClients && kicked < excess; j++)
            {
                if (!managed[j] || IsFakeClient(j))
                    continue;

                for (int b = 0; b < bots && kicked < excess; b++)
                {
                    int i = managedBots[b];
                    if (i == 0 || IsPlayerAlive(i) || GetClientTeam(i) != GetClientTeam(j))
                        continue;
                    KickClient(i);
                    managedBots[b] = 0;
                    kicked++;
                }
            }

            // Kick: Any bots
            for (int b = 0; b < bots && kicked < excess; b++)
            {
                int i = managedBots[b];
                if (i == 0)
                    continue;
                KickClient(i);
                managedBots[b] = 0;
                kicked++;
            }
        }
    }
    // balance, layer
    else if (!g_IsMVM && (strcmp(mode, "balance") == 0 || strcmp(mode, "layer") == 0))
    {
        if (g_ConVars[mp_teams_unbalance_limit].IntValue <= 0)
        {
            g_hQuotaTimer = null;
            return Plugin_Stop;
        }

        int activeTeams[MAXPLAYERS + 1];
        int activeTeamCount = 0;
        for (int i = 2; i < g_TeamCount; i++)
            if (IsTeamActive(i))
                activeTeams[activeTeamCount++] = i;

        int humansPerTeam[MAXPLAYERS + 1];
        int botsPerTeam[MAXPLAYERS + 1];
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!managed[i])
                continue;
            if (IsFakeClient(i))
                botsPerTeam[GetClientTeam(i)]++;
            else
                humansPerTeam[GetClientTeam(i)]++;
        }

        int maxHumans = 0;
        for (int i = 0; i < activeTeamCount; i++)
        {
            int t = activeTeams[i];
            if (humansPerTeam[t] > maxHumans)
                maxHumans = humansPerTeam[t];
        }

        int desired = maxHumans;

        // Remove excess bots
        for (int i = 0; i < activeTeamCount; i++)
        {
            int t = activeTeams[i];
            int currentTotal = humansPerTeam[t] + botsPerTeam[t];
            if (currentTotal <= desired)
                continue;

            int excess = currentTotal - desired;
            int kicked = 0;

            // Kick: Any dead bots
            for (int b = 0; b < bots && kicked < excess; b++)
            {
                int j = managedBots[b];
                if (j == 0 || GetClientTeam(j) != t || IsPlayerAlive(j))
                    continue;
                KickClient(j);
                managedBots[b] = 0;
                kicked++;
            }

            // Kick: Any bots
            for (int b = 0; b < bots && kicked < excess; b++)
            {
                int j = managedBots[b];
                if (j == 0 || GetClientTeam(j) != t)
                    continue;
                KickClient(j);
                managedBots[b] = 0;
                kicked++;
            }
        }

        // Fill gaps with bots
        for (int i = 0; i < activeTeamCount; i++)
        {
            int t = activeTeams[i];
            int currentTotal = humansPerTeam[t] + botsPerTeam[t];
            if (currentTotal < desired)
            {
                if (spawnType != -1 && !AddBot(spawnType))
                {
                    g_hQuotaTimer = CreateTimer(g_ConVars[plugin_bot_quota_interval].FloatValue, Timer_MaintainBotQuota, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                    return Plugin_Stop;
                }
                
                break;
            }
        }
    }
    g_hQuotaTimer = null;
    return Plugin_Stop;
}

public void Timer_SetBotName(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientConnected(client) || IsClientSourceTV(client) || IsClientReplay(client))
        return;

    char path[PLATFORM_MAX_PATH], name[PLATFORM_MAX_PATH];

    GetClientModel(client, path, sizeof(path));

    if (JSON_GetBotName(path, name, sizeof(name)))
        SetClientName(client, name);
}