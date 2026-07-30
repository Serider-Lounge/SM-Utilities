public void OnClientPutInServer(int client)
{
    if (g_ConVars[plugin_bot_autoteambalance].BoolValue && IsFakeClient(client))
    {
        SDKHook(client, SDKHook_CanBeAutobalanced, CanBeAutoBalanced);
    }
}