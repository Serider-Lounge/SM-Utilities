public void OnClientDisconnect(int client)
{
    g_ThirdPerson[client] = false;
    g_IsVIP[client] = false;
}