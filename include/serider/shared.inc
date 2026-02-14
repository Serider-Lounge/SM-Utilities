methodmap Entity
{
    public Entity(int entity)
    {
        return view_as<Entity>(entity);
    }

    property int index
    {
        public get()
        {
            return view_as<int>(this);
        }
    }

    property int userid
    {
        public get()
        {
            return GetClientUserId(this.index);
        }
    }

    property int team
    {
        public get()
        {
            return GetClientTeam(this.index);
        }
        public set(int team)
        {
            ChangeClientTeam(this.index, team);
        }
    }

    property int skin
    {
        public get()
        {
            return GetEntProp(this.index, Prop_Send, "m_nForcedSkin");
        }
        public set(int value)
        {
            SetEntProp(this.index, Prop_Send, "m_bForcedSkin", 1);
            SetEntProp(this.index, Prop_Send, "m_nForcedSkin", value);
        }
    }

    public bool AcceptInput(const char[] input, any ...)
    {
        return AcceptEntityInput(this.index, input);
    }
}