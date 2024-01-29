#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>
#include <left4dhooks>
#include <mpds_shop>

#define PLUGIN_NAME             "MPDS Shop"
#define PLUGIN_DESCRIPTION      "服务器商店与内嵌的击杀奖励系统"
#define PLUGIN_VERSION          "REV 1.0.0 Beta 2"
#define PLUGIN_AUTHOR           "oblivcheck"
#define PLUGIN_URL              "https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop"

/************************************************************************

Changes Log:

2024-01-29 (REV 1.0.0 Beta 2)
   - Add some macro definitions to modify the plugin settings.
   - Organize the code.

2024-01-29 (REV 1.0.0 Beta)
	- Initial version.

* Earlier versions were based on hp_rewards(https://forums.alliedmods.net/showthread.php?p=2411161)
	* version 2.2

* My own final version: 1.2.2 (fork by 2.2)
	* 1.2.2 (fork by 2.2) -> REV 1.0.0 Beta

************************************************************************/

#define DEBUG 0

#define ClassTank	8
bool	On;

//---------------------------------------------------------------------------||

// 游戏默认的生命值上限，用于逻辑判断
#define	MAX_HEALTH_DEF		100
// 永久生命值的上限，临时生命值没有特别设置，这意味着最大总生命值应该是200? 
//   默认游戏设置下，过多的临时生命值，将导致倒地时的生命值接近400？只是猜测
#define	MAX_HP			150

// 帮助队友获得的奖励：pt与永久生命值
#define	DEFIB_REWARD		60
#define	DEFIB_REWARD_PT		20
#define	HEAL_REWARD		20
#define	HEAL_REWARD_PT		5
#define	REVIVE_REWARD		30
#define REVIVE_REWARD_PT	5
// 如果玩家挂边，获取他当前倒地生命值的Tick间隔
#define	HANGING_CHECK_INTERVAL	45
// 挂边时，被救助的玩家生命值低于这个值会被认为是需要紧急救助的
#define	REVIVE_HP_REWARD	100
// 如果被救助的玩家是挂边状态，但并不被认为是需要紧急救助，那么玩家应该恢复的生命值将被下面的值覆盖
#define	REVIVE_FAST_REWARD	10

// 扫描存活TANK的时间间隔(秒)
#define	TANK_ALIVE_TIMER_INTERVAL	5.0
// 玩家单独击杀了Tank，并且仅使用近战武器，奖励的PT
#define	TANK_SOLO_MELEE_REWARD		1000
// 击杀TANK奖励PT
#define	TANK_REWARD			10
// 仅使用近战击杀TANK额外的奖励PT
#define	TANK_ONLY_MELEE_REWARD		50
// TANK发现幸存者后，存活时间>=TANK_ALIVE_TIMER_COUNT*TANK_ALIVE_TIMER_INTERVAL
//   后开始在每一次检查中扣除幸存者的PT
#define	TANK_ALIVE_TIMER_COUNT		35
// 每一次扣除的数量
#define	TANK_ALIVE_DEDUCT		1

// 击杀特殊感染者恢复的临时生命值，
//   在玩家当前总生命值没有超过MAX_HEALTH_DEF的情况下，
//     这不会让生命值高于MAX_HEALTH_DEF
#define	BOOMER_REWARD		10.0
#define	SPITTER_REWARD		10.0
#define	SMOKER_REWARD		14.0
#define	JOCKEY_REWARD		14.0
#define	HUNTER_REWARD		18.0
#define	CHARGER_REWARD		20.0

/***商店物品的详细属性在 CacheShopItem() 中进行设置***/
// 允许抽奖的次数，如果被限制了；如果玩家的pt点数在花费LDW_PRICE之后将为负数，则启用限制
//   限制会在高于(LDW_PRICE-1)时被重置，地图结束时也将重置
//     目前的版本下，所有物品的库存也将在地图结束时重置
#define	LDW_LIMIT		2
// 抽奖需要花费的点数
#define LDW_PRICE		6

// 如果是写实模式，!buy中每一项物品的价格乘以这个值
#define	REALISM_MODE_SPENT_MULT	2.5

// 是否允许使用除颤器
// 对于MPDS服务器，它可能会导致崩溃
#define	ALLOW_USE_DEFIB		0

//---------------------------------------------------------------------------||

bool	g_bHero[MAXPLAYERS+1];
bool	g_bPlayerHanging[MAXPLAYERS+1];
int	g_iPlayerHanging_HP[MAXPLAYERS+1];

#define MODEL_CRATE                             "models/props_junk/explosive_box001.mdl"
char g_sParticles[4][] =
{
        "fireworks_01",
        "fireworks_02",
        "fireworks_03",
        "fireworks_04"
};

char g_sSoundsLaunch[6][] =
{
        "ambient/atmosphere/firewerks_launch_01.wav",
        "ambient/atmosphere/firewerks_launch_02.wav",
        "ambient/atmosphere/firewerks_launch_03.wav",
        "ambient/atmosphere/firewerks_launch_04.wav",
        "ambient/atmosphere/firewerks_launch_05.wav",
        "ambient/atmosphere/firewerks_launch_06.wav"
};

char g_sSoundsBursts[4][] =
{
        "ambient/atmosphere/firewerks_burst_01.wav",
        "ambient/atmosphere/firewerks_burst_02.wav",
        "ambient/atmosphere/firewerks_burst_03.wav",
        "ambient/atmosphere/firewerks_burst_04.wav"
};

#define MAX_WEAPONS2            29
static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
        "models/w_models/weapons/w_pistol_B.mdl",
        "models/w_models/weapons/w_desert_eagle.mdl",
        "models/w_models/weapons/w_rifle_m16a2.mdl",
        "models/w_models/weapons/w_rifle_ak47.mdl",
        "models/w_models/weapons/w_rifle_sg552.mdl",
        "models/w_models/weapons/w_desert_rifle.mdl",
        "models/w_models/weapons/w_autoshot_m4super.mdl",
        "models/w_models/weapons/w_shotgun_spas.mdl",
        "models/w_models/weapons/w_shotgun.mdl",
        "models/w_models/weapons/w_pumpshotgun_A.mdl",
        "models/w_models/weapons/w_smg_uzi.mdl",
        "models/w_models/weapons/w_smg_a.mdl",
        "models/w_models/weapons/w_smg_mp5.mdl",
        "models/w_models/weapons/w_sniper_mini14.mdl",
        "models/w_models/weapons/w_sniper_awp.mdl",
        "models/w_models/weapons/w_sniper_military.mdl",
        "models/w_models/weapons/w_sniper_scout.mdl",
        "models/w_models/weapons/w_m60.mdl",
        "models/w_models/weapons/w_grenade_launcher.mdl",
        "models/weapons/melee/w_chainsaw.mdl",
        "models/w_models/weapons/w_eq_molotov.mdl",
        "models/w_models/weapons/w_eq_pipebomb.mdl",
        "models/w_models/weapons/w_eq_bile_flask.mdl",
        "models/w_models/weapons/w_eq_painpills.mdl",
        "models/w_models/weapons/w_eq_adrenaline.mdl",
        "models/w_models/weapons/w_eq_Medkit.mdl",
        "models/w_models/weapons/w_eq_defibrillator.mdl",
        "models/w_models/weapons/w_eq_explosive_ammopack.mdl",
        "models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
};
#define SOUND_HEART                     "player/heartbeatloop.wav"

