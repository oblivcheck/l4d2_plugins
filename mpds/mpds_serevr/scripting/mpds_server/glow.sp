//---------------------------------------------------------------------------||
//              角色光晕，用于写实模式
//---------------------------------------------------------------------------||
#define  GlowColor  255 + 20*256 + 147*65536    //value = [0] + [1]*256 + [2]*65535

ConVar  g_hGlow;
bool  g_bGlow;

ConVar  g_hGlowDist;
int  g_iGlowDist;

ConVar  g_hHintName;
bool  g_bHintName;

ConVar  g_hHintName_Dist;
float  g_fHintName_Dist;

Handle  g_hGlowTimer;
bool  hasGlow[MAXPLAYERS+1];

ConVar  hIsRealismMode;
bool  IsRealismMode;

void _Glow_OnPluginStart()
{
  g_hGlow = CreateConVar("mpds_glow", "0");
  g_hGlow.AddChangeHook(Event_ConVarDiffLockChanged);

  g_hGlowDist = CreateConVar("mpds_glow_dist", "1200");
  g_hGlowDist.AddChangeHook(Event_ConVarDiffLockChanged);

  g_hHintName = CreateConVar("mpds_hintname", "0");
  g_hHintName.AddChangeHook(Event_ConVarDiffLockChanged);

  g_hHintName_Dist = CreateConVar("mpds_hintname_dist", "150.0");
  g_hHintName_Dist.AddChangeHook(Event_ConVarDiffLockChanged);

  hIsRealismMode = FindConVar("mp_gamemode");
  char buffer[16];
  hIsRealismMode.GetString(buffer, sizeof(buffer) );
  if(strcmp(buffer, "realism") == 0 )
    IsRealismMode = true;
  else    IsRealismMode = false;
  hIsRealismMode.AddChangeHook(Event_ConVarChanged);
}

void _Glow_Event_ConVarChanged()
{
  char buffer[16];
  hIsRealismMode.GetString(buffer, sizeof(buffer) );
  if(strcmp(buffer, "realism") == 0 )
    IsRealismMode = true;
  else    IsRealismMode = false;

  if(IsRealismMode)
  {
    ServerCommand("mpds_glow 1");
    ServerCommand("mpds_hintname 1");
  }
}
void _Glow_CreateTimer()
{
  g_hGlowTimer = CreateTimer(3.0, tSetGlow, TIMER_REPEAT);
}

void set_glow(int client)
{  
  if(!hasGlow[client])
  {
    hasGlow[client] = true;
    SetEntProp(client, Prop_Send, "m_iGlowType", 3);
    SetEntProp(client, Prop_Send, "m_glowColorOverride", GlowColor);
    SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
    SetEntProp(client, Prop_Send, "m_nGlowRangeMin", g_iGlowDist);
    SetEntProp(client, Prop_Send, "m_bFlashing", 1);
  }
}

void reset_glow(int i)
{
  if(i)
  {
    hasGlow[i] = false;
    SetEntProp(i, Prop_Send, "m_iGlowType", 0);
    SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
    SetEntProp(i, Prop_Send, "m_nGlowRange", 0);
    SetEntProp(i, Prop_Send, "m_nGlowRangeMin", 0);
    SetEntProp(i, Prop_Send, "m_bFlashing", 0);
    return;
  }
      
  for(int client=1; client<=MaxClients; client++)
  {
    hasGlow[client] = false;

    if(!IsClientConnected(client) )
      continue;
    if(!IsClientInGame(client) )
      continue;
    if(!(GetClientTeam(client) == 2) )
      continue;

    SetEntProp(client, Prop_Send, "m_iGlowType", 0);
    SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
    SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
    SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
    SetEntProp(client, Prop_Send, "m_bFlashing", 0);
  }
}


Action tSetGlow(Handle Timer)
{

  if(!g_bGlow)
    return Plugin_Stop;

  for(int client=1; client<=MaxClients; client++)
  {
    if(!IsClientConnected(client) )
      continue;
    if(!IsClientInGame(client) )
      continue;
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client) )
      set_glow(client);
    // 不知道是否需要检查，会将战役中的特定状态Glow也覆盖吗？
    else  reset_glow(client);
  }

  return Plugin_Continue;
}

public void ThirdstrikeGlow_OnSetGlow(int client)
{
  hasGlow[client] = true;  
}

public void ThirdstrikeGlow_OnResetGlow(int client)
{
  hasGlow[client] = false;
}


