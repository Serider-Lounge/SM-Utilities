public Action Command_NavGenerate(int args)
{
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
		char hostname[256];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		SendTrainingMessageToAll(hostname, "Generating Navigation Mesh...", TMSG_NOFLAGS);
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