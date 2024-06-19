#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <multicolors>
#include <clientprefs>

#include <mpds_shop>
#include "mpds_server/fuc.sp"
#include "mpds_server/debug.sp"
#include "mpds_server/glow.sp"
//#include <gm>

/*
2024-06-19 (3.7b)
  - 整理代码.
  - 编译时默认不包括GM库.
  - 整合mpds_fix.sp && mpds_chainsaw_sapwn.sp &7 mpds_anglesfix.sp
  - 可加载外部VScript.
  - !zs 命令现在使用内置函数，并且可以播放自杀枪声.
  - 一些提示&注释调整
*/

#define PLUGIN_NAME             "MPDS Server"
#define PLUGIN_DESCRIPTION      "多人专用服务器上的小功能集合"
#define PLUGIN_VERSION          "3.7b"
#define PLUGIN_AUTHOR           "oblivcheck"
#define PLUGIN_URL              "https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds/mpds_server"

public Plugin:myinfo =
{
        name = PLUGIN_NAME,
        author = PLUGIN_AUTHOR,
        description = PLUGIN_DESCRIPTION,
        version = PLUGIN_VERSION,
        url = PLUGIN_URL
}

char  ServerName[128];

int  g_iANNCount;

ConVar  g_hDiff;

#define    MUSCI_CHURCH    "plats/churchbell_begin_loop.wav"
#define EMSHUD_FLAG        HUD_FLAG_ALIGN_CENTER | HUD_FLAG_TEXT | HUD_FLAG_NOBG
#define EMSHUD_SLOT        2      
#define ZS_Sound  "weapons/magnum/gunfire/magnum_shoot.wav"

char  sSound_TankYell[][]={
  "player/tank/voice/attack/tank_attack_01.wav",
  "player/tank/voice/attack/tank_attack_02.wav",
  "player/tank/voice/attack/tank_attack_03.wav",
  "player/tank/voice/attack/tank_attack_04.wav",
  "player/tank/voice/attack/tank_attack_05.wav",
  "player/tank/voice/attack/tank_attack_06.wav",
  "player/tank/voice/attack/tank_attack_07.wav",
  "player/tank/voice/attack/tank_attack_08.wav",
  "player/tank/voice/attack/tank_attack_09.wav",
  "player/tank/voice/attack/tank_attack_10.wav",
};

#define DEF_R      160
#define DEF_G      110
#define DEF_B      50
#define DEF_A      64
#define S_DEF      "160 110 50 64"

#define SCREENFADE_FRACBITS           (1 << 9) // 512
#define FFADE_IN                      0x0001
#define FFADE_OUT                     0x0002
#define FFADE_STAYOUT                 0x0008
#define FFADE_PURGE                   0x0010

#define FADE_TIME    1.0
#define FADE_DURAATION    SCREENFADE_FRACBITS * FADE_TIME


ConVar  g_hLobby;
int  g_iLobby;
char  g_sLobbyID[48];

ConVar  g_hCookie;

// 一次性菜单！
int g_iPlayerID[MAXPLAYERS+1]
ConVar  g_hDiffLock;
bool  g_bDiffLock;

ConVar  g_hServerMaxPlayerSlots;
int  g_iServerMaxPlayerSlots;

// 画面滤镜
UserMsg g_umFade;
ConVar  g_hEyes;
bool  g_bEyes;
bool  g_bProEyes[MAXPLAYERS+1][2];
bool  g_bProtectingEyes[MAXPLAYERS+1];
Cookie  g_hCookie_EyesRGBA;
int  g_iEyesRGBA[MAXPLAYERS+1][4];
//Cookie  g_hCookie_EyesSiwtchMethod;
//bool  g_bEyesSiwtchMethod;

ConVar  g_hHostName;
char  g_sHostName[128];

bool  g_bPluginLibraryLoaded_mpds_shop;
bool  g_bCookieCached[MAXPLAYERS+1];

// 当前的难度，从简单到专家(0~3)
bool  g_bDiff[4];

public void OnLibraryAdded(const char[] name)
{
  if(strcmp(name, "mpds_shop") == 0)
    g_bPluginLibraryLoaded_mpds_shop = true;
}
public void OnLibraryRemoved(const char[] name)
{
  if(strcmp(name, "mpds_shop") == 0)
    g_bPluginLibraryLoaded_mpds_shop = false;
}

