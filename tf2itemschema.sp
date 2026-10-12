#include <sourcemod>
#include <sdktools>
#include <keyvalues>
#include <ripext/json>
#include <tf2itemschema>

#define MAX_WEAPONS 48

char g_GameDir[64];
char g_PathJSON[PLATFORM_MAX_PATH];

StringMap  g_hItems;           // item name -> defindex
StringMap  g_hAttributes;      // attribute name -> defindex
IntMap     g_hItemsByDef;      // defindex -> item name
IntMap     g_hAttributesByDef; // defindex -> attribute name
IntMap     g_hItemClasses;     // defindex -> classname (items only)

public Plugin myinfo = 
{
    name = "TF2 Item Schema",
    author = "Heapons",
    description = "",
    version = "26w32a",
    url = "https://github.com/Heapons/SM-Utilities"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("tf2itemschema");

	CreateNative("TFSchema_FindItemByDefIndex",      Native_FindItemByDefIndex);
	CreateNative("TFSchema_FindItemByName",          Native_FindItemByName);
	CreateNative("TFSchema_FindAttributeByName",     Native_FindAttributeByName);
	CreateNative("TFSchema_FindAttributeByDefIndex", Native_FindAttributeByDefIndex);
	CreateNative("TFSchema_GetClassName",            Native_GetClassName);
	CreateNative("TFSchema_GiveNamedItem",           Native_GiveNamedItem);
	CreateNative("TFSchema_RemoveItem",              Native_RemoveItem);
	CreateNative("TFSchema_RemoveAllItems",          Native_RemoveAllItems);
	CreateNative("TFSchema_GetPlayerWeapons",        Native_GetPlayerWeapons);
}

public void OnPluginStart()
{
	GetGameFolderName(g_GameDir, sizeof(g_GameDir));
	BuildPath(Path_SM, g_PathJSON, sizeof(g_PathJSON), "data/sm_utilities/items_game.json");

	if (!FileExists(g_PathJSON))
	{
		GenerateSchema();
	}

	LoadSchema();
}

public void OnMapStart()
{
	if (strcmp(g_GameDir, "tf2classified") == 0)
	{
		GenerateSchema();
		LoadSchema();
	}
}

void GenerateSchema()
{
	static dirExists = false;
	if (!dirExists)
	{
		char dir[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, dir, sizeof(dir), "data/sm_utilities");
		if (!DirExists(dir))
		{
			CreateDirectory(dir);
			dirExists = true;
		}
	}

	JSONObject schema = new JSONObject();

	JSONObject prefabs = new JSONObject();
	schema.Set("prefabs", prefabs);

	JSONObject items = new JSONObject();
	schema.Set("items", items);

	JSONObject attributes = new JSONObject();
	schema.Set("attributes", attributes);

	ArrayList files = new ArrayList(PLATFORM_MAX_PATH);
	StringMap seen = new StringMap();

	AddSourceWithBases(files, seen, "scripts/items/items_game.txt");
	if (strcmp(g_GameDir, "tf2classified") == 0)
	{
		/* Map-specific items overwrite custom ones. */
		AddSourceWithBases(files, seen, "scripts/items/custom_items_game.txt");

		char mapName[96];
		GetCurrentMap(mapName, sizeof(mapName));
		if (mapName[0] != '\0')
		{
			char mapFile[PLATFORM_MAX_PATH];
			FormatEx(mapFile, sizeof(mapFile), "scripts/items/%s_items_game.txt", mapName);
			AddSourceWithBases(files, seen, mapFile);
		}
	}
	else if (strcmp(g_GameDir, "fc_tfsdk") == 0)
	{
		AddSourceWithBases(files, seen, "scripts/items/items_custom.txt");
	}

	char path[PLATFORM_MAX_PATH];
	for (int i = 0; i < files.Length; i++)
	{
		files.GetString(i, path, sizeof(path));

		KeyValues kv = new KeyValues("schema");
		if (kv.ImportFromFile(path))
		{
			MergeSection(kv, prefabs, "prefabs", false);
			MergeSection(kv, items, "items", true);
			MergeSection(kv, attributes, "attributes", true);
		}
		delete kv;
	}

	delete files;
	delete seen;

	File out = OpenFile(g_PathJSON, "w");
	if (out == null)
	{
		LogError("[tf2itemschema] Could not create '%s'.", g_PathJSON);
		delete schema;
		delete prefabs;
		delete items;
		delete attributes;
		return;
	}
	delete out;

	if (!schema.ToFile(g_PathJSON, JSON_INDENT(4)))
	{
		LogError("[tf2itemschema] Failed to write '%s'.", g_PathJSON);
		DeleteFile(g_PathJSON);
	}

	delete schema;
	delete prefabs;
	delete items;
	delete attributes;
}

