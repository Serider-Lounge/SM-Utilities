// Menus
stock void ShowCreditsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Credits);
    menu.SetTitle("Credits");

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.json");

    JSONObject json = JSONObject.FromFile(path);
    if (json == null)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits config.");
        delete menu;
        return;
    }

    JSONArray creditsArray = view_as<JSONArray>(view_as<JSONObject>(json).Get("credits"));
    if (creditsArray == null)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Invalid credits format.");
        delete json;
        delete menu;
        return;
    }

    int count = creditsArray.Length;
    for (int i = 0; i < count; i++)
    {
        JSONObject entry = view_as<JSONObject>(creditsArray.Get(i));
        if (entry == null)
            continue;

        char name[256];
        entry.GetString("name", name, sizeof(name));
        if (name[0] != '\0')
        {
            menu.AddItem(name, name);
        }
    }

    delete json;
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

stock void ShowCreditsContributorMenu(int client, const char[] contributor)
{
    Menu menu = new Menu(MenuHandler_CreditsContributor);
    menu.SetTitle("Credits | %s", contributor);
    menu.ExitBackButton = true;

    strcopy(g_CreditsSelection[client], sizeof(g_CreditsSelection[]), contributor);

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.json");

    JSONObject json = JSONObject.FromFile(path);
    if (json == null)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits config.");
        delete menu;
        return;
    }

    JSONArray creditsArray = view_as<JSONArray>(view_as<JSONObject>(json).Get("credits"));
    if (creditsArray == null)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Invalid credits format.");
        delete json;
        delete menu;
        return;
    }

    bool found = false;
    int count = creditsArray.Length;
    for (int i = 0; i < count; i++)
    {
        JSONObject entry = view_as<JSONObject>(creditsArray.Get(i));
        if (entry == null)
            continue;

        char name[256];
        entry.GetString("name", name, sizeof(name));
        if (strcmp(name, contributor) == 0)
        {
            found = true;
            
            char url[256];
            entry.GetString("url", url, sizeof(url));
            if (url[0] != '\0')
            {
                if (StrContains(url, "steamcommunity.com") != -1)
                {
                    menu.AddItem("steam", "Steam");
                }
                else
                {
                    menu.AddItem("steam", "Website");
                }
            }
            menu.AddItem("contributions", "Contributions");
            break;
        }
    }

    delete json;

    if (!found)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits entry for \x05%s\x01.", contributor);
        delete menu;
        return;
    }

    menu.Display(client, MENU_TIME_FOREVER);
}

stock void ShowCreditsContributionsMenu(int client)
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/credits.json");

    JSONObject json = JSONObject.FromFile(path);
    if (json == null)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits config.");
        return;
    }

    JSONArray creditsArray = view_as<JSONArray>(view_as<JSONObject>(json).Get("credits"));
    if (creditsArray == null)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Invalid credits format.");
        delete json;
        return;
    }

    Menu menu = new Menu(MenuHandler_CreditsContributions);
    menu.SetTitle("Contributions | %s", g_CreditsSelection[client]);
    menu.ExitBackButton = true;

    bool found = false;
    int count = creditsArray.Length;
    for (int i = 0; i < count; i++)
    {
        JSONObject entry = view_as<JSONObject>(creditsArray.Get(i));
        if (entry == null)
            continue;

        char name[256];
        entry.GetString("name", name, sizeof(name));
        if (strcmp(name, g_CreditsSelection[client]) == 0)
        {
            found = true;
            
            JSONArray contributions = view_as<JSONArray>(entry.Get("contributions"));
            if (contributions != null)
            {
                int contribCount = contributions.Length;
                for (int j = 0; j < contribCount; j++)
                {
                    JSONObject contrib = view_as<JSONObject>(contributions.Get(j));
                    if (contrib == null)
                        continue;

                    char contribName[128];
                    contrib.GetString("name", contribName, sizeof(contribName));
                    if (contribName[0] == '\0')
                        strcopy(contribName, sizeof(contribName), "Unnamed contribution");

                    char contribUrl[256];
                    contrib.GetString("url", contribUrl, sizeof(contribUrl));

                    char itemInfo[32];
                    FormatEx(itemInfo, sizeof(itemInfo), "contrib:%d", j);

                    if (contribUrl[0] != '\0')
                    {
                        menu.AddItem(itemInfo, contribName);
                    }
                    else
                    {
                        menu.AddItem(itemInfo, contribName, ITEMDRAW_DISABLED);
                    }
                }
            }
            break;
        }
    }

    delete json;

    if (!found)
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Could not load credits entry for \x05%s\x01.", g_CreditsSelection[client]);
        delete menu;
        return;
    }

    menu.Display(client, MENU_TIME_FOREVER);
}