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
        if (StrEqual(name, contributor))
        {
            found = true;
            
            char url[256];
            entry.GetString("url", url, sizeof(url))
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
        if (StrEqual(name, g_CreditsSelection[client]))
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
                    Format(itemInfo, sizeof(itemInfo), "contrib:%d", j);

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

// Downloads
stock void ProcessDownloadsConfig()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/sm_utilities/downloads.json");
    
    if (!FileExists(path))
    {
        PrintToServer(PLUGIN_PREFIX ... " 'downloads.json' not found.");
        return;
    }
    
    JSONObject json = JSONObject.FromFile(path);
    if (json == null)
    {
        PrintToServer(PLUGIN_PREFIX ... " Failed to parse 'downloads.json'.");
        return;
    }
    
    JSONObject maps = view_as<JSONObject>(json.Get("maps"));
    if (maps != null)
    {
        char mapName[96], mapDisplayName[64];
        GetCurrentMap(mapName, sizeof(mapName));
        GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));
        
        JSONObjectKeys iter = maps.Keys();
        char mapPattern[PLATFORM_MAX_PATH];
        while (iter.ReadKey(mapPattern, sizeof(mapPattern)))
        {
            Regex regex = new Regex(mapPattern);
            if (regex != null && regex.Match(mapDisplayName) > 0)
            {
                JSONObject mapFiles = view_as<JSONObject>(maps.Get(mapPattern));
                if (mapFiles != null)
                {
                    JSONArray array = view_as<JSONArray>(mapFiles);
                    for (int i = 0; i < array.Length; i++)
                    {
                        if (array.GetType(i) == JSON_STRING)
                        {
                            char filePath[PLATFORM_MAX_PATH];
                            array.GetString(i, filePath, sizeof(filePath));
                            if (filePath[0] != '\0')
                            {
                                Regex fileRegex = new Regex(filePath);
                                if (fileRegex != null)
                                {
                                    if (FileExists(filePath))
                                    {
                                        AddFileToDownloadsTable(filePath);
                                        PrecacheFile(filePath);
                                    }
                                    else
                                    {
                                        char basePath[PLATFORM_MAX_PATH];
                                        strcopy(basePath, FindCharInString(filePath, '/', true) + 2, filePath);
                                        DirectoryListing dir = OpenDirectory(basePath, true);
                                        if (dir != null)
                                        {
                                            char fileName[PLATFORM_MAX_PATH];
                                            FileType fileType;
                                            while (dir.GetNext(fileName, sizeof(fileName), fileType))
                                            {
                                                if (fileType == FileType_File)
                                                {
                                                    char fullPath[PLATFORM_MAX_PATH];
                                                    Format(fullPath, sizeof(fullPath), "%s%s", basePath, fileName);
                                                    if (fileRegex.Match(fullPath) > 0)
                                                    {
                                                        AddFileToDownloadsTable(fullPath);
                                                        PrecacheFile(fullPath);
                                                    }
                                                }
                                            }
                                            delete dir;
                                        }
                                    }
                                    delete fileRegex;
                                }
                            }
                        }
                    }
                }
            }
            delete regex;
        }
        delete iter;
    }
    delete json;
}