public void OnPluginStart()
{
  _CCSP_HookEvent();  
  _Glow_CreateTimer();
  _Glow_OnPluginStart();
  _AngFix_OnPluginStart();
  //服务器初始名称
  char path[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "hostname.txt");
  bool hasHostName = FileExists(path);
  if (hasHostName)
  {
    File hFile;
    hFile = OpenFile(path, "rb");  
    if(hFile != null )
    {
      int len = FileSize(path);
      if(hFile.ReadString(ServerName, sizeof(ServerName), len-1) != -1)
      ServerCommand("hostname \"%s\"", ServerName);
      // 防止第一次启动时读取到默认名称
      ServerExecute();
      PrintToServer("读取:%s 字节长度:%d", ServerName, len);
    }
    delete hFile;
    
  }
  g_hHostName = FindConVar("hostname");
  int flags = GetConVarFlags(g_hHostName)
  SetConVarFlags(g_hHostName, flags &~ FCVAR_NOTIFY);
  g_hHostName.GetString(g_sHostName, sizeof(g_sHostName) );
  SetConVarString(g_hHostName, g_sHostName);

  g_hLobby = CreateConVar("mpds_lobby", "-1");
  g_hLobby.AddChangeHook(Event_ConVarChanged);

  g_hDiffLock = CreateConVar("mpds_difflock", "1");
  g_hDiffLock.AddChangeHook(Event_ConVarDiffLockChanged);
  
  g_hCookie = FindConVar("sv_lobby_cookie");

  HookUserMessage(g_umFade, FadeHook, true);
  g_hEyes = CreateConVar("mpds_fade", "1");
  g_hEyes.AddChangeHook(Event_ConVarDiffLockChanged);
  g_hCookie_EyesRGBA = RegClientCookie("mpds_eyes_rgba", "滤镜的颜色", CookieAccess_Protected);
//  g_hCookie_EyesSiwtchMethod = RegClientCookie("mpds_eyes_switch", "启用滤镜的方式", CookieAccess_Protected);
    
  HookEvent("player_disconnect", Event_PlayerDisconnect);
  HookEvent("finale_win", Event_Finale_Win,  EventHookMode_PostNoCopy);
  HookEvent("round_start", Event_RoundStart);
  HookEvent("tank_spawn", Event_Tank_Spawn);

  AddCommandListener(Listener_CallVote, "callvote");

  g_hDiff = FindConVar("z_difficulty");
  g_hDiff.AddChangeHook(Event_ConVarDiffLockChanged);

  g_hServerMaxPlayerSlots = FindConVar("sv_maxplayers");
  g_hServerMaxPlayerSlots.AddChangeHook(Event_ConVarChanged);

  CreateTimer(120.0, tAnnouncement, _, TIMER_REPEAT)

  RegConsoleCmd("sm_zs", cmd_zs);
  RegConsoleCmd("sm_proe", cmd_proe);
//  GM_Create();
//  RegConsoleCmd("sm_mst", cmd_mst);
//  RegConsoleCmd("sm_proem", cmd_prom);
  RegConsoleCmd("sm_h", cmd_help);
//  CreateWhiteList();
  AutoGetInfo();
  _Debug();
}

#define  MAXANNCOUNT  7
Action tAnnouncement(Handle Timer)
{
  if(GetAllPlayersInServer() >= MaxClients)
    return Plugin_Continue;

  int index = CreateFakeClient("Red_Color_Bot");
  ChangeClientTeam(index, 3);

  CreateTimer(1.0, tPrintHint, index);  

  return Plugin_Continue;
}

Action tPrintHint(Handle Timer, any index)
{
  switch(g_iANNCount)
  {
    case  0:{
      CPrintToChatAll("{red}    --------------------------------");
      CPrintToChatAll("{blue}    想要服务器上有超过四名玩家？");
      PrintToChatAll("\x03    请安装创意工坊中的\"8人大厅\"Mod.");
      CPrintToChatAll("{blue}    steamcommunity.com/sharedfiles/filedetails/?id=2539311505");
      CPrintToChatAll("\x03    在服务器为空的时候，使用\x05connect\x03连接到服务器");
      CPrintToChatAll("{red}    --------------------------------");
      }
    case  1:{
      CPrintToChatAll("{red}[MPDS]\x01 QQ群:948265569，欢迎进群一起玩～");
      }
    case  2:{
      CPrintToChatAll("{red}[MPDS]\x01 可以使用\x05!buy\x01命令来打开服务器商店");
      CPrintToChatAll("\x05\x01 使用\x05!h\x01 来了解此服务器的信息与常用命令");
      }
    case  3:{
        CPrintToChatAll("{red}[MPDS]\x01 \x04 服务器商店中存在免费的武器&物品.");
      }
    case  4:{
      CPrintToChatAll("{red}[MPDS]\x01 如果第一个进入服务器的玩家没有安装8人MOD");
      CPrintToChatAll("\x04 \x01那么通常情况下第五个玩家是无法进入服务器的！");
      }
    case  MAXANNCOUNT:  CPrintToChatAll("{red}[MPDS]\x01 有任何疑问，请在Steam组讨论区留言.");
  }

  if(IsValidClient(index) )
  {
    KickClient(index, "");
  }

  if(g_iANNCount == MAXANNCOUNT)  
  {
    g_iANNCount = 0;
    return Plugin_Continue;
  }
  g_iANNCount++;

  return Plugin_Continue;
}


void Event_Finale_Win(Event event, const char[] name, bool dontBroadcast)
{
  CPrintToChatAll("{red}[MPDS]\x01 QQ群:\x05948265569\x01，欢迎进群一起玩～");
}
//---------------------------------------------------------------------------||
//    控制台命令
//---------------------------------------------------------------------------||
public Action cmd_help(int client, int args)
{
  if(0< client <= MaxClients)
  {
    CPrintToChat(client, "{blue}  ----------");

    CPrintToChat(client, "\x04[信息]\x01 QQ群:948265569");
    CPrintToChat(client, "\x04[信息]\x01 每章节开始时会依据人数延迟生成额外的医疗包，生成在随机一个玩家的位置");
    CPrintToChat(client, "\x04[信息]\x01 更多信息请留意屏幕顶部闪烁的提示与聊天框的红色提示...");
    CPrintToChat(client, "\x05!h  \x01打印服务器信息");
    //CPrintToChat(client, "\x05!servers\x01或\x05!ss  \x01查看所有服务器状态(玩家数量|地图)");
    CPrintToChat(client, "\x05!zs  \x01自杀");
    //CPrintToChat(client, "\x05!ji  \x01加入感染者  \x05!js \x01或\x05!join \x01加入幸存者");
    CPrintToChat(client, "\x05!buy  \x01打开服务器商店，或按下\x04E\x01+\x04R\x01来快速打开");
    CPrintToChat(client, "\x05!ldw  \x01抽奖:商店中的可用物品或随机的{blue}pt");
    CPrintToChat(client, "\x05!proe  \x01打开&关闭画面滤镜，可自定义，参数为RGBA色彩值");
    CPrintToChat(client, "\x05\x01  服务器默认值： \x05!proe %s\x01", S_DEF);
    CPrintToChat(client, "[聊天框向上滑动以查看的全部信息]");
    
    CPrintToChat(client, "{blue}  ----------");
  }
  return Plugin_Continue;
}

