// Shared
public bool TargetFilter_Team(const char[] pattern, ArrayList clients, int client)
{
    char teamPattern[32];
    for (int i = 0; i < sizeof(teamPattern) - 1 && pattern[i + 1] != '\0'; i++)
    {
        teamPattern[i] = pattern[i + 1];
    }
    teamPattern[sizeof(teamPattern) - 1] = '\0';

    int team = FindTeamByName(teamPattern);

    char teamName[32];
    GetTeamName(team, teamName, sizeof(teamName));

    if (!StrEqual(teamPattern, teamName, false))
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

        if (TF2C_GetAssignedVIP(GetClientTeam(i)) == i)
        {
            clients.Push(i);
        }
    }
    return true;
}