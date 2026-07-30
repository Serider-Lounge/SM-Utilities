public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    char convarName[64];
    convar.GetName(convarName, sizeof(convarName));
    if (StrEqual(convarName, "nav_generate_auto"))
    {
        NavGenerate();
    }
    else if (StrEqual(convarName, "mp_friendlyfire"))
    {
        g_ConVars[sm_navbot_tf_teammates_are_enemies].SetBool(convar.BoolValue);
    }
    else if (StrContains(convarName, "tf_mvm") == 0 ||
             StrContains(convarName, "sm_bots_fun_quota") == 0 ||
             StrEqual(convarName, "sm_bots_fun_type"))
    {
        MaintainBotQuota();
    }
}