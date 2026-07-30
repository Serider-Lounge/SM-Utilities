bool CanBeAutoBalanced(int client, bool origRet)
{
    if (g_IsTF2SDK)
    {
        // https://github.com/caxanga334/sm-plugins/blob/master/source/autobalance_bots.sp
        if (TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
            TF2_IsPlayerInCondition(client, TFCond_HalloweenKart))
        {
            return false;
        }
    }
    return true;
}