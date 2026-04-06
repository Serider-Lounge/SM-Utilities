/**
 * Formats a player's name with their render color if set, or team color otherwise.
 *
 * @param client    Client index.
 * @param name      Buffer to store the formatted name.
 * @param maxlen    Maximum length of the buffer.
 */
stock void GetPlayerName(int client, char[] name, int maxlen)
{
	int red, green, blue, alpha, color;
	GetEntityRenderColor(client, red, green, blue, alpha);
	color = (red << 16) | (green << 8) | blue;
	if (color != 0xFFFFFF)
	{
		Format(name, maxlen, "\x07%06X%N\x01", color, client);
	}
	else
	{
		Format(name, maxlen, "\x03%N\x01", client);
	}
}