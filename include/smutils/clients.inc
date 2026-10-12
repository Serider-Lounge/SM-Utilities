#include <clients>
#include <smutils/entities>

class Player
{
    private Entity entity_;

    Player(int index)
    {
        this.entity_ = new Entity(index);
    }

    property int index
    {
        get()
        {
            return this.entity_.index;
        }
    }

    property int ref
    {
        get()
        {
            return this.entity_.ref;
        }
    }

    property int userid
    {
        get()
        {
            return GetClientUserId(this.index);
        }
    }

    property int collision_group
    {
        get()
        {
            return this.entity_.collision_group;
        }
        set(int value)
        {
            this.entity_.collision_group = value;
        }
    }

    property int owner
    {
        get()
        {
            return this.entity_.owner;
        }
    }

    property int team
    {
        get()
        {
            return this.entity_.team;
        }
        set(int value)
        {
            this.entity_.team = value;
        }
    }

    property int skin
    {
        get()
        {
            return this.entity_.skin;
        }
        set(int value)
        {
            this.entity_.skin = value;
        }
    }

    property float gravity
    {
        get()
        {
            return this.entity_.gravity;
        }
        set(float value)
        {
            this.entity_.gravity = value;
        }
    }

    property float scale
    {
        get()
        {
            return this.entity_.scale;
        }
        set(float value)
        {
            this.entity_.scale = value;
        }
    }

    property int render_color
    {
        get()
        {
            return this.entity_.render_color;
        }
        set(int value)
        {
            this.entity_.render_color = value;
        }
    }

    property int health
    {
        get()
        {
            return this.entity_.health;
        }
        set(int value)
        {
            this.entity_.health = value;
        }
    }

    property int max_health
    {
        get()
        {
            return this.entity_.max_health;
        }
        set(int value)
        {
            this.entity_.max_health = value;
        }
    }

    property int armor
    {
        get()
        {
            return this.entity_.armor;
        }
        set(int value)
        {
            this.entity_.armor = value;
        }
    }

    property int max_armor
    {
        get()
        {
            return this.entity_.max_armor;
        }
        set(int value)
        {
            this.entity_.max_armor = value;
        }
    }

    property float max_speed
    {
        get()
        {
            return GetEntPropFloat(this.index, Prop_Data, "m_flMaxspeed");
        }
        set(float value)
        {
            SetEntPropFloat(this.index, Prop_Send, "m_flMaxspeed", value);
        }
    }

    property int hidehud
    {
        get()
        {
            return this.entity_.hidehud;
        }
        set(int value)
        {
            this.entity_.hidehud = value;
        }
    }

    property int frags
    {
        get()
        {
            return GetClientFrags(this.index);
        }
    }

    property int deaths
    {
        get()
        {
            return GetClientDeaths(this.index);
        }
    }

    property int serial
    {
        get()
        {
            return GetClientSerial(this.index);
        }
    }

    property int data_rate
    {
        get()
        {
            return GetClientDataRate(this.index);
        }
    }

    property float time
    {
        get()
        {
            return GetClientTime(this.index);
        }
    }

    char[] GetName(bool team_color = false) // if true, format as "\x03%s\x01" where %s is the player's name
    {
        char buffer[MAX_NAME_LENGTH];
        GetClientName(this.index, buffer, buffer.size);

        if (team_color)
        {
            int size = strlen(buffer) + 10;
            char[] name = new char[size];
            Format(name, name.size, "\x03%s\x01", buffer);
            return name;
        }

        int size = strlen(buffer) + 1;
        char[] name = new char[size];
        strcopy(name, name.size, buffer);
        return name;
    }

    char[] GetColoredName()
    {
        int size = strlen(this.GetName()) + 10;
        char[] name = new char[size];
        Format(name, name.size, "\x07%06X%s\x01", this.entity_.render_color, this.GetName());
        return name;
    }

    char[] GetSteamID2()
    {
        static char buffer[MAX_AUTHID_LENGTH];
        GetClientAuthId(this.index, AuthId_Steam2, buffer, buffer.size);
        return buffer;
    }

    char[] GetSteamID3()
    {
        static char buffer[MAX_AUTHID_LENGTH];
        GetClientAuthId(this.index, AuthId_Steam3, buffer, buffer.size);
        return buffer;
    }

