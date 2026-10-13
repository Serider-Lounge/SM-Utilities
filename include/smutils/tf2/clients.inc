#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <smutils/clients>
#include <smutils/entities>

class TFPlayer
{
    private Player player_;

    TFPlayer(int index)
    {
        this.player_ = new Player(index);
    }

    property int index
    {
        get()
        {
            return this.player_.index;
        }
    }

    property int userid
    {
        get()
        {
            return this.player_.userid;
        }
    }

    property int ref
    {
        get()
        {
            return this.player_.ref;
        }
    }

    property int collision_group
    {
        get()
        {
            return this.player_.collision_group;
        }
        set(int value)
        {
            this.player_.collision_group = value;
        }
    }

    char[] GetName(bool team_color = false)
    {
        return this.player_.GetName(team_color);
    }

    char[] GetColoredName()
    {
        return this.player_.GetColoredName();
    }

    char[] GetSteamID2()
    {
        return this.player_.GetSteamID2();
    }

    char[] GetSteamID3()
    {
        return this.player_.GetSteamID3();
    }

    char[] GetSteamID64()
    {
        return this.player_.GetSteamID64();
    }

    property int owner
    {
        get()
        {
            return this.player_.owner;
        }
    }

    property TFTeam team
    {
        get()
        {
            return view_as<TFTeam>(this.player_.team);
        }
        set(TFTeam value)
        {
            this.player_.team = view_as<int>(value);
        }
    }

    property int skin
    {
        get()
        {
            return this.player_.skin;
        }
        set(int value)
        {
            this.player_.skin = value;
        }
    }

    property float gravity
    {
        get()
        {
            return this.player_.gravity;
        }
        set(float value)
        {
            this.player_.gravity = value;
        }
    }

    property float scale
    {
        get()
        {
            return this.player_.scale;
        }
        set(float value)
        {
            this.player_.scale = value;
        }
    }

    property int render_color
    {
        get()
        {
            return this.player_.render_color;
        }
        set(int value)
        {
            this.player_.render_color = value;
        }
    }

    property int health
    {
        get()
        {
            return this.player_.health;
        }
        set(int value) { this.player_.health = value; }
    }

    property int max_health
    {
        get()
        {
            return this.player_.max_health;
        }
        set(int value)
        {
            this.player_.max_health = value;
        }
    }

    property int armor
    {
        get()
        {
            return this.player_.armor;
        }
        set(int value)
        {
            this.player_.armor = value;
        }
    }

    property int max_armor
    {
        get()
        {
            return this.player_.max_armor;
        }
        set(int value)
        {
            this.player_.max_armor = value;
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
            return this.player_.hidehud;
        }
        set(int value)
        {
            this.player_.hidehud = value;
        }
    }

    bool AcceptInput(const char[] input)
    {
        return this.player_.AcceptInput(input);
    }

    char[] GetClassname()
    {
        return this.player_.GetClassname();
    }

    void SetModel(const char[] model)
    {
        this.player_.SetModel(model);
    }

    bool GetModelName(char[] buffer, int maxlen)
    {
        return this.player_.GetModelName(buffer, maxlen);
    }

    int GetProp(PropType type, const char[] prop, int size = 4, int element = 0)
    {
        return this.player_.GetProp(type, prop, size, element);
    }

    void SetProp(PropType type, const char[] prop, any value, int size = 4, int element = 0)
    {
        this.player_.SetProp(type, prop, value, size, element);
    }

    float GetPropFloat(PropType type, const char[] prop, int element = 0)
    {
        return this.player_.GetPropFloat(type, prop, element);
    }

    void SetPropFloat(PropType type, const char[] prop, float value, int element = 0)
    {
        this.player_.SetPropFloat(type, prop, value, element);
    }

    int GetPropEnt(PropType type, const char[] prop, int element = 0)
    {
        return this.player_.GetPropEnt(type, prop, element);
    }

    void GetPropVector(PropType type, const char[] prop, float vec[3], int element = 0)
    {
        this.player_.GetPropVector(type, prop, vec, element);
    }

    void SetPropVector(PropType type, const char[] prop, const float vec[3], int element = 0)
    {
        this.player_.SetPropVector(type, prop, vec, element);
    }

    int GetPropString(PropType type, const char[] prop, char[] buffer, int maxlen, int element = 0)
    {
        return this.player_.GetPropString(type, prop, buffer, maxlen, element);
    }

    int SetPropString(PropType type, const char[] prop, const char[] buffer, int element = 0)
    {
        return this.player_.SetPropString(type, prop, buffer, element);
    }

    bool Spawn()
    {
        return this.player_.Spawn();
    }

    void Activate()
    {
        this.player_.Activate();
    }

    void Remove()
    {
        this.player_.Remove();
    }

    void Teleport(const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR, const float velocity[3] = NULL_VECTOR)
    {
        this.player_.Teleport(origin, angles, velocity);
    }

