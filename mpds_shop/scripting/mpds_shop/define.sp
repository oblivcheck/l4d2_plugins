#define ClassTank	8
bool	On;

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

#define MAX_WEAPONS2    29
char g_sWeaponModels2[MAX_WEAPONS2][] =
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
#define SOUND_HEART   "player/heartbeatloop.wav"

Handle	chPlayerPT;
// 临时缓存的数据
int g_iPlayerPT[MAXPLAYERS+1];
bool  g_bCookieCached[MAXPLAYERS+1];

// 硬编码数组第二维的大小，这应该大于商店中的物品总数
#define SHOP_ITEM_NUM   128
// 为什么不使用ADT，因为早期版本中出现了问题，而我不想继续检查，故而直接硬编码大小
// 末尾索引(SHOP_ITEM_NUM+1)记录客户端的STEAMID
int g_iClientShopItemRemainingQuantity[128][SHOP_ITEM_NUM+1];

// 应该始终以tank_burn_duration_expert值的一半进行判断 170/2 = 85 (17次计时)
// 追踪相应的Cvar变化？ 也许以后...
int g_iTankAliveTime;
// 用于计算与Tank作战过程中的点数变化，仅用于打印提示.
int g_iTankPTChanged;

int g_iClientCount_LDW[MAXPLAYERS+1];
bool	IsRealismMode;
ConVar	hIsRealismMode;

int g_iTank_player=-1;
bool g_bSpawnPlayerTank;
#define   PlayerTankSpawned_Hint    "ui/gascan_spawn.wav"

char g_sShopStockType[2][]={
	"团队共享",
	"每个玩家"
};


// MethodMap 是以后的事情
char g_sShopType[7][]={
	"一级武器",
	"二级武器",
	"三级武器",
	"近战武器",
	"医疗物品",
	"其它物品",
	"特殊效果"
};
int g_iClientViewShopType[MAXPLAYERS+1];

int g_iPlayerTankSpawned_SendMSG_Count;

//int g_iTankAlive[MAXPLAYERS+1];
Handle g_hTankAliveTimer;
bool g_bTankFind[MAXPLAYERS+1];

// 用于PT_Get()的保留值，除此之外没有实际作用
char _PTS[16];

// 商店快捷键
bool g_bPlayerOpenShopCooldown[MAXPLAYERS+1];
