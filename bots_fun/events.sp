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

// player_disconnect
public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    NavGenerate();
    MaintainBotQuota();
}

// player_team
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    MaintainBotQuota();
}

// post_inventory_application, teamplay_flag_event
public void Event_PlayerUpdate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients)
        return;

    if (IsFakeClient(client))
        CreateTimer(0.2, Timer_SetNameFromModel, client, TIMER_FLAG_NO_MAPCHANGE);
}

// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || client > MaxClients)
        return;

    if (IsFakeClient(client))
    {
        CreateTimer(0.2, Timer_SetNameFromModel, client, TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    MaintainBotQuota();
}

// teamplay_round_start
public void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    char botType[32];
    GetConVarString(g_ConVars[plugin_bot_type], botType, sizeof(botType));

    // TFBots
    if (NavMesh.IsLoaded() && (StrEqual(botType, "valve") || StrEqual(botType, "random")))
    {
        if (!event.GetBool("full_reset"))
            return;

        // Payload Race
        if (FindEntityByClassname(-1, "tf_logic_multiple_escort") != -1)
        {
            GameRules_SetProp("m_nGameType", TF_GAMETYPE_ESCORT);

            int cart = -1;
            while ((cart = FindEntityByClassname(cart, "mapobj_cart_dispenser")) != -1)
            {
                int team = GetEntProp(cart, Prop_Send, "m_iTeamNum");
                if (team <= 1)
                    continue;

                int flag = CreateEntityByName("item_teamflag");
                if (!IsValidEntity(flag))
                    continue;

                DispatchKeyValue(flag, "targetname", "bots_fun_item_teamflag");
                DispatchKeyValueInt(flag, "trail_effect", 0);
                DispatchKeyValue(flag, "flag_model", "models/empty.mdl");
                DispatchKeyValueInt(flag, "ReturnTime", 999999);
                DispatchKeyValueInt(flag, "solid", 0);
                DispatchKeyValueInt(flag, "GameType", 1);

                DispatchSpawn(flag);

                float cartPos[3];
                GetEntPropVector(cart, Prop_Data, "m_vecAbsOrigin", cartPos);
                TeleportEntity(flag, cartPos, NULL_VECTOR, NULL_VECTOR);

                SetVariantString("!activator");
                AcceptEntityInput(flag, "SetParent", cart);
            }
        }
    }
}