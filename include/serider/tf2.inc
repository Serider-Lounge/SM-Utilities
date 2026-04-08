#include <tf2_stocks>

// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/Script_Functions/Constants#FHideHUD
#define HIDEHUD_WEAPONSELECTION      (1<<0)
#define HIDEHUD_FLASHLIGHT           (1<<1)
#define HIDEHUD_ALL                  (1<<2)
#define HIDEHUD_HEALTH               (1<<3)
#define HIDEHUD_PLAYERDEAD           (1<<4)
#define HIDEHUD_BITCOUNT             18
#define HIDEHUD_NEEDSUIT             (1<<5)
#define HIDEHUD_MISCSTATUS           (1<<6)
#define HIDEHUD_CHAT                 (1<<7)
#define HIDEHUD_CROSSHAIR            (1<<8)
#define HIDEHUD_VEHICLE_CROSSHAIR    (1<<9)
#define HIDEHUD_INVEHICLE            (1<<10)
#define HIDEHUD_BONUS_PROGRESS       (1<<11)
#define HIDEHUD_BUILDING_STATUS      (1<<12)
#define HIDEHUD_CLOAK_AND_FEIGN      (1<<13)
#define HIDEHUD_PIPES_AND_CHARGE     (1<<14)
#define HIDEHUD_METAL                (1<<15)
#define HIDEHUD_TARGET_ID            (1<<16)
#define HIDEHUD_MATCH_STATUS         (1<<17)

// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/Script_Functions/Constants#LIFE
enum LifeState
{
    Alive,
    Dying,
    Dead,
    Respawnable,
    Discardbody
};

enum
{
    TF_AMMO_DUMMY,
    TF_AMMO_PRIMARY,
    TF_AMMO_SECONDARY,
    TF_AMMO_METAL,
    TF_AMMO_GRENADES1,
    TF_AMMO_GRENADES2,
    TF_AMMO_GRENADES3,
    TF_AMMO_COUNT
};

static const char ammo_names[TF_AMMO_COUNT][32] =
{
    "TF_AMMO_DUMMY",
    "TF_AMMO_PRIMARY",
    "TF_AMMO_SECONDARY",
    "TF_AMMO_METAL",
    "TF_AMMO_GRENADES1",
    "TF_AMMO_GRENADES2",
    "TF_AMMO_GRENADES3"
};

static const int ammo_types[TF_AMMO_COUNT] =
{
    TF_AMMO_DUMMY,
    TF_AMMO_PRIMARY,
    TF_AMMO_SECONDARY,
    TF_AMMO_METAL,
    TF_AMMO_GRENADES1,
    TF_AMMO_GRENADES2,
    TF_AMMO_GRENADES3
};

const TFClassType TFClass_Civilian = view_as<TFClassType>(10);