public Action cmd_zs(int client, int args)
{
  if(!g_bCookieCached[client] && g_bPluginLibraryLoaded_mpds_shop)
  {
    CPrintToChat(client,"{blue}[商店]\x01 相关数据正在加载，请稍后再试...");
    return Plugin_Continue;
  }

  if(IsPlayerAlive(client) )
  {
    if(GetClientTeam(client) == 3)
    {
      FakeClientCommand(client, "sm_zss", client);
      PrintToChat(client,"\x04:)");
      return Plugin_Continue;
    }
    
    PrefetchSound(ZS_Sound);
    PrecacheSound(ZS_Sound, true);
    EmitSoundToAll(ZS_Sound);
    ForcePlayerSuicide(client);
    MPDS_Shop_PT_Change(client, "-1");
    if(GetRandomFloat(0.00, 100.0) > 50.0)
      PrintToChatAll("\x03%N 自杀啦！", client);
    else  PrintToChatAll("\x03%N 失去了梦想...", client);

    char sPt[16];
    MPDS_Shop_PT_Get(client, sPt, 16);
    CPrintToChat(client,"{blue}由于自杀失去了 1 pt... 剩余: %s pt", sPt);
  }

  return Plugin_Continue;
}

public Action cmd_proe(int client, int args)
{
  if(!args)
  {
    PrintToChat(client, "!proe 来切换滤镜状态");
    PrintToChat(client, "带参数地使用命令来设置滤镜颜色： !proe [R] [G] [B] [A]");
    if(g_bProEyes[client][0])
    {
      g_bProEyes[client][0] = false;
      PrintToChat(client, "\x04%N 你的画面滤镜现在\x05关闭\x04...", client);
      return Plugin_Continue;
    }

    g_bProEyes[client][0] = true;
    PrintToChat(client, "\x04%N 你的画面滤镜现在\x05启用\x04...", client);
  }
  else
  {
    char buffer[16];
    GetCmdArgString(buffer, sizeof(buffer) );

    int old[4];
    for(int i=0; i<4; i++)
      old[i] = g_iEyesRGBA[client][i];

    if (!SaveClientEyesRGBA(client, buffer) )
    {
      PrintToChat(client, "\x01默认设置: \x04!proe %d %d %d %d\x01  [R][G][B][A]分别对应[红][绿][蓝][透明度]", DEF_R, DEF_G, DEF_B, DEF_A);
      PrintToChat(client, "参数的值应该介于0~255之间（包含）， 使用空格来分割它们");
    }
    else
    {
      PrintToChat(client, "\x03保存的滤镜颜色由 \x05%d %d %d %d\x01 变化为 \x05%d %d %d %d", old[0], old[1], old[2], old[3], g_iEyesRGBA[client][0], g_iEyesRGBA[client][1], g_iEyesRGBA[client][2], g_iEyesRGBA[client][3]);
      g_bProEyes[client][0] = false;
      CreateTimer(FADE_TIME, tEyesColorChange, GetClientUserId(client) );
    }      
  }

  return Plugin_Continue;
}

Action tEyesColorChange(Handle Timer, any userid)
{
  int client = GetClientOfUserId(userid);
  if(IsClientInGame(client) && client)
    g_bProEyes[client][0] = true;

  return Plugin_Continue;
}

/*
public Action cmd_proem(int client, int args)
{
  PrintToChat(client, "\x04 目前不可用...");
  return Plugin_Continue;
}
*/

//---------------------------------------------------------------------------||
//    Cvar变更
//---------------------------------------------------------------------------||
// 重新加载插件时自动获取信息
void AutoGetInfo()
{
  ServerExecute();
  g_iServerMaxPlayerSlots = g_hServerMaxPlayerSlots.IntValue;

  char sDiff[8];
  g_hDiff.GetString(sDiff, sizeof(sDiff) );
  
  if(g_bDiffLock)
  {
    if(sDiff[0] == 'H' || sDiff[0] == 'I')
      ServerCommand("sm_cvar z_difficulty \"Normal\"");
  }
  for(int i=0;i<4;i++)
    g_bDiff[i] = false;

  switch(sDiff[0])
  {
    case    'e':    Format(sDiff, sizeof(sDiff), "简单");
    case    'E':    Format(sDiff, sizeof(sDiff), "简单");
    case    'n':    Format(sDiff, sizeof(sDiff), "普通");
    case    'N':    Format(sDiff, sizeof(sDiff), "普通");
    case    'h':
    {
        Format(sDiff, sizeof(sDiff), "困难");
        g_bDiff[2] = true;
    }
    case    'H':    
    {
        Format(sDiff, sizeof(sDiff), "困难");
        g_bDiff[2] = true;
    }
    case    'i':
    {
        Format(sDiff, sizeof(sDiff), "专家");
        g_bDiff[3] = true;
    }
    case    'I':
    {
        Format(sDiff, sizeof(sDiff), "专家");
        g_bDiff[3] = true;
    }
  }
  char name[2][64];
  ExplodeString(g_sHostName, "|", name,  2, 64);
  ServerCommand("hostname \"%s| 难度：%s\"", name[0], sDiff);
  Format(g_sHostName, sizeof(g_sHostName), "%s| 难度：%s", name[0], sDiff);
}

public Action Event_Revive_Success(Event event, const char[] name, bool dontBroadcast)
{
  int target = GetClientOfUserId(event.GetInt("subject") );
  _AngFix_Event_Revive_Success(target);
  return Plugin_Continue;
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
  g_iServerMaxPlayerSlots = g_hServerMaxPlayerSlots.IntValue;
  _Glow_Event_ConVarChanged();

  if(GetAllPlayersInServer() >= MaxClients)
    return;

  int index = CreateFakeClient("CMD_红色字体工具人");
  ChangeClientTeam(index, 3);
  RequestFrame(rRED_PrintToChatAll_LobbyID, index);
}

