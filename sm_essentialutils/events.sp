// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    // Third-Person
    CreateTimer(0.1, Timer_PlayerSpawn, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PlayerSpawn(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientInGame(client))
        return Plugin_Stop;

    let player = new TFPlayer(client);
    player.SetForcedTauntCam(g_ThirdPerson[client]);
    return Plugin_Stop;
}

// player_death
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_KillFeedOnlySelf[i] && i == attacker)
        {
            event.BroadcastDisabled = true;
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

// player_disconnect
public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    g_KillFeedOnlySelf[client] = false;
}

// teamplay_round_start
public void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_ConVars[setup_fastbuild] != null &&
        g_ConVars[setup_fastbuild].BoolValue && GameRules_GetProp("m_bInSetup") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
    {
        g_ConVars[tf_fastbuild].SetBool(true);
        g_ConVars[tf_cheapobjects].SetBool(true);
        g_ConVars[tf_obj_upgrade_per_hit].SetInt(200);
    }
    else
    {
        g_ConVars[tf_fastbuild].SetBool(false);
        g_ConVars[tf_cheapobjects].SetBool(false);
        g_ConVars[tf_obj_upgrade_per_hit].RestoreDefault();
    }
}

// teamplay_setup_finished
public void Event_TeamplaySetupFinished(Event event, const char[] name, bool dontBroadcast)
{
    if (g_ConVars[setup_fastbuild] != null &&
        g_ConVars[setup_fastbuild].BoolValue && !GameRules_GetProp("m_bPlayingMannVsMachine"))
    {
        g_ConVars[tf_fastbuild].SetBool(false);
        g_ConVars[tf_cheapobjects].SetBool(false);
        g_ConVars[tf_obj_upgrade_per_hit].RestoreDefault();
    }
}
