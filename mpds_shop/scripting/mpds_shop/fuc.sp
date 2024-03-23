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
