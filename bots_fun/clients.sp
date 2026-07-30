public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
    {
        SDKHook(client, SDKHook_CanBeAutobalanced, CanBeAutoBalanced);
    }
}