// Shared
public bool TargetFilter_Team(const char[] pattern, ArrayList clients, int client)
{
    char teamPattern[32];
    strcopy(teamPattern, sizeof(teamPattern), pattern[1]);

    int team = FindTeamByName(teamPattern);

    char teamName[32];
    GetTeamName(team, teamName, sizeof(teamName));

    if (strcmp(teamPattern, teamName, false) != 0)
    {
        return true;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (GetClientTeam(i) == team)
        {
            clients.Push(i);
        }
    }
    return true;
}

// Team Fortress 2 Classified
public bool TargetFilter_VIPs(const char[] pattern, ArrayList clients, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        if (TF2C_GetAssignedVIP(view_as<TFTeam>(GetClientTeam(i))) == i)
        {
            clients.Push(i);
        }
    }
    return true;
}