Handle	chPlayerPT;
// 临时缓存的数据
int	g_iPlayerPT[MAXPLAYERS+1];
bool	g_bCookieCached[MAXPLAYERS+1];

// 硬编码数组第二维的大小，这应该大于商店中的物品总数
#define SHOP_ITEM_NUM		64
// 为什么不使用ADT，因为早期版本中出现了问题，而我不想继续检查，故而直接硬编码大小
int g_iClientShopItemRemainingQuantity[MAXPLAYERS+1][SHOP_ITEM_NUM];

// MethodMap... 也许以后
ArrayList SubShop_ItemDisplayName;
ArrayList SubShop_ItemWeaponName;
ArrayList SubShop_ItemWeaponPrice;
ArrayList SubShop_ItemWeaponCount;
ArrayList SubShop_ItemWeaponAmmoMult;

// 应该始终以tank_burn_duration_expert值的一半进行判断 170/2 = 85 (17次计时)
// 追踪相应的Cvar变化？ 也许以后...
int g_iTankAliveTime;
// 用于与计算Tank作战过程中的点数变化，仅用于打印提示.
int g_iTankPTChanged;

int g_iClientCount_LDW[MAXPLAYERS+1];
bool	IsRealismMode;
ConVar	hIsRealismMode;

public Plugin:myinfo =
{
        name = PLUGIN_NAME,
        author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,
        version = PLUGIN_VERSION,
        url = PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("mpds_shop");

	CreateNative("MPDS_Shop_PT_Add", Native_MPDS_Shop_PT_Add);
	CreateNative("MPDS_Shop_PT_Subtract", Native_MPDS_Shop_PT_Subtract);
	CreateNative("MPDS_Shop_PT_Get", Native_MPDS_Shop_PT_Get);

	return APLRes_Success;
}

int Native_MPDS_Shop_PT_Add(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int pt = GetNativeCell(2);

	PT_Add(client, pt );

	return PT_Get(client);
}

int Native_MPDS_Shop_PT_Subtract(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int pt = GetNativeCell(2);

	PT_Subtract(client, pt);
	
	return PT_Get(client);	
}

int Native_MPDS_Shop_PT_Get(Handle plugin, int numParams)
{
	return PT_Get(GetNativeCell(1) );
}

public OnPluginStart()
{
#if !ALLOW_USE_DEFIB
	HookEvent("defibrillator_begin", Event_Defibrillator_Begin);
#endif
	HookEvent("defibrillator_used", Event_Defibrillator_Used);
	HookEvent("player_ledge_grab", Event_Player_Ledge_Grab);
	HookEvent("revive_success", Event_Revive_Success);
	HookEvent("heal_begin", Event_Heal_Begin);
	HookEvent("heal_interrupted", Event_Heal_Interrupted);
	HookEvent("heal_success", Event_Heal_Success);
// infected_death 是一个好的选择，但最早的版本测试过，是无效的。现在测试似乎有效？不理解的...
// 现在不需要这项功能，这实际上还大幅度降低了服务器的压力
//	HookEvent("infected_hurt", Event_Infected_Hurt);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	HookEvent("tank_killed", Event_Tank_Kiiled);	
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_PluginReset);
	HookEvent("finale_win", Event_PluginReset);
	HookEvent("mission_lost", Event_PluginReset);
	HookEvent("map_transition", Event_PluginReset);
	HookEvent("player_death", Event_Player_Death);
	

	hIsRealismMode = FindConVar("mp_gamemode");	
	char buffer[16];
	hIsRealismMode.GetString(buffer, sizeof(buffer) );
	if(strcmp(buffer, "realism") == 0 )
		IsRealismMode = true;
	else	IsRealismMode = false;
	hIsRealismMode.AddChangeHook(Event_ConVarChanged);

	chPlayerPT = RegClientCookie("mpds_pt_re3", "该玩家拥有的商店点数", CookieAccess_Protected);
	RegConsoleCmd("sm_buy", cmd_buy);
	RegConsoleCmd("sm_ldw", cmd_ldw);
	RegAdminCmd("sm_hreset", cmd_hreset, ADMFLAG_ROOT);	

	CacheShopItem();
	// 除非插件在运行时被更换，否则这只会在插件的生命周期内创建一次，不需要担心影响CookieCached标记的正确性
	CreateTimer(0.5, tDelayExecuteCMD);
}

Action tDelayExecuteCMD(Handle Timer)
{
	ServerCommand("sm_hreset");	
	return Plugin_Continue;
}

//---------------------------------------------------------------------------||
//              Cvar变更
//---------------------------------------------------------------------------||
public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char buffer[16];
	hIsRealismMode.GetString(buffer, sizeof(buffer) );
	if(strcmp(buffer, "realism") == 0 )
		IsRealismMode = true;
	else	IsRealismMode = false;
}
Action cmd_hreset(int client, int args)
{
	for(int i=1; i<MaxClients; i++)
	{
		g_bCookieCached[i] = true;
		if(IsClientInGame(i) )
			if(!IsFakeClient(i) )
			{
				char cC[16];
				GetClientCookie(i, chPlayerPT, cC, sizeof(cC) );
				int cookieValue = StringToInt(cC);
				ReplyToCommand(client, "%d#%N: %s#%d", i, i, cC, cookieValue);
				g_iPlayerPT[i] = PT_Get(i);			
				
			}
	}

	ResetClientShopItemCount();
	ResetClientCount_LDW();
	ReplyToCommand(client, "sm_hreset: 执行完毕");
	return Plugin_Continue;
}

// 这种方式得出的值是不准确的，现在不需要了...
// 对于会生成数百个感染者的服务器，这会显著增加服务器的压力
// 对于MPDS服务器，早期版本的测试表明：在8+玩家的尸潮场景中，移除这个功能使服务器的var降低了至少1.0ms
/*
int	g_iInfectedKilledCount[MAXPLAYERS+1];
public Action Event_Infected_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	static int client, entity, dmg, dmgtype;
//	static int sHealth;
	static bool dead;

	dmgtype = event.GetInt("type");
	if(dmgtype & DMG_BURN)
		return Plugin_Continue;

	client = GetClientOfUserId(event.GetInt("attacker") );

	if(client == 0)
		return Plugin_Continue;

	dmg = event.GetInt("amount");
	entity = event.GetInt("entityid");	
	dead = (GetEntProp(entity, Prop_Data, "m_iHealth") - dmg) <= 0;		

	if(dead)
	{
//		sHealth = GetClientHealth(client);
                float fHP = float(GetClientHealth(client)) + ML4D_GetPlayerTempHealth(client);
		int iHP = RoundToFloor(fHP);

		g_iInfectedKilledCount[client]++;
		// 50个
		if(g_iInfectedKilledCount[client] > 50)
		{
			PrintToChatAll("%d", iHP);
			if( (fHP + 8.0) < 100.0 )
				SetEntProp(client, Prop_Send, "m_iHealth", iHP+8);
			else if(fHP <= 100.0)
				SetEntProp(client, Prop_Send, "m_iHealth", 100);
	
			else if(fHP > 100.0 && (fHP + 8.0) <= 150.0)
				SetEntProp(client, Prop_Send, "m_iHealth", iHP+8);

			else if(fHP > 100.0)
				SetEntProp(client, Prop_Send, "m_iHealth", 150);

			g_iInfectedKilledCount[client] = 0;
			PrintToChat(client, "\x05杀死了大量感染者, 获得了\x038\x05奖励生命值.");			
			if (!IsFakeClient(client) )
			{
				if(PT_Add(client, 1) != -1)
					CPrintToChat(client, "\x03\x01获得了{blue} 1 pt\x01");
				else	CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");
			}

		}
	}

	return Plugin_Continue;
}
*/

