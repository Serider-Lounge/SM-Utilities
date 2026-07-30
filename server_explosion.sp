#include <sourcemod>
#include <sdktools>
#include <keyvalues>
#include <multicolors>

#define PLUGIN_PREFIX "[\x03Server Explosion\x01]"

// GLOBAL VARIABLES
int g_iFlashCounter = 0;
Handle g_hFlashTimer = null;
KeyValues g_hPresets = null;
char g_sSoundAlarm[PLATFORM_MAX_PATH];
char g_sSoundExplosion[PLATFORM_MAX_PATH];
int g_iMaxFlashes;
float g_fFlashInterval;
float g_fExplosionDuration;
char g_sExecuteCommand[64];
char g_sTextDisplay[256];
int g_iBgColor[4];
int g_iBgColorFade[4];

public Plugin myinfo =
{
    name = "Imminent Server Explosion",
    author = "Breadd~, Heapons",
    description = "Flashes screen, plays alarm, triggers explosion, then executes a command.",
    version = "26w31a",
    url = "https://github.com/Serider-Lounge/SM-Utilities"
};

public void OnPluginStart()
{
    // Translations
    LoadTranslations("server_explosion.phrases");

    // Commands
    RegAdminCmd("sm_trigger_serverexplosion", Command_Explode, ADMFLAG_ROOT, "Triggers a server explosion sequence. Usage: sm_trigger_serverexplosion [preset]");

    // Load presets from cfg
    LoadPresets();
}

public void OnMapStart()
{
    LoadPresets();
}

// --------------------------------------------------------------------------
// Preset Loading
// --------------------------------------------------------------------------

void LoadPresets()
{
    if (g_hPresets != null)
        delete g_hPresets;

    g_hPresets = new KeyValues("Presets");

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/server_explosion/presets.cfg");

    LogMessage("[Server Explosion] Attempting to load presets from: %s", path);
    
    if (!g_hPresets.ImportFromFile(path))
    {
        LogError("[Server Explosion] Failed to load presets file: %s", path);
        return;
    }

    LogMessage("[Server Explosion] Presets file loaded successfully");
    
    g_hPresets.Rewind();
    if (g_hPresets.GotoFirstSubKey())
    {
        do
        {
            char keyName[64];
            g_hPresets.GetSectionName(keyName, sizeof(keyName));
            LogMessage("[Server Explosion] Found preset: %s", keyName);
        }
        while (g_hPresets.GotoNextKey());
        g_hPresets.Rewind();
    }
    else
    {
        LogError("[Server Explosion] No presets found in file!");
    }

    if (!LoadPresetValues("default"))
    {
        LogError("[Server Explosion] Failed to load 'default' preset from presets.cfg");
    }
}

bool LoadPresetValues(const char[] presetName)
{
    g_hPresets.Rewind();

    LogMessage("[Server Explosion] Looking for preset: %s", presetName);
    
    if (!g_hPresets.JumpToKey(presetName))
    {
        LogError("[Server Explosion] Preset '%s' not found in presets.cfg", presetName);
        return false;
    }

    LogMessage("[Server Explosion] Found preset '%s', loading values...", presetName);

    g_hPresets.GetString("sound_alarm",     g_sSoundAlarm,     sizeof(g_sSoundAlarm),     "ambient/alarms/klaxon1.wav");
    g_hPresets.GetString("sound_explosion", g_sSoundExplosion, sizeof(g_sSoundExplosion), "ambient/explosions/explode_1.wav");
    g_iMaxFlashes        = g_hPresets.GetNum("max_flashes", 3);
    g_fFlashInterval     = g_hPresets.GetFloat("flash_interval", 1.0);
    g_fExplosionDuration = g_hPresets.GetFloat("duration", 0.25);
    g_hPresets.GetString("execute_command", g_sExecuteCommand, sizeof(g_sExecuteCommand), "_restart");
    g_hPresets.GetString("text_display",    g_sTextDisplay,    sizeof(g_sTextDisplay),    "SERVER EXPLOSION IMMINENT");

    char colorStr[32];

    g_hPresets.GetString("bg_color", colorStr, sizeof(colorStr), "255 0 0 100");
    ParseColorString(colorStr, g_iBgColor);

    g_hPresets.GetString("bg_color_fade", colorStr, sizeof(colorStr), "255 255 255 255");
    ParseColorString(colorStr, g_iBgColorFade);

    g_hPresets.Rewind();
    return true;
}

void ParseColorString(const char[] colorStr, int color[4])
{
    char parts[4][8];
    ExplodeString(colorStr, " ", parts, 4, sizeof(parts[]));
    for (int i = 0; i < 4; i++)
    {
        color[i] = StringToInt(parts[i]);
    }
}

