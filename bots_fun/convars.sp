public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    for (int i = 0; i < MAX_CONVARS; i++)
    {
        if (g_ConVars[i] == convar)
        {
            switch (i)
            {
                case plugin_nav_generate_auto:
                {
                    NavGenerate();
                }
                case mp_friendlyfire:
                {
                    g_ConVars[sm_navbot_tf_teammates_are_enemies].SetBool(convar.BoolValue);
                }
                case plugin_bot_type:
                {
                    UpdateBotTypes();
                    MaintainBotQuota();
                }
                case plugin_bot_quota,
                     plugin_bot_quota_mode,
                     plugin_bot_quota_interval,
                     plugin_bot_quota_mvm,
                     plugin_bot_type_random,
                     tf_mvm_defenders_team_size,
                     tf_mvm_max_invaders:
                {
                    MaintainBotQuota();
                }
            }
            break;
        }
    }
}