// Account for included #base files.
void AddSourceWithBases(ArrayList files, StringMap seen, const char[] path)
{
	if (files == null || seen == null || seen.ContainsKey(path))
	{
		return;
	}
	seen.SetValue(path, true);

	char basePath[PLATFORM_MAX_PATH], relPath[PLATFORM_MAX_PATH];
	ArrayList bases = new ArrayList(PLATFORM_MAX_PATH);
	File file = OpenFile(path, "r", true);
	if (file != null)
	{
		char line[PLATFORM_MAX_PATH];
		while (file.ReadLine(line, sizeof(line)))
		{
			TrimString(line);
			if (line[0] == '\0' || line[0] == '/')
			{
				continue;
			}
			
			if (strncmp(line, "#base", 5) != 0)
			{
				break;
			}

			int first = FindCharInString(line, '"');
			int last = FindCharInString(line, '"', true);
			if (first == -1 || last <= first)
			{
				continue;
			}

			strcopy(relPath, sizeof(relPath), line[first + 1]);
			relPath[last - first - 1] = '\0';

			FormatEx(basePath, sizeof(basePath), "scripts/items/%s", relPath);
			bases.PushString(basePath);
		}
		delete file;
	}

	for (int i = 0; i < bases.Length; i++)
	{
		bases.GetString(i, basePath, sizeof(basePath));
		if (strcmp(basePath, "scripts/items/items_game.txt") != 0)
		{
			AddSourceWithBases(files, seen, basePath);
		}
	}
	delete bases;

	files.PushString(path);
}

void MergeSection(KeyValues kv, JSONObject entries, const char[] section, bool byName)
{
	kv.Rewind();
	if (!kv.JumpToKey(section))
	{
		return;
	}

	bool inAttributes = (strcmp(section, "attributes") == 0);

	if (kv.GotoFirstSubKey())
	{
		char entryName[64], jsonKey[64];
		do
		{
			kv.GetSectionName(entryName, sizeof(entryName));

			/* Check if section key is an integer (defindex). */
			int defindex;
			bool hasDefindex = (StringToIntEx(entryName, defindex) == strlen(entryName));

			if (byName)
			{
				kv.GetString("name", jsonKey, sizeof(jsonKey));
				if (jsonKey[0] == '\0')
				{
					IntToString(defindex, jsonKey, sizeof(jsonKey));
				}
			}
			else
			{
				strcopy(jsonKey, sizeof(jsonKey), entryName);
			}

			JSONObject entry = new JSONObject();
			if (hasDefindex)
			{
				entry.SetInt("defindex", defindex);
			}
			if (!KvNodeToObject(kv, entry, inAttributes))
			{
				delete entry;
				continue;
			}

			entries.Set(jsonKey, entry);
			delete entry;
		}
		while (kv.GotoNextKey());
	}
}

bool KvNodeToObject(KeyValues kv, JSONObject obj, bool inAttributes = false)
{
	if (!kv.GotoFirstSubKey(false))
	{
		return false;
	}

	char fieldName[64], name[64], subValue[16], value[1024], namesArr[9][32];
	bool any = false;
	do
	{
		kv.GetSectionName(fieldName, sizeof(fieldName));

		static const char nameListFields[][32] =
		{
			"used_by_classes",
			"tags",
			"capabilities"
		};

		bool isNameList = false;
		for (int i = 0; i < sizeof(nameListFields); i++)
		{
			if (strcmp(fieldName, nameListFields[i]) == 0)
			{
				isNameList = true;
				break;
			}
		}

		if (isNameList)
		{
			JSONArray names = new JSONArray();
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(name, sizeof(name));
					kv.GetString(NULL_STRING, subValue, sizeof(subValue));
					if (subValue[0] != '\0' && strcmp(subValue, "0") != 0)
					{
						names.PushString(name);
					}
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			else
			{
				kv.GetString(NULL_STRING, value, sizeof(value));
				int count = ExplodeString(value, " ", namesArr, sizeof(namesArr), sizeof(namesArr[]), true);
				for (int i = 0; i < count; i++)
				{
					if (strcmp(namesArr[i], "0") != 0)
					{
						names.PushString(namesArr[i]);
					}
				}
			}
			obj.Set(fieldName, names);
			delete names;
			any = true;
			continue;
		}

		if (kv.GotoFirstSubKey(false))
		{
			kv.GoBack();
			bool indexed = true;
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(name, sizeof(name));
					int dummy;
					if (StringToIntEx(name, dummy) != strlen(name))
					{
						indexed = false;
						break;
					}
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}

			if (indexed)
			{
				JSONArray child = new JSONArray();
				KvNodeToArray(kv, child, inAttributes);
				if (child.Length > 0)
				{
					obj.Set(fieldName, child);
					delete child;
					any = true;
				}
				else
				{
					delete child;
				}
			}
			else
			{
				JSONObject child = new JSONObject();
				if (KvNodeToObject(kv, child, inAttributes))
				{
					obj.Set(fieldName, child);
					delete child;
					any = true;
				}
				else
				{
					delete child;
				}
			}
			continue;
		}

		/* Leaf scalar value. Skip "name" field (used as JSON key, not stored in object). */
		if (strcmp(fieldName, "name") == 0)
		{
			continue;
		}

		kv.GetString(NULL_STRING, value, sizeof(value));
		if (value[0] != '\0')
		{
			SetFieldValue(kv, obj, fieldName, value, inAttributes);
			any = true;
		}
	}
	while (kv.GotoNextKey(false));

	kv.GoBack();
	return any;
}

