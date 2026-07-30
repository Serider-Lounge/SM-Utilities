public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client) && g_ConVars[plugin_bot_autoteambalance].BoolValue)
    {
        SDKHook(client, SDKHook_CanBeAutobalanced, CanBeAutoBalanced);
    }
}