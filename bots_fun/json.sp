public bool JSON_GetBotName(const char[] path, char[] buffer, int maxlen)
{
    if (!g_ConVars[plugin_bot_names].BoolValue)
        return false;

    if (g_BotConfig == null)
        return false;

    if (!g_BotConfig.HasKey("bot_names"))
        return false;

    JSONObject bot_names = view_as<JSONObject>(g_BotConfig.Get("bot_names"));

    bool success = false;

    switch (g_ConVars[plugin_bot_names].IntValue)
    {
        case 1:
        {
            if (bot_names.HasKey("default"))
            {
                JSONArray defaults = view_as<JSONArray>(bot_names.Get("default"));
                if (defaults.Length > 0)
                {
                    int index = GetRandomInt(0, defaults.Length - 1);
                    defaults.GetString(index, buffer, maxlen);
                    success = true;
                }
                delete defaults;
            }
        }
        case 2:
        {
            if (bot_names.HasKey("models"))
            {
                char model[PLATFORM_MAX_PATH];
                Regex regex = new Regex("[^/\\\\]+(?=\\.[^./\\\\]+$)");
                if (regex.Match(path))
                {
                    regex.GetSubString(0, model, sizeof(model));

                    JSONObject models = view_as<JSONObject>(bot_names.Get("models"));
                    if (models.HasKey(model))
                    {
                        models.GetString(model, buffer, maxlen);
                        success = true;
                    }
                    delete models;
                }
                delete regex;
            }
        }
    }

    delete bot_names;

    return success;
}

/**
 * Retrieves the bot types allowed on the current map, if defined.
 * 
 * @param types     Array to fill with the allowed bot type strings, in priority order.
 * @param maxCount  Maximum number of types to store.
 * @return          The number of types stored, 0 if no bots are allowed on this map,
 *                  or -1 if there is no map restriction (normal behavior).
 */
stock int JSON_GetMapBotTypes(char[][] types, int maxCount)
{
    if (g_BotConfig == null)
        return -1;

    if (!g_BotConfig.HasKey("maps"))
        return -1;

    JSONObject maps = view_as<JSONObject>(g_BotConfig.Get("maps"));

    char mapName[96], mapDisplayName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));

    int count = -1;

    JSONObjectKeys keys = maps.Keys();
    if (keys)
    {
        char pattern[64];
        while (keys.ReadKey(pattern, sizeof(pattern)))
        {
            Regex regex = new Regex(pattern);

            if (!regex.Match(mapDisplayName))
            {
                delete regex;
                continue;
            }
            
            delete regex;

            JSONArray arr = view_as<JSONArray>(maps.Get(pattern));
            count = arr.Length < maxCount ? arr.Length : maxCount;
            char type[64];
            for (int i = 0; i < count; i++)
            {
                arr.GetString(i, type, sizeof(type));
                strcopy(types[i], sizeof(type), type);
            }
            delete arr;
            break;
        }
        delete keys;
    }

    delete maps;

    return count;
}