void KvNodeToArray(KeyValues kv, JSONArray arr, bool inAttributes)
{
	if (!kv.GotoFirstSubKey(false))
	{
		return;
	}

	char name[64], value[1024];
	do
	{
		if (kv.GotoFirstSubKey(false))
		{
			kv.GoBack();
			bool indexed = true;
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(name, sizeof(name));
					int dummy;
					if (StringToIntEx(name, dummy) != strlen(name))
					{
						indexed = false;
						break;
					}
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}

			if (indexed)
			{
				JSONArray child = new JSONArray();
				KvNodeToArray(kv, child, inAttributes);
				arr.Push(child);
				delete child;
			}
			else
			{
				JSONObject child = new JSONObject();
				if (KvNodeToObject(kv, child, inAttributes))
				{
					arr.Push(child);
					delete child;
				}
				else
				{
					delete child;
				}
			}
			continue;
		}

		kv.GetString(NULL_STRING, value, sizeof(value));
		if (value[0] != '\0')
		{
			PushFieldValue(kv, arr, value, inAttributes);
		}
	}
	while (kv.GotoNextKey(false));

	kv.GoBack();
}

void SetFieldValue(KeyValues kv, JSONObject obj, const char[] key, const char[] value, bool inAttributes)
{
	static const char boolFields[][32] =
	{
		"show_in_armory",
		"enabled",
		"propername",
		"baseitem",
		"hidden",
		"stored_as_integer",
		"can_affect_market_name"
	};

	for (int i = 0; i < sizeof(boolFields); i++)
	{
		if (strcmp(key, boolFields[i]) == 0)
		{
			obj.SetBool(key, value[0] == '1');
			return;
		}
	}

	KvDataTypes type = kv.GetDataType(NULL_STRING);
	if (inAttributes && (type == KvData_Int || type == KvData_Float))
	{
		obj.SetFloat(key, kv.GetFloat(NULL_STRING, 0.0));
	}
	else if (!inAttributes && type == KvData_Int)
	{
		obj.SetInt(key, kv.GetNum(NULL_STRING, 0));
	}
	else if (!inAttributes && type == KvData_Float)
	{
		obj.SetFloat(key, kv.GetFloat(NULL_STRING, 0.0));
	}
	else
	{
		obj.SetString(key, value);
	}
}

/** Pushes a leaf scalar onto an array (same typing rules as SetFieldValue). */
void PushFieldValue(KeyValues kv, JSONArray arr, const char[] value, bool inAttributes)
{
	KvDataTypes type = kv.GetDataType(NULL_STRING);
	if (inAttributes && (type == KvData_Int || type == KvData_Float))
	{
		arr.PushFloat(kv.GetFloat(NULL_STRING, 0.0));
	}
	else if (!inAttributes && type == KvData_Int)
	{
		arr.PushInt(kv.GetNum(NULL_STRING, 0));
	}
	else if (!inAttributes && type == KvData_Float)
	{
		arr.PushFloat(kv.GetFloat(NULL_STRING, 0.0));
	}
	else
	{
		arr.PushString(value);
	}
}