public void OnClientDisconnect(int client)
{
	//g_iInfectedKilledCount[client] = 0;	
	g_bHero[client] = false;

	if(!IsFakeClient(client) )
		PT_Update(client, true);
	// 因为是有间隔的扫描
	g_bPlayerHanging[client] = false;

	// Cookie每一次连接都会重新加载
	g_bCookieCached[client] = false;
}

//---------------------------------------------------------------------------||
//		使用除颤器复活队友的奖励
//---------------------------------------------------------------------------||
#if !ALLOW_USE_DEFIB
public Action Event_Defibrillator_Begin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid") );

	PrintToChat(client, "除颤器目前已被禁止使用!");

	int target = GetPlayerWeaponSlot(client, 3);
	SDKHooks_DropWeapon(client, target);
	RemoveEntity(target);

	return Plugin_Handled;
}
#endif
public Action Event_Defibrillator_Used(Event event, const char[] name, bool dontBroadcast)

{
	int client = GetClientOfUserId(event.GetInt("userid") );

	if(client == 0)
		return Plugin_Continue;
	int target =  GetClientOfUserId(event.GetInt("subject") );
	int HP = GetClientHealth(client);
	if((HP + DEFIB_REWARD) < MAX_HP )
		SetEntProp(client, Prop_Send, "m_iHealth", HP + DEFIB_REWARD , 1);
	else	SetEntProp(client, Prop_Send, "m_iHealth", MAX_HP, 1);

	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
	// 停止播放声音的方法来自 l4d_heartbeat.sp
	// 这对我来说是一个意外发现
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);

	// Heartbeat sound, stop dupe sound bug, only way.
	RequestFrame(OnFrameSound, client);
	ResetSound(client);
	ResetSound(client);
	ResetSound(client);
	ResetSound(client);
	ResetSoundObs(client);

	PrintToChatAll("\x05%N \x03使用除颤器救回 \x05%N", client, target);
	PrintToChatAll("\x03----获得了\x05%d\x03生命值奖励并重置了自己的健康状态.", DEFIB_REWARD);

	if(!IsFakeClient(client) )
	{
		if(PT_Add(client, DEFIB_REWARD_PT) != -1 )
			CPrintToChat(client, "\x03\x01获得了{blue} %d pt\x01", DEFIB_REWARD_PT);
		else	CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");
	}

	return Plugin_Continue;
}

void ResetSoundObs(int client)
{
        for( int i = 1; i <= MaxClients; i++ )
        {
                if( IsClientInGame(i) && !IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") == client )
                {
                        RequestFrame(OnFrameSound, GetClientUserId(i));
                        ResetSound(i);
                        ResetSound(i);
                        ResetSound(i);
                        ResetSound(i);
                }
        }
}
// 需要注意MPDS服务器的设置嘛？ 它启用了偶数刻度模拟...
void OnFrameSound(int client)
{
        if( client )
        {
                ResetSound(client);
		// NextFrame ?
		// ...
        }
}

void ResetSound(int client)
{
        StopSound(client, SNDCHAN_AUTO, SOUND_HEART);
        StopSound(client, SNDCHAN_STATIC, SOUND_HEART);
}
//---------------------------------------------------------------------------||
//		治愈濒死队友的奖励		
//---------------------------------------------------------------------------||
public Action Event_Heal_Begin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid") );
	int target = GetClientOfUserId(event.GetInt("subject") );

	if(client == target)
		return Plugin_Continue;
		
	if (GetEntProp(target, Prop_Send, "m_currentReviveCount") == 2)
		g_bHero[client] = true;

	return Plugin_Continue;
}

public Action Event_Heal_Interrupted(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid") );
	int target = GetClientOfUserId(event.GetInt("subject") );

	if(client == target)
		return Plugin_Continue;

	// 也许不需要关心闲置和断开连接
	if(g_bHero[client])
		g_bHero[client] = false;

	return Plugin_Continue;
}

public Action Event_Heal_Success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid") );
	int target = GetClientOfUserId(event.GetInt("subject") );

	if(client == target)
		return Plugin_Continue;

	int HP = GetClientHealth(client);

	if (g_bHero[client])
	{
		if((HP + HEAL_REWARD) < MAX_HP )
			SetEntProp(client, Prop_Send, "m_iHealth", HP + HEAL_REWARD, 1);
		else	SetEntProp(client, Prop_Send, "m_iHealth", MAX_HP, 1);

		PrintToChatAll("\x05%N \x03使用医疗包治愈了处于濒死状态的 \x05%N\x03，获得了\x05%d\x03生命值奖励", client, target, HEAL_REWARD);

		if (!IsFakeClient(client) )
		{
			if(PT_Add(client, HEAL_REWARD_PT) != -1)
				CPrintToChat(client, "\x03\x01获得了{blue} 5 pt\x01", HEAL_REWARD_PT);
			else	CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");
		}
	}
	else		PrintToChatAll("\x05%N \x03使用医疗包治愈了 \x05%N\x03.", client, target);


	return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//		救起队友的奖励		
//---------------------------------------------------------------------------||
public Action Event_Player_Ledge_Grab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid") );
	g_bPlayerHanging[client] = true;

	return Plugin_Continue;
}
// 简单方法，对于180tick的MPDS服务器，这意味着每0.25s进行一次检查
// 这种方法应该不会有问题，恢复的生命值是在救助完成时进行判断的
//  有什么好的方法可以在获取救助前被帮助者的倒地生命值...
public void OnGameFrame()
{
	static int skip;
	skip++;
	if(skip>=HANGING_CHECK_INTERVAL)
	{
		skip=0;
		for(int i =1; i<=MaxClients; i++)
		{
			if(g_bPlayerHanging[i])
			{
				// 忽略TEMP。不关心那么多
				g_iPlayerHanging_HP[i] = GetClientHealth(i);
			}
		}
	}
}

public Action Event_Revive_Success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid") );

	if(client == 0)
		return Plugin_Continue;
	int target =  GetClientOfUserId(event.GetInt("subject") );
	int HP = GetClientHealth(client);

	int Add_HP;
	if(g_bPlayerHanging[target])
	{
		g_bPlayerHanging[target] = false;
		if(g_iPlayerHanging_HP[target] < REVIVE_HP_REWARD)
			Add_HP = REVIVE_REWARD;
		else	Add_HP = REVIVE_FAST_REWARD;
	}
	else	Add_HP = REVIVE_REWARD;

	if((HP + Add_HP) < MAX_HP)
		SetEntProp(client, Prop_Send, "m_iHealth", HP + Add_HP, 1);

	else 	SetEntProp(client, Prop_Send, "m_iHealth", MAX_HP, 1);

	PrintToChatAll("\x05%N \x03救起了 \x05%N\x03，获得了\x05%d\x03生命值奖励", client, target, Add_HP);
	if(Add_HP == REVIVE_REWARD)
	{
		if(!IsFakeClient(client) )
		{
			if(PT_Add(client, REVIVE_REWARD_PT) != -1 )
				CPrintToChat(client, "\x03\x01获得了{blue} %d pt\x01", REVIVE_REWARD_PT);
			else	CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");
		}
	}

	bool ColdDown = event.GetBool("lastlife");
	if(ColdDown )
		PrintToChatAll("\x04%N\x03 再一次倒下就会死亡...有人来帮助他吗？", target);

	return Plugin_Continue;
}

