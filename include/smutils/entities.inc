#include <sdktools>

enum
{
    COLLISION_GROUP_NONE,
    COLLISION_GROUP_DEBRIS,
    COLLISION_GROUP_DEBRIS_TRIGGER,
    COLLISION_GROUP_INTERACTIVE_DEBRIS,
    COLLISION_GROUP_INTERACTIVE,
    COLLISION_GROUP_PLAYER,
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,
    COLLISION_GROUP_NPC,
    COLLISION_GROUP_IN_VEHICLE,
    COLLISION_GROUP_WEAPON,
    COLLISION_GROUP_VEHICLE_CLIP,
    COLLISION_GROUP_PROJECTILE,
    COLLISION_GROUP_DOOR_BLOCKER,
    COLLISION_GROUP_PASSABLE_DOOR,
    COLLISION_GROUP_DISSOLVING,
    COLLISION_GROUP_PUSHAWAY,
    COLLISION_GROUP_NPC_ACTOR,
    COLLISION_GROUP_NPC_SCRIPTED,

    // Team Fortress 2
    TFCOLLISION_GROUP_GRENADES,
    TFCOLLISION_GROUP_OBJECT,
    TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT,
    TFCOLLISION_GROUP_COMBATOBJECT,
    TFCOLLISION_GROUP_ROCKETS,
    TFCOLLISION_GROUP_RESPAWNROOMS,
    TFCOLLISION_GROUP_PUMPKIN_BOMB,
    TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS
}

class Entity
{
    private int index_;

    Entity(int index)
    {
        this.index_ = index;
    }

    property int index
    {
        get()
        {
            return this.index_;
        }
    }

    property int ref
    {
        get()
        {
            return EntIndexToEntRef(this.index_);
        }
    }
    property int owner
    {
        get()
        {
            static const char sendProps[][] =
            {
                "m_hOwnerEntity",
                "m_hBuilder",
                "m_hLauncher"
            };

            static const char dataProps[][] =
            {
                "m_hOwner",
                "m_hThrower"
            };

            int owner = this.index_;
            bool changed = true;

            while (changed)
            {
                changed = false;

                for (int i = 0; i < sendProps.size; i++)
                {
                    if (HasEntProp(owner, Prop_Send, sendProps[i]))
                    {
                        let parent = GetEntPropEnt(owner, Prop_Send, sendProps[i]);
                        if (parent != -1 && parent != owner)
                        {
                            owner = parent;
                            changed = true;
                            break;
                        }
                    }
                }

                if (changed)
                    continue;

                for (int i = 0; i < dataProps.size; i++)
                {
                    if (HasEntProp(owner, Prop_Data, dataProps[i]))
                    {
                        let parent = GetEntPropEnt(owner, Prop_Data, dataProps[i]);
                        if (parent != -1 && parent != owner)
                        {
                            owner = parent;
                            changed = true;
                            break;
                        }
                    }
                }
            }

            return owner;
        }
    }