void LoadSchema()
{
	ClearSchema();

	JSONObject root = JSONObject.FromFile(g_PathJSON);
	if (root == null)
		return;

	g_hItems = new StringMap();
	g_hAttributes = new StringMap();
	g_hItemsByDef = new IntMap();
	g_hAttributesByDef = new IntMap();
	g_hItemClasses = new IntMap();

	BuildSchemaMap(root, "items", g_hItems, g_hItemsByDef, g_hItemClasses, true);
	BuildSchemaMap(root, "attributes", g_hAttributes, g_hAttributesByDef, null, false);

	delete root;
}

void BuildSchemaMap(JSONObject root, const char[] section, StringMap map, IntMap mapByDef, IntMap classes, bool isItems)
{
	if (!root.HasKey(section))
	{
		return;
	}

	JSONObject obj = view_as<JSONObject>(root.Get(section));
	if (obj == null)
	{
		return;
	}

	JSONObjectKeys keys = obj.Keys();
	char key[64], className[64];

	while (keys.ReadKey(key, sizeof(key)))
	{
		if (!obj.HasKey(key))
		{
			continue;
		}

		JSONObject entry = view_as<JSONObject>(obj.Get(key));
		if (entry == null)
		{
			continue;
		}

		if (!entry.HasKey("defindex"))
		{
			delete entry;
			continue;
		}

		int defindex = entry.GetInt("defindex");

		/* Plain value/string cells - no nested handle ownership to manage. */
		map.SetValue(key, defindex);
		mapByDef.SetString(defindex, key);

		if (isItems)
		{
			if (ResolveClassName(root, key, className, sizeof(className)))
			{
				classes.SetString(defindex, className);
			}
		}

		delete entry;
	}

	delete keys;
	delete obj;
}

void ClearSchema()
{
	delete g_hItems;
	delete g_hAttributes;
	delete g_hItemsByDef;
	delete g_hAttributesByDef;
	delete g_hItemClasses;

	g_hItems = null;
	g_hAttributes = null;
	g_hItemsByDef = null;
	g_hAttributesByDef = null;
	g_hItemClasses = null;
}

bool ReadClassName(JSONObject obj, char[] buffer, int maxlen)
{
	static const char keys[][32] =
	{
		"item_class",
		"base_item_name",
		"name"
	};
	for (int i = 0; i < sizeof(keys); i++)
	{
		if (obj.GetString(keys[i], buffer, maxlen) && buffer[0] != '\0')
		{
			if (i > 0) // base_item_name and name need lowercasing
			{
				for (int j = 0; buffer[j] != '\0'; j++)
				{
					buffer[j] = CharToLower(buffer[j]);
				}
			}
			return true;
		}
	}
	return false;
}

/**
 * Resolves a spawnable classname for the given item name.
 * Priority:
 *   1. Item's own item_class field
 *   2. Item's JSON key lowercased (e.g. "TF_WEAPON_SHOTGUN_PRIMARY" -> "tf_weapon_shotgun_primary")
 *   3. Prefab's item_class field
 *   4. Item's base_item_name or name
 *   5. Prefab's base_item_name or name
 */
bool ResolveClassName(JSONObject root, const char[] itemName, char[] buffer, int maxlen)
{
	if (root == null || !root.HasKey("items"))
	{
		return false;
	}

	JSONObject items = view_as<JSONObject>(root.Get("items"));
	JSONObject item = null;

	if (items != null && items.HasKey(itemName))
	{
		item = view_as<JSONObject>(items.Get(itemName));
	}

	bool found = false;

	if (item != null && item.GetString("item_class", buffer, maxlen) && buffer[0] != '\0')
	{
		found = true;
	}

	if (!found && item != null && item.HasKey("prefab"))
	{
		strcopy(buffer, maxlen, itemName);
		for (int i = 0; buffer[i] != '\0'; i++)
		{
			buffer[i] = CharToLower(buffer[i]);
		}
		found = true;
	}

	char prefab[64];
	if (!found && item != null && item.GetString("prefab", prefab, sizeof(prefab)) &&
		prefab[0] != '\0' && root.HasKey("prefabs"))
	{
		JSONObject prefabs = view_as<JSONObject>(root.Get("prefabs"));
		if (prefabs != null && prefabs.HasKey(prefab))
		{
			JSONObject prefabObject = view_as<JSONObject>(prefabs.Get(prefab));
			if (prefabObject.GetString("item_class", buffer, maxlen) && buffer[0] != '\0')
			{
				found = true;
			}
			delete prefabObject;
		}
		delete prefabs;
	}

	if (!found && item != null && ReadClassName(item, buffer, maxlen))
	{
		found = true;
	}

	if (!found && item != null && item.GetString("prefab", prefab, sizeof(prefab)) &&
		prefab[0] != '\0' && root.HasKey("prefabs"))
	{
		JSONObject prefabs = view_as<JSONObject>(root.Get("prefabs"));
		if (prefabs != null && prefabs.HasKey(prefab))
		{
			JSONObject prefabObject = view_as<JSONObject>(prefabs.Get(prefab));
			found = ReadClassName(prefabObject, buffer, maxlen);
			delete prefabObject;
		}
		delete prefabs;
	}

	if (!found)
	{
		strcopy(buffer, maxlen, itemName);
		for (int i = 0; buffer[i] != '\0'; i++)
		{
			buffer[i] = CharToLower(buffer[i]);
		}
		found = true;
	}

	delete item;
	delete items;
	return found;
}

