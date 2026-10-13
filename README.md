# SM Utilities
Useful commands and includes for server owners & plugin developers alike.

**Minimum SourceMod build required:** [1.13](https://www.sourcemod.net/downloads.php?branch=dev&all=1)

# Dependencies
## JSON
- [RIP Ext](https://github.com/srcdslab/sm-ext-ripext)
  - If on Extension API v9: [moonspub/sm-ext-ripext](https://github.com/moonspub/sm-ext-ripext).
## Navigation Mesh
- [SourcePawn NavMesh](https://github.com/Heapons/sourcepawn-navmesh)
## TF2 Items
- [TF2 Item Schema](https://github.com/Serider-Lounge/SM-Utilities/releases)

# <img src="https://deathreus.gallerycdn.vsassets.io/extensions/deathreus/sp-linter/0.0.2/1615327137416/Microsoft.VisualStudio.Services.Icons.Default" width="32" height="32" style="vertical-align: text-bottom;"> Includes

| File | Description |
|---------|-------------|
| `clients.inc` | Client utilities |
| `entities.inc` | Entity utilities |
| `fc.inc` | Fortress Connected utilities |
| `open_fortress.inc` | Open Fortress utilities |
| `ripext/(...).inc` | HTTP utilities |
| `tf2.inc` / `tf2/(...).inc` | Team Fortress 2 (and if applicable, [mod](https://store.steampowered.com/mods/440/)) utilities |
| `tf2classified.inc` | Team Fortress 2 Classified utilities |

# <img src="https://yuexiawode.gallerycdn.vsassets.io/extensions/yuexiawode/sourcepawn/1.1.8/1673439019601/Microsoft.VisualStudio.Services.Icons.Default" width="32" height="32" style="vertical-align: text-bottom;"> Plugins
## 💥 Server Explosion
### Commands

| Name | Usage | Description |
|------|-------|-------------|
| `sm_trigger_serverexplosion` | `[preset]` | Triggers a server explosion sequence. If no preset is specified, `default` is used. |

### Configuration

> [!WARNING]
> Slash comments aren't supported!

#### [`presets.cfg`](https://github.com/Serider-Lounge/SM-Utilities/tree/main/configs/server_explosion/presets.cfg)

```json
"default"
{
    "sound_alarm"       "ambient/alarms/klaxon1.wav"
    "sound_explosion"   "ambient/explosions/explode_1.wav"
    "max_flashes"       "3"
    "flash_interval"    "1.0"
    "duration"          "0.25"
    "execute_command"   "_restart"
    "text_display"      "server_explosion_hud"
    "bg_color"          "255 0 0 100"
    "bg_color_fade"     "255 255 255 255"
}
```

- `sound_alarm`: Sound to play everytime the screen flashes.
- `sound_explosion`: Sound to play when the explosion is over.
- `max_flashes`: Maximum number of flash/warning effects before the final explosion.
- `flash_interval`: Interval in seconds between each flash/warning effect.
- `duration`: Duration in seconds of the final explosion screen fade before executing the command.
- `execute_command`: Server command to execute when the explosion sequence is complete.
- [`text_display`](https://github.com/Serider-Lounge/SM-Utilities/blob/main/translations/server_explosion.phrases.txt): Translation phrase name for the HUD text displayed during warnings.
- `bg_color`: Background color and alpha of the screen flash during warnings. Format: `R G B A`.
- `bg_color_fade`: Background color and alpha of the final explosion screen flash. Format: `R G B A`.

https://github.com/user-attachments/assets/18b14705-3b3e-4046-9124-49215f99c853

---

## 🤖 Bots Fun

### Supported
- [RCBot2](https://github.com/APGRoboCop/rcbot2)
- [NavBot](https://github.com/caxanga334/NavBot)

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_bot_autoteambalance` | `1` | Whether bots are affected by auto-balance. |
| `sm_bot_names` | `2` | Whether to use custom bot names. Allowed values: `0`, `1`, `2`.<br>If `0`, no custom names are used.<br>If `1`, only `default` names are used.<br>If `2`, rename bots based on their models. |
| `sm_bot_quota_interval` | `1.0` | The interval at which to maintain the bot quota. |
| `sm_bot_quota_mode` | `balance` | Determines the type of quota. Allowed values: `fill`, `layer`, `balance`.<br>If `fill`, the server will adjust bots to keep sm_bot_quota total players in the game.<br>If `layer`, the server will adjust bots to keep teams balanced at bare minimum.<br>If `balance`, the server will adjust bots to keep teams balanced and force players to replace remaining bots. |
| `sm_bot_quota` | `12` | Determines the total number of bots in the game.<br><img src="https://cdn.fastly.steamstatic.com/steamcommunity/public/images/apps/440/033bdd91842b6aca0633ee1e5f3e6b82f2e8962f.ico" width="16" height="16" style="vertical-align: text-bottom;"> MVM is supported through `sm_bot_quota_mvm`. |
| `sm_bot_quota_mvm` | `1` | <img src="https://cdn.fastly.steamstatic.com/steamcommunity/public/images/apps/440/033bdd91842b6aca0633ee1e5f3e6b82f2e8962f.ico" width="16" height="16" style="vertical-align: text-bottom;"> Whether to manage the bot quota in Mann Vs. Machine. |
| `sm_bot_type` | `navbot,rcbot2,valve` | The type of bot to spawn. Allowed values: [`valve`](https://developer.valvesoftware.com/wiki/Bot), [`rcbot2`](https://github.com/APGRoboCop/rcbot2), [`navbot`](https://github.com/caxanga334/NavBot).<br>If bot types are sequenced (separated by commas), the priority order will be read from left to right. |
| `sm_bot_type_random` | `0` | Whether to randomly select a bot type from `sm_bot_type`.<br>If a bot type is blacklisted, it won't be accounted for. |
| `sm_bot_humans_only` | `1` | <img src="https://cdn.fastly.steamstatic.com/steamcommunity/public/images/apps/440/033bdd91842b6aca0633ee1e5f3e6b82f2e8962f.ico" width="16" height="16" style="vertical-align: text-bottom;"> Whether to pre-maturely end the round when all humans are dead in Arena Mode or Sudden Death mode. |
| `sm_nav_generate_auto` | `0` | Whether to automatically generate navmeshes for the current map if none exist. Only triggers when the server enters in hibernation. |

### Admin Commands

| Name | Usage | Description |
|------|-------|-------------|
| `sm_puppet_add` | `<name>` | Add a puppet bot with the given name. |

### Server Commands

> [!NOTE]
> The `FCVAR_CHEATS` flag has been stripped from the following commands:
> - `nav_generate`
> - `nav_generate_incremental`
> - `nav_mark_walkable`
> - `bot_kick`

### Target Filters

| Filter | Description |
|--------|-------------|
| `@rcbots` | Target RCBots. |

### Configuration

> [!WARNING]
> Slash comments aren't supported!

#### [`bots_fun.json`](https://github.com/Serider-Lounge/SM-Utilities/tree/main/configs/sm_utilities/bots_fun.json)

```json
{
    "bot_names":
    {
        "default":
        [
            "Minecraft Steve",
            "xXProAimbotterXx"
        ],
        "models":
        {
            //"substring": "Bot Name",
            "scout":      "Scout",
            "soldier":    "Soldier",
            "pyro":       "Pyro",
            "civilian":   "Civilian"
        }
    },
    "maps":
    {
        // Regex pattern
        "^koth_.*$":
        [
            // Bot types
            "valve",
            "rcbot2",
            "navbot"
        ]

        // Allow all bot types for every unspecified map
    }
}
```

- `bot_names`
  - `default`: Random names for bots to choose from upon spawning (`sm_bot_names` must be set to `1`).
  - `models`: Rename bots based on their model paths (`sm_bot_names` must be set to `2`).
- `maps`: Whitelist/Blacklist bot types for maps.

## 🧰 Essentials

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_convert_vscript_vip` | `1` | <img src="https://shared.fastly.steamstatic.com/community_assets/images/apps/3545060/08607ace82bfb52cf8993efe88c2ef00fa25c96f.ico" width="16" height="16" style="vertical-align: text-bottom;"> Convert VScript VIP to TF2C VIP. |
| `sm_truce_active` | `0` | Toggle [truce mode](https://wiki.teamfortress.com/wiki/Truce_mode). |
| `sm_thirdperson_enabled` | `1` | Allow players to use third-person view. |
| `sm_setup_fastbuild` | `0` | Enable fast building during setup time. |

### Admin Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `sm_(set)team` | `[target] <team>` | Set player's team |
| `sm_(set)class` | `[target] <class>` | Set player's class |
| `sm_respawn` | `[target]` | Force respawn player(s) |
| `sm_health` | `[target] <amount>` | Set player's health |
| `sm_maxhealth` | `[target] <amount>` | Set player's max health |
| `sm_armor` | `[target] <amount>` | Set player's armor |
| `sm_giveammo` | `[target] <ammo_type> <amount>` | Give ammo to player |
| `sm_giveclip` | `[target] <amount>` | Give clip to player |
| `sm_currency` | `[target] <amount>` | Set player's currency |
| `sm_scale` | `[target] <amount>` | Set player's scale |
| `sm_addattr(ibute)` | `[target] <attribute> [value] [duration]` | Add attribute to player |
| `sm_removeattr(ibute)` | `[target] <attribute>` | Remove attribute from player |
| `sm_getattr(ibute)` | `[target] <attribute> <default_value>` | Get attribute value from player |
| `sm_fireinput` | `<target> <input> <value>` | Fire entity input on player |
| `sm_setcollision` | `[target] <collisiongroup>` | Set player's collision group |
| `sm_hint` | `<target> <message> <duration> [icon]` | Show an [instructor hint](https://developer.valvesoftware.com/wiki/Env_instructor_hint) to player |
| `sm_addcond` | `[target] <condition> [duration]` | Add condition to player |
| `sm_removecond` | `[target] <condition>` | Remove condition from player |
| `sm_giveweapon` | `[target] <item> [classname] [defindex]` | Give weapon to player |
| `sm_removeweapon` | `[target] <item>` | Remove weapon from player |
| `sm_stripweapons` | `[target]` | Strip all weapons from player |
| `sm_getweapons` | `[target]` | Get player's weapons |

> [!TIP]
> **Ammo types**:
> - `0` = dummy.
> - `1` = primary.
> - `2` = secondary.
> - `3` = metal.
> - `4`, `5`, `6` = grenades.

### Player Commands

| Command | Description |
|---------|-------------|
| `sm_fp` / `sm_firstperson` | Switch to first-person view |
| `sm_tp` / `sm_thirdperson` | Switch to third-person view |
| `sm_credits` | Opens a menu to view server contributors |
| `sm_killfeed` | Toggle whether the local kill feed only shows your own kills |

### Target Filters

| Filter | Description |
|--------|-------------|
| @teamname | Target players on a specific team by name (e.g. @spectator) |
| @vips | <img src="https://shared.fastly.steamstatic.com/community_assets/images/apps/3545060/08607ace82bfb52cf8993efe88c2ef00fa25c96f.ico" width="16" height="16" style="vertical-align: text-bottom;"> Target VIP players |

### Configuration

###### [`credits.json`](https://github.com/Serider-Lounge/SM-Utilities/tree/main/configs/sm_utilities/credits.json)
```json
{
    "credits":
    [
        {
            // Author
            "name": "Maxxy",
            "url": "https://steamcommunity.com/profiles/76561198033547232",
            // Contributions
            "contributions":
            [
                {
                    "name": "Deathmatch Mercenary",
                    "url": "https://steamcommunity.com/sharedfiles/filedetails/?id=416722824"
                }
            ]
        }
    ]
}
```
- `name`: Name of the author.
  - `url`: Link to their website, profile, etc.
- `contributions`
  - `name`: Title of the contribution.
  - `url`: Link source of the contribution.

## 🗺️ Map Utilities

### Admin Commands

| Command | Description |
|---------|-------------|
| `sm_reloadmap` | Reloads the current map with a 3-second countdown. Displays a [hint](https://developer.valvesoftware.com/wiki/Env_instructor_hint) or [training message](https://github.com/arthurdead/sm-plugins/blob/master/addons/sourcemod/scripting/trainingmsg.sp) to all players. |

## 👤 Player Utilities

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_fastrespawn_maxplayers` | `8` | Maximum number of players required for fast respawn to be enabled. |
| `sm_fastrespawn_ignore_bots` | `1` | Whether to ignore bots when counting players for fast respawn. |
| `sm_fastrespawn_ignore_spectators` | `1` | Whether to ignore spectators when counting players for fast respawn. |

## 🖥️ Server Utilities

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_quit_retry` | `1` | Whether to send retry command to clients on quit. |
| `sm_restart_retry` | `1` | Whether to send retry command to clients on restart. |

### Admin Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `sm_retry` | | Sends the `retry` command to a client, reconnecting them to the server. |

## ⚔️ Friendly-Fire

### ConVars

| ConVar | Default | Description |
|--------|---------|-------------|
| `sm_friendlyfire_endround` | `1` | Enable friendly-fire at the end of rounds. |