// --------------------------------------------------------------------------
// Command
// --------------------------------------------------------------------------

public Action Command_Explode(int client, int args)
{
    char presetName[64];

    if (args >= 1)
    {
        GetCmdArg(1, presetName, sizeof(presetName));
    }
    else
    {
        strcopy(presetName, sizeof(presetName), "default");
    }

    if (!LoadPresetValues(presetName))
    {
        CReplyToCommand(client, PLUGIN_PREFIX ... " Preset '%s' not found in presets.cfg!", presetName);
        return Plugin_Handled;
    }

    if (g_hFlashTimer != null)
    {
        KillTimer(g_hFlashTimer);
        g_hFlashTimer = null;
    }

    g_iFlashCounter = 0;

    // Immediate first effect
    PerformWarningEffect();

    // Start the countdown timer
    g_hFlashTimer = CreateTimer(g_fFlashInterval, Timer_WarningLoop, _, TIMER_REPEAT);

    CReplyToCommand(client, PLUGIN_PREFIX ... " Imminent Server Explosion Activated (preset: %s)", presetName);
    return Plugin_Handled;
}

// --------------------------------------------------------------------------
// Timers
// --------------------------------------------------------------------------

public Action Timer_WarningLoop(Handle timer)
{
    g_iFlashCounter++;

    // IF WE REACH THE END OF THE COUNTDOWN
    if (g_iFlashCounter >= g_iMaxFlashes)
    {
        g_hFlashTimer = null;

        // Trigger the finale
        FinalExplosionSequence();

        return Plugin_Stop;
    }

    PerformWarningEffect();
    return Plugin_Continue;
}

// Execute command
public Action Timer_ExecuteCommand(Handle timer)
{
    LogMessage("Server explosion sequence complete. Executing: %s", g_sExecuteCommand);

    ServerCommand(g_sExecuteCommand);
    return Plugin_Handled;
}

// --------------------------------------------------------------------------
// Effects
// --------------------------------------------------------------------------

void FinalExplosionSequence()
{
    // Play explosion sound to ALL clients
    PrecacheSound(g_sSoundExplosion, true);
    EmitSoundToAll(g_sSoundExplosion);

    // Screen Flashbang
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            Client_ScreenFade(i, 1000, 0, 0x0001, g_iBgColorFade[0], g_iBgColorFade[1], g_iBgColorFade[2], g_iBgColorFade[3]);
        }
    }

    // Create a timer to execute the command after the sound plays
    CreateTimer(g_fExplosionDuration, Timer_ExecuteCommand);
}

// Red Flashes + Klaxon
void PerformWarningEffect()
{
    // Initial text params
    SetHudTextParams(-1.0, -1.0, 0.5, 255, 255, 255, 255, 2, 0.0, 0.0, 0.0);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            PrecacheSound(g_sSoundAlarm, true);
            EmitSoundToClient(i, g_sSoundAlarm);

            char textDisplay[256];
            Format(textDisplay, sizeof(textDisplay), "%T", g_sTextDisplay, i);
            ShowHudText(i, -1, textDisplay);

            // Colored Flash
            Client_ScreenFade(i, 250, 0, 0x0001, g_iBgColor[0], g_iBgColor[1], g_iBgColor[2], g_iBgColor[3]);
        }
    }
}

// --------------------------------------------------------------------------
// Stock: Cross-Game ScreenFade Compatibility
// --------------------------------------------------------------------------
stock void Client_ScreenFade(int client, int duration, int mode, int holdtime, int r, int g, int b, int a)
{
    UserMsg userMessage = GetUserMessageId("Fade");
    
    if (userMessage == INVALID_MESSAGE_ID) 
        return;

    if (GetFeatureStatus(FeatureType_Native, "GetUserMessageId") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
    {
        Handle pb = StartMessageOne("Fade", client);
        if (pb != null) 
        {
            PbSetInt(pb, "duration", duration);
            PbSetInt(pb, "hold_time", holdtime);
            PbSetInt(pb, "flags", mode);
            int color = (a << 24) + (b << 16) + (g << 8) + r;
            PbSetInt(pb, "clr", color);
            EndMessage();
        }
    }
    else 
    {
        Handle msg = StartMessageOne("Fade", client);
        if (msg != null)
        {
            BfWriteShort(msg, duration);
            BfWriteShort(msg, holdtime);
            BfWriteShort(msg, mode);
            BfWriteByte(msg, r);
            BfWriteByte(msg, g);
            BfWriteByte(msg, b);
            BfWriteByte(msg, a);
            EndMessage();
        }
    }
}