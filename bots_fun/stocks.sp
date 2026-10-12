/**
 * Whether the gamemode is Arena Mode or Sudden Death.
 * 
 * @return  True if the gamemode is Arena Mode or Sudden Death, false otherwise.
 */
stock bool TF2_IsPermaDeathMode()
{
    return g_ConVars[plugin_humans_only].BoolValue &&
           (GameRules_GetProp("m_iRoundState") == 7 ||
           GameRules_GetProp("m_nGameType") == TF_GAMETYPE_ARENA ||
           view_as<bool>(GameRules_GetProp("m_bPlayingArena")));
}

/**
 * Enforces the bot quota by adding or removing bots as necessary.
 */
stock void MaintainBotQuota()
{
    if (g_hQuotaTimer == null && !g_IsNavGenerating)
    {
        g_hQuotaTimer = CreateTimer(g_ConVars[plugin_bot_quota_interval].FloatValue, Timer_MaintainBotQuota, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Refreshes the bot type order from per-map restrictions or 'sm_bot_type'.
 */
stock void UpdateBotTypes()
{
    g_BotTypeCount = 0;

    char types[BOT_TYPE_COUNT][16];
    int count = JSON_GetMapBotTypes(types, BOT_TYPE_COUNT);
    if (count < 0)
    {
        char value[128];
        g_ConVars[plugin_bot_type].GetString(value, sizeof(value));
        count = ExplodeString(value, ",", types, BOT_TYPE_COUNT, sizeof(types[]));
    }

    for (int i = 0; i < count; i++)
    {
        TrimString(types[i]);

        int botType = -1;
        for (int j = 0; j < BOT_TYPE_COUNT; j++)
            if (strcmp(types[i], g_BotTypes[j], false) == 0)
            {
                botType = j;
                break;
            }

        if (botType != -1)
            g_BotTypeOrder[g_BotTypeCount++] = botType;
    }
}

/**
 * Whether the bot type is currently available to spawn.
 * 
 * @param botType  The bot type to check.
 * @return         True if the bot type is available, false otherwise.
 */
stock bool IsBotTypeAvailable(int botType)
{
    switch (botType)
    {
        case BOT_TYPE_VALVE: 
            return NavMesh_Exists() && view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
        case BOT_TYPE_NAVBOT:
            return g_Libraries[navbot] && NavBotNavMesh.IsLoaded();
        case BOT_TYPE_RCBOT2:
            return g_Libraries[rcbot2] && RCBot2_IsWaypointAvailable();
    }
    return false;
}

/**
 * Gets the bot spawn type.
 * 
 * @return  The first available bot type in the order, or -1 if none are available.
 */
stock int GetBotSpawnType()
{
    if (g_BotTypeCount == 0)
        return -1;

    if (g_ConVars[plugin_bot_type_random].BoolValue)
    {
        for (int i = g_BotTypeCount - 1; i > 0; i--)
        {
            int j = GetRandomInt(0, i);
            int temp = g_BotTypeOrder[i];
            g_BotTypeOrder[i] = g_BotTypeOrder[j];
            g_BotTypeOrder[j] = temp;
        }
    }

    for (int i = 0; i < g_BotTypeCount; i++)
        if (IsBotTypeAvailable(g_BotTypeOrder[i]))
            return g_BotTypeOrder[i];

    return -1;
}

/**
 * Whether the bot type is enabled.
 * 
 * @param botType  The bot type to check.
 * @return         True if the bot type is enabled, false otherwise.
 */
stock bool IsBotTypeEnabled(int botType)
{
    for (int i = 0; i < g_BotTypeCount; i++)
    {
        if (g_BotTypeOrder[i] == botType)
            return true;
    }
    return false;
}

/**
 * Adds a bot to the server based on the specified bot type.
 * 
 * @param botType  The bot type to add.
 * @return         True if the bot was added successfully, false otherwise.
 */
stock bool AddBot(int botType)
{
    if (!IsBotTypeAvailable(botType))
        return false;

    switch (botType)
    {
        case BOT_TYPE_VALVE:
        {
            if (NavMesh_Exists())
            {
                // Team Fortress 2
                if (g_IsTF2SDK)
                {
                    char class[32];
                    if (!g_ConVars[tf_bot_reevaluate_class_in_spawnroom].BoolValue)
                    {
                        g_PlayerClasses.GetString(GetRandomInt(0, g_PlayerClasses.Length - 1), class, sizeof(class));
                    }

                    bool isCivilianAllowed = g_ConVars[tf2c_allow_special_classes].BoolValue || g_ConVars[sig_etc_allow_civilian_class].BoolValue;
                    if (!isCivilianAllowed && strcmp(class, "civilian") == 0)
                    {
                        if (g_PlayerClasses.Length > 1)
                        {
                            do
                            {
                                g_PlayerClasses.GetString(GetRandomInt(0, g_PlayerClasses.Length - 1), class, sizeof(class));
                            } while (strcmp(class, "civilian", false) == 0);
                        }
                    }
                    return TF2_SpawnBot(_, _, class, g_ConVars[bot_difficulty].IntValue) != -1;
                }
                return SpawnBot(_, _, g_ConVars[bot_difficulty].IntValue) != -1;
            }
            return false;
        }
        case BOT_TYPE_NAVBOT:
        {
            if (g_Libraries[navbot] && NavBotNavMesh.IsLoaded())
            {
                NavBot bot = NavBot("NavBot");
                return !bot.IsNull;
            }
        }
        case BOT_TYPE_RCBOT2:
        {
            if (g_Libraries[rcbot2] && RCBot2_IsWaypointAvailable())
            {
                return RCBot2_CreateBot("RCBot") != -1;
            }
        }
    }
    return false;
}

/**
 * Generates Navigation Mesh based on 'nav_generate_auto'.
 */
stock void NavGenerate()
{
    if (g_ConVars[plugin_nav_generate_auto] != null &&
        g_ConVars[plugin_nav_generate_auto].BoolValue && g_IsServerHibernating)
    {
        if (!NavMesh_Exists())
        {
            ServerCommand("nav_generate");
        }
        else if (g_Libraries[navbot] && !NavBotNavMesh.IsLoaded())
        {
            NavBotNavMesh.Generate();
        }
    }
}