public void Event_ConVarDiffLockChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
  g_bEyes = g_hEyes.BoolValue;
  g_bDiffLock = g_hDiffLock.BoolValue;
  g_bGlow = g_hGlow.BoolValue;
  g_iGlowDist = g_hGlowDist.IntValue
  g_bHintName = g_hHintName.BoolValue;
//  g_fHintName_Dist = g_hHintName.FloatValue;

  if(g_bGlow && !IsValidHandle(g_hGlowTimer))
  {
    g_hGlowTimer = CreateTimer(3.0, tSetGlow,  _, TIMER_REPEAT);
    //g_hGlowSurvivors.SetInt(0);
  }
  else
  {
    //g_hGlowSurvivors.SetInt(1);
    reset_glow(0);
  }
  char sDiff[8];
  g_hDiff.GetString(sDiff, sizeof(sDiff) );
  
  if(g_bDiffLock)
  {
    if(sDiff[0] == 'H' || sDiff[0] == 'I')
      ServerCommand("sm_cvar z_difficulty \"Normal\"");
  }
  for(int i=0;i<4;i++)
    g_bDiff[i] = false;

  switch(sDiff[0])
  {
    case    'e':    Format(sDiff, sizeof(sDiff), "简单");
    case    'E':    Format(sDiff, sizeof(sDiff), "简单");
    case    'n':    Format(sDiff, sizeof(sDiff), "普通");
    case    'N':    Format(sDiff, sizeof(sDiff), "普通");
    case    'h':
    {
        Format(sDiff, sizeof(sDiff), "困难");
        g_bDiff[2] = true;
    }
    case    'H':    
    {
        Format(sDiff, sizeof(sDiff), "困难");
        g_bDiff[2] = true;
    }
    case    'i':
    {
        Format(sDiff, sizeof(sDiff), "专家");
        g_bDiff[3] = true;
    }
    case    'I':
    {
        Format(sDiff, sizeof(sDiff), "专家");
        g_bDiff[3] = true;
    }
  }

  char name[2][64];
  ExplodeString(g_sHostName, "|", name,  2, 64);
  ServerCommand("hostname \"%s| 难度：%s\"", name[0], sDiff);
  Format(g_sHostName, sizeof(g_sHostName), "%s| 难度：%s", name[0], sDiff);

  SetCvar();
}

void rRED_PrintToChatAll_LobbyID(any index)
{    
  g_iLobby = g_hLobby.IntValue;

  if(g_iLobby == 1)
  {
    ServerCommand("sv_cookie \"%s\"",g_sLobbyID);
    CPrintToChatAll("{red}[%s]\x01 \x05大厅匹配已启用:\x01 %s", PLUGIN_NAME, g_sLobbyID);
  }
  else if(g_iLobby == 0)
  {
//    L4D_GetLobbyReservation(g_sLobbyID, sizeof(g_sLobbyID) );
    Format(g_sLobbyID, sizeof(g_sLobbyID), "%s", GetLobbyCookie() );
    CPrintToChatAll("{red}[%s]\x01 \x05大厅匹配已关闭.", PLUGIN_NAME, g_sLobbyID);
    ServerCommand("sv_cookie 0");
  }
  else
  {
//    L4D_GetLobbyReservation(g_sLobbyID, sizeof(g_sLobbyID) );
    Format(g_sLobbyID, sizeof(g_sLobbyID), "%s", GetLobbyCookie() );
    CPrintToChatAll("{red}[%s]\x01 \x05大厅Cookie已保存:\x01 %s", PLUGIN_NAME, g_sLobbyID);
  }

  if(IsValidClient(index) )
    KickClient(index, "");
}

//---------------------------------------------------------------------------||
//    关闭友军火力
//---------------------------------------------------------------------------||