void RemoveWeaponFromPlayer(int client, int weapon)
{
	if (!IsValidEntity(weapon))
	{
		return;
	}

	int extraWearable = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if (extraWearable != -1 && IsValidEntity(extraWearable))
	{
		RemoveEntity(extraWearable);
	}

	extraWearable = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if (extraWearable != -1 && IsValidEntity(extraWearable))
	{
		RemoveEntity(extraWearable);
	}

	RemoveEntity(weapon);
}

bool LookupNameByDef(IntMap mapByDef, int defindex, char[] buffer, int maxlen)
{
	if (mapByDef == null)
	{
		return false;
	}

	return mapByDef.GetString(defindex, buffer, maxlen);
}

int LookupDefByName(StringMap map, const char[] name)
{
	if (map == null)
	{
		return -1;
	}

	int defindex;
	if (map.GetValue(name, defindex))
	{
		return defindex;
	}

	return -1;
}

/* Natives */
int Native_FindItemByDefIndex(Handle plugin, int numParams)
{
	char name[64];
	if (LookupNameByDef(g_hItemsByDef, GetNativeCell(1), name, sizeof(name)))
	{
		SetNativeString(2, name, GetNativeCell(3));
		return true;
	}

	SetNativeString(2, "", GetNativeCell(3));
	return false;
}

int Native_FindAttributeByDefIndex(Handle plugin, int numParams)
{
	char name[64];
	if (LookupNameByDef(g_hAttributesByDef, GetNativeCell(1), name, sizeof(name)))
	{
		SetNativeString(2, name, GetNativeCell(3));
		return true;
	}

	SetNativeString(2, "", GetNativeCell(3));
	return false;
}

int Native_FindItemByName(Handle plugin, int numParams)
{
	char name[64];
	GetNativeString(1, name, sizeof(name));
	return LookupDefByName(g_hItems, name);
}

int Native_FindAttributeByName(Handle plugin, int numParams)
{
	char name[64];
	GetNativeString(1, name, sizeof(name));
	return LookupDefByName(g_hAttributes, name);
}

int Native_GetClassName(Handle plugin, int numParams)
{
	int defindex = GetNativeCell(1);
	int maxlen = GetNativeCell(3);

	char className[64];
	if (g_hItemClasses != null && g_hItemClasses.GetString(defindex, className, sizeof(className)))
	{
		SetNativeString(2, className, maxlen);
		return true;
	}

	SetNativeString(2, "", maxlen);
	return false;
}

