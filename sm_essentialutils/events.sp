// player_spawn
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    TFPlayer player = TFPlayer(client);

    // Third-Person
    CreateTimer(0.1, Timer_PlayerSpawn, player, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PlayerSpawn(Handle timer, int client)
{
    TFPlayer player = TFPlayer(client);
    player.SetForcedTauntCam(g_ThirdPerson[client]);
    return Plugin_Stop;
}

// teamplay_round_start
public void Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_ConVars[setup_fastbuild].BoolValue && GameRules_GetProp("m_bInSetup") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
    {
        g_ConVars[tf_fastbuild].SetBool(true);
        g_ConVars[tf_cheapobjects].SetBool(true);
        g_ConVars[tf_obj_upgrade_per_hit].SetInt(200);
    }
}

// teamplay_setup_finished
public void Event_TeamplaySetupFinished(Event event, const char[] name, bool dontBroadcast)
{
    if (g_ConVars[setup_fastbuild].BoolValue && !GameRules_GetProp("m_bPlayingMannVsMachine"))
    {
        g_ConVars[tf_fastbuild].SetBool(false);
        g_ConVars[tf_cheapobjects].SetBool(false);
        g_ConVars[tf_obj_upgrade_per_hit].RestoreDefault();
    }
}
