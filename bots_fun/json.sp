public bool JSON_GetBotName(const char[] path, char[] buffer, int maxlen)
{
    static char configPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, configPath, sizeof(configPath), "configs/sm_utilities/bots_fun.json");

    if (!FileExists(configPath))
        return false;

    JSONObject json = JSONObject.FromFile(configPath);
    if (!json)
        return false;

    if (!json.HasKey("bot_names"))
    {
        delete json;
        return false;
    }

    char model[PLATFORM_MAX_PATH];
    Regex regex = new Regex("[^/\\\\]+(?=\\.[^./\\\\]+$)");
    if (regex.Match(path))
    {
        regex.GetSubString(0, model, sizeof(model));
        delete regex;

        JSONObject bot_names = view_as<JSONObject>(json.Get("bot_names"));
        if (bot_names.HasKey(model))
        {
            bot_names.GetString(model, buffer, maxlen);
            delete bot_names;
            delete json;
            return true;
        }
        delete bot_names;
    }

    delete regex;
    delete json;
    
    return false;
}