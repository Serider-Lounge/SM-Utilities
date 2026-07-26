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

methodmap Entity
{
    /**
     * Entity methodmap for generic entity manipulation.
     * Provides property accessors and utility methods for Source entities.
     */
    public Entity(int entity)
    {
        return view_as<Entity>(entity);
    }

    
    /**
     * Gets the entity index.
     *
     * @return Entity index.
     */
    property int index
    {
        public get()
        {
            return view_as<int>(this);
        }
    }

    /** Gets the entity's owner
     * 
     * @return Owner entity index, or -1 if no owner.
     */
    property int owner
    {
        public get()
        {
            static const char sendProps[][32] =
            {
                "m_hOwnerEntity",
                "m_hBuilder",
                "m_hLauncher"
            };
        
            static const char dataProps[][32] =
            {
                "m_hOwner",
                "m_hThrower"
            };
        
	        int owner = -1;
        
            for (int i = 0; i < sizeof(sendProps); i++)
            {
                if (HasEntProp(this.index, Prop_Send, sendProps[i]))
                {
                    owner = GetEntPropEnt(this.index, Prop_Send, sendProps[i]);
                    if (owner != -1 && owner != this.index)
                        return Entity(owner).owner;
                }
            }

            for (int i = 0; i < sizeof(dataProps); i++)
            {
                if (HasEntProp(this.index, Prop_Data, dataProps[i]))
                {
                    owner = GetEntPropEnt(this.index, Prop_Data, dataProps[i]);
                    if (owner != -1 && owner != this.index)
                        return Entity(owner).owner;
                }
            }

            return this.index;
        }
    }

    /**
     * Gets or sets the team number for this entity.
     *
     * @return Team number.
     */
    property int team
    {
        public get()
        {
            return GetClientTeam(this.index);
        }
        public set(int team)
        {
            if (HasEntProp(this.index, Prop_Send, "m_iTeamNum"))
            {
                ChangeClientTeam(this.index, team);
            }
            else
            {
                this.AcceptInput("SetTeam", team);
            }
        }
    }

    /**
     * Gets or sets the skin index for this entity.
     *
     * @return Skin index.
     */
    property int skin
    {
        public get()
        {
            return GetEntProp(this.index, Prop_Send, "m_nSkin");
        }
        public set(int value)
        {
            SetEntProp(this.index, Prop_Send, "m_bForcedSkin", 1);
            SetEntProp(this.index, Prop_Send, "m_nForcedSkin", value);
        }
    }

    /**
     * Gets or sets the gravity multiplier for this entity.
     *
     * @return Gravity value.
     */
    property float gravity
    {
        public get()
        {
            return GetEntPropFloat(this.index, Prop_Send, "m_flGravity");
        }
        public set(float value)
        {
            SetEntPropFloat(this.index, Prop_Send, "m_flGravity", value);
        }
    }

    /**
     * Gets or sets the player's model scale.
     *
     * @return Scale value.
     */
    property float scale
    {
        public get()
        {
            return GetEntPropFloat(this.index, Prop_Send, "m_flModelScale");
        }
        public set(float value)
        {
            SetEntPropFloat(this.index, Prop_Send, "m_flModelScale", value);
        }
    }

    /**
     * Gets or sets the render color (RGB) for this entity as an integer.
     *
     * @return Render color as 0xRRGGBB.
     */
    property int render_color
    {
        public get()
        {
            int red, green, blue, alpha, color;
            GetEntityRenderColor(this.index, red, green, blue, alpha);
            color = (red << 16) | (green << 8) | blue;
            return color;
        }
        public set(int color)
        {
            int red = (color >> 16) & 0xFF;
            int green = (color >> 8) & 0xFF;
            int blue = color & 0xFF;

            SetEntityRenderColor(this.index, red, green, blue, 255);
        }
    }

    /**
     * Sends an input to the entity.
     *
     * @param input     Input name.
     * @param ...       Optional input parameters.
     * @return          True if input was accepted, false otherwise.
     */
    public bool AcceptInput(const char[] input, any ...)
    {
        return AcceptEntityInput(this.index, input);
    }

    /**
     * Gets the classname of the entity.
     *
     * @param buffer    Buffer to store classname.
     * @param maxlen    Maximum length of buffer.
     * @return          True on success, false otherwise.
     */
    public void GetClassname(char[] buffer, int maxlen)
    {
        GetEntityClassname(this.index, buffer, maxlen);
    }

    /**
     * Sets the model for the entity.
     *
     * @param model     Model path.
     * @param ...       Optional input parameters.
     * @return          True if input was accepted, false otherwise.
     */
    public bool SetModel(const char[] model, any ...)
    {
        return this.AcceptInput("SetModel", model);
    }

    /**
     * Gets the model name of the entity.
     *
     * @param buffer    Buffer to store model name.
     * @param maxlen    Maximum length of buffer.
     * @return          True on success, false otherwise.
     */
    public bool GetModelName(char[] buffer, int maxlen)
    {
        return GetEntPropString(this.index, Prop_Data, "m_ModelName", buffer, maxlen);
    }
}

methodmap NavMesh
{
    /**
     * Get the amount of navigation areas.
     * 
     * @return  Nav area count.
     */
    public static int GetNavAreaCount()
    {
        int ent = CreateEntityByName("info_target");

        SetVariantString("NetProps.SetPropInt(self, \"m_spawnflags\", NavMesh.GetNavAreaCount())");
        AcceptEntityInput(ent, "RunScriptCode");

        int areaCount = GetEntProp(ent, Prop_Data, "m_spawnflags");
            
        RemoveEntity(ent);
        return areaCount;
    }

    /**
     * Check if navigation meshes are present.
     * 
     * @return True if GetNavAreaCount() > 0, false otherwise.
     */
    public static bool IsLoaded()
    {
        return NavMesh.GetNavAreaCount() > 0;
    }

    /**
     * Check if <mapname>.nav exists.
     * 
     * @return True if <mapname>.nav is present
     */
    public static bool FileExists()
    {
        char mapName[96], mapDisplayName[64];
        GetCurrentMap(mapName, sizeof(mapName));
        GetMapDisplayName(mapName, mapDisplayName, sizeof(mapDisplayName));

        char navPath[PLATFORM_MAX_PATH];
        Format(navPath, sizeof(navPath), "maps/%s.nav", mapName);

        File file = OpenFile(navPath, "r", true);

        bool fileExists = (file != null);
        delete file;

        return fileExists;
    }
}

/**
 * Displays a text message above an entity.
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
stock int DisplayText(int entity, color[4] = {255, 255, 255, 255}, const char[] message = "", int font = 0, float offset[3] = {0.0, 0.0, 0.0}, int size = 8, const char[] parent = "head")
{
    if (entity == -1 || !IsValidEntity(entity))
    {
        return -1;
    }

    int point_worldtext = CreateEntityByName("point_worldtext");
    if (point_worldtext == -1)
    {
        return -1;
    }

    char colorString[32];
    Format(colorString, sizeof(colorString), "%d %d %d %d", color[0], color[1], color[2], color[3]);

    char text[64];
    if (message[0] != '\0')
    {
        strcopy(text, sizeof(text), message);
    }
    else
    {
        strcopy(text, sizeof(text), "Leader");
    }

    DispatchKeyValue(point_worldtext, "message", text);
    char fontString[16];
    IntToString(font, fontString, sizeof(fontString));
    DispatchKeyValue(point_worldtext, "font", fontString);
    char textsize[16];
    IntToString(size, textsize, sizeof(textsize));
    DispatchKeyValue(point_worldtext, "textsize", textsize);
    DispatchKeyValue(point_worldtext, "orientation", "1");

    float origin[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
    origin[0] += offset[0];
    origin[1] += offset[1];
    origin[2] += offset[2];
    TeleportEntity(point_worldtext, origin, NULL_VECTOR, NULL_VECTOR);

    DispatchSpawn(point_worldtext);
    ActivateEntity(point_worldtext);

    SetVariantString(colorString);
    AcceptEntityInput(point_worldtext, "SetColor");

    SetVariantString("!activator");
    AcceptEntityInput(point_worldtext, "SetParent", entity);

    if (entity > 0 && entity <= MaxClients)
    {
        SetVariantString(parent);
        AcceptEntityInput(point_worldtext, "SetParentAttachmentMaintainOffset");
    }

    return point_worldtext;
}