public OnClientPutInServer(client)
{
  SDKHook(client, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public Action eOnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
  if(fDamage == 0.00)
    return Plugin_Continue;
//    char sBf[64];
//    GetEntityClassname(iInflictor, sBf, sizeof(sBf) );
//    if( (iDamagetype & DMG_BURN) >= 0)
//      PrintToChatAll("%d %d %s", iAttacker, iInflictor, sBf);

  if(iAttacker == iInflictor)
  {
    if(GetClientTeam(iVictim) == 2)
    {
      char buffer[16];
      GetEntityClassname(iInflictor, buffer, sizeof(buffer) );
      if(iDamagetype & DMG_BURN)
        if(strcmp("inferno", buffer, false) == 0)
          return Plugin_Handled;        
    }
  }

  if(!IsValidClientIndex(iAttacker) )
    return Plugin_Continue;

  static String:sInflictor[18];
  GetEntityClassname(iInflictor, sInflictor, sizeof(sInflictor));
  if(sInflictor[0] == 'p' && StrContains(sInflictor, "prop") > 0 )
    return Plugin_Continue;

  if(GetClientTeam(iVictim) == 2)
  {
    if(GetClientTeam(iAttacker) == 2 && !IsFakeClient(iAttacker) )
    {
      return Plugin_Handled;
    }
  }
  return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//              阻止更改难度至普通以上
//---------------------------------------------------------------------------||
public Action Listener_CallVote(int client, const char[] command, int argc)
{
  char sIssue[32], sTarget[32];
  GetCmdArg(1, sIssue, sizeof(sIssue));
  GetCmdArg(2, sTarget, sizeof(sTarget));

  if(g_bDiffLock)
  {
    if(strcmp(sIssue, "changedifficulty", false) == 0)
    {
      if(sTarget[0] == 'H' || sTarget[0] == 'I')
      {
        PrintToChat(client, "\x05[MPDS] \x03此服务器禁止将难度调整为普通以上.")
        return Plugin_Handled;
      }

    }
  }

  if(strcmp(sIssue, "returntolobby", false) == 0)
  {
    PrintToChat(client, "\x05[MPDS] \x03此操作已被禁用.")
    return Plugin_Handled;
  }

  if(strcmp(sIssue, "restartgame", false) == 0)
  {
    PrintToChat(client, "\x05[MPDS] \x03此操作已被禁用.");
    return Plugin_Handled;
  }

  return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//    预缓存声音&设置IsMapRuning标记
//---------------------------------------------------------------------------||
public void OnMapStart()
{
  LoadVScript();
  _CCSP_OnMapStart();

  for(int i=0;i<10;i++)
  {
    PrefetchSound(sSound_TankYell[i]);
    PrecacheSound(sSound_TankYell[i]);
  }
}

//---------------------------------------------------------------------------||
//              进入与离开消息
//---------------------------------------------------------------------------||
public bool OnClientConnect( int client, char []rejectmsg, int maxlen)
{

  if(!IsFakeClient(client) )
  {
    int num = GetPlayerNum();
    PrintToChatAll("\x04[%d/%d] \x05%N\x03 正在连接到服务器.", num, g_iServerMaxPlayerSlots,client);
    EmitSoundToAll(sSound_TankYell[GetRandomInt(0,9)], SOUND_FROM_PLAYER);
  }

  return true;
}

Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
  int client = GetClientOfUserId(GetEventInt(event,"userid"));

  if (!(1 <= client <= MaxClients))
  return Plugin_Handled;

  if (!IsClientInGame(client))
  return Plugin_Handled;

  if (IsFakeClient(client))
  return Plugin_Handled;

  g_bProEyes[client][0] = false;
  g_bProEyes[client][1] = false;
  g_bProtectingEyes[client] = false;

  char reason[64];
  char message[128];
  GetEventString(event, "reason", reason, sizeof(reason));

  if(StrContains(reason, "connection rejected", false) != -1)
    Format(message,sizeof(message),"连接被拒绝");
  else if(StrContains(reason, "timed out", false) != -1)
    Format(message,sizeof(message),"连接超时");
  else if(StrContains(reason, "by user", false) != -1)
    Format(message,sizeof(message),"玩家断开连接");
  else if(StrContains(reason, "No Steam logon", false) != -1)
    Format(message,sizeof(message),"Steam账户验证失败");
  else if(StrContains(reason, "Steam account is being used in another", false) != -1)
    Format(message,sizeof(message),"Steam账户正在被其他人使用");
  else if(StrContains(reason, "Steam Connection lost", false) != -1)
    Format(message,sizeof(message),"与Steam的连接丢失");
  else if(StrContains(reason, "This Steam account does not own this game", false) != -1)
    Format(message,sizeof(message),"游戏所有权验证失败");
  else if(StrContains(reason, "Validation Rejected", false) != -1)
    Format(message,sizeof(message),"游戏文件验证失败");
  else  message = reason;

  PrintToChatAll("%N 已离开游戏：%s", client, message);
//  ServerCommand("say %N 已断开连接：%s", client, message);
  // 清除记录
  int id = GetSteamAccountID(client);
  for(int i=1; i<=MaxClients; i++)
  {
    if(g_iPlayerID[i] == id)
    {
      g_iPlayerID[i]=0;
      break;
    }
  }

  SetEventBroadcast(event, true)

  return Plugin_Continue;
}

//---------------------------------------------------------------------------||
//              准入设置与保存服务器大厅ID
//---------------------------------------------------------------------------||
public void OnClientConnected(int client)
{

  if(IsFakeClient(client) )
    return;

  char tag[32];
  GetConVarString(FindConVar("sv_search_key"), tag, sizeof(tag) );
  if(strcmp(tag, "greenflu") == 0)
  {
    ServerCommand("sv_search_key \"\"");
    PrintToServer("\n %s : 大厅匹配密钥限制设置为空", PLUGIN_NAME);
    ServerCommand("sv_steamgroup_exclusive \"0\"");
    PrintToServer("\n %s : 组成员优先取消", PLUGIN_NAME);
  }
}
//---------------------------------------------------------------------------||
//              简单控制c1m4与c6m3的特感生成时间（至少目前我没有太多的精力）
//---------------------------------------------------------------------------||
// 对于服务器目前的设置，这些操作是无效的
/*
static char c1m4Fix[]="l4d_infectedbots_adjust_reduced_spawn_times_on_player 1";
static char c6m3Fix[]="l4d_infectedbots_spawn_time_min 50";

static char c1m4Def[]="l4d_infectedbots_adjust_reduced_spawn_times_on_player 2";
static char c6m3Def[]="l4d_infectedbots_spawn_time_min 40";

void FixSomeMapDiff()
{
  char name[24];
  GetCurrentMap(name, sizeof(name) );
  if(strcmp(name, "c1m4_atrium") == 0)
  {
    ServerCommand("%s", c1m4Fix);
    ServerCommand("%s", c6m3Def);
    return;
  }
  if(strcmp(name, "c6m3_port") == 0)
  {
    ServerCommand("%s", c1m4Fix);
    ServerCommand("%s", c6m3Fix);
    return;
  }
  // 需要注释掉相关插件的cfg文件
  ServerCommand("%s", c1m4Def);
  ServerCommand("%s", c6m3Def);
  
  if(strcmp(name, "l4d_yama_1") == 0)
  {
    ServerCommand("sm plugins unload safedoor_scavenge");
    return;
  }
}
*/
//---------------------------------------------------------------------------||
//              欢迎菜单 为了覆盖缓冲区
//---------------------------------------------------------------------------||
public void OnClientPostAdminCheck(int client)
{
//  if(IsFirstConnected(client) )
    CreateTimer(5.0, tDelayDisplay, client);
}

Action tDelayDisplay(Handle Timer, any client)
{
  if(IsClientInGame(client) )
  {
    for(int i=1; i<= MaxClients; i++)
    {
      if(g_iPlayerID[i] == 0)
      {
        // 这可能与L4dtoolZ冲突吗
        g_iPlayerID[i] = GetSteamAccountID(client);
        break;
      }
    }
    DisplayWellcomeMenu(client);
  }
  return Plugin_Continue;

}

void DisplayWellcomeMenu(int client)
{
  Menu wellcome = CreateMenu(Menu_rc);
  wellcome.ExitButton = false;
  wellcome.SetTitle("欢迎进入 %s", g_sHostName);
  wellcome.AddItem("QQ群：948265569", "QQ群：948265569");
  wellcome.AddItem("欢迎一起来玩~", "欢迎一起来玩~");
  wellcome.Display(client, MENU_TIME_FOREVER);
}

public int Menu_rc(Menu menu, MenuAction action, int param1, int param2)
{
/*
  if(action == MenuAction_Select)
  {
    PrintServerHint(param1);
  }
*/
  if(action == MenuAction_End)
  {
    if(!IsValidHandle(menu) )
      return 0;
    delete menu;
  }
  return 0;
}

//---------------------------------------------------------------------------||
//    削弱近战对Tank的伤害
//---------------------------------------------------------------------------||
void Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
  int index = event.GetInt("tankid");
  SDKHook(index, SDKHook_OnTakeDamage, eTank_OnTakeDamage);
}

public Action eTank_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
  //Melee
  if(fDamage == 0.0)  return Plugin_Continue;
  if(weapon < 0 || !IsValidEntity(weapon))        return Plugin_Continue;

  if(0 < iAttacker <= MaxClients)
  {
    if(GetClientTeam(iAttacker) == 2)
    {
      char weaponName[32];
      GetEntityClassname(weapon, weaponName, sizeof(weaponName));
      if(strcmp(weaponName, "weapon_melee") == 0)
      {
        int num = GetPlayerNum();
        if(num < 9)
          fDamage = fDamage / 2;
        else  if(num < 14)
          fDamage = fDamage / 4;
        else  fDamage = fDamage / 5;
      }
      return Plugin_Changed;
    }
  }
  return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//              EMUS HUD
//---------------------------------------------------------------------------||
Handle g_tUpdateInterval;
public void OnConfigsExecuted()
{
  if(!IsValidHandle(g_tUpdateInterval) )
  {
    //HudSet(EMSHUD_SLOT);
    g_tUpdateInterval = CreateTimer(0.5, UpdateHint, _, TIMER_REPEAT);    
  }

  L4D2_SetIntWeaponAttribute("weapon_chainsaw", L4D2IWA_ClipSize, 120);
  L4D2_SetIntWeaponAttribute("weapon_chainsaw", L4D2IWA_DefaultSize, 120);

  L4D2_SetIntWeaponAttribute("weapon_rifle", L4D2IWA_Damage, 38);
  L4D2_SetIntWeaponAttribute("weapon_rifle_sg552", L4D2IWA_Damage, 38);

  L4D2_SetFloatWeaponAttribute("weapon_pistol_magnum", L4D2FWA_PenetrationNumLayers, 4.0);
  L4D2_SetIntWeaponAttribute("weapon_pistol_magnum", L4D2IWA_ClipSize, 12);
  L4D2_SetIntWeaponAttribute("weapon_pistol_magnum", L4D2IWA_DefaultSize, 12);

  L4D2_SetIntWeaponAttribute("weapon_rifle_m60", L4D2IWA_ClipSize, 300);
  L4D2_SetIntWeaponAttribute("weapon_rifle_m60", L4D2IWA_DefaultSize, 300);
  L4D2_SetFloatWeaponAttribute("weapon_rifle_m60", L4D2FWA_CycleTime, 0.055); // 0.11 -> 0.055

  L4D2_SetIntWeaponAttribute("weapon_grenade_launcher", L4D2IWA_ClipSize, 2);
  L4D2_SetIntWeaponAttribute("weapon_grenade_launcher", L4D2IWA_DefaultSize, 2);

  CreateTimer(3.0, tDelaySetCvar);
}

Action tDelaySetCvar(Handle Timer)
{
  SetCvar();

  return Plugin_Continue;
}

void SetCvar()
{
  ServerCommand("sm_cvar z_throttle_hit_interval_easy 0.1");
  ServerCommand("sm_cvar z_throttle_hit_interval_normal 0.1");
  ServerCommand("sm_cvar z_throttle_hit_interval_hard 0.0");
  ServerCommand("sm_cvar z_throttle_hit_interval_expert 0.0");

  ServerCommand("sm_cvar z_head_damage_causes_wounds 0");
  ServerCommand("sm_cvar z_non_head_damage_factor_easy 2");
  ServerCommand("sm_cvar z_non_head_damage_factor_normal 1.0");
  ServerCommand("sm_cvar z_non_head_damage_factor_hard 0.75");
  ServerCommand("sm_cvar z_non_head_damage_factor_expert 0.5");
  ServerCommand("sm_cvar z_health 50");
  ServerCommand("sm_cvar survivor_crawl_speed 30");
  
  // 高级难度的特定设置
  if(g_bDiff[2])
  {
    ServerCommand("l4d_survivorrespawn_thrownweapon 0");
    ServerCommand("l4d_survivorrespawn_respawntimeout 20");
    ServerCommand("l4d_survivorrespawn_deathlimit 4");
    ServerCommand("l4d_infectedbots_read_data hard");
//    ServerCommand("l4d_infectedbots_spawn_time_max 70");
//    ServerCommand("l4d_infectedbots_spawn_time_min 32");
//    ServerCommand("l4d_infectedbots_adjust_reduced_spawn_times_on_player 2");
  
  }
  // 专家难度的特定设置
  else if(g_bDiff[3])
  {
    ServerCommand("l4d_survivorrespawn_thrownweapon 0");
    ServerCommand("l4d_survivorrespawn_respawntimeout 20");
    ServerCommand("l4d_survivorrespawn_deathlimit 4");
//    ServerCommand("l4d_infectedbots_spawn_time_max 60");
//    ServerCommand("l4d_infectedbots_spawn_time_min 28");
//    ServerCommand("l4d_infectedbots_adjust_reduced_spawn_times_on_player 2");
    ServerCommand("l4d_infectedbots_read_data expert");
  }
  // 返回默认设置
  else
  {
    ServerCommand("l4d_survivorrespawn_thrownweapon 2");
    ServerCommand("l4d_survivorrespawn_respawntimeout 30");
    ServerCommand("l4d_survivorrespawn_deathlimit 4");
//    ServerCommand("l4d_infectedbots_spawn_time_max 80");
//    ServerCommand("l4d_infectedbots_spawn_time_min 40");
//    ServerCommand("l4d_infectedbots_adjust_reduced_spawn_times_on_player 2");
    ServerCommand("l4d_infectedbots_read_data coop");
  }
}

public void Event_RoundStart(Event hEvent, const char[] strName, bool DontBroadcast)
{
  _CCSP_RoundStart();
  HudSet(EMSHUD_SLOT);
}

int  iHud_count;
bool  bHud_countpp=true;
int  iHUD_MSG_count;

#define  HUD_MAXMSG  27
static char g_sMSG[][]={
  "输入 !zs 可以自杀  !csm 可以更换角色 !buy 打开商店 !ldw 进行抽奖 !h 来获取帮助",
  "多人尸潮 服务器尚处于测试阶段",
  "可以通过输入 !join 来加入游戏",
  "通过 !jukestop 来关闭安全屋唱片机音乐",
  "友军伤害已经被关闭",
  "触发安全门事件时，请留意聊天框的提示...",
  "迷雾来临时看不清？太闪眼？ 请输入 !proe 来打开画面滤镜",
  "尝试打开安全门时降临的Tank在生成的一段时间内是无敌的 你对于它也是:)",
  "本服务器感染者数量较多，请紧跟随队伍前进",
  "电锯已经被增强，当回合重启一次后，开始区域将刷新电锯",
  "马格南，M16，SG552，M60，榴弹发射器均已经过调整",
  "帮助队友可以让你有机会突破默认的生命值上限",
  "QQ群:948265569",
  "想要休息一下(闲置)？ 只需原地不动一段时间",
  "服务器每一天的早上九点整关闭，一小时后重新启动",
  "当你加入服务器的Steam组，它(指服务器)就不会突然消失啦！",
  "此服务器支持8人大厅",
  "挂机几个小时都没有人加入？快来群里摇人吧～",
  "手持某些物品对着目标按下 R键 即可传递它，如果是机器人也可以交换对方的物品",
  "请注意其他人的位置与健康状况",
  "除了MPDS，还有其他九台神秘的服务器",
  "如果喜欢此服务器，请按\x05H\x01点击加入\x05服务器的Steam组",
  "服务器的每日消息中也包括了许多信息，请按H查看它",
  "使用除颤器复活队友还会清除你的黑白状态",
  "通过 !jukenext 来切换安全屋唱片机的下一首曲目",
  "某些时间段可能很难有人匹配到此服务器...",
  "治疗处于濒死黑白状态的队友可以获得生命值"
};
Action UpdateHint(Handle timer)
{
  if(bHud_countpp)
    iHud_count++;
  if(iHud_count >= 400)  
  {
    iHUD_MSG_count++;
    bHud_countpp = false;
    // 180秒
    iHud_count = 0;


    if(iHUD_MSG_count >= 23)
      iHUD_MSG_count=0;
    UpdateHUD(EMSHUD_SLOT, g_sMSG[iHUD_MSG_count]);  
  }
  return Plugin_Continue;
}
#define HUD_FLAG_PRESTR      (1<<0)  //  do you want a string/value pair to start(pre) or end(post) with the static string (default is PRE)
#define HUD_FLAG_POSTSTR    (1<<1)  //  ditto
#define HUD_FLAG_BEEP      (1<<2)  //  Makes a countdown timer blink
#define HUD_FLAG_BLINK      (1<<3)  //  do you want this field to be blinking
#define HUD_FLAG_AS_TIME    (1<<4)  //  to do..
#define HUD_FLAG_COUNTDOWN_WARN  (1<<5)  //  auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG      (1<<6)  //  dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER  (1<<7)  //  by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT    (1<<8)  //  Left justify this text
#define HUD_FLAG_ALIGN_CENTER  (1<<9)  //  Center justify this text
#define HUD_FLAG_ALIGN_RIGHT  (3<<8)  //  Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS  (1<<10)  //  only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED  (1<<11)  //  only show to the special infected team
#define HUD_FLAG_TEAM_MASK    (3<<10)  //  link HUD_FLAG_TEAM_SURVIVORS and HUD_FLAG_TEAM_INFECTED
#define HUD_FLAG_UNKNOWN1    (1<<12)  //  ?
#define HUD_FLAG_TEXT      (1<<13)  //  ?
#define HUD_FLAG_NOTVISIBLE    (1<<14)  //  if you want to keep the slot data but keep it from displaying

//---------------------------------------------------------------------------||
//              画面滤镜
//---------------------------------------------------------------------------||
public void OnClientCookiesCached(int client)
{
  if(IsFakeClient(client) )
    return;

  g_bCookieCached[client] = true;

  char sRGBA[16];//, sSwitchMethod[2];
  GetClientCookie(client, g_hCookie_EyesRGBA, sRGBA, sizeof(sRGBA) );
  
  if(sRGBA[0])
  {
    SetClientEyesRGBA(client, sRGBA);
  }
  else
  {
    SaveClientEyesRGBA(client, S_DEF);
  }
/*
  if(sSwitchMethod[0])
  {
    g_bEyesSiwtchMethod[client] = StringToInt(sSwitchMethod);
  }
*/
}


void SetClientEyesRGBA(int client, const char[] value)
{
  char buffer[4][4];
  ExplodeString(value, " ", buffer, 4, 4);

  for(int i=0; i<4; i++)
    g_iEyesRGBA[client][i] = StringToInt(buffer[i])
}

bool SaveClientEyesRGBA(int client, const char[] value)
{
  char buffer[4][4];
  ExplodeString(value, " ", buffer, 4, 4);

  int ibuffer[4];
  for(int i=0; i<4; i++)
  {
    ibuffer[i] = StringToInt(buffer[i]);    
    if(ibuffer[i] > 255 || ibuffer[i] < 0)
      return false;
  }

  if(ibuffer[0] == 0 && ibuffer[1] == 0 && ibuffer[2] == 0 && ibuffer[3] == 0)
    return false;

  SetClientEyesRGBA(client, value);
  SetClientCookie(client, g_hCookie_EyesRGBA, value);

  return true;
}
int Count[MAXPLAYERS+1];
public Action OnPlayerRunCmd(int client)
{
  Count[client]++;
  if(g_bHintName && !IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && Count[client] >= 45)
  {
    int target = GetClientAimTarget(client);
    if(0 < target <= MaxClients)
    {
      if(IsClientInGame(target)  )
      {
        if(GetClientTeam(target) == 2)
        {
          float mPos[3], tPos[3];
          GetClientAbsOrigin(client, mPos);
          GetClientAbsOrigin(target, tPos);
          if(GetVectorDistance(mPos, tPos) <= 150.0 )
          {
            PrintHintText(client, "[ %N ]", target);
          }
        }
      }
    }
    Count[client] = 0;
  }

  if(!g_bEyes)  
    return Plugin_Continue;
  
  if(IsFakeClient(client) )
    return Plugin_Continue;

  if(g_bProEyes[client][0])
  {
    if(g_bProEyes[client][0] && g_bProEyes[client][1])
      PerformFadeOut(client);

    g_bProEyes[client][1] = true;
    PerformFadeIn(client);

    return Plugin_Continue;
  }
  if(!g_bProEyes[client][0] && g_bProEyes[client][1])
  {
    g_bProEyes[client][1] = false;
    PerformFadeIn(client);
  }
  return Plugin_Continue;
}

Action FadeHook(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
  if (playersNum != 1)
    return Plugin_Continue;

  int client = players[0];

  if (!IsValidClient(client))
    return Plugin_Continue;

  if (IsFakeClient(client))
    return Plugin_Continue;

  if (g_bProtectingEyes[client])
  {
    g_bProtectingEyes[client] =false;
    return Plugin_Continue;
  }
  return Plugin_Handled;
}

void ScreenFade(int client, int delay, int duration, int type, int red, int green, int blue, int alpha)
{
    Handle message = StartMessageOne("Fade", client);
    BfWrite bf = UserMessageToBfWrite(message);
    bf.WriteShort(delay);
    bf.WriteShort(duration);
    bf.WriteShort(type);
    bf.WriteByte(red);
    bf.WriteByte(green);
    bf.WriteByte(blue);
    bf.WriteByte(alpha);
    EndMessage();
}

void PerformFadeOut(int client)
{
    g_bProtectingEyes[client] = true;
    ScreenFade(client, RoundFloat(FADE_DURAATION),SCREENFADE_FRACBITS, FFADE_PURGE|FFADE_OUT|FFADE_STAYOUT, g_iEyesRGBA[client][0], g_iEyesRGBA[client][1], g_iEyesRGBA[client][2], g_iEyesRGBA[client][3]);
}

void PerformFadeIn(int client)
{
    g_bProtectingEyes[client] = true;
    ScreenFade(client, RoundFloat(FADE_DURAATION), SCREENFADE_FRACBITS, FFADE_PURGE|FFADE_IN, g_iEyesRGBA[client][0], g_iEyesRGBA[client][1], g_iEyesRGBA[client][2], g_iEyesRGBA[client][3]);
}

//---------------------------------------------------------------------------||
//              Stock
//---------------------------------------------------------------------------||
stock bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

stock bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

stock char[] GetLobbyCookie()
{
  char sCookie[20];
  g_hCookie.GetString(sCookie, sizeof(sCookie) );

  return sCookie;
}

stock void HudSet(int slot)
{
  GameRules_SetPropFloat("m_fScriptedHUDPosX", 0.00, slot, true);
  GameRules_SetPropFloat("m_fScriptedHUDPosY", 0.00, slot, true);
  GameRules_SetPropFloat("m_fScriptedHUDWidth", 1.0, slot, true);
  GameRules_SetPropFloat("m_fScriptedHUDHeight", 0.05, slot, true);  
}
stock void UpdateHUD(int slot, const char[] msg)
{  
//  if(msg[0] )
  {
    CreateTimer(6.0, tRemove_REDHUD, slot);
    GameRules_SetProp("m_iScriptedHUDFlags", EMSHUD_FLAG | HUD_FLAG_BLINK, _, slot);
    GameRules_SetPropString("m_szScriptedHUDStringSet", msg, true, slot);
  }
}

Action tRemove_REDHUD(Handle Timer, any slot)
{
  GameRules_SetProp("m_iScriptedHUDFlags", EMSHUD_FLAG & ~ HUD_FLAG_BLINK, _, slot);
  CreateTimer(20.0, tRemoveHUD, slot);
  return Plugin_Continue;
}

Action tRemoveHUD(Handle Timer, any slot)
{
  RemoveHUD(slot);
  return Plugin_Continue;  
}

stock void RemoveHUD(int slot)
{
  GameRules_SetPropString("m_szScriptedHUDStringSet", "", true, slot);
  bHud_countpp = true;
}

stock int GetAllPlayersInServer()
{
  int count = 0;
  for(int i = 1; i < MaxClients + 1; i++)
  {
    if(IsClientConnected(i))
    {
    count++;
    }
  }
  return count;
}
//---------------------------------------------------------------------------||
//              pt系统相关
//---------------------------------------------------------------------------||
public void OnClientDisconnect(int client)
{
  hasGlow[client] = false;
  g_bCookieCached[client] = false;
}
