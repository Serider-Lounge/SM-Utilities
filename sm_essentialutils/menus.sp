// Credits
public int MenuHandler_Credits(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        int client = param1;
        char contributor[64];
        menu.GetItem(param2, contributor, sizeof(contributor));
        ShowCreditsContributorMenu(client, contributor);
    }
    return 0;
}

public int MenuHandler_CreditsContributor(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowCreditsMenu(param1);
    }
    else if (action == MenuAction_Select)
    {
        int client = param1;
        char itemInfo[32];
        menu.GetItem(param2, itemInfo, sizeof(itemInfo));

        if (StrEqual(itemInfo, "contributions"))
        {
            ShowCreditsContributionsMenu(client);
            return 0;
        }

        if (!StrEqual(itemInfo, "steam"))
        {
            return 0;
        }

        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.json");

        JSONObject json = JSONObject.FromFile(path);
        if (json == null)
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits config.");
            return 0;
        }

        char url[256];
        JSONArray creditsArray = view_as<JSONArray>(view_as<JSONObject>(json).Get("credits"));
        if (creditsArray != null)
        {
            int count = creditsArray.Length;
            for (int i = 0; i < count; i++)
            {
                JSONObject entry = view_as<JSONObject>(creditsArray.Get(i));
                if (entry == null)
                    continue;

                char name[256];
                entry.GetString("name", name, sizeof(name));
                if (StrEqual(name, g_CreditsSelection[client]))
                {
                    entry.GetString("url", url, sizeof(url));
                    break;
                }
            }
        }

        delete json;

        if (url[0] == '\0')
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " No URL is set for that credits entry.");
            return 0;
        }

        CPrintToChat(client, "\x03%s", url);
    }
    return 0;
}

public int MenuHandler_CreditsContributions(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
    {
        ShowCreditsContributorMenu(param1, g_CreditsSelection[param1]);
    }
    else if (action == MenuAction_Select)
    {
        int client = param1;
        char itemInfo[32];
        menu.GetItem(param2, itemInfo, sizeof(itemInfo));

        if (StrContains(itemInfo, "contrib:", false) != 0)
        {
            return 0;
        }

        // Extract contribution index
        char indexStr[16];
        strcopy(indexStr, sizeof(indexStr), itemInfo[7]);
        int contribIndex = StringToInt(indexStr);

        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.json");

        JSONObject json = JSONObject.FromFile(path);
        if (json == null)
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits config.");
            return 0;
        }

        char url[256] = "";
        JSONArray creditsArray = view_as<JSONArray>(view_as<JSONObject>(json).Get("credits"));
        if (creditsArray != null)
        {
            int count = creditsArray.Length;
            for (int i = 0; i < count; i++)
            {
                JSONObject entry = view_as<JSONObject>(creditsArray.Get(i));
                if (entry == null)
                    continue;

                char name[256];
                entry.GetString("name", name, sizeof(name));
                if (StrEqual(name, g_CreditsSelection[client]))
                {
                    JSONArray contributions = view_as<JSONArray>(entry.Get("contributions"));
                    if (contributions != null && contribIndex < contributions.Length)
                    {
                        JSONObject contrib = view_as<JSONObject>(contributions.Get(contribIndex));
                        if (contrib != null)
                        {
                            contrib.GetString("url", url, sizeof(url));
                        }
                    }
                    break;
                }
            }
        }

        delete json;

        if (url[0] == '\0')
        {
            CReplyToCommand(client, PLUGIN_PREFIX ... " No URL is set for that contribution.");
            return 0;
        }

        CPrintToChat(client, "\x03%s", url);
    }
    return 0;
}