    void GetOrigin(float vec[3])
    {
        this.player_.GetOrigin(vec);
    }

    void SetOrigin(const float vec[3])
    {
        this.player_.SetOrigin(vec);
    }

    bool AcceptInputInt(const char[] input, int value)
    {
        return this.player_.AcceptInputInt(input, value);
    }

    bool AcceptInputString(const char[] input, const char[] value)
    {
        return this.player_.AcceptInputString(input, value);
    }

    property TFClassType classtype
    {
        get()
        {
            return view_as<TFClassType>(GetEntProp(this.index, Prop_Send, "m_iClass"));
        }
        set(TFClassType value)
        {
            SetEntProp(this.index, Prop_Send, "m_iClass", view_as<int>(value));
            SetEntProp(this.index, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(value));
        }
    }

    property int currency
    {
        get()
        {
            return GetEntProp(this.index, Prop_Send, "m_nCurrency");
        }
        set(int value)
        {
            if (value < 0)
                value = 0;
            else if (value > 30000)
                value = 30000;

            SetEntProp(this.index, Prop_Send, "m_nCurrency", value);
        }
    }

    property int frags
    {
        get()
        {
            return this.player_.frags;
        }
    }

    property int deaths
    {
        get()
        {
            return this.player_.deaths;
        }
    }

    property int serial
    {
        get()
        {
            return this.player_.serial;
        }
    }

    property int data_rate
    {
        get()
        {
            return this.player_.data_rate;
        }
    }

    property float time
    {
        get()
        {
            return this.player_.time;
        }
    }

    void ForceChangeTeam(TFTeam team)
    {
        if (this.team == team)
            return;

        int lifeState = GetEntProp(this.index, Prop_Send, "m_lifeState");
        SetEntProp(this.index, Prop_Send, "m_lifeState", LIFE_DEAD);
            
        // Workaround to brute-force the team change in MVM
        bool isMVM = view_as<bool>(GameRules_GetProp("m_bPlayingMannVsMachine"));
        GameRules_SetProp("m_bPlayingMannVsMachine", false);

        this.player_.team = view_as<int>(team);
            
        SetEntProp(this.index, Prop_Send, "m_lifeState", lifeState);
        GameRules_SetProp("m_bPlayingMannVsMachine", isMVM ? 1 : 0);
    }

    bool IsArenaSpectator()
    {
        return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_bArenaSpectator"));
    }

    bool SetCustomModel(const char[] model)
    {
        if (!PrecacheModel(model))
            PrecacheModel(model);

        SetVariantString(model);
        return this.AcceptInput("SetCustomModelWithClassAnimations");
    }

    bool RunScriptCode(const char[] script)
    {
        SetVariantString(script);
        return this.AcceptInput("RunScriptCode");
    }

    bool ForceRespawn()
    {
        return this.RunScriptCode("self.ForceRespawn()");
    }

    bool AddAttribute(const char[] name, float value = 1.0, float duration = -1.0)
    {
        return TF2_AddAttribute(this.index, name, value, duration);
    }

    bool RemoveAttribute(const char[] name)
    {
        return TF2_RemoveAttribute(this.index, name);
    }

    float GetAttribute(const char[] name, float defaultValue)
    {
        return TF2_GetAttribute(this.index, name, defaultValue);
    }

    bool DropFlag(bool silent = false)
    {
        char script[64];
        Format(script, script.size, "self.DropFlag(%b)", silent);
        return this.RunScriptCode(script);
    }

    bool SetForcedTauntCam(bool toggle = true)
    {
        SetVariantInt(view_as<int>(toggle));
        return this.AcceptInput("SetForcedTauntCam");
    }

    bool AddHudHideFlags(int flags)
    {
        char script[64];
        Format(script, script.size, "self.AddHudHideFlags(%d)", flags);
        return this.RunScriptCode(script);
    }

    bool CancelTaunt()
    {
        return this.RunScriptCode("self.CancelTaunt()");
    }

    bool AddCond(TFCond condition, float duration = TFCondDuration_Infinite)
    {
        char script[128];
        Format(script, script.size, "self.AddCondEx(%d, %f, null)", condition, duration);
        return this.RunScriptCode(script);
    }

    bool RemoveCond(TFCond condition)
    {
        char script[64];
        Format(script, script.size, "self.RemoveCond(%d)", condition);
        return this.RunScriptCode(script);
    }

    bool IsInCondition(TFCond condition)
    {
        return TF2_IsPlayerInCondition(this.index, condition);
    }

    bool Regenerate(bool refillHealthAmmo)
    {
        char script[64];
        Format(script, script.size, "self.Regenerate(%b)", refillHealthAmmo);
        return this.RunScriptCode(script);
    }

    bool IsConnected()
    {
        return this.player_.IsConnected();
    }