    property int team
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Data, "m_iTeamNum");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Data, "m_iTeamNum", value);
        }
    }

    property int skin
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Send, "m_nSkin");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Send, "m_bForcedSkin", 1);
            SetEntProp(this.index_, Prop_Send, "m_nForcedSkin", value);
        }
    }

    property float gravity
    {
        get()
        {
            return GetEntPropFloat(this.index_, Prop_Send, "m_flGravity");
        }
        set(float value)
        {
            SetEntPropFloat(this.index_, Prop_Send, "m_flGravity", value);
        }
    }

    property float scale
    {
        get()
        {
            return GetEntPropFloat(this.index_, Prop_Send, "m_flModelScale");
        }
        set(float value)
        {
            SetEntPropFloat(this.index_, Prop_Send, "m_flModelScale", value);
        }
    }

    property int render_color
    {
        get()
        {
            int red, green, blue, alpha;
            GetEntityRenderColor(this.index_, red, green, blue, alpha);
            return (red << 16) | (green << 8) | blue;
        }
        set(int color)
        {
            int red = (color >> 16) & 0xFF;
            int green = (color >> 8) & 0xFF;
            int blue = color & 0xFF;
            SetEntityRenderColor(this.index_, red, green, blue, 255);
        }
    }

    property int health
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Send, "m_iHealth");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Send, "m_iHealth", value);
        }
    }

    property int max_health
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Data, "m_iMaxHealth");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Data, "m_iMaxHealth", value);
        }
    }

    property int armor
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Data, "m_ArmorValue");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Data, "m_ArmorValue", value);
        }
    }

    property int max_armor
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Data, "m_iMaxArmor");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Data, "m_iMaxArmor", value);
        }
    }

    property int hidehud
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Send, "m_iHideHUD");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Send, "m_iHideHUD", value);
        }
    }

    property int collision_group
    {
        get()
        {
            return GetEntProp(this.index_, Prop_Data, "m_CollisionGroup");
        }
        set(int value)
        {
            SetEntProp(this.index_, Prop_Data, "m_CollisionGroup", value);
        }
    }

    bool IsValid()
    {
        return IsValidEntity(this.index_);
    }

    bool AcceptInput(const char[] input)
    {
        return AcceptEntityInput(this.index_, input);
    }

    char[] GetClassname()
    {
        char buffer[128];
        GetEntityClassname(this.index_, buffer, sizeof(buffer));

        int size = strlen(buffer) + 1;
        char[] classname = new char[size];
        strcopy(classname, classname.size, buffer);
        return classname;
    }

    void SetModel(const char[] model)
    {
        SetEntityModel(this.index_, model);
    }

    bool GetModelName(char[] buffer, int maxlen)
    {
        return GetEntPropString(this.index_, Prop_Data, "m_ModelName", buffer, maxlen);
    }

    bool Spawn()
    {
        return DispatchSpawn(this.index_);
    }

    void Activate()
    {
        ActivateEntity(this.index_);
    }

    void Remove()
    {
        RemoveEntity(this.index_);
    }

    void Teleport(const float origin[3] = NULL_VECTOR, const float angles[3] = NULL_VECTOR, const float velocity[3] = NULL_VECTOR)
    {
        TeleportEntity(this.index_, origin, angles, velocity);
    }

    void GetOrigin(float vec[3])
    {
        GetEntPropVector(this.index_, Prop_Send, "m_vecOrigin", vec);
    }

    void SetOrigin(const float vec[3])
    {
        SetEntPropVector(this.index_, Prop_Send, "m_vecOrigin", vec);
    }

    bool AcceptInputInt(const char[] input, int value)
    {
        SetVariantInt(value);
        return AcceptEntityInput(this.index_, input);
    }

    bool AcceptInputString(const char[] input, const char[] value)
    {
        SetVariantString(value);
        return AcceptEntityInput(this.index_, input);
    }

    int GetProp(PropType type, const char[] prop, int size = 4, int element = 0)
    {
        return GetEntProp(this.index_, type, prop, size, element);
    }

    void SetProp(PropType type, const char[] prop, any value, int size = 4, int element = 0)
    {
        SetEntProp(this.index_, type, prop, value, size, element);
    }

    float GetPropFloat(PropType type, const char[] prop, int element = 0)
    {
        return GetEntPropFloat(this.index_, type, prop, element);
    }

    void SetPropFloat(PropType type, const char[] prop, float value, int element = 0)
    {
        SetEntPropFloat(this.index_, type, prop, value, element);
    }

    int GetPropEnt(PropType type, const char[] prop, int element = 0)
    {
        return GetEntPropEnt(this.index_, type, prop, element);
    }

    void GetPropVector(PropType type, const char[] prop, float vec[3], int element = 0)
    {
        GetEntPropVector(this.index_, type, prop, vec, element);
    }

    void SetPropVector(PropType type, const char[] prop, const float vec[3], int element = 0)
    {
        SetEntPropVector(this.index_, type, prop, vec, element);
    }

    int GetPropString(PropType type, const char[] prop, char[] buffer, int maxlen, int element = 0)
    {
        return GetEntPropString(this.index_, type, prop, buffer, maxlen, element);
    }

    int SetPropString(PropType type, const char[] prop, const char[] buffer, int element = 0)
    {
        return SetEntPropString(this.index_, type, prop, buffer, element);
    }
}

/**
 * Checks if a team is active.
 * @note This function should not be called before OnMapStart.
 * 
 * @param team  Team index.
 * @return      True if the team is active, false otherwise.
 */
