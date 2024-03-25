int Weapon_GetPrimaryAmmoType(int weapon)
{
        return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

int Weapon_GetSecondaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
}

void Client_SetWeaponPlayerAmmoEx(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1)
{
        int offset_ammo = FindDataMapInfo(client, "m_iAmmo");

        if (primaryAmmo != -1) {
                int offset = offset_ammo + (Weapon_GetPrimaryAmmoType(weapon) * 4);
                SetEntData(client, offset, primaryAmmo, 4, true);
        }

        if (secondaryAmmo != -1) {
                int offset = offset_ammo + (Weapon_GetSecondaryAmmoType(weapon) * 4);
                SetEntData(client, offset, secondaryAmmo, 4, true);
        }
}

// --
// 最早的版本中没有包括left4dhooks函数库，记得我可能对这些函数进行了一些修改，所以在这里使用自定义的版本以防万一
// --
/**
 * Set players temporarily health. Allows for setting above 200 HP.
 *
 * @param client                Client index.
 * @param tempHealth    Temporarily health.
 * @noreturn
 * @error                               Invalid client index.
 */
void ML4D_SetPlayerTempHealthFloat(int client, float tempHealth)
{
        static ConVar painPillsDecayCvar;
        if (painPillsDecayCvar == null)
        {
                painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
                if (painPillsDecayCvar == null)
                {
                        return;
                }
        }
//	PrintToChatAll("!");
        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", tempHealth);
//        SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime() + ((tempHealth - 200) / painPillsDecayCvar.FloatValue + 1 / painPillsDecayCvar.FloatValue));
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime() );
}
/**
 * Returns player temporarily health.
 *
 * Note: This will not work with mutations or campaigns that alters the decay
 * rate through vscript'ing. If you want to be sure that it works no matter
 * the mutation, you will have to detour the OnGetScriptValueFloat function.
 * Doing so you are able to capture the altered decay rate and calculate the
 * temp health the same way as this function does.
 *
 * @param client                Client index.
 * @return                              Player's temporarily health, -1 if unable to get.
 * @error                               Invalid client index or unable to find pain_pills_decay_rate cvar.
 */
int ML4D_GetPlayerTempHealth(int client)
{
        static ConVar painPillsDecayCvar;
        if (painPillsDecayCvar == null)
        {
                painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
                if (painPillsDecayCvar == null)
                {
                        return -1;
                }
        }

        int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * painPillsDecayCvar.FloatValue)) - 1;
        return tempHealth < 0 ? 0 : tempHealth;
}
// ****************************************************************
void ExecuteRootCommand(int client, const char[] cmd)
{
		int flag = GetUserFlagBits(client);
		bool hasFlag;
		if(flag == 0 || !(flag & ADMFLAG_ROOT) )
		{
			hasFlag = true;
			SetUserFlagBits(client, flag | ADMFLAG_ROOT);
		}
		FakeClientCommand(client, cmd);

		if(hasFlag)
			SetUserFlagBits(client, flag & ~ADMFLAG_ROOT);
}

int GetPlayerNum()
{
  int count;
  for(int i =1; i<=MaxClients; i++)
  {
    //https://forums.alliedmods.net/archive/index.php/t-132438.html
    if(IsClientConnected(i) )
    {
      if(IsClientInGame(i) )
          if(GetClientTeam(i) == 2)
            count++;
    }
  }
  return count;
}