    char[] GetSteamID64()
    {
        static char buffer[MAX_AUTHID_LENGTH];
        GetClientAuthId(this.index, AuthId_SteamID64, buffer, buffer.size);
        return buffer;
    }

    bool AcceptInput(const char[] input)
    {
        return this.entity_.AcceptInput(input);
    }

    char[] GetClassname()
    {
        return this.entity_.GetClassname();
    }

    void SetModel(const char[] model)
    {
        this.entity_.SetModel(model);
    }

    bool GetModelName(char[] buffer, int maxlen)
    {
        return this.entity_.GetModelName(buffer, maxlen);
    }

    int GetProp(PropType type, const char[] prop, int size = 4, int element = 0)
    {
        return this.entity_.GetProp(type, prop, size, element);
    }

    void SetProp(PropType type, const char[] prop, any value, int size = 4, int element = 0)
    {
        this.entity_.SetProp(type, prop, value, size, element);
    }

    float GetPropFloat(PropType type, const char[] prop, int element = 0)
    {
        return this.entity_.GetPropFloat(type, prop, element);
    }

    void SetPropFloat(PropType type, const char[] prop, float value, int element = 0)
    {
        this.entity_.SetPropFloat(type, prop, value, element);
    }

    int GetPropEnt(PropType type, const char[] prop, int element = 0)
    {
        return this.entity_.GetPropEnt(type, prop, element);
    }

    void GetPropVector(PropType type, const char[] prop, float vec[3], int element = 0)
    {
        this.entity_.GetPropVector(type, prop, vec, element);
    }

    void SetPropVector(PropType type, const char[] prop, const float vec[3], int element = 0)
    {
        this.entity_.SetPropVector(type, prop, vec, element);
    }

    int GetPropString(PropType type, const char[] prop, char[] buffer, int maxlen, int element = 0)
    {
        return this.entity_.GetPropString(type, prop, buffer, maxlen, element);
    }

    int SetPropString(PropType type, const char[] prop, const char[] buffer, int element = 0)
    {
        return this.entity_.SetPropString(type, prop, buffer, element);
    }

    bool Spawn()
    {
        return this.entity_.Spawn();
    }

    void Activate()
    {
        this.entity_.Activate();
    }

    void Remove()
    {
        this.entity_.Remove();
    }

    void Teleport(const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR, const float velocity[3] = NULL_VECTOR)
    {
        this.entity_.Teleport(origin, angles, velocity);
    }

    void GetOrigin(float vec[3])
    {
        this.entity_.GetOrigin(vec);
    }

    void SetOrigin(const float vec[3])
    {
        this.entity_.SetOrigin(vec);
    }

    bool AcceptInputInt(const char[] input, int value)
    {
        return this.entity_.AcceptInputInt(input, value);
    }

    bool AcceptInputString(const char[] input, const char[] value)
    {
        return this.entity_.AcceptInputString(input, value);
    }

    bool IsConnected()
    {
        return IsClientConnected(this.index);
    }

    bool IsInGame()
    {
        return IsClientInGame(this.index);
    }

    bool IsInKickQueue()
    {
        return IsClientInKickQueue(this.index);
    }

    bool IsAuthorized()
    {
        return IsClientAuthorized(this.index);
    }

    bool IsFake()
    {
        return IsFakeClient(this.index);
    }

    bool IsSourceTV()
    {
        return IsClientSourceTV(this.index);
    }

    bool IsReplay()
    {
        return IsClientReplay(this.index);
    }

    bool IsObserver()
    {
        return IsClientObserver(this.index);
    }

    bool IsAlive()
    {
        return IsPlayerAlive(this.index);
    }

    bool IsTimingOut()
    {
        return IsClientTimingOut(this.index);
    }

    int GetIP(char[] buffer, int maxlen, bool removePort = true)
    {
        return GetClientIP(this.index, buffer, maxlen, removePort);
    }

    bool GetInfo(const char[] key, char[] value, int maxlen)
    {
        return GetClientInfo(this.index, key, value, maxlen);
    }

    int GetSteamAccountID(bool validate = true)
    {
        return GetSteamAccountID(this.index, validate);
    }

    void GetWeapon(char[] buffer, int maxlen)
    {
        GetClientWeapon(this.index, buffer, maxlen);
    }