int Native_GiveNamedItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	char itemName[64];
	GetNativeString(2, itemName, sizeof(itemName));

	char itemClass[64];
	if (numParams >= 3)
	{
		GetNativeString(3, itemClass, sizeof(itemClass));
	}

	int defindex = -1;
	if (numParams >= 4)
	{
		defindex = GetNativeCell(4);
	}

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return -1;
	}

	if (itemName[0] == '\0')
	{
		return -1;
	}

	/* Resolve the item's defindex. */
	if (defindex < 0)
	{
		defindex = LookupDefByName(g_hItems, itemName);
		if (defindex < 0)
		{
			return -1;
		}
	}

	char className[64];
	if (itemClass[0] != '\0')
	{
		strcopy(className, sizeof(className), itemClass);
	}
	else if (g_hItemClasses == null || !g_hItemClasses.GetString(defindex, className, sizeof(className)))
	{
		strcopy(className, sizeof(className), itemName);
		for (int i = 0; className[i] != '\0'; i++)
		{
			className[i] = CharToLower(className[i]);
		}
	}

	ArrayList loadout = new ArrayList();
	for (int i = 0; i < MAX_WEAPONS; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1 || !IsValidEntity(weapon))
		{
			continue;
		}

		loadout.Push(weapon);
	}

	int entity = CreateEntityByName(className);
	if (entity == -1)
	{
		delete loadout;
		return -1;
	}

	SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", defindex);
	SetEntProp(entity, Prop_Send, "m_iEntityLevel", 0);
	SetEntProp(entity, Prop_Send, "m_bInitialized", 1);
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);

	char scriptFile[PLATFORM_MAX_PATH];
	FormatEx(scriptFile, sizeof(scriptFile), "scripts/%s.txt", className);

	KeyValues kv = new KeyValues("WeaponData");
	if (kv.ImportFromFile(scriptFile))
	{
		int clipSize = kv.GetNum("clip_size", -1);
		if (clipSize == -1)
		{
			clipSize = kv.GetNum("default_clip", -1);
		}

		if (clipSize != -1)
		{
			SetEntProp(entity, Prop_Send, "m_iClip1", clipSize);
		}

		int maxAmmo = kv.GetNum("MaxAmmo", -1);

		char primaryAmmo[32], secondaryAmmo[32];
		kv.GetString("primary_ammo", primaryAmmo, sizeof(primaryAmmo), "None");
		kv.GetString("secondary_ammo", secondaryAmmo, sizeof(secondaryAmmo), "None");

		if (maxAmmo != -1)
		{
			if (strcmp(primaryAmmo, "None") != 0)
			{
				if (strcmp(primaryAmmo, "TF_AMMO_PRIMARY") == 0)
				{
					SetEntProp(client, Prop_Data, "m_iAmmo", maxAmmo, 4, TF_AMMO_PRIMARY);
				}
			}
			if (strcmp(secondaryAmmo, "None") != 0)
			{
				if (strcmp(secondaryAmmo, "TF_AMMO_SECONDARY") == 0)
				{
					SetEntProp(client, Prop_Data, "m_iAmmo", maxAmmo, 4, TF_AMMO_SECONDARY);
				}
			}
		}
	}
	delete kv;

	DispatchSpawn(entity);

	EquipPlayerWeapon(client, entity);

	for (int i = 0; i < loadout.Length; i++)
	{
		int oldWeapon = loadout.Get(i);

		bool equipped = false;
		for (int j = 0; j < 48 && !equipped; j++)
		{
			if (GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", j) == oldWeapon)
			{
				equipped = true;
			}
		}

		if (!equipped && IsValidEntity(oldWeapon))
		{
			int extraWearable = GetEntPropEnt(oldWeapon, Prop_Send, "m_hExtraWearable");
			if (extraWearable != -1 && IsValidEntity(extraWearable))
			{
				RemoveEntity(extraWearable);
			}

			extraWearable = GetEntPropEnt(oldWeapon, Prop_Send, "m_hExtraWearableViewModel");
			if (extraWearable != -1 && IsValidEntity(extraWearable))
			{
				RemoveEntity(extraWearable);
			}

			RemoveEntity(oldWeapon);
		}
	}

	delete loadout;
	return entity;
}

int Native_RemoveItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	char itemName[64];
	GetNativeString(2, itemName, sizeof(itemName));

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}

	int defindex = LookupDefByName(g_hItems, itemName);
	if (defindex < 0)
	{
		return false;
	}

	for (int i = 0; i < 48; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1 || !IsValidEntity(weapon))
		{
			continue;
		}

		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") != defindex)
		{
			continue;
		}

		RemoveWeaponFromPlayer(client, weapon);
		return true;
	}

	return false;
}

int Native_RemoveAllItems(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}

	bool removed = false;
	for (int i = 0; i < 48; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1 || !IsValidEntity(weapon))
		{
			continue;
		}

		RemoveWeaponFromPlayer(client, weapon);
		removed = true;
	}

	return removed;
}

int Native_GetPlayerWeapons(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client (%d)", client);
	}

	bool useNames = GetNativeCell(2);

	ArrayList weapons = new ArrayList(useNames ? 64 : 1);

	char name[64];
	for (int i = 0; i < 48; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1 || !IsValidEntity(weapon))
		{
			continue;
		}

		int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		if (useNames)
		{
			if (defindex < 0 || !LookupNameByDef(g_hItemsByDef, defindex, name, sizeof(name)))
			{
				IntToString(defindex, name, sizeof(name));
			}

			weapons.PushString(name);
		}
		else
		{
			weapons.Push(defindex);
		}
	}

	return weapons;
}