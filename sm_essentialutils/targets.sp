// Shared
public bool TargetFilter_Team(const char[] pattern, ArrayList clients, int client)
{
    bool negate = (pattern[1] == '!');
    int offset = negate ? 2 : 1;

    char teamPattern[32];
    for (int i = 0; i < sizeof(teamPattern) - 1 && pattern[offset + i] != '\0'; i++)
    {
        teamPattern[i] = pattern[offset + i];
    }
    teamPattern[sizeof(teamPattern) - 1] = '\0';

    int teamIndex = FindTeamByName(teamPattern);

    char teamName[32];
    GetTeamName(teamIndex, teamName, sizeof(teamName));

    if (!StrEqual(teamPattern, teamName, false))
    {
        return true;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        bool isTeam = (GetClientTeam(i) == teamIndex);
        if ((negate && !isTeam) || (!negate && isTeam))
        {
            clients.Push(i);
        }
    }
    return true;
}

// Team Fortress 2 Classified
public bool TargetFilter_VIPs(const char[] pattern, ArrayList clients, int client)
{
    bool negate = (pattern[1] == '!');

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;

        bool isVIP = TF2C_GetAssignedVIP(GetClientTeam(i)) == i;
        if ((negate && !isVIP) || (!negate && isVIP))
        {
            clients.Push(i);
        }
    }
    return true;
}