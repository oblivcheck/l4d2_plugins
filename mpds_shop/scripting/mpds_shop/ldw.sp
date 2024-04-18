void LDW(int client, bool limit=false)
{
  SetRandomSeed(RoundToFloor(GetEngineTime() ) );

  if(limit)
  {
    if(g_iClientCount_LDW[client] == 0)
    {
      CPrintToChat(client, "{blue}[商店-抽奖]\x01 你当前章节剩余的抽奖次数不足...");
      return;
    }
    g_iClientCount_LDW[client]--;
  }
  
  float value = GetRandomFloat(0.00, 1000.00);
  if(value < 100.00)
  {
    ServerCommand("sm_slay #%d", GetClientUserId(client));
    //SDKHooks_TakeDamage(client, 0, 0, 1000.0, DMG_FALL);    
    CPrintToChatAll("{blue}[商店-抽奖]\x01 %N 花费{blue} %d pt\x01获得了\x05解脱...", client, LDW_PRICE);
    PT_Get(client, _PTS);
    CPrintToChat(client, "{blue} 剩余: %s pt", _PTS );
    return;    
  }
  if(value < 400.00)
  {
    int pt = RoundToNearest(GetRandomFloat(-60.00, 30.00) );
    PT_Add(client, pt);
    CPrintToChatAll("{blue}[商店-抽奖]\x01 %N 花费{blue} %d pt\x01获得了\x05 %d pt", client, LDW_PRICE, pt);
    PT_Get(client, _PTS);
    CPrintToChat(client, "{blue} 剩余: %s pt", _PTS );
    return;
  }

  bool allow = true;
  while(allow)
  {    
    int idx = RoundToNearest(GetRandomFloat(0.00, float(SubShop_ItemDisplayName.Length-1) ) );
    if(Get_SubShopItemWeaponPrice(idx, client) == -1 )
      continue;
    char name[64];
    SubShop_ItemName.GetString(idx, name, sizeof(name) );
    // 这里是针对随机物品，锁定的选项&&特殊效果会被上一步先行排除，仅限于目前的状态.
    if(!name[0] )
      continue;

    allow = false;
    if(SetItems(client, name, idx, LDW_PRICE) )
    {
      SubShop_ItemDisplayName.GetString(idx, name, sizeof(name) );    
      CPrintToChatAll("{blue}[商店-抽奖]\x01 %N 花费{blue} %d pt\x01获得了\x05 %s", client, LDW_PRICE, name);
    }
    else
    {
      if(limit)
        g_iClientCount_LDW[client]++;  

      CPrintToChat(client, "{blue}[商店-抽奖]\x01 设置物品失败，所有花费已返还.");
    }
    PT_Get(client, _PTS);
    CPrintToChat(client, "{blue} 剩余: %s pt", _PTS );
  }
}