void fuc_Precache()
{
  PrefetchSound(PlayerTankSpawned_Hint);
  PrecacheSound(PlayerTankSpawned_Hint);

  for( int i = 0; i < MAX_WEAPONS2; i++ )
    PrecacheModel(g_sWeaponModels2[i], true);

  PrecacheModel("models/weapons/melee/v_bat.mdl", true);
  PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", true);
  PrecacheModel("models/weapons/melee/v_crowbar.mdl", true);
  PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", true);
  PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
  PrecacheModel("models/weapons/melee/v_frying_pan.mdl", true);
  PrecacheModel("models/weapons/melee/v_golfclub.mdl", true);
  PrecacheModel("models/weapons/melee/v_katana.mdl", true);
  PrecacheModel("models/weapons/melee/v_machete.mdl", true);
  PrecacheModel("models/weapons/melee/v_tonfa.mdl", true);
  PrecacheModel("models/weapons/melee/v_pitchfork.mdl", true);
  PrecacheModel("models/weapons/melee/v_shovel.mdl", true);

  PrecacheModel("models/weapons/melee/w_bat.mdl", true);
  PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", true);
  PrecacheModel("models/weapons/melee/w_crowbar.mdl", true);
  PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", true);
  PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
  PrecacheModel("models/weapons/melee/w_frying_pan.mdl", true);
  PrecacheModel("models/weapons/melee/w_golfclub.mdl", true);
  PrecacheModel("models/weapons/melee/w_katana.mdl", true);
  PrecacheModel("models/weapons/melee/w_machete.mdl", true);
  PrecacheModel("models/weapons/melee/w_tonfa.mdl", true);
  PrecacheModel("models/weapons/melee/w_pitchfork.mdl", true);
  PrecacheModel("models/weapons/melee/w_shovel.mdl", true);

  PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
  PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
  PrecacheGeneric("scripts/melee/crowbar.txt", true);
  PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
  PrecacheGeneric("scripts/melee/fireaxe.txt", true);
  PrecacheGeneric("scripts/melee/frying_pan.txt", true);
  PrecacheGeneric("scripts/melee/golfclub.txt", true);
  PrecacheGeneric("scripts/melee/katana.txt", true);
  PrecacheGeneric("scripts/melee/machete.txt", true);
  PrecacheGeneric("scripts/melee/tonfa.txt", true);
  PrecacheGeneric("scripts/melee/pitchfork.txt", true);
  PrecacheGeneric("scripts/melee/shovel.txt", true);

  // 基本都是give命令可以直接获取的物品 也许根本不需要预缓存
  PrecacheModel("models/weapons/melee/v_gnome.mdl", true);
  PrecacheGeneric("scripts/weapon_gnome.txt", true);
  // 对于MPDS服务器，烟花盒其他插件会进行操作（随机替换Gascan）
  {
    int i;
    for( i = 0; i <= 3; i++ ) PrecacheParticle(g_sParticles[i]);
    for( i = 0; i <= 3; i++ ) PrecacheSound(g_sSoundsBursts[i], true);
    for( i = 0; i <= 5; i++ ) PrecacheSound(g_sSoundsLaunch[i], true);
    PrecacheModel(MODEL_CRATE, true);	
  }
}
// https://forums.alliedmods.net/showthread.php?p=1441088
void PrecacheParticle(const char[] sEffectName)
{
        static int table = INVALID_STRING_TABLE;
        if( table == INVALID_STRING_TABLE )
        {
                table = FindStringTable("ParticleEffectNames");
        }

        if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
        {
                bool save = LockStringTables(false);
                AddToStringTable(table, sEffectName);
                LockStringTables(save);
        }
}
// ****************************************************************
int PT_Add(int client, int pt)
{
  if(g_bCookieCached[client])  
  {
    g_iPlayerPT[client] = g_iPlayerPT[client] + pt;
    PT_Update(client, true);
    return 0;
  }

  return -1;
}

int PT_Subtract(int client, int pt)
{
  if(g_bCookieCached[client])  
  {
    g_iPlayerPT[client] = g_iPlayerPT[client] - pt;
    PT_Update(client, true);
    return 0;
  }

  return -1;
}

int PT_Get(int client, char[] sPt)
{
  if(g_bCookieCached[client])  
  {
    IntToString(PT_Update(client, false), sPt, 16 );    
    return 1;
  }
  Format(sPt, 16, "COOKIENOTCACHED");
  return 0;
}


