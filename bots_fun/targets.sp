public bool TargetFilter_RCBots(const char[] pattern, ArrayList clients, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (IsRCBot2Client(i))
        {
            clients.Push(i);
        }
    }
    return true;
}