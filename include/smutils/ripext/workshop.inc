class Map
{
    private char[] name;
    private char[] displayName;
    private char[] ugcid;

    Map()
    {
        char mapName[96];
        this.name = GetCurrentMap(mapName, mapName.size);
        if (strncmp(this.name, "workshop/", 9) == 0)
        {
            // Extract UGC ID from 'workshop/<mapname>.ugc<ugcid>'
            int pos = FindCharInString(this.name, '.');
            
            char ugcid[32];
            strcopy(ugcid, sizeof(ugcid), this.name[pos + 4]);
            this.ugcid = ugcid;
        }

        char displayName[64];
        this.displayName = GetMapDisplayName(this.name, displayName, displayName.size);
    }
}

typedef WorkshopDetailsCallback = function void (
    const char[] ugcid,
    const char[] title,
    const char[] preview_url,
    const char[] creator,
    const char[][] tags,
    any data
);

/**
 * Makes an HTTP request to get details about the workshop map.
 * 
 * @param ugcid         UGC ID of the workshop map.
 * @param callback      Callback to receive details.
 * @param data          Data value, if used.
 */
stock void GetWorkshopMapDetails(const char[] ugcid, WorkshopDetailsCallback callback, any data = 0)
{
    HTTPRequest req = new HTTPRequest("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/");
    req.AppendFormParam("itemcount", "1");
    req.AppendFormParam("publishedfileids[0]", ugcid);

    DataPack pack = new DataPack();
    pack.WriteFunction(callback);
    pack.WriteString(ugcid);
    pack.WriteCell(data);

    req.PostForm(HTTPResponse_GetWorkshopDetails, pack);
}

stock void HTTPResponse_GetWorkshopDetails(HTTPResponse response, DataPack pack)
{
    pack.Reset();
    Function callback = pack.ReadFunction();
    char ugcid[PLATFORM_MAX_PATH];
    pack.ReadString(ugcid, sizeof(ugcid));
    any data = pack.ReadCell();
    delete pack;

    char title[256], preview_url[256], creator[64];
    char tags[16][64];

    if (response.Status == HTTPStatus_OK && response.Data != null)
    {
        JSONObject root = view_as<JSONObject>(response.Data);
        JSONObject responseObj = view_as<JSONObject>(root.Get("response"));
        JSONArray details = view_as<JSONArray>(responseObj.Get("publishedfiledetails"));
        if (details.Length > 0)
        {
            JSONObject detail = view_as<JSONObject>(details.Get(0));
            detail.GetString("title", title, sizeof(title));
            detail.GetString("preview_url", preview_url, sizeof(preview_url));
            detail.GetString("creator", creator, sizeof(creator));

            JSONArray tagsArray = view_as<JSONArray>(detail.Get("tags"));
            
            delete tagsArray;
            delete detail;
        }
        delete details;
        delete responseObj;
        delete root;
    }
    else
    {
        strcopy(preview_url, sizeof(preview_url), "https://community.cloudflare.steamstatic.com/public/images/sharedfiles/steam_workshop_default_image.png");
    }

    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushString(ugcid);
    Call_PushString(title);
    Call_PushString(preview_url);
    Call_PushString(creator);
    Call_PushArray(tags, tags.size);
    Call_PushCell(data);
    Call_Finish();
}