    void GetMaxs(float vec[3])
    {
        GetClientMaxs(this.index, vec);
    }

    void GetMins(float vec[3])
    {
        GetClientMins(this.index, vec);
    }

    void GetAbsAngles(float ang[3])
    {
        GetClientAbsAngles(this.index, ang);
    }

    void GetAbsOrigin(float vec[3])
    {
        GetClientAbsOrigin(this.index, vec);
    }

    float GetLatency(NetFlow flow)
    {
        return GetClientLatency(this.index, flow);
    }

    float GetAvgLatency(NetFlow flow)
    {
        return GetClientAvgLatency(this.index, flow);
    }

    float GetAvgLoss(NetFlow flow)
    {
        return GetClientAvgLoss(this.index, flow);
    }

    float GetAvgChoke(NetFlow flow)
    {
        return GetClientAvgChoke(this.index, flow);
    }

    float GetAvgData(NetFlow flow)
    {
        return GetClientAvgData(this.index, flow);
    }

    float GetAvgPackets(NetFlow flow)
    {
        return GetClientAvgPackets(this.index, flow);
    }

    void Kick(const char[] format = "", any ...)
    {
        KickClient(this.index, format, ...);
    }

    void KickEx(const char[] format = "", any ...)
    {
        KickClientEx(this.index, format, ...);
    }

    void SetAdmin(AdminId id, bool temp = false)
    {
        SetUserAdmin(this.index, id, temp);
    }

    AdminId GetAdmin()
    {
        return GetUserAdmin(this.index);
    }

    void SetFlagBits(int flags)
    {
        SetUserFlagBits(this.index, flags);
    }

    int GetFlagBits()
    {
        return GetUserFlagBits(this.index);
    }

    bool CanTarget(int target)
    {
        return CanUserTarget(this.index, target);
    }

    bool RunAdminCacheChecks()
    {
        return RunAdminCacheChecks(this.index);
    }

    void NotifyPostAdminCheck()
    {
        NotifyPostAdminCheck(this.index);
    }

    void SetFakeClientConVar(const char[] cvar, const char[] value)
    {
        SetFakeClientConVar(this.index, cvar, value);
    }
}

/**
 * Spawns a bot client.
 * 
 * @param name          Player name.
 * @param team          Team name.
 * @param difficulty    Difficulty skill level (set to '-1' for random).
 * @return              Client index of the spawned bot, or '-1' otherwise.
 */
stock int SpawnBot(const char[] name = NULL_STRING, const char[] team = NULL_STRING, int difficulty = 1)
{
    bool[] bots = new bool[MaxClients + 1];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
        {
            bots[i] = true;
        }
    }

    char args[128];
    if (name[0] != '\0')
    {
        StrCat(args, args.size, name);
        StrCat(args, args.size, " ");
    }
    if (team[0] != '\0')
    {
        StrCat(args, args.size, team);
        StrCat(args, args.size, " ");
    }
    if (difficulty >= -1 && difficulty <= 3)
    {
        char botDifficulty[16];
        FormatEx(botDifficulty, botDifficulty.size, "%d", difficulty == -1 ? GetRandomInt(0, 3) : difficulty);
        StrCat(args, args.size, botDifficulty);
        StrCat(args, args.size, " ");
    }

    StrCat(args, args.size, "noquota");

    // https://developer.valvesoftware.com/wiki/Bot#Related_Console_Commands_and_Variables
    char gameDir[32];
    GetGameFolderName(gameDir, gameDir.size);
    ServerCommand("%sbot_add %s", StrEqual(gameDir, "hl2mp") ? "hl2mp_" : "", args);

    int client = -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!bots[i] && IsClientInGame(i) && IsFakeClient(i))
        {
            client = i;
            break;
        }
    }

    return client;
}

/**
 * Gets a player's color based on their Steam ID.
 * 
 * @param client    Client index.
 * @return          Color in HEX (0xRRGGBB).
 */
stock int GetPlayerColorFromSteamID(int client)
{
    char steamID64[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_SteamID64, steamID64, steamID64.size, true))
    {
        return 0xFFFFFF;
    }

    int color = 0;
    for (int i = 0; steamID64[i] != '\0'; i++)
    {
        color = color * 10 + (steamID64[i] - '0');
    }
    return color & 0xFFFFFF;
}