public OnMapStart()
{
	On = true;

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

public OnMapEnd()
{
	ResetClientCount_LDW();
	ResetClientShopItemCount();
	g_iTankAliveTime = 0;
	g_iTankPTChanged = 0;
	On = false;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	if(On)
	{
		return Plugin_Continue;
	}
	On = true;

	return Plugin_Continue;
}

public Action Event_PluginReset(Event event, const char[] name, bool dontBroadcast)
{
	if(!On)
	{
		return Plugin_Continue;
	}
	On = false;

	return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//			击杀特殊感染者的奖励
//---------------------------------------------------------------------------||
public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	if(On)
	{
		int target = GetClientOfUserId(GetEventInt(event, "userid") );
		if(target <= 0 || target > MaxClients || !IsClientInGame(target) || GetClientTeam(target) != 3)
			return Plugin_Continue;

		int client  = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || L4D_IsPlayerIncapacitated(client))
			return Plugin_Continue;
		
		float Add_Health;
		int iClass = GetEntProp(target, Prop_Send, "m_zombieClass");
		char sTarget[32];
		switch(iClass)
		{
			case	2:{
					Format(sTarget, sizeof(sTarget), "Boomer");
					Add_Health = BOOMER_REWARD;
			}
			case	4:{
					Format(sTarget, sizeof(sTarget), "Spitter");
					Add_Health = SPITTER_REWARD;
			}
			case	1:{
					Format(sTarget, sizeof(sTarget), "Smoker");
					Add_Health = SMOKER_REWARD;
			}
			case	5:{
					Format(sTarget, sizeof(sTarget), "Jockey");
					Add_Health = JOCKEY_REWARD;
			}
			case	3:{	
					Format(sTarget, sizeof(sTarget), "Hunter");
					Add_Health = HUNTER_REWARD;
			}

			case	6:{ 
					Format(sTarget, sizeof(sTarget), "Charger");
					Add_Health = CHARGER_REWARD;
			}
		}

		float client_health = float(GetClientHealth(client)) + ML4D_GetPlayerTempHealth(client);
		if((client_health + Add_Health) < float(MAX_HEALTH_DEF) )
			ML4D_SetPlayerTempHealthFloat(client, Add_Health + ML4D_GetPlayerTempHealth(client) );

		else if (client_health <= float(MAX_HEALTH_DEF) )
			ML4D_SetPlayerTempHealthFloat(client, float(MAX_HEALTH_DEF) - client_health + ML4D_GetPlayerTempHealth(client) );			

		else if (client_health > float(MAX_HEALTH_DEF) && (client_health + Add_Health) <= MAX_HP)
			ML4D_SetPlayerTempHealthFloat(client, Add_Health + ML4D_GetPlayerTempHealth(client) );

		PrintToChat(client, "\x05杀死了\x03%s\x05, 获得了\x03%.f\x01临时生命值.", sTarget, Add_Health);

	}

	return Plugin_Continue;
}

//---------------------------------------------------------------------------||
//			pt系统
//---------------------------------------------------------------------------||
public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client) )
		return;
	
	g_bCookieCached[client] = true;

        char sPT[16];
        chPlayerPT = FindClientCookie("mpds_pt_re3");
        GetClientCookie(client, chPlayerPT, sPT, sizeof(sPT) );
	PrintToServer("商店：OnClientCookiesCached: %s", sPT);
        g_iPlayerPT[client] = StringToInt(sPT);
}

void ResetClientCount_LDW()
{
	for(int i=1; i<= MaxClients; i++)
		g_iClientCount_LDW[i] = -1;
}
// 不在章节失败时刷新
void ResetClientShopItemCount()
{
	PrintToServer("\n[商店] 重置客户端物品可购买物品的剩余数量\n");

	for(int client=1; client<MaxClients; client++)
		for(int idx=0; idx< SHOP_ITEM_NUM; idx++)
			g_iClientShopItemRemainingQuantity[client][idx] = -1;
}

void SetClientShopItemCount(client, item, value)
{
	g_iClientShopItemRemainingQuantity[client][item] = value;
}

int GetClientShopItemCount(client, item)
{
	if(g_iClientShopItemRemainingQuantity[client][item] == -1 )
		return SubShop_ItemWeaponCount.Get(item);
	
	return  g_iClientShopItemRemainingQuantity[client][item];
}

Action cmd_buy(int client, int args)
{
	if(client <= MaxClients)
	{
		if(client == 0)
		{
			for(int i=1; i<=MaxClients; i++)
			{
				if(!IsClientInGame(i) )
					continue;
				if(IsFakeClient(i) )
					continue;	

				PrintToServer("## %N 点数剩余：%d", i, PT_Get(i) );
			}
			if(args)
			{
				char cmd[16];
				GetCmdArgString(cmd, sizeof(cmd) );
				char buffer[2][8];
				ExplodeString(cmd, " ", buffer, 2, 8);
				int userid = StringToInt(buffer[0]);
				if(userid)
				{
					int target = GetClientOfUserId(userid);
					if(!target)
						PrintToServer("没有找到userid对应的客户端");
					else
					{
						if(!IsFakeClient(target)  )			
						{
							int pt = StringToInt(buffer[1]);
							PrintToServer("#%N: 目前拥有：%d | 设置点数变化： %d", target, PT_Get(target),  pt );
							PT_Add(target, pt);
						}
					}
				}
				else	PrintToServer("使用方法： sm_buy userid 要增加的pt数量");
			}
			return Plugin_Continue;
		}
		if(!g_bCookieCached[client])
		{
			CPrintToChat(client, "{blue}[商店]\x01 相关数据正在加载，请稍后再试...");
			return Plugin_Continue;
		}	
		CPrintToChat(client, "{blue}[商店]\x01 商店系统目前是测试状态，内容可能经常变化...");
		CPrintToChat(client, "{blue}[商店]\x01 拥有的点数(pt)剩余 {blue}%d", PT_Get(client));
		CPrintToChat(client, "{blue}[商店]\x01 花费{blue} %d pt\x01以使用\x05!ldw\x01命令进行抽奖", LDW_PRICE);
		DisplayShopMenu(client);
	}

	return Plugin_Continue;
}
Action cmd_ldw(int client, int args)
{
	if(0 < client <= MaxClients)
	{
		if(!g_bCookieCached[client])
		{
			CPrintToChat(client, "{blue}[商店]\x01 相关数据正在加载，请稍后再试...");
			return Plugin_Continue;
		}

		if(GetClientTeam(client) != 2)
		{
			CPrintToChat(client, "{blue}[商店]\x01 你必须是一名幸存者才能使用此命令！");
			return Plugin_Continue;
		}
		if(!IsPlayerAlive(client) )
		{
			CPrintToChat(client, "{blue}[商店]\x01 你必须存活才能使用此命令！");
			return Plugin_Continue;

		}
		if(L4D_IsPlayerIncapacitated(client) )
		{
			CPrintToChat(client, "{blue}[商店]\x01 目前，倒地状态不允许使用此命令！");
			return Plugin_Continue;
		}

		int pt = PT_Get(client);
		if(pt < LDW_PRICE)
		{
			if(g_iClientCount_LDW[client] == -1)
				g_iClientCount_LDW[client] = LDW_LIMIT;

			CPrintToChat(client, "{blue}[商店-抽奖]\x01 当前章节的剩余抽奖次数：{blue}%d", g_iClientCount_LDW[client]);
			CPrintToChat(client, "{blue} \x01由于你的点数当前为：{blue}%d pt\x01，因此抽奖次数具有限制.", pt);

			LDW(client, true);
		}
		else
		{
			g_iClientCount_LDW[client] = LDW_LIMIT;
			LDW(client);
		}

	}

	return Plugin_Continue;
}