methodmap TFPlayer < Entity
{
    /**
     * Creates a TFPlayer instance from a client index.
     *
     * @param client    Client index.
     */
    public TFPlayer(int client)
    {
        return view_as<TFPlayer>(client);
    }

    /**
     * Gets the client index for this player.
     *
     * @return Client index.
     */
    property int index
    {
        public get()
        {
            return view_as<int>(this);
        }
    }

    /**
     * Gets the user ID for this player.
     *
     * @return User ID.
     */
    property int userid
    {
        public get()
        {
            return GetClientUserId(this.index);
        }
    }

    /**
     * Gets or sets the player's current health.
     *
     * @return Health value.
     */
    property int health
    {
        public get()
        {
            return GetEntProp(this.index, Prop_Send, "m_iHealth");
        }
        public set(int value)
        {
            SetEntProp(this.index, Prop_Send, "m_iHealth", value);
        }
    }

    /**
     * Gets or sets the player's maximum health.
     *
     * @return Max health value.
     */
    property int max_health
    {
        public get()
        {
            return GetEntProp(this.index, Prop_Data, "m_iMaxHealth");
        }
        public set(int value)
        {
            SetVariantInt(value);
            AcceptEntityInput(this.index, "SetMaxHealth");
        }
    }

    /**
     * Gets or sets the player's armor.
     * 
     * @return Armor value.
     */
    property int armor
    {
        public get()
        {
            return GetEntProp(this.index, Prop_Data, "m_ArmorValue");
        }
        public set(int value)
        {
            SetEntProp(this.index, Prop_Data, "m_ArmorValue", value);
        }
    }

    /**
     * Gets or sets the player's currency (Mann vs. Machine).
     *
     * @return Currency value.
     */
    property int currency
    {
        public get()
        {
            return GetEntProp(this.index, Prop_Send, "m_nCurrency");
        }
        public set(int value)
        {
            SetEntProp(this.index, Prop_Send, "m_nCurrency", value < 0 ? 0 : value > 30000 ? 30000 : value);
        }
    }

    /**
     * Gets or sets the player's team.
     *
     * @return Team value.
     */
    property TFTeam team
    {
        public get()
        {
            return TF2_GetClientTeam(this.index);
        }
        public set(TFTeam team)
        {
            if (this.team == team)
                return;

            int lifeState = GetEntProp(this.index, Prop_Send, "m_lifeState");
            SetEntProp(this.index, Prop_Send, "m_lifeState", view_as<LifeState>(Dead));
            TF2_ChangeClientTeam(this.index, team);
            SetEntProp(this.index, Prop_Send, "m_lifeState", lifeState);
        }
    }

    /**
     * Gets or sets the player's class.
     *
     * @return Class type.
     */
    property TFClassType class
    {
        public get()
        {
            return view_as<TFClassType>(GetEntProp(this.index, Prop_Send, "m_iClass"));
        }
        public set(TFClassType classType)
        {
            SetEntProp(this.index, Prop_Send, "m_iClass", view_as<int>(classType));
            SetEntProp(this.index, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(classType));
        }
    }

    /**
     * Gets the player's active conditions as a bitmask.
     * 
     * @return Bitmask of active conditions.
     */
    property TFCond condition
    {
        public get()
        {
            return view_as<TFCond>(GetEntProp(this.index, Prop_Send, "m_nPlayerCond")|GetEntProp(this.index, Prop_Send, "_condition_bits")|GetEntProp(this.index, Prop_Send, "m_nPlayerCondEx")<<32|GetEntProp(this.index, Prop_Send, "m_nPlayerCondEx2")<<64|GetEntProp(this.index, Prop_Send, "m_nPlayerCondEx3")<<96|GetEntProp(this.index, Prop_Send, "m_nPlayerCondEx4")<<128);
        }
    }

    /**
     * Gets or sets the player's render color (RGB as int).
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
            int wearable = -1;
            while ((wearable = FindEntityByClassname(wearable, "tf_wearable")) != -1)
            {
                if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") == this.index)
                {
                    SetEntProp(wearable, Prop_Send, "m_nRenderMode", GetEntProp(this.index, Prop_Send, "m_nRenderMode"));
                    SetEntityRenderColor(wearable, red, green, blue, 255);
                }
            }
        }
    }

    /**
     * Gets or sets whether the player has a boss health bar.
     *
     * @return True if enabled, false otherwise.
     */
    property bool boss_health_bar
    {
        public get()
        {
            return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_bUseBossHealthBar"));
        }
        public set(bool state)
        {
            SetEntProp(this.index, Prop_Send, "m_bUseBossHealthBar", state);
        }
    }

    /**
     * Gets or sets whether the player is glowing.
     *
     * @return True if glowing, false otherwise.
     */
    property bool glow
    {
        public get()
        {
            return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_bGlowEnabled"));
        }
        public set(bool state)
        {
            SetEntProp(this.index, Prop_Send, "m_bGlowEnabled", state);
        }
    }


    /**
     * Gets the player's class name as a string.
     *
     * @param buffer    Buffer to store class name.
     * @param maxlen    Maximum length of buffer.
     */
    public void GetClassName(char[] buffer, int maxlen)
    {
        switch (this.class)
        {
            case TFClass_Scout:     strcopy(buffer, maxlen, "scout");
            case TFClass_Sniper:    strcopy(buffer, maxlen, "sniper");
            case TFClass_Soldier:   strcopy(buffer, maxlen, "soldier");
            case TFClass_DemoMan:   strcopy(buffer, maxlen, "demo");
            case TFClass_Medic:     strcopy(buffer, maxlen, "medic");
            case TFClass_Heavy:     strcopy(buffer, maxlen, "heavy");
            case TFClass_Pyro:      strcopy(buffer, maxlen, "pyro");
            case TFClass_Spy:       strcopy(buffer, maxlen, "spy");
            case TFClass_Engineer:  strcopy(buffer, maxlen, "engineer");
            case TFClass_Civilian:  strcopy(buffer, maxlen, "civilian");
        }
    }

    /**
     * Returns true if the player is an arena spectator.
     *
     * @return True if arena spectator, false otherwise.
     */
    public bool IsArenaSpectator()
    {
        return view_as<bool>(GetEntProp(this.index, Prop_Send, "m_bArenaSpectator"));
    }

    /**
     * Sets a custom model for the player.
     *
     * @param model     Model path.
     * @param ...       Optional input parameters.
     * @return          True if input was accepted, false otherwise.
     */
    public bool SetCustomModel(const char[] model, any ...)
    {
        if (!PrecacheModel(model)) PrecacheModel(model);
        SetVariantString(model);
        return this.AcceptInput("SetCustomModelWithClassAnimations");
    }

    /**
     * Runs script code on the player entity.
     *
     * @param script    Script code to run.
     * @return          True if input was accepted, false otherwise.
     */
    public bool RunScriptCode(const char[] script)
    {
        int len = strlen(script) + 2;
        char[] buffer = new char[len];
        strcopy(buffer, len, script);
        SetVariantString(buffer);
        return this.AcceptInput("RunScriptCode");
    }

    /**
     * Forces the player to respawn.
     *
     * @return True if input was accepted, false otherwise.
     */
    public bool ForceRespawn()
    {
        SetVariantString("self.ForceRespawn()");
        return this.AcceptInput("RunScriptCode");
    }

    /**
     * Adds an attribute to the player.
     *
     * @param name      Attribute name.
     * @param value     Attribute value (default 1.0).
     * @param duration  Duration in seconds (default -1.0 for permanent).
     * @return          True if input was accepted, false otherwise.
     */
    public bool AddAttribute(const char[] name, float value = 1.0, float duration = -1.0)
    {
        int len = strlen(name) + 64;
        char[] buffer = new char[len];
        Format(buffer, len, "self.Add%sAttribute(\"%s\", %f, %f)", 0 < this.index <= MaxClients ? "Custom" : "", name, value, duration);
        return this.RunScriptCode(buffer);
    }

    /**
     * Removes an attribute from the player.
     *
     * @param name      Attribute name.
     * @return          True if input was accepted, false otherwise.
     */
    public bool RemoveAttribute(const char[] name)
    {
        int len = strlen(name) + 64;
        char[] buffer = new char[len];
        Format(buffer, len, "self.Remove%sAttribute(\"%s\")", 0 < this.index <= MaxClients ? "Custom" : "", name);
        return this.RunScriptCode(buffer);
    }

    /**
     * Gets an attribute value from the player.
     *
     * @param name           Attribute name.
     * @param default_value  Default value if not set.
     * @return               Attribute value.
     */
    public float GetAttribute(const char[] name, float default_value = 1.0)
    {
        int len = strlen(name) + 128;
        char[] buffer = new char[len];
        Format(buffer, len, "NetProps.SetPropFloat(self, \"m_flPoseParameter\", self.Get%sAttribute(\"%s\", %f))", 0 < this.index <= MaxClients ? "Custom" : "", name, default_value);
        this.RunScriptCode(buffer);
        return GetEntPropFloat(this.index, Prop_Data, "m_flPoseParameter");
    }

    /**
     * Drops the flag the player is carrying.
     *
     * @param silent    If true, drop silently.
     * @return          True if input was accepted, false otherwise.
     */
    public bool DropFlag(bool silent = false)
    {
        char buffer[32];
        Format(buffer, sizeof(buffer), "self.DropFlag(%b)", silent);
        return this.RunScriptCode(buffer);
    }

    /**
     * Sets forced taunt camera for the player.
     *
     * @param toggle    Enable or disable forced taunt cam (default true).
     * @return          True if input was accepted, false otherwise.
     */
    public bool SetForcedTauntCam(bool toggle = true)
    {
        SetVariantInt(view_as<int>(toggle));
        return this.AcceptInput("SetForcedTauntCam");
    }

    /**
     * Adds HUD hide flags for the player.
     *
     * @param flags     HUD hide flags to add.
     * @return          True if input was accepted, false otherwise.
     */
    public bool AddHudHideFlags(int flags)
    {
        char buffer[48];
        Format(buffer, sizeof(buffer), "self.AddHudHideFlags(%d)", flags);
        return this.RunScriptCode(buffer);
    }

    /**
     * Cancels the player's taunt.
     *
     * @return True if input was accepted, false otherwise.
     */
    public bool CancelTaunt()
    {
        char buffer[24];
        Format(buffer, sizeof(buffer), "self.CancelTaunt()");
        return this.RunScriptCode(buffer);
    }

    /**
     * Adds a condition to the player.
     *
     * @param condition     Condition index.
     * @param duration      Duration in seconds (default -1.0 for permanent).
     * @return              True if input was accepted, false otherwise.
     */
    public bool AddCond(TFCond condition, float duration = -1.0)
    {
        char buffer[64];
        Format(buffer, sizeof(buffer), "self.AddCondEx(%d, %f, null)", condition, duration);
        return this.RunScriptCode(buffer);
    }

    /**
     * Removes a condition from the player.
     *
     * @param condition     Condition index.
     * @return              True if input was accepted, false otherwise.
     */
    public bool RemoveCond(TFCond condition)
    {
        char buffer[48];
        Format(buffer, sizeof(buffer), "self.RemoveCond(%d)", condition);
        return this.RunScriptCode(buffer);
    }

    /**
     * Check whether or not a condition is set on a player
     *
     * @param client        Player's index.
     * @param cond          TFCond constant
     * @return              True if set, false otherwise
     */
    public bool IsInCondition(TFCond condition)
    {
        return TF2_IsPlayerInCondition(this.index, condition);
    }

    /**
     * Regenerates the player's health and ammo.
     * 
     * @param refill_health_ammo    If true, refills health and ammo.
     * @return                      True if input was accepted, false otherwise.
     */
    public bool Regenerate(bool refill_health_ammo)
    {
        char buffer[32];
        Format(buffer, sizeof(buffer), "self.Regenerate(%b)", refill_health_ammo);
        return this.RunScriptCode(buffer);
    }

    /**
     * Gives a weapon to the player by item index or classname.
     * 
     * @param index         Item index from items_game.txt (ignored if classname is provided).
     * @param classname     Optional item classname (e.g. "tf_weapon_rocketlauncher"). If provided, takes precedence over index.
     * @return              True if weapon was successfully given, false otherwise.
     */
    public bool GiveWeapon(int index, const char[] classname = "")
    {
        if (this.index <= 0 || this.index > MaxClients || !IsClientInGame(this.index))
            return false;

        char item_class[64];
        int slot = -1;
        char item_slot[32];
        if (classname[0] != '\0')
        {
            strcopy(item_class, sizeof(item_class), classname);
        }
        else
        {
            char itemKey[16];
            IntToString(index, itemKey, sizeof(itemKey));

            char paths[3][PLATFORM_MAX_PATH];
            strcopy(paths[0], sizeof(paths[]), "scripts/items/items_game.txt");
            
            char mapName[64], mapPath[PLATFORM_MAX_PATH];
            GetCurrentMap(mapName, sizeof(mapName));
            Format(mapPath, sizeof(mapPath), "scripts/items/%s_items_game.txt", mapName);
            strcopy(paths[1], sizeof(paths[]), mapPath);
            
            strcopy(paths[2], sizeof(paths[]), "scripts/items/custom_items_game.txt");

            bool found = false;
            int bucket = -1;
            for (int i = 0; i < 3 && !found; i++)
            {
                KeyValues kv = new KeyValues("items_game");
                if (!kv.ImportFromFile(paths[i]))
                {
                    delete kv;
                    continue;
                }

                if (kv.JumpToKey("items") && kv.JumpToKey(itemKey))
                {
                    if (kv.GetDataType("prefab") != KvData_None)
                    {
                        kv.GetString("name", item_class, sizeof(item_class));
                    }
                    else
                    {
                        kv.GetString("item_class", item_class, sizeof(item_class));
                    }

                    if (kv.GetDataType("bucket") != KvData_None)
                    {
                        bucket = kv.GetNum("bucket", -1);
                    }
                    else if (kv.GetDataType("item_slot") != KvData_None)
                    {
                        kv.GetString("item_slot", item_slot, sizeof(item_slot));
                    }

                    kv.Rewind();
                    found = true;
                }
                delete kv;
            }

            if (!found || item_class[0] == '\0')
            {
                return false;
            }
        }

        if (bucket != -1)
        {
            slot = bucket;
        }
        else if (item_slot[0] != '\0')
        {
            if (StrEqual(item_slot, "primary"))
            {
                slot = TFWeaponSlot_Primary;
            }
            else if (StrEqual(item_slot, "secondary"))
            {
                slot = TFWeaponSlot_Secondary;
            }
            else if (StrEqual(item_slot, "melee"))
            {
                slot = TFWeaponSlot_Melee;
            }
            else if (StrEqual(item_slot, "grenade"))
            {
                slot = TFWeaponSlot_Grenade;
            }
            else if (StrEqual(item_slot, "building"))
            {
                slot = TFWeaponSlot_Building;
            }
            else if (StrContains(item_slot, "pda") == 0)
            {
                slot = TFWeaponSlot_PDA;
            }
            else if (StrEqual(item_slot, "item1"))
            {
                slot = TFWeaponSlot_Item1;
            }
            else if (StrEqual(item_slot, "item2"))
            {
                slot = TFWeaponSlot_Item2;
            }
        }

        for (int i = 0; i < sizeof(item_class) && item_class[i] != '\0'; i++)
        {
            if (item_class[i] == '_')
                continue;

            item_class[i] = CharToLower(item_class[i]);
        }

        // Cleanup the previous weapon if it shares a slot with the new weapon
        if (slot >= TFWeaponSlot_Primary && slot <= TFWeaponSlot_Item2)
        {
            if (bucket == -1 && (StrContains(item_class, "revolver") != -1 || StrContains(item_class, "tranq") != -1))
            {
                this.RemoveWeapon(TFWeaponSlot_Primary);
            }
            else
            {
                this.RemoveWeapon(slot);
            }
        }

        int weapon = CreateEntityByName(item_class);
        if (weapon == -1 || !IsValidEntity(weapon))
        {
            return false;
        }

        char scriptFile[128];
        Format(scriptFile, sizeof(scriptFile), "scripts/%s.txt", item_class);
        KeyValues kv = new KeyValues("WeaponData");
        if (kv.ImportFromFile(scriptFile))
        {
            int clip_size = kv.GetNum("clip_size", -1);
            int default_clip = kv.GetNum("default_clip", -1);
            int max_ammo = kv.GetNum("MaxAmmo", -1);

            char primary_ammo[32], secondary_ammo[32];
            kv.GetString("primary_ammo", primary_ammo, sizeof(primary_ammo), "None");
            kv.GetString("secondary_ammo", secondary_ammo, sizeof(secondary_ammo), "None");

            if (clip_size != -1)
            {
                SetEntProp(weapon, Prop_Send, "m_iClip1", clip_size);
            }
            else if (default_clip != -1)
            {
                SetEntProp(weapon, Prop_Send, "m_iClip1", default_clip);
            }

            if (max_ammo != -1)
            {
                if (primary_ammo[0] != '\0' && !StrEqual(primary_ammo, "None"))
                {
                    for (int i = 0; i < TF_AMMO_COUNT; i++)
                    {
                        if (StrEqual(primary_ammo, ammo_names[i]))
                        {
                            SetEntProp(this.index, Prop_Data, "m_iAmmo", max_ammo, 4, ammo_types[i]);
                            break;
                        }
                    }
                }
                if (secondary_ammo[0] != '\0' && !StrEqual(secondary_ammo, "None"))
                {
                    for (int i = 0; i < TF_AMMO_COUNT; i++)
                    {
                        if (StrEqual(secondary_ammo, ammo_names[i]))
                        {
                            SetEntProp(this.index, Prop_Data, "m_iAmmo", max_ammo, 4, ammo_types[i]);
                            break;
                        }
                    }
                }
            }
        }
        delete kv;

        SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", index);
        SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 0);
        SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
        SetEntProp(weapon, Prop_Send, "m_bValidatedAttachedEntity", 1);
        SetEntPropEnt(weapon, Prop_Data, "m_hOwner", this.index);

        DispatchSpawn(weapon);

        EquipPlayerWeapon(this.index, weapon);

        return true;
    }

    /**
     * Removes a weapon from this player by slot.
     *
     * @param slot      Weapon slot to remove.
     */
    public void RemoveWeapon(int slot)
    {
        for (int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Item2; i++)
        {
            int weapon = GetEntPropEnt(this.index, Prop_Send, "m_hMyWeapons", i);
            if (weapon == -1 || !IsValidEntity(weapon))
                continue;
            
            if (i != slot)
                continue;

            int wearable = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
            if (wearable != -1 && IsValidEntity(wearable))
            {
                RemoveEntity(wearable);
            }

            wearable = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
            if (wearable != -1 && IsValidEntity(wearable))
            {
                RemoveEntity(wearable);
            }

            RemovePlayerItem(this.index, weapon);
            RemoveEntity(weapon);
        }
    }

    /**
     * Removes all weapons from this player.
     */
    public void RemoveAllWeapons()
    {
        for (int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Item2; i++)
        {
            this.RemoveWeapon(i);
        }
    }

    /**
     * Gets the weapon entity in a slot for this player.
     *
     * @param slot      Weapon slot.
     * @return          Weapon entity index.
     */
    public int GetWeapon(int slot)
    {
        return GetEntPropEnt(this.index, Prop_Send, "m_hMyWeapons", slot);
    }
}