    bool IsInGame()
    {
        return this.player_.IsInGame();
    }

    bool IsInKickQueue()
    {
        return this.player_.IsInKickQueue();
    }

    bool IsAuthorized()
    {
        return this.player_.IsAuthorized();
    }

    bool IsFake()
    {
        return this.player_.IsFake();
    }

    bool IsSourceTV()
    {
        return this.player_.IsSourceTV();
    }

    bool IsReplay()
    {
        return this.player_.IsReplay();
    }

    bool IsObserver()
    {
        return this.player_.IsObserver();
    }

    bool IsAlive()
    {
        return this.player_.IsAlive();
    }

    bool IsTimingOut()
    {
        return this.player_.IsTimingOut();
    }

    int GetIP(char[] buffer, int maxlen, bool removePort = true)
    {
        return this.player_.GetIP(buffer, maxlen, removePort);
    }

    bool GetInfo(const char[] key, char[] value, int maxlen)
    {
        return this.player_.GetInfo(key, value, maxlen);
    }

    int GetSteamAccountID(bool validate = true)
    {
        return this.player_.GetSteamAccountID(validate);
    }

    void GetWeapon(char[] buffer, int maxlen)
    {
        this.player_.GetWeapon(buffer, maxlen);
    }

    void GetMaxs(float vec[3])
    {
        this.player_.GetMaxs(vec);
    }

    void GetMins(float vec[3])
    {
        this.player_.GetMins(vec);
    }

    void GetAbsAngles(float ang[3])
    {
        this.player_.GetAbsAngles(ang);
    }

    void GetAbsOrigin(float vec[3])
    {
        this.player_.GetAbsOrigin(vec);
    }

    float GetLatency(NetFlow flow)
    {
        return this.player_.GetLatency(flow);
    }

    float GetAvgLatency(NetFlow flow)
    {
        return this.player_.GetAvgLatency(flow);
    }

    float GetAvgLoss(NetFlow flow)
    {
        return this.player_.GetAvgLoss(flow);
    }

    float GetAvgChoke(NetFlow flow)
    {
        return this.player_.GetAvgChoke(flow);
    }

    float GetAvgData(NetFlow flow)
    {
        return this.player_.GetAvgData(flow);
    }

    float GetAvgPackets(NetFlow flow)
    {
        return this.player_.GetAvgPackets(flow);
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
        this.player_.SetAdmin(id, temp);
    }

    AdminId GetAdmin()
    {
        return this.player_.GetAdmin();
    }

    void SetFlagBits(int flags)
    {
        this.player_.SetFlagBits(flags);
    }

    int GetFlagBits()
    {
        return this.player_.GetFlagBits();
    }

    bool CanTarget(int target)
    {
        return this.player_.CanTarget(target);
    }

    bool RunAdminCacheChecks()
    {
        return this.player_.RunAdminCacheChecks();
    }

    void NotifyPostAdminCheck()
    {
        this.player_.NotifyPostAdminCheck();
    }

    void SetFakeClientConVar(const char[] cvar, const char[] value)
    {
        this.player_.SetFakeClientConVar(cvar, value);
    }
}

/**
 * Spawns a TFBot client.
 * 
 * @param name          Player name.
 * @param team          Team name.
 * @param class         Class identifier (used by 'joinclass' command or as per defined in 'scripts/playerclasses/<class>.ctx').
 * @param difficulty    Difficulty skill level (set to '-1' for random).
 * @return              Client index of the spawned bot, or '-1' otherwise.
 */
stock int TF2_SpawnBot(const char[] name = NULL_STRING, const char[] team = NULL_STRING, const char[] class = NULL_STRING, int difficulty = 1)
{
    bool[] bots = new bool[MaxClients + 1];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
        {
            bots[i] = true;
        }
    }

    static const char botDifficulty[][] =
    {
        "easy",
        "normal",
        "hard",
        "expert"
    };

    let args = new char[128];

    if (class[0] != '\0')
    {
        StrCat(args, args.size, class);
        StrCat(args, args.size, " ");
    }
    if (team[0] != '\0')
    {
        StrCat(args, args.size, team);
        StrCat(args, args.size, " ");
    }
    if (difficulty >= -1 && difficulty <= 3)
    {
        StrCat(args, args.size, difficulty == -1 ? botDifficulty[GetRandomInt(0, 3)] : botDifficulty[difficulty]);
        StrCat(args, args.size, " ");
    }
    if (name[0] != '\0')
    {
        StrCat(args, args.size, name);
        StrCat(args, args.size, " ");
    }

    StrCat(args, args.size, "noquota");

    ServerCommand("tf_bot_add %s", args);

    int tf_bot = -1;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!bots[i] && IsClientInGame(i) && IsFakeClient(i))
        {
            tf_bot = i;
            break;
        }
    }

    return tf_bot;
}