stock bool IsTeamActive(int team)
{
    static bool supported = false;

    if (!supported)
    {
        supported = FindSendPropInfo("CTFGameRulesProxy", "m_iTeamsActive") > 0;
    }

    if (supported)
    {
        return view_as<bool>(GameRules_GetProp("m_iTeamsActive") & (1 << (team - 2)));
    }

    static int teamCount = 0;
    
    if (teamCount == 0)
    {
        teamCount = GetTeamCount();
    }

    return team > 1 && team < teamCount;
}

/**
 * Returns the total number of active teams in a game.
 * @note This function should not be called before OnMapStart.
 *
 * @return  Total number of active teams.
 */
stock int GetActiveTeamCount()
{
    static bool supported = false;

    if (!supported)
    {
        supported = FindSendPropInfo("CTFGameRulesProxy", "m_iTeamsActive") > 0;
    }

    static int teamCount = 0;

    if (teamCount == 0)
    {
        teamCount = GetTeamCount();
    }

    if (supported)
    {
        int count = 0;
        for (int i = 2; i < teamCount; i++)
        {
            if (IsTeamActive(i))
                count++;
        }
        return count;
    }

    return teamCount - 2;
}

/**
 * Checks if an entity is stuck.
 * 
 * @param entity    Entity index.
 * @return          True if the entity is stuck, false otherwise.
 */
stock bool IsEntityStuck(int entity)
{
	float origin[3], mins[3], maxs[3];

    let ent = new Entity(entity);
    ent.GetPropVector(Prop_Send, "m_vecOrigin", origin);
    ent.GetPropVector(Prop_Send, "m_vecMins", mins);
    ent.GetPropVector(Prop_Send, "m_vecMaxs", maxs);

    TR_TraceHullFilter(origin, origin, mins, maxs, MASK_SOLID, TR_FilterSelf, entity);
	return TR_DidHit();
}

static bool TR_FilterSelf(int entity, int contentsMask, int other)
{
	return entity != other;
}
/**
 * Displays a text message above an entity using a point_worldtext.
 *
 * @param entity    Entity index to display text above.
 * @param color     Text color as an array of 4 integers (RGBA).
 * @param message   Text message to display.
 * @param font      Font to use for the text.
 * @param offset    Offset from the entity's origin to display the text at.
 * @param size      Text size.
 * @param parent    Parent attachment for the text.
 * @return          Entity index of the created point_worldtext, or -1 on failure.
 */
stock int DisplayText(int entity, int color[4] = {255, 255, 255, 255}, const char[] message = "", int font = 0, float offset[3] = {0.0, 0.0, 0.0}, int size = 8, const char[] parent = "head")
{
    let ent = new Entity(entity);
    if (!ent.IsValid())
        return -1;

    let point_worldtext = new Entity(CreateEntityByName("point_worldtext"));
    if (point_worldtext.index == -1)
        return -1;

    char colorString[32];
    Format(colorString, colorString.size, "%d %d %d %d", color[0], color[1], color[2], color[3]);

    char text[64];
    if (message[0] != '\0')
        strcopy(text, text.size, message);
    else
        strcopy(text, text.size, "Leader");

    DispatchKeyValue(point_worldtext.index, "message", text);

    char fontString[16];
    IntToString(font, fontString, fontString.size);
    DispatchKeyValue(point_worldtext.index, "font", fontString);

    char textsize[16];
    IntToString(size, textsize, textsize.size);
    DispatchKeyValue(point_worldtext.index, "textsize", textsize);
    DispatchKeyValue(point_worldtext.index, "orientation", "1");

    float origin[3];
    ent.GetOrigin(origin);
    origin[0] += offset[0];
    origin[1] += offset[1];
    origin[2] += offset[2];
    point_worldtext.Teleport(origin);

    point_worldtext.Spawn();
    point_worldtext.Activate();

    point_worldtext.AcceptInputString("SetColor", colorString);

    SetVariantString("!activator");
    AcceptEntityInput(point_worldtext.index, "SetParent", entity);

    if (entity > 0 && entity <= MaxClients)
    {
        SetVariantString(parent);
        AcceptEntityInput(point_worldtext.index, "SetParentAttachmentMaintainOffset");
    }

    return point_worldtext.index;
}