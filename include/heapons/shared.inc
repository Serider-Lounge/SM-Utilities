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
}