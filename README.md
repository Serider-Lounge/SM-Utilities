# SM Utilities
Useful commands and includes for server owners & plugin developers alike.

# Includes
## Serider

| Include | Description |
|---------|-------------|
| `chat.inc` | Chat utilities |
| `open_fortress.inc` | Open Fortress utilities |
| `shared.inc` | Source Engine shared utilities |
| `steam.inc` | Steam utilities |
| `tf2.inc` | Team Fortress 2 (and if applicable, [mod](https://store.steampowered.com/mods/440/)) utilities |
| `tf2classified.inc` | Team Fortress 2 Classified utilities |

# Plugins
## Essentials

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_convert_mobster_vip` | `1` | Convert Mobster VIP to TF2C VIP. |
| `sm_truce_active` | `0` | Toggle [truce mode](https://wiki.teamfortress.com/wiki/Truce_mode). |

### Admin Commands

| Command | Usage | Description |
|---------|-------|-------------|
| sm_(set)team | `[target] <team>` | Set player's team |
| sm_(set)class | `[target] <class>` | Set player's class |
| sm_respawn | `[target]` | Force respawn player(s) |
| sm_health | `[target] <amount>` | Set player's health |
| sm_maxhealth | `[target] <amount>` | Set player's max health |
| sm_currency | `[target] <amount>` | Set player's currency |
| sm_scale | `[target] <amount>` | Set player's scale |
| sm_addattr(ibute) | `[target] <attribute> [value] [duration]` | Add attribute to player |
| sm_removeattr(ibute) | `[target] <attribute>` | Remove attribute from player |
| sm_getattr(ibute) | `[target] <attribute>` | Get attribute value from player |
| sm_fireinput | `<target> <input> <value>` | Fire entity input on player |
| sm_hint | `<target> <message> <duration> [icon]` | Show instructor hint to player |
| sm_addcond | `[target] <condition> [duration]` | Add condition to player |
| sm_removecond | `[target] <condition>` | Remove condition from player |
| sm_giveweapon | `[target] <defindex> [classname]` | Give weapon to player |
| sm_removeweapon | `[target] <defindex>` | Remove weapon from player |
| sm_stripweapons | `[target]` | Strip all weapons from player |

### Player Commands

| Command | Description |
|---------|-------------|
| sm_fp / sm_firstperson | Switch to first-person view |
| sm_tp / sm_thirdperson | Switch to third-person view |
| sm_credits | View server contributors |

#### `addons/sourcemod/configs/sm_utilities/credits.cfg`
> Example config:
```json
"Credits"
{
    "Maxxy"
    {
        "steam" "76561198033547232"
        "contributions"
        {
            "0"
            {
                "url"  "https://steamcommunity.com/sharedfiles/filedetails/?id=416722824"
                "name" "Deathmatch Mercenary"
            }
        }
    }
}
```

### Target Filters

| Filter | Description |
|--------|-------------|
| @teamname | Target players on a specific team by name (e.g. @spectator) |
| @vips | <img src="https://shared.fastly.steamstatic.com/community_assets/images/apps/3545060/08607ace82bfb52cf8993efe88c2ef00fa25c96f.ico" width="16" height="16" style="vertical-align: text-bottom;"> Target Civilian players |

## 🗺️ Map Utilities

### Admin Commands

| Command | Description |
|---------|-------------|
| sm_reloadmap | Reloads the current map |

### Server Commands
Stripped `FCVAR_CHEATS` flag out of the following commands:

| Command |
|---------|
| nav_generate |
| nav_generate_incremental |
| sm_nav_generate |
| sm_nav_generate_incremental |
| bot_kick |

## 🖥️ Server Utilities
### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_quit_retry` | `1` | Send retry command to clients on quit. |
| `sm_restart_retry` | `1` | Send retry command to clients on restart. |

## ⚔️ Friendly-Fire

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_friendlyfire_endround` | `1` | Enable friendly-fire at the end of rounds. |