void LDW(int client, bool limit=false)
{
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
	if(value < 400.00)
	{
		int pt = RoundToNearest(GetRandomFloat(-60.00, 30.00) );
		PT_Add(client, pt);
		CPrintToChatAll("{blue}[商店-抽奖]\x01 %N 花费{blue} %d pt\x01获得了\x05 %d pt", client, LDW_PRICE, pt);
		CPrintToChat(client, "{blue} 剩余: %d pt", PT_Get(client) );
		return;
	}

	bool allow = true;
	while(allow)
	{		
		int idx = RoundToNearest(GetRandomFloat(0.00, float(SubShop_ItemDisplayName.Length-1) ) );
		if(SubShop_ItemWeaponPrice.Get(idx) == -1 )
			continue;
		char name[64];
		SubShop_ItemWeaponName.GetString(idx, name, sizeof(name) );
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
		CPrintToChat(client, "{blue} 剩余: %d pt", PT_Get(client) );
	}
}
// MethodMap 是以后的事情
static char g_sShopType[7][]={
	"一级武器",
	"二级武器",
	"三级武器",
	"近战武器",
	"医疗物品",
	"其它物品",
	"特殊效果"
};
#define	MAXSHOPTYPE	7
// 特定类别商店的第一个项目的绝对索引
int g_iShopArrayIndexOffest[MAXSHOPTYPE]={0, 7, 19, 23, 37, 42, 53};
int g_iClientViewShopType[MAXPLAYERS+1];

