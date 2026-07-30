/**
 * Whether the gamemode is Arena Mode or Sudden Death.
 * 
 * @return  True if the gamemode is Arena Mode or Sudden Death, false otherwise.
 */
stock bool TF2_IsPermaDeathMode()
{
    return g_ConVars[plugin_humans_only].BoolValue &&
           (FindEntityByClassname(-1, "tf_logic_arena") != -1 ||
            GameRules_GetProp("m_iRoundState") == 7);
}

/**
 * Enforces the bot quota by adding or removing bots as necessary.
 */
stock void MaintainBotQuota()
{
    if (FindEntityByClassname(-1, "tf_logic_mann_vs_machine") != -1)
        return;

    if (g_hQuotaTimer != null)
        return;

    g_hQuotaTimer = CreateTimer(g_ConVars[plugin_bot_quota_interval].FloatValue, Timer_MaintainBotQuota, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Gets the spawn type of a bot based on the bot type string.
 * 
 * @param botType  The bot type string.
 * @return         The spawn type of the bot, or -1 otherwise.
 */
stock int GetBotSpawnType(const char[] botType)
{
    if (StrEqual(botType, "valve", false))
    {
        if (NavMesh.IsLoaded())
            return BOT_TYPE_VALVE;
    }
    else if (StrEqual(botType, "navbot", false))
    {
        if (g_Libraries[navbot] && NavBotNavMesh.IsLoaded())
            return BOT_TYPE_NAVBOT;
    }
    else if (StrEqual(botType, "rcbot2", false))
    {
        if (g_Libraries[rcbot2] && RCBot2_IsWaypointAvailable())
            return BOT_TYPE_RCBOT2;
    }
    else if (StrEqual(botType, "random", false))
    {
        return BOT_TYPE_COUNT;
    }
    return -1;
}

/**
 * Adds a bot to the server based on the specified bot type.
 * 
 * @param botType  The bot type to add, or BOT_TYPE_COUNT to add a random bot type.
 * @return         True if the bot was added successfully, false otherwise.
 */
stock bool AddBot(int botType = BOT_TYPE_COUNT)
{
    switch (botType)
    {
        case BOT_TYPE_COUNT:
        {
            return AddBot(GetRandomInt(0, BOT_TYPE_COUNT - 1));
        }
        case BOT_TYPE_VALVE:
        {
            if (NavMesh.IsLoaded())
            {
                // Team Fortress 2
                if (g_IsTF2SDK)
                {
                    char class[32];
                    static const char playerClasses[][] = {"scout", "soldier", "pyro", "demoman", "heavyweapons", "engineer", "medic", "sniper", "spy"};
                    strcopy(class, sizeof(class), playerClasses[GetRandomInt(0, sizeof(playerClasses) - 1)]);

                    if (!g_ConVars[tf_bot_reevaluate_class_in_spawnroom].BoolValue)
                    {
                        int random = GetRandomInt(1, 10);
                        switch (random)
                        {
                            case 10:
                            {
                                // Team Fortress 2 Classified
                                if (StrEqual(g_GameDir, "tf2classified"))
                                {
                                    if (g_ConVars[tf2c_allow_special_classes].BoolValue)
                                    {
                                        strcopy(class, sizeof(class), "civilian");
                                    }
                                }
                                // Fortress Connected
                                else if (StrEqual(g_GameDir, "fc_sdk"))
                                {
                                    strcopy(class, sizeof(class), "john");
                                }
                                // Fortress-Life
                                else if (StrEqual(g_GameDir, "fl2"))
                                {
                                    strcopy(class, sizeof(class), "gordonfreeman");
                                }
                            }
                        }
                    }
                    return TF2_SpawnBot(_, _, class, g_ConVars[bot_difficulty].IntValue) != -1;
                }
                return SpawnBot(_, _, g_ConVars[bot_difficulty].IntValue) != -1;
            }
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
    if (g_ConVars[plugin_nav_generate_auto].BoolValue && g_IsServerHibernating)
    {
        if (!NavMesh.IsLoaded())
            ServerCommand("nav_generate");
    }
}