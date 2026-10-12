// player_death
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_ConVars[plugin_humans_only].BoolValue)
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (IsFakeClient(victim) || event.GetInt("death_flags") & 32) // Feign Death (Dead Ringer)
            return;

        if (TF2_IsPermaDeathMode())
        {
            int aliveHumans = 0;
            for (int i = 1; i <= MaxClients; i++)
            {

                if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
                    continue;

                if (i == victim)
                    continue;

                if (GetClientTeam(i) <= 1)
                    continue;

                aliveHumans++;
            }

            if (aliveHumans == 0)
                TF2_EndRound(TF2_GetClientTeam(attacker));
        }
    }
}

// player_connect
public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetBool("bot"))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

// player_disconnect
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetBool("bot"))
    {
        return Plugin_Handled;
    }
    NavGenerate();
    MaintainBotQuota();
    return Plugin_Continue;
}

// player_team
public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (event.GetBool("bot"))
    {
        return Plugin_Handled;
    }
    MaintainBotQuota();
    return Plugin_Continue;
}

// post_inventory_application, teamplay_flag_event
public void Event_PlayerUpdate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients)
        return;

    if (IsFakeClient(client) && g_ConVars[plugin_bot_names].BoolValue)
        CreateTimer(0.2, Timer_SetBotName, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients)
        return;

    if (IsFakeClient(client))
    {
        // Set bot name
        if (g_ConVars[plugin_bot_names].BoolValue)
            CreateTimer(0.2, Timer_SetBotName, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);

        return;
    }

    // Bot Quota
    MaintainBotQuota();
}

// teamplay_round_start
public void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    char mapName[96], mapDisplayName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));

    // TFBots
    if (NavMesh_Exists() && IsBotTypeEnabled(BOT_TYPE_VALVE))
    {
        if (g_IsTF2SDK)
        {
            if (!event.GetBool("full_reset"))
                return;

            // Payload Carts / MVM Tanks
            float pos[3];
            int entity = -1;
            while ((entity = FindEntityByClassname(entity, "mapobj_cart_dispenser")) != -1 ||
                   (entity = FindEntityByClassname(entity, "tank_boss")) != -1)
            {
                int team = GetEntProp(entity, Prop_Data, "m_iTeamNum");
                if (team <= 1)
                    continue;

                int item_teamflag = CreateEntityByName("item_teamflag");
                if (!IsValidEntity(item_teamflag))
                    continue;

                DispatchKeyValue(item_teamflag, "targetname", "bots_fun_item_teamflag");
                DispatchKeyValueInt(item_teamflag, "trail_effect", 0);
                DispatchKeyValue(item_teamflag, "flag_model", "models/empty.mdl");
                DispatchKeyValueInt(item_teamflag, "ReturnTime", 999999);
                DispatchKeyValueInt(item_teamflag, "solid", 0);
                DispatchKeyValueInt(item_teamflag, "GameType", 1);

                DispatchSpawn(item_teamflag);

                GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
                TeleportEntity(item_teamflag, pos, NULL_VECTOR, NULL_VECTOR);

                SetVariantString("!activator");
                AcceptEntityInput(item_teamflag, "SetParent", entity);
            }
        }
    }
}