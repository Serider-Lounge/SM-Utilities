#if defined _tf2itemschema_included
  #endinput
#endif
#define _tf2itemschema_included

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

/**
 * Look for "item_name" based on the defindex (fetch from the late-generated 'items_game.json').
 *
 * @param 	defindex 	The defindex to look for.
 * @param   buffer 		The buffer to store the item_name in.
 * @param   maxlen 		The maximum length of the buffer.
 * @return 				True if the item was found, false otherwise.
 */
native bool TFSchema_FindItemByDefIndex(int defindex, char[] buffer, int maxlen);

/**
 * Look for the defindex based on the item's name (fetch from the late-generated 'items_game.json').
 *
 * @param 	item_name 	The name of the item to look for.
 * @return 				The defindex of the item, or -1 if not found.
 */
native int TFSchema_FindItemByName(const char[] item_name);

/**
 * Look for the attribute's defindex based on the attribute's name (fetch from the late-generated 'items_game.json').
 *
 * @param 	attribute_name 	The name of the attribute to look for.
 * @return 					The defindex of the attribute, or -1 if not found.
 */
native int TFSchema_FindAttributeByName(const char[] attribute_name);

/**
 * Look for the attribute's name based on the attribute's defindex (fetch from the late-generated 'items_game.json').
 *
 * @param 	defindex 	The defindex of the attribute to look for.
 * @param   buffer 		The buffer to store the attribute's name in.
 * @param   maxlen 		The maximum length of the buffer.
 * @return 				True if the attribute was found, false otherwise.
 */
native bool TFSchema_FindAttributeByDefIndex(int defindex, char[] buffer, int maxlen);

/**
 * Get the classname of the item based on the defindex (fetch from the late-generated 'items_game.json').
 * In priority order, look for: item_class, base_item_name (case must be lowered), item_name (case must be lowered).
 * If none of those exist under the defindex key, look for "prefab" and search for the aforementioned keys again one more time under the prefab's key.
 *
 * @param 	defindex 	The defindex of the item to look for.
 * @param   buffer 		The buffer to store the classname in.
 * @param   maxlen 		The maximum length of the buffer.
 * @return 				True if the classname was resolved, false otherwise.
 */
native bool TFSchema_GetClassName(int defindex, char[] buffer, int maxlen);

/**
 * Give a named item to a player.
 *
 * @param 	client 		The client to give the item to.
 * @param 	item_name 	The name of the item to give.
 * @param 	item_class 	The classname to override the item with (NULL_STRING if omitted).
 * @param   defindex 	The defindex to override the item with (-1 if omitted).
 * @return 				Return the index of the weapon entity if found, -1 otherwise.
 */
native int TFSchema_GiveNamedItem(int client, const char[] item_name, const char[] item_class = NULL_STRING, int defindex = -1);

/**
 * Remove an item from a player.
 *
 * @param 	client 		The client to remove the item from.
 * @param 	item_name 	The name of the item to remove.
 * @return 				True if the item was removed successfully, false otherwise.
 */
native bool TFSchema_RemoveItem(int client, const char[] item_name);

/**
 * Remove all items from a player.
 *
 * @param 	client 		The client to remove the items from.
 * @return 				True if the items were removed successfully, false otherwise.
 */
native bool TFSchema_RemoveAllItems(int client);

/**
 * Store all weapons from a player in an ArrayList by iterating through m_hMyWeapons.
 *
 * Each element is either the item's name or its defindex, depending on useNames.
 *
 * @param 	client 		The client to get the weapons from.
 * @param   useNames 	Whether to store the item names (true) or their defindexes (false, by default).
 * @return 				An ArrayList containing the weapon names or defindexes. The caller is
 *                      responsible for closing the list.
 * @error 				Invalid client.
 */
native ArrayList TFSchema_GetPlayerWeapons(int client, bool useNames = false);

public SharedPlugin __pl_tf2itemschema =
{
	name = "tf2itemschema",
	file = "tf2itemschema.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_tf2itemschema_SetNTVOptional()
{
	MarkNativeAsOptional("TFSchema_FindItemByDefIndex");
	MarkNativeAsOptional("TFSchema_FindItemByName");
	MarkNativeAsOptional("TFSchema_FindAttributeByName");
	MarkNativeAsOptional("TFSchema_FindAttributeByDefIndex");
	MarkNativeAsOptional("TFSchema_GetClassName");
	MarkNativeAsOptional("TFSchema_GiveNamedItem");
	MarkNativeAsOptional("TFSchema_RemoveItem");
	MarkNativeAsOptional("TFSchema_RemoveAllItems");
	MarkNativeAsOptional("TFSchema_GetPlayerWeapons");
}
#endif