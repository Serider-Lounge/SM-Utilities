/**
 * Reads a value from the game's gameinfo.txt.
 *
 * @param key       Key to look up.
 * @param buffer    Buffer to store the value.
 * @param maxlen    Maximum length of the buffer.
 * @return          True on success, false otherwise.
 */
stock bool GameInfo_GetKey(const char[] key, char[] buffer, int maxlen)
{
    KeyValues kv = new KeyValues("GameInfo");
    if (!kv.ImportFromFile("gameinfo.txt"))
    {
        delete kv;
        return false;
    }

    kv.GetString(key, buffer, maxlen);
    delete kv;
    return true;
}

/**
 * Gets the app id from gameinfo.txt.
 *
 * @return Game appid, or 0 if it could not be read.
 */
stock int GameInfo_GetAppId()
{
    KeyValues kv = new KeyValues("GameInfo");
    if (!kv.ImportFromFile("gameinfo.txt") || !kv.JumpToKey("FileSystem"))
    {
        delete kv;
        return 0;
    }

    int appid = kv.GetNum("SteamAppId");
    delete kv;
    return appid;
}

/**
 * Gets the game name from gameinfo.txt.
 *
 * @param buffer    Buffer to store the game name.
 * @param maxlen    Maximum length of the buffer.
 */
stock void GameInfo_GetGameName(char[] buffer, int maxlen)
{
    GameInfo_GetKey("game", buffer, maxlen);
}

/**
 * Gets the developer name from gameinfo.txt.
 *
 * @param buffer    Buffer to store the developer name.
 * @param maxlen    Maximum length of the buffer.
 */
stock void GameInfo_GetDeveloperName(char[] buffer, int maxlen)
{
    GameInfo_GetKey("developer", buffer, maxlen);
}

/**
 * Gets the developer URL from gameinfo.txt.
 *
 * @param buffer    Buffer to store the developer URL.
 * @param maxlen    Maximum length of the buffer.
 */
stock void GameInfo_GetDeveloperURL(char[] buffer, int maxlen)
{
    GameInfo_GetKey("developer_url", buffer, maxlen);
}

typedef AppDetailsCallback = function void (
    int appid,
    const char[] name,
    const char[] icon,
    any data
);

/**
 * Builds a Steam store asset URL.
 * Available assets:
 * - library_600x900
 * - library_hero
 * - page_bg_raw
 * - logo
 * - capsule_616x353
 * - page_bg_generated_v6b
 * - hero_capsule
 * - header
 *
 * @param appid     The app id to build the URL for.
 * @param asset     The asset filename (without extension).
 * @param buffer    Buffer to store the full URL.
 * @param maxlen    Maximum length of the buffer.
 */
stock void Steam_GetStoreAsset(int appid, const char[] asset, char[] buffer, int maxlen)
{
    Format(buffer, maxlen, "https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/%d/%s.jpg", appid, asset);
}

/**
 * Builds a Steam store asset URL for the current game.
 *
 * @param asset     The asset filename (without extension).
 * @param buffer    Buffer to store the full URL.
 * @param maxlen    Maximum length of the buffer.
 */
stock void Steam_GetGameStoreAsset(const char[] asset, char[] buffer, int maxlen)
{
    Steam_GetStoreAsset(GameInfo_GetAppId(), asset, buffer, maxlen);
}

/**
 * Queries the Steam Web API for app details.
 *
 * @param appid      The AppID to query.
 * @param key        Steam Web API key.
 * @param callback   Callback to receive app details.
 * @param data       Optional data to pass to callback.
 */
stock void Steam_GetAppDetails(int appid, const char[] key, AppDetailsCallback callback, any data = 0)
{
    HTTPRequest req = new HTTPRequest("https://api.steampowered.com/ICommunityService/GetApps/v1/");
    req.AppendQueryParam("key", "%s", key);
    req.AppendQueryParam("appids[0]", "%d", appid);

    DataPack pack = new DataPack();
    pack.WriteFunction(callback);
    pack.WriteCell(appid);
    pack.WriteCell(data);

    req.Get(HTTPResponse_GetAppDetails, pack);
}

/**
 * Handles the HTTP response for Steam_GetAppDetails().
 * Calls the user callback with (appid, name, icon, data).
 */
stock void HTTPResponse_GetAppDetails(HTTPResponse response, DataPack pack)
{
    pack.Reset();
    Function callback = pack.ReadFunction();
    int appid = pack.ReadCell();
    any data = pack.ReadCell();
    delete pack;

    char name[128], icon[128];

    if (response.Status == HTTPStatus_OK && response.Data != null)
    {
        JSONObject root = view_as<JSONObject>(response.Data);
        JSONObject responseObj = view_as<JSONObject>(root.Get("response"));
        JSONArray apps = view_as<JSONArray>(responseObj.Get("apps"));
        for (int i = 0; i < apps.Length; i++)
        {
            JSONObject app = view_as<JSONObject>(apps.Get(i));
            if (app.GetInt("appid") == appid)
            {
                app.GetString("name", name, sizeof(name));
                app.GetString("icon", icon, sizeof(icon));
                delete app;
                break;
            }
            delete app;
        }
        delete apps;
        delete responseObj;
        delete root;
    }

    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushCell(appid);
    Call_PushString(name);
    Call_PushString(icon);
    Call_PushCell(data);
    Call_Finish();
}