void CacheShopItem()
{
	// 对于随机的物品，只关注显示名称与价格
	// 后三个值重置的默认值为-1
	// 始终确保每一个项目的显示名称不为空，它被用于计算项目的总数
	SubShop_ItemDisplayName = CreateArray(32);
	SubShop_ItemWeaponName = CreateArray(32);
	// -1 = 锁定的物品
	// 价格
	SubShop_ItemWeaponPrice = CreateArray(1);
	// -2 = 无限
	// 这个项目当前章节对于玩家的可购买次数
	SubShop_ItemWeaponCount = CreateArray(1);
	// -2 = 参数是无效的
	// 武器的备用弹药=武器的默认弹匣大小*设置的值
	SubShop_ItemWeaponAmmoMult = CreateArray(1);

	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemWeaponName.PushString("");	
//	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponPrice.Push(8);
	SubShop_ItemWeaponCount.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("泵动式霰弹枪");
	SubShop_ItemWeaponName.PushString("weapon_pumpshotgun");	
//	SubShop_ItemWeaponPrice.Push(8);
	SubShop_ItemWeaponPrice.Push(0);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("铬制霰弹枪");
	SubShop_ItemWeaponName.PushString("weapon_shotgun_chrome");	
//	SubShop_ItemWeaponPrice.Push(8);
	SubShop_ItemWeaponPrice.Push(0);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("微型冲锋枪");
	SubShop_ItemWeaponName.PushString("weapon_smg");	
//	SubShop_ItemWeaponPrice.Push(5);
	SubShop_ItemWeaponPrice.Push(0);
//	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("消音冲锋枪");
	SubShop_ItemWeaponName.PushString("weapon_smg_silenced");	
//	SubShop_ItemWeaponPrice.Push(8);
	SubShop_ItemWeaponPrice.Push(0);
//	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("Mp5冲锋枪");
	SubShop_ItemWeaponName.PushString("weapon_smg_mp5");	
//	SubShop_ItemWeaponPrice.Push(4);
	SubShop_ItemWeaponPrice.Push(0);
//	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("手枪");
	SubShop_ItemWeaponName.PushString("weapon_pistol");	
	SubShop_ItemWeaponPrice.Push(0);
	SubShop_ItemWeaponCount.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	// 二级商店
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(20);
	SubShop_ItemWeaponCount.Push(-2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("M16步枪");
	SubShop_ItemWeaponName.PushString("weapon_rifle");
	SubShop_ItemWeaponPrice.Push(12);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("Ak47步枪");
	SubShop_ItemWeaponName.PushString("weapon_rifle_ak47");	
	SubShop_ItemWeaponPrice.Push(16);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("军用步枪");
	SubShop_ItemWeaponName.PushString("weapon_rifle_desert");	
	SubShop_ItemWeaponPrice.Push(14);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("Sg552步枪");
	SubShop_ItemWeaponName.PushString("weapon_rifle_sg552");	
	SubShop_ItemWeaponPrice.Push(12);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("自动霰弹枪");
	SubShop_ItemWeaponName.PushString("weapon_autoshotgun");	
	SubShop_ItemWeaponPrice.Push(16);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("战斗霰弹枪");
	SubShop_ItemWeaponName.PushString("weapon_shotgun_spas");	
	SubShop_ItemWeaponPrice.Push(16);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(14);

	SubShop_ItemDisplayName.PushString("狩猎步枪");
	SubShop_ItemWeaponName.PushString("weapon_hunting_rifle");	
	SubShop_ItemWeaponPrice.Push(5);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("军用狙击步枪");
	SubShop_ItemWeaponName.PushString("weapon_sniper_military");	
	SubShop_ItemWeaponPrice.Push(14);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("侦察狙击步枪");
	SubShop_ItemWeaponName.PushString("weapon_sniper_scout");	
	SubShop_ItemWeaponPrice.Push(2);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(27);

	SubShop_ItemDisplayName.PushString("Awp狙击步枪");
	SubShop_ItemWeaponName.PushString("weapon_sniper_awp");	
	SubShop_ItemWeaponPrice.Push(5);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("Magnum手枪");
	SubShop_ItemWeaponName.PushString("weapon_pistol_magnum");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	// 三级商店
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(30);
	SubShop_ItemWeaponCount.Push(-2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("M60轻机枪");
	SubShop_ItemWeaponName.PushString("weapon_rifle_m60");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("榴弹发射器");
	SubShop_ItemWeaponName.PushString("weapon_grenade_launcher");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(18);

	SubShop_ItemDisplayName.PushString("电锯");
	SubShop_ItemWeaponName.PushString("weapon_chainsaw");	
	SubShop_ItemWeaponPrice.Push(20);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	// 近战武器
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemWeaponName.PushString("");
	SubShop_ItemWeaponPrice.Push(40);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("干草叉");
	SubShop_ItemWeaponName.PushString("weapon_melee+pitchfork");	
	SubShop_ItemWeaponPrice.Push(0);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("消防斧");
	SubShop_ItemWeaponName.PushString("weapon_melee+fireaxe");	
	SubShop_ItemWeaponPrice.Push(20);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("平底锅");
	SubShop_ItemWeaponName.PushString("weapon_melee+frying_pan");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("砍刀");
	SubShop_ItemWeaponName.PushString("weapon_melee+machete");	
	SubShop_ItemWeaponPrice.Push(20);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("棒球棍");
	SubShop_ItemWeaponName.PushString("weapon_melee+baseball_bat");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("撬棍");
	SubShop_ItemWeaponName.PushString("weapon_melee+crowbar");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("板球棒");
	SubShop_ItemWeaponName.PushString("weapon_melee+cricket_bat");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("警棍");
	SubShop_ItemWeaponName.PushString("weapon_melee+tonfa");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);


	SubShop_ItemDisplayName.PushString("武士刀");
	SubShop_ItemWeaponName.PushString("weapon_melee+katana");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("电吉他");
	SubShop_ItemWeaponName.PushString("weapon_melee+electric_guitar");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("小刀");
	SubShop_ItemWeaponName.PushString("weapon_melee+knife");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("高尔夫球杆");
	SubShop_ItemWeaponName.PushString("weapon_melee+golfclub");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("铁铲");
	SubShop_ItemWeaponName.PushString("weapon_melee+shovel");	
	SubShop_ItemWeaponPrice.Push(15);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	// 医疗物品
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(20);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

#if ALLOW_USE_DEFIB
		SubShop_ItemDisplayName.PushString("除颤器");
		SubShop_ItemWeaponName.PushString("weapon_defibrillator");	
		SubShop_ItemWeaponPrice.Push(10);
		SubShop_ItemWeaponCount.Push(4);
		SubShop_ItemWeaponAmmoMult.Push(-2);
#endif
#if !ALLOW_USE_DEFIB
		SubShop_ItemDisplayName.PushString("除颤器-禁用");
		SubShop_ItemWeaponName.PushString("weapon_defibrillator");	
		SubShop_ItemWeaponPrice.Push(-1);
		SubShop_ItemWeaponCount.Push(4);
		SubShop_ItemWeaponAmmoMult.Push(-2);
#endif

	SubShop_ItemDisplayName.PushString("医疗包");
	SubShop_ItemWeaponName.PushString("weapon_first_aid_kit");	
	SubShop_ItemWeaponPrice.Push(30);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("药丸");
	SubShop_ItemWeaponName.PushString("weapon_pain_pills");	
	SubShop_ItemWeaponPrice.Push(8);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("肾上腺素");
	SubShop_ItemWeaponName.PushString("weapon_adrenaline");	
	SubShop_ItemWeaponPrice.Push(6);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	// 其他物品
	SubShop_ItemDisplayName.PushString("随机的物品");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("燃烧瓶");
	SubShop_ItemWeaponName.PushString("weapon_molotov");	
	SubShop_ItemWeaponPrice.Push(12);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("土质炸弹");
	SubShop_ItemWeaponName.PushString("weapon_pipe_bomb");	
	SubShop_ItemWeaponPrice.Push(10);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("胆汁罐");
	SubShop_ItemWeaponName.PushString("weapon_vomitjar");	
	SubShop_ItemWeaponPrice.Push(12);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("丙烷罐");
	SubShop_ItemWeaponName.PushString("weapon_propanetank");	
	SubShop_ItemWeaponPrice.Push(2);
	SubShop_ItemWeaponCount.Push(2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("氧气瓶");
	SubShop_ItemWeaponName.PushString("weapon_oxygentank");	
	SubShop_ItemWeaponPrice.Push(1);
	SubShop_ItemWeaponCount.Push(4);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("侏儒玩偶");
	SubShop_ItemWeaponName.PushString("weapon_gnome");	
	SubShop_ItemWeaponPrice.Push(0);
	SubShop_ItemWeaponCount.Push(8);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("高爆弹升级包");
	SubShop_ItemWeaponName.PushString("weapon_upgradepack_explosive");	
	SubShop_ItemWeaponPrice.Push(16);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("燃烧弹升级包");
	SubShop_ItemWeaponName.PushString("weapon_upgradepack_incendiary");	
	SubShop_ItemWeaponPrice.Push(12);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("汽油桶-待定");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("烟花盒-待定");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(1);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	// 特殊效果
	SubShop_ItemDisplayName.PushString("--占位符--");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("自杀并复活(重生)-待定");
	SubShop_ItemWeaponName.PushString("other+");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("自我救助(自救)-待定");
	SubShop_ItemWeaponName.PushString("other+");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("快速购买-待定");
	SubShop_ItemWeaponName.PushString("other+");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(-2);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("升级镭射装置-待定");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

	SubShop_ItemDisplayName.PushString("放置镭射升级盒-待定");
	SubShop_ItemWeaponName.PushString("");	
	SubShop_ItemWeaponPrice.Push(-1);
	SubShop_ItemWeaponCount.Push(0);
	SubShop_ItemWeaponAmmoMult.Push(-2);

}

void DisplayShopMenu(int client)
{
	Menu shop = CreateMenu(Menu_Shop);
//	shop.ExitButton = false;
	shop.SetTitle("MPDS 服务器商店 %s", PLUGIN_VERSION);
	for(int i=0; i<7; i++)
		shop.AddItem(g_sShopType[i], g_sShopType[i]);

	shop.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Shop(Menu menu, MenuAction action, int param1, int param2)
{

	if(action == MenuAction_Select)
	{
		if(param2 < MAXSHOPTYPE)
			DisplayShopMenu_Sub(param1, param2);

		return 0;
	}

	if(action == MenuAction_End)
	{
		if(!IsValidHandle(menu) )
			return 0;
		delete menu;
	}

	return 0;
}
// 获取特定类型商店拥有的物品总数
int GetSubShopItemNum(int type)
{
	if( (type + 1) <=  (MAXSHOPTYPE - 1) )
		return (g_iShopArrayIndexOffest[type+1] - g_iShopArrayIndexOffest[type] );

	if( type == 0)
		return g_iShopArrayIndexOffest[type+1];

	// type == (MAXSHOPTYPE - 1)	
	return (SubShop_ItemDisplayName.Length - g_iShopArrayIndexOffest[type]);
}

void DisplayShopMenu_Sub(int client, int type)
{
	Menu shop_sub = CreateMenu(Menu_Shop_Sub);
	shop_sub.SetTitle("拥有[%dpt]  |  商店 - %s", PT_Get(client), g_sShopType[type]);

	for(int i=0; i< GetSubShopItemNum(type); i++)
	{
		static char buffer[32], title[64], sCount[8], sPrice[8];
		static int targetItemIndex, iCount, iPrice;

		targetItemIndex = g_iShopArrayIndexOffest[type] + i;
		SubShop_ItemDisplayName.GetString(targetItemIndex, buffer, sizeof(buffer) );

		iCount = GetClientShopItemCount(client, targetItemIndex);
		IntToString(iCount, sCount, sizeof(sCount) );
		iPrice = SubShop_ItemWeaponPrice.Get(targetItemIndex);
		IntToString(iPrice, sPrice, sizeof(sPrice) );

		if(iCount == -2)
			Format(sCount, sizeof(sCount), "无限");
	
		if(iPrice == -1)
			Format(sPrice, sizeof(sPrice), "锁定");
		else if(iPrice == 0)
			Format(sPrice, sizeof(sPrice), "免费");
		else
		{
			if(IsRealismMode)
				Format(sPrice, sizeof(sPrice), "%dpt", iPrice * 2);
			else	Format(sPrice, sizeof(sPrice), "%dpt", iPrice );
		}
		Format(title, sizeof(title), "[%s] %s [剩余: %s]", sPrice, buffer, sCount );
		shop_sub.AddItem(title, title);
	}
	g_iClientViewShopType[client] = type;

	shop_sub.Display(client, MENU_TIME_FOREVER);	

}

public int Menu_Shop_Sub(Menu menu, MenuAction action, int param1, int param2)
{

	if(action == MenuAction_Select)
		PT_BuyItem(param1, param2);

	if(action == MenuAction_End)
	{
		if(!IsValidHandle(menu) )
			return 0;
		delete menu;
	}

	return 0;
}

// ShopItemIndex是一个绝对索引
// 现在我不明白当时出于什么考虑 设置&&命名 了RandomPrice 参数...
bool SetItems(int client, const char[] weapon, int ShopItemIndex=-1, int RandomPrice = -1)
{
	bool value;

	if(strncmp(weapon, "other", 5, false) == 0)
	{
#if DEBUG
		PrintToChatAll("是一个特殊效果：%s", weapon);
#endif
		value = false;		
	}

	bool IsMelee;
	char buffer[2][16];
        int entity_weapon;
	
	if(strncmp("weapon_melee", weapon, 12, false) == 0)
	{
		ExplodeString(weapon, "+", buffer, 2, 16);
		IsMelee = true;
#if DEBUG
		PrintToChatAll("%s+%s", buffer[0], buffer[1]);
#endif
		entity_weapon = CreateEntityByName("weapon_melee");
	}
	else	entity_weapon = CreateEntityByName(weapon);

	if(entity_weapon == -1)
	{
		ServerCommand("say [%s]: Function \"SetItems()\" Failed: Unable to Create entity.", PLUGIN_NAME);				
		ServerCommand("say [%s]: Function \"SetItems()\" Failed: Target: %s", PLUGIN_NAME, weapon);				
		value = false;
	}
	if(ShopItemIndex != -1  && entity_weapon != -1)
	{
		if(RandomPrice != -1)
			PT_Subtract(client, RandomPrice);
		else	PT_Subtract(client, SubShop_ItemWeaponPrice.Get(ShopItemIndex) );
		value =  true;
	}

	if(value)
	{
	        DispatchKeyValue(entity_weapon, "solid", "6");
		if(IsMelee)
		        DispatchKeyValue(entity_weapon, "melee_script_name", buffer[1]);

	        DispatchSpawn(entity_weapon);
	        EquipPlayerWeapon(client, entity_weapon);	

		int mult = SubShop_ItemWeaponAmmoMult.Get(ShopItemIndex);
		if(mult != -2)
			Client_SetWeaponPlayerAmmoEx(client, entity_weapon, GetEntProp(entity_weapon, Prop_Send, "m_iClip1") * mult);
	}
	return value;
}

void PT_BuyItem(int client, int SubShopItemIndex)
{
	if(GetClientTeam(client) != 2)
	{
		CPrintToChat(client, "{blue}[商店]\x01 你必须是一名幸存者才能购买物品！");
		return;
	}
	if(!IsPlayerAlive(client) )
	{
		CPrintToChat(client, "{blue}[商店]\x01 你必须存活才能购买物品！");
		return;
	}
	if(L4D_IsPlayerIncapacitated(client) )
	{
		CPrintToChat(client, "{blue}[商店]\x01 目前，倒地状态不允许进行购买！");
		return;
	}

	int own_pt = PT_Get(client);
	int targetIteamIndex = g_iShopArrayIndexOffest[g_iClientViewShopType[client]] + SubShopItemIndex;
	int item_price = SubShop_ItemWeaponPrice.Get(targetIteamIndex);

	if(item_price == -1)
	{
		CPrintToChat(client, "{blue}[商店]\x01 不可购买的物品！", own_pt);
		return;
	}
#if DEBUG
	PrintToChatAll("需要的点数:%d", item_price);
#endif
	if(GetClientShopItemCount(client, targetIteamIndex) == 0 )
	{
		CPrintToChat(client, "{blue}[商店]\x01 目标物品在当前地图的剩余可购买次数已用尽!", own_pt);
		return;
	}
	if(own_pt < item_price && item_price != 0)
	{
		CPrintToChat(client, "{blue}[商店]\x01 点数不够！你现在只有{blue} %d pt\x01!", own_pt);
		return;
	}

	char sWeapon[32];

	// 随机的物品
	if(SubShopItemIndex == 0)
	{
		// 忽略第一个索引，它是随机的物品
		int MinItemIndex = g_iShopArrayIndexOffest[g_iClientViewShopType[client]] + 1;
		int MaxItemIndex = MinItemIndex + GetSubShopItemNum(g_iClientViewShopType[client]) - 2;
#if DEBUG	
		PrintToChatAll("%d %d", GetSubShopItemNum(g_iClientViewShopType[client]), g_iClientViewShopType[client]);
		PrintToChatAll("ShopType: %d, ItemIndextRange: Min=%d Max=%d", g_iClientViewShopType[client], MinItemIndex, MaxItemIndex);
#endif
		targetIteamIndex = GetRandomInt(MinItemIndex, MaxItemIndex);

		// 也许需要进行额外的操作避免短暂的帧速率下降和一些误操作可能引起的服务器挂起
		// 也许...??
		while(SubShop_ItemWeaponPrice.Get(targetIteamIndex) == -1)
			targetIteamIndex = GetRandomInt(MinItemIndex, MaxItemIndex);

		SubShop_ItemWeaponName.GetString(targetIteamIndex, sWeapon, sizeof(sWeapon) );
#if DEBUG
		PrintToChatAll("targetIteamIndex:%d 选定的物品: %s", targetIteamIndex, sWeapon);
#endif
	}
	else	SubShop_ItemWeaponName.GetString(targetIteamIndex, sWeapon, sizeof(sWeapon) );

	if(IsRealismMode)	item_price =  RoundToNearest(item_price * REALISM_MODE_SPENT_MULT);

	if(SetItems(client, sWeapon, targetIteamIndex, item_price) )
	{
		char sWeapon_DisplayName[32];
		SubShop_ItemDisplayName.GetString(targetIteamIndex, sWeapon_DisplayName, sizeof(sWeapon_DisplayName) );

		if(SubShopItemIndex == 0)
		{
			char sWeapon_RandomName[32];
			targetIteamIndex = g_iShopArrayIndexOffest[g_iClientViewShopType[client]] + SubShopItemIndex;
			SubShop_ItemDisplayName.GetString(targetIteamIndex, sWeapon_RandomName, sizeof(sWeapon_RandomName) );

			CPrintToChatAll("{blue}[商店-随机物品]\x01 \x05%N \x01在类别为\x05%s\x01的商店中中花费{blue} %d pt \x01获得了\x05%s", client, g_sShopType[g_iClientViewShopType[client]], item_price, sWeapon_DisplayName);	
			CPrintToChat(client, "{blue}[商店]\x01 购买了 %s，剩余点数:{blue} %d ", sWeapon_RandomName, PT_Get(client) );	
		}
		else
		{
			CPrintToChat(client, "{blue}[商店]\x01 购买了 %s，剩余点数:{blue} %d ", sWeapon_DisplayName, PT_Get(client) );
		}

		if(IsRealismMode)	CPrintToChat(client, "{blue} \x01写实模式的点数花费：\x05%.fx", REALISM_MODE_SPENT_MULT);

		int count = GetClientShopItemCount(client, targetIteamIndex);
		if(count != -2)			
			SetClientShopItemCount(client, targetIteamIndex, count - 1 );

	}
}

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

int PT_Get(int client)
{
	if(g_bCookieCached[client])	
	{
		return PT_Update(client, false);		
	}

	return -102400;
}


int PT_Update(int client, bool write)
{
	char sPT[16];
	chPlayerPT = FindClientCookie("mpds_pt_re3");
	GetClientCookie(client, chPlayerPT, sPT, sizeof(sPT) );
	//  StringToInt失败时返回0
	//  所以不需要检查新玩家
	if(!write)
	{
		g_iPlayerPT[client] = StringToInt(sPT);
	}
	else
	{
		IntToString(g_iPlayerPT[client], sPT, sizeof(sPT) );
		SetClientCookie(client, chPlayerPT, sPT);
	}
	// 早期版本这里具有一些点数变化的检查，也许以后要注意..

	return g_iPlayerPT[client];
}

//---------------------------------------------------------------------------||
//			周期性检查Tank是否存活
//---------------------------------------------------------------------------||
//int g_iTankAlive[MAXPLAYERS+1];
Handle g_hTankAliveTimer;
bool g_bTankFind[MAXPLAYERS+1];
// --
// 希望在Tank发现幸存者时才开始计时，早期的几个版本显示这里实际上存在一些逻辑问题，属于小概率事件，未来需要进一步检查...
// --
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	if(GetEntProp(specialInfected, Prop_Send, "m_zombieClass") == 8)
		g_bTankFind[specialInfected] = true;

	return Plugin_Continue;
}

void Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid") );
	// 如果更改目标总是在生成之后，这应该没有问题！
	// g_iTankAlive数组考虑了多Tank场景，但这是早期版本某个需求的要求，现在？也许有更好的方法替代...
	if(g_bTankFind[tank])	g_bTankFind[tank] = false;
/*
	for(int i=1; i<MaxClients; i++)
	{
		// 如果有那么多Tank非正常死亡？我认为暂时不需要考虑这种情况...
		if(g_iTankAlive[i] == 0)
			g_iTankAlive[i] = GetClientOfUserId(tank);
	}
*/
	if(!IsValidHandle(g_hTankAliveTimer) )
		g_hTankAliveTimer = CreateTimer(TANK_ALIVE_TIMER_INTERVAL, tTankAlive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_Tank_Kiiled(Event event, const char[] name, bool dontBroadcast)
{
	int killer = GetClientOfUserId(event.GetInt("attacker") );
	bool solo = event.GetBool("solo");
	bool melee = event.GetBool("melee_only");
#if DEBUG
	PrintToChatAll("Event_Tank_Kiiled: %N#%d", killer, killer);
#endif
	if(solo && melee && IsClientInGame(killer) )
	{
		ServerCommand("[%s]: %N Event_Tank_Kiiled: solo AND melee", PLUGIN_NAME, killer);
		PT_Add(killer, TANK_SOLO_MELEE_REWARD);
		CPrintToChatAll("\x03%N\x01仅使用近战武器杀死了一只Tank, 且没有其他人的伤害贡献！");
		CPrintToChatAll("\x03%N\x01 获得了{blue} %d pt\x01的奖励！", TANK_SOLO_MELEE_REWARD);
		return;
	}

	CPrintToChatAll("\x03一只Tank已经死亡，所有幸存者获得了{blue} %d pt的奖励.", TANK_REWARD);

	int value = TANK_REWARD;

	if(melee)
	{
		CPrintToChatAll("\x03所有幸存者因Tank仅受到了近战伤害而得到的额外奖励: {blue} %d pt", TANK_ONLY_MELEE_REWARD);
		value = value + TANK_ONLY_MELEE_REWARD;
	}

	for(int i=1; i<MaxClients; i++)
	{
		if(!IsClientInGame(i) )
			continue;

		if(GetClientTeam(i) != 2)
			continue;

		PT_Add(i, value);
	}

	g_iTankPTChanged = g_iTankPTChanged + value;
}

Action tTankAlive(Handle Timer)
{		
	bool alive;
	bool find;

	for(int i=1; i<MaxClients; i++)
	{
		if(!IsClientInGame(i) )
			continue;


		if(GetClientTeam(i) == 3)
		{
			// Tank
			if(GetEntProp(i, Prop_Send, "m_zombieClass") == 8)	
			{	
				if(IsPlayerAlive(i) )
				{
					alive = true;
					if(g_bTankFind[i])
					{
						find = true;
						break;
					}
				}
			
				// 也许还需要在实体移除时进行设置！不然有概率出问题  
				else	g_bTankFind[i] = false;
			}
		}
	}

	if(alive)
	{
		if(find)
		{
			g_iTankAliveTime++;

			// 存活时间等于或多余85秒后开始扣除，这是目前专家难度下烧死Tank所需时间的一半
			if( !(TANK_ALIVE_TIMER_COUNT < g_iTankAliveTime) )
				return Plugin_Continue;

			int value = TANK_ALIVE_DEDUCT;
// 早期版本具有阶段性倍增的点数扣除机制
/*
			if(g_iTankAliveTime >= 34)
				value = 2
			...
			......
*/
			for(int i=1; i<MaxClients; i++)
			{
				if(!IsClientInGame(i) )
					continue;

				if(GetClientTeam(i) != 2)
					continue;

				if(IsFakeClient(i) )
					continue;

				PT_Subtract(i, value);
			}

			g_iTankPTChanged = g_iTankPTChanged - value;

		}
	}
	else
	{
		char value[8];
		IntToString(g_iTankPTChanged, value, sizeof(value) );
		if(g_iTankPTChanged > 0)
			Format(value, sizeof(value), "+%s", value);

		PrintToChatAll("\x03自\x04Tank\x03生成以来，每个幸存者的点数变化为: \x05%s", value);

		g_iTankAliveTime = 0;
		g_iTankPTChanged = 0;

		return Plugin_Stop;	
	}

	return Plugin_Continue;
}

//---------------------------------------------------------------------------||
//			Stock
//---------------------------------------------------------------------------||
stock int Weapon_GetPrimaryAmmoType(int weapon)
{
        return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

stock int Weapon_GetSecondaryAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType");
}

stock void Client_SetWeaponPlayerAmmoEx(int client, int weapon, int primaryAmmo=-1, int secondaryAmmo=-1)
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

stock int Client_GetWeaponPrimaryAmmo(client, weapon)
{
	int offset_ammo = FindDataMapInfo(client, "m_iAmmo");
	int offset = offset_ammo + (Weapon_GetSecondaryAmmoType(weapon) * 4);
	GetEntProp(weapon, Prop_Send, "m_iClip1");

	return GetEntData(client, offset);
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
stock void ML4D_SetPlayerTempHealthFloat(int client, float tempHealth)
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
stock int ML4D_GetPlayerTempHealth(int client)
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
