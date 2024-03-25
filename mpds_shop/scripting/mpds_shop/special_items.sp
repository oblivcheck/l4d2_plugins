// 生成并控制一只Tank
bool SetItems_AllowSpawnTank(int client)
{
  if(L4D2_IsTankInPlay() || g_iTank_player != -1)
  {
        PrintToChat(client, "\x04 游戏中不能有存活的Tank！");
        return false;
  }
  if(GetPlayerNum() < 8)
  {
    PrintToChat(client, "\x04 游戏中的幸存者数量必须大于7个.");
    return false;
  }
  return true;
}

bool Sitems_SpawnPlayerTank(int client, int ShopItemIndex)
{
  int flags = GetCommandFlags("z_spawn_old");
  SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
  FakeClientCommand(client, "z_spawn_old tank auto");
  SetCommandFlags("z_spawn_old", flags);      
  g_bSpawnPlayerTank = true;
  for(int i=1; i<=MaxClients; i++)
  {
    if(!IsClientInGame(i) )
      continue;
    if(GetClientTeam(i) == 3)
    {
      if(GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
      {
        g_iTank_player = client;
        ExecuteRootCommand(client, "sm_ji");
        L4D_ReplaceTank(i, client);

        char sDiff[16];
        ConVar hDiff = FindConVar("z_difficulty");
        hDiff.GetString(sDiff, sizeof(sDiff) );
        if(strncmp(sDiff, "H", 1, false) == 0 || strncmp(sDiff, "I", 1, false) == 0 )
        {
          int hp = GetEntProp(client, Prop_Send, "m_iHealth") / 2;
          SetEntProp(client, Prop_Send, "m_iHealth", hp);
        }

        PT_Subtract(client, Get_SubShopItemWeaponPrice(ShopItemIndex, client) );
        CreateTimer(0.5, tPlayerTankSpawned_SendMSG, client, TIMER_REPEAT);
        return true;
      }
    }
  }
  PrintToChat(client, "\x04 没有找到生成的Tank.");
  return false;
}

Action tPlayerTankSpawned_SendMSG(Handle Tiemr, any client)
{
  if(g_iPlayerTankSpawned_SendMSG_Count == 6)
  {
    g_iPlayerTankSpawned_SendMSG_Count=0;
    return Plugin_Stop;
  }
  if(IsClientInGame(client) )
  {
    if(GetClientTeam(client) == 3)
    {
      EmitSoundToAll(PlayerTankSpawned_Hint, SOUND_FROM_PLAYER);      
      char sDiff[16];
      ConVar hDiff = FindConVar("z_difficulty");
      hDiff.GetString(sDiff, sizeof(sDiff) );
      if(strncmp(sDiff, "H", 1, false) == 0 || strncmp(sDiff, "I", 1, false) == 0 )
        CPrintToChatAll("{red}[TANK] \x03%N\x05已经控制了一只{red}50%%\x05血量的{red}Tank\x05！", client);
      else  CPrintToChatAll("{red}[TANK] \x03%N\x05已经控制了一只{red}100%%\x05血量的{red}Tank\x05！", client);

      g_iPlayerTankSpawned_SendMSG_Count++;
    }
  }
  return Plugin_Continue;
}
// 发射烟花
void Sitems_Fireworks(int client, const char[] weapon)
{
    char buffer[2][16];
    ExplodeString(weapon, "+", buffer, 2, 16);
    ExecuteRootCommand(client, buffer[1]);
    PrintToChat(client, "\x03  烟花正在你瞄准的位置发射！！！");
    PrintToChatAll( "\x05%N\x01 发射了一枚烟花！", client);    
}
