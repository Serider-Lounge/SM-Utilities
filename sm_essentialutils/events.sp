// player_spawn
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

// teamplay_round_start
public void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (StrEqual(g_GameDir, "tf2classified"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            g_IsVIP[i] = false;
        }
    }

    if (g_ConVars[setup_fastbuild].BoolValue && GameRules_GetProp("m_bInSetup"))
    {
        g_ConVars[tf_fastbuild].SetBool(true);
        g_ConVars[tf_cheapobjects].SetBool(true);
        g_ConVars[tf_obj_upgrade_per_hit].SetInt(200);
    }
}

// teamplay_setup_finished
public void Event_TeamplaySetupFinished(Event event, const char[] name, bool dontBroadcast)
{
    if (g_ConVars[setup_fastbuild].BoolValue)
    {
        g_ConVars[tf_fastbuild].SetBool(false);
        g_ConVars[tf_cheapobjects].SetBool(false);
        g_ConVars[tf_obj_upgrade_per_hit].RestoreDefault();
    }
}

// TF2C: vip_tutorial
public void Event_VIPTutorial(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_IsVIP[client] = true;
}