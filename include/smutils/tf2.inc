#include <sdktools>
#include <smutils/tf2/clients>

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
enum
{
    LIFE_ALIVE,
    LIFE_DYING,
    LIFE_DEAD,
    LIFE_RESPAWNABLE,
    LIFE_DISCARDBODY,

    LIFE_COUNT
};

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_shareddefs.h#L277-L293
enum
{
	TF_GAMETYPE_UNDEFINED,
	TF_GAMETYPE_CTF,
	TF_GAMETYPE_CP,
	TF_GAMETYPE_ESCORT,
	TF_GAMETYPE_ARENA,
	TF_GAMETYPE_MVM,
	TF_GAMETYPE_RD,
	TF_GAMETYPE_PASSTIME,
	TF_GAMETYPE_PD,

	TF_GAMETYPE_COUNT
};

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/shared/tf/tf_shareddefs.h#L256-L269
enum
{
	TF_FLAGTYPE_CTF,
	TF_FLAGTYPE_ATTACK_DEFEND,
	TF_FLAGTYPE_TERRITORY_CONTROL,
	TF_FLAGTYPE_INVADE,
	TF_FLAGTYPE_RESOURCE_CONTROL,
	TF_FLAGTYPE_ROBOT_DESTRUCTION,
	TF_FLAGTYPE_PLAYER_DESTRUCTION,

    TF_FLAGTYPE_COUNT
};

enum
{
    TF_HUDTYPE_DEFAULT,
    TF_HUDTYPE_CTF,
    TF_HUDTYPE_CP,
    TF_HUDTYPE_PAYLOAD,

    TF_HUDTYPE_COUNT
}

const TFClassType TFClass_Civilian = view_as<TFClassType>(10);

/**
 * Attaches a tf_glow entity to a parent entity with an arbitrary color.
 *
 * @param entity    Parent entity index.
 * @param color     Glow color as an array of 4 integers (RGBA).
 * @return          tf_glow entity index.
 */
stock int TF2_Glow(int entity, int color[4] = {255, 255, 255, 255})
{
    let ent = new Entity(entity);

    char targetname_old[64];
    ent.GetPropString(Prop_Data, "m_iName", targetname_old, targetname_old.size);

    char classname[64];
    strcopy(classname, classname.size, ent.GetClassname());

    char targetname[126];
    Format(targetname, targetname.size, "%s%i", classname, entity);
    DispatchKeyValue(entity, "targetname", targetname);

    let tf_glow = new Entity(CreateEntityByName("tf_glow"));
    DispatchKeyValue(tf_glow.index, "target", targetname);
    tf_glow.Spawn();

    SetVariantString("!activator");
    AcceptEntityInput(tf_glow.index, "SetParent", entity, tf_glow.index);

    SetVariantColor(color);
    tf_glow.AcceptInput("SetGlowColor");

    tf_glow.AcceptInput("Enable");

    ent.SetPropString(Prop_Data, "m_iName", targetname_old);

    return tf_glow.index;
}

/**
 * Gets the name of the current MvM popfile.
 *
 * @param buffer    The buffer to store the popfile name.
 * @param maxlen    The maximum length of the buffer.
 * @param cleanup   If true, trims "scripts/population/" and ".pop".
 * @return          The length of the popfile name, 0 if not found.
 */
stock int TF2_GetPopFileName(char[] buffer, int maxlen, bool cleanup = false)
{
    let entity = new Entity(FindEntityByClassname(-1, "tf_objective_resource"));
    if (entity.index == -1)
        return 0;

    char name[128];
    entity.GetPropString(Prop_Send, "m_iszMvMPopfileName", name, name.size);

    if (cleanup)
    {
        ReplaceString(name, name.size, "scripts/population/", "");
        ReplaceString(name, name.size, ".pop", "");
    }

    return strcopy(buffer, maxlen, name);
}

/**
 * Ends the current round.
 *
 * @param team             Winner team index.
 * @param force_map_reset  Whether to force a map reset.
 */
stock void TF2_EndRound(TFTeam team = TFTeam_Unassigned, bool force_map_reset = true)
{
    let entity = new Entity(CreateEntityByName("game_round_win"));
    if (entity.index != -1)
    {
        entity.SetProp(Prop_Data, "m_iTeamNum", view_as<int>(team));
        entity.SetProp(Prop_Data, "m_bForceMapReset", view_as<int>(force_map_reset));
        entity.AcceptInput("RoundWin");
        entity.Remove();
    }
}

/**
 * Adds an attribute to an entity via VScript.
 *
 * @param entity    Entity index (player or non-player).
 * @param name      Attribute name.
 * @param value     Attribute value.
 * @param duration  Duration in seconds (-1 for permanent).
 * @return          True if the input was accepted.
 */
stock bool TF2_AddAttribute(int entity, const char[] name, float value = 1.0, float duration = -1.0)
{
    char script[512];
    Format(script, script.size, "self.Add%sAttribute(\"%s\", %f, %f)", 0 < entity && entity <= MaxClients ? "Custom" : "", name, value, duration);

    let ent = new Entity(entity);
    return ent.AcceptInputString("RunScriptCode", script);
}

/**
 * Removes an attribute from an entity via VScript.
 *
 * @param entity    Entity index.
 * @param name      Attribute name.
 * @return          True if the input was accepted.
 */
stock bool TF2_RemoveAttribute(int entity, const char[] name)
{
    char script[512];
    Format(script, script.size, "self.Remove%sAttribute(\"%s\")", 0 < entity && entity <= MaxClients ? "Custom" : "", name);

    let ent = new Entity(entity);
    return ent.AcceptInputString("RunScriptCode", script);
}

/**
 * Gets an attribute value from an entity via VScript.
 *
 * @param entity        Entity index.
 * @param name          Attribute name.
 * @param defaultValue  Default value if the attribute is not set.
 * @return              Attribute value.
 */
stock float TF2_GetAttribute(int entity, const char[] name, float defaultValue)
{
    char script[512];
    Format(script, script.size, "NetProps.SetPropFloat(self, \"m_flPoseParameter\", self.Get%sAttribute(\"%s\", %f))", 0 < entity && entity <= MaxClients ? "Custom" : "", name, defaultValue);

    let ent = new Entity(entity);
    ent.AcceptInputString("RunScriptCode", script);
    return ent.GetPropFloat(Prop_Data, "m_flPoseParameter");
}

stock TFTeam TF2_GetHalloweenTeam()
{
    static let teamCount = 0;
    if (teamCount == 0)
    {
        teamCount = GetTeamCount() + 1;
    }
    return view_as<TFTeam>(teamCount);
}