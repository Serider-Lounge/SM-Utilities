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

    // TF2
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