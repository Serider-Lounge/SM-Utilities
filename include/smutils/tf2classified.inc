const TFTeam TFTeam_Green       = view_as<TFTeam>(4);
const TFTeam TFTeam_Yellow      = view_as<TFTeam>(5);

enum
{
    TF2C_COND_TRANQUILIZED = 136,
    TF2C_COND_CIV_SPEED,
    TF2C_COND_AIRBLAST,
    TF2C_COND_ANCHOR_FALL_CHARGED,
    TF2C_COND_LAUNCHED,
    TF2C_COND_JUMPPAD_ASSIST,
    TF2C_COND_JUST_USED_JUMPPAD,
    TF2C_COND_CIV_DAMAGE,
    TF2C_COND_LAUNCHED_SELF,
    TF2C_COND_CIV_HEAL,
    TF2C_COND_CONCUSSION,
    TF2C_COND_MIRV_SLOW,
    TF2C_COND_RESIDUAL_HEAL,
    TF2C_COND_BRICK,
    TF2C_COND_NOHEALING,
    TF2C_COND_TRANQUILIZED2,
    TF2C_COND_INTANGIBLE
};

const TFCond TF2CCond_Tranquilized      = view_as<TFCond>(TF2C_COND_TRANQUILIZED);
const TFCond TF2CCond_CivSpeed          = view_as<TFCond>(TF2C_COND_CIV_SPEED);
const TFCond TF2CCond_Airblast          = view_as<TFCond>(TF2C_COND_AIRBLAST);
const TFCond TF2CCond_AnchorFallCharged = view_as<TFCond>(TF2C_COND_ANCHOR_FALL_CHARGED);
const TFCond TF2CCond_Launched          = view_as<TFCond>(TF2C_COND_LAUNCHED);
const TFCond TF2CCond_JumppadAssist     = view_as<TFCond>(TF2C_COND_JUMPPAD_ASSIST);
const TFCond TF2CCond_JustUsedJumppad   = view_as<TFCond>(TF2C_COND_JUST_USED_JUMPPAD);
const TFCond TF2CCond_CivDamage         = view_as<TFCond>(TF2C_COND_CIV_DAMAGE);
const TFCond TF2CCond_LaunchedSelf      = view_as<TFCond>(TF2C_COND_LAUNCHED_SELF);
const TFCond TF2CCond_CivHeal           = view_as<TFCond>(TF2C_COND_CIV_HEAL);
const TFCond TF2CCond_Concussion        = view_as<TFCond>(TF2C_COND_CONCUSSION);
const TFCond TF2CCond_MirvSlow          = view_as<TFCond>(TF2C_COND_MIRV_SLOW);
const TFCond TF2CCond_ResidualHeal      = view_as<TFCond>(TF2C_COND_RESIDUAL_HEAL);
const TFCond TF2CCond_Brick             = view_as<TFCond>(TF2C_COND_BRICK);
const TFCond TF2CCond_NoHealing         = view_as<TFCond>(TF2C_COND_NOHEALING);
const TFCond TF2CCond_Tranquilized2     = view_as<TFCond>(TF2C_COND_TRANQUILIZED2);
const TFCond TF2CCond_Intangible        = view_as<TFCond>(TF2C_COND_INTANGIBLE);

enum // m_iPlayerRank
{
    TF_RANK_INVALID = -2,
    TF_RANK_NONE = -1,
    
    TF_RANK_PLAYTESTER,
    TF_RANK_CONTRIBUTOR,
    TF_RANK_DEVELOPER,

    TF_RANK_COUNT
};

/**
 * Gets the assigned VIP of the team.
 *
 * @param team    Index of the team.
 * @return        Client index of the assigned VIP.
 */
stock int TF2C_GetAssignedVIP(TFTeam team)
{
    let tf_team = new Entity(GetTeamEntity(view_as<int>(team)));
    return tf_team.GetProp(Prop_Send, "m_iVIP");
}

/**
 * Gets the assigned VIPs of the team.
 * 
 * @param team    Index of the team.
 * @return        Array of client indexes of the assigned VIPs.
 */
stock ArrayList TF2C_GetAssignedVIPs()
{
    ArrayList vips = new ArrayList(4);

    for (int i = 2; i < 6; i++)
    {
        let tf_team = new Entity(GetTeamEntity(i));
        int vip = tf_team.GetProp(Prop_Send, "m_iVIP");
        if (vip != -1)
        {
            vips.Push(vip);
        }
    }
    
    return vips;
}

/**
 * Adds an attribute to the player with a string value.
 *
 * @param name      Attribute name.
 * @param value     Attribute value.
 * @return          True if input was accepted, false otherwise.
 */
public bool TF2C_AddAttributeString(int entity, const char[] name, const char[] value)
{
    int len = strlen(name) + 64;
    char[] buffer = new char[len];
    Format(buffer, len, "self.Add%sAttributeString(\"%s\", \"%s\")", 0 < entity <= MaxClients ? "Custom" : "", name, value);

    let ent = new Entity(entity);
    return ent.AcceptInputString("RunScriptCode", buffer);
}