int PT_Update(int client, bool write)
{
  char sPT[16];
  chPlayerPT = FindClientCookie("mpds_pt_re3");
  GetClientCookie(client, chPlayerPT, sPT, sizeof(sPT) );

  if(!write)
  {
    g_iPlayerPT[client] = StringToInt(sPT);
  }
  else
  {
    IntToString(g_iPlayerPT[client], sPT, sizeof(sPT) );
    SetClientCookie(client, chPlayerPT, sPT);
  }

  return g_iPlayerPT[client];
}
// ****************************************************************
void ResetClientCount_LDW()
{
  for(int i=1; i<= MaxClients; i++)
    g_iClientCount_LDW[i] = -1;
}
// 不在章节失败时刷新
void ResetClientShopItemInventory()
{
  PrintToServer("\n[商店] 重置客户端物品可购买物品的剩余数量\n");

  for(int client=0; client<SingleMapMaxPlayers; client++)
    for(int idx=0; idx< SHOP_ITEM_NUM+1; idx++)
      g_iClientShopItemRemainingQuantity[client][idx] = -1;
}

void SetClientShopItemInventory(client, item, value)
{
  int id = GetSteamAccountID(client);
  if(id != 0)
  {
    int idx = ShopItemInventory_GetClientIndexOfSteamID(id);
    if(idx != -1)
      g_iClientShopItemRemainingQuantity[idx][item] = value;
    else  PrintToChatAll("ERROR: SetClientShopItemInventory(); %N# target idx == 0", client);
  }
  else  PrintToChatAll("ERROR: SetClientShopItemInventory(); %N# id == 0", client);
}

int GetClientShopItemInventory(client, item)
{
  int id = GetSteamAccountID(client);
  if(id != 0)
  {
    int idx = ShopItemInventory_GetClientIndexOfSteamID(id);
    if(idx != -1)
    {
      if(g_iClientShopItemRemainingQuantity[idx][item] == -1 )
        return SubShop_ItemInventory.Get(item);
  
      return  g_iClientShopItemRemainingQuantity[idx][item];
    }
    else  PrintToChatAll("ERROR: GetClientShopItemInventory(); %N# target idx == 0", client);
  }
  else  PrintToChatAll("ERROR: GetClientShopItemInventory(); %N# id == 0", client);

  return 0;
}

int ShopItemInventory_GetClientIndexOfSteamID(int id)
{
  for(int i=0; i<SingleMapMaxPlayers; i++)
  {
    if(g_iClientShopItemRemainingQuantity[i][SHOP_ITEM_NUM] == id)
      return i;
  }

  return -1;
}

int Get_SubShopItemWeaponPrice(int ShopItemIndex, int client)
{
  static char sPrice[32];
  static int iPrice;
  SubShop_ItemPrice.GetString(ShopItemIndex, sPrice, sizeof(sPrice) );

  if(strncmp(sPrice, "f", 1, false) == 0)
    iPrice = 0;
  else if(strncmp(sPrice, "l", 1, false) == 0)
    iPrice = -1;
  else if(StrContains(sPrice, "+", false) != -1)
  { 
    static char buffer[2][16];
    ExplodeString(sPrice, "+", buffer, 2, 16);
    static int ownpt;
    static char sPt[16];
    if(PT_Get(client, sPt) )
      ownpt = StringToInt(sPt);
    // 如果是实时的计算价格，那么就应该避免客户端在Cookie未加载的情况下打开商店.
    else  
      ownpt = 100000;

    iPrice = StringToInt(buffer[0]) + (RoundToCeil(StringToFloat(buffer[1]) * (ownpt < 0 ? -ownpt : ownpt )) );
  }
  else 
    iPrice = StringToInt(sPrice);

  return iPrice;
}
// 获取特定类型商店拥有的物品总数
int GetSubShopItemNum(int type)
{
  if( (type + 1) <=  (MAXSHOPTYPE - 1) )
    return (g_iShopArrayIndexOffest[type+1] - g_iShopArrayIndexOffest[type] );

  if( type == 0)
    return g_iShopArrayIndexOffest[type+1];

  return (SubShop_ItemDisplayName.Length - g_iShopArrayIndexOffest[type]);
}
