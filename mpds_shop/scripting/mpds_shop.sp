#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>
#include <left4dhooks>

#define PLUGIN_NAME             "MPDS Shop"
#define PLUGIN_DESCRIPTION      "服务器商店与内嵌的击杀奖励系统"
#define PLUGIN_VERSION          "REV 1.1.2"
#define PLUGIN_AUTHOR           "oblivcheck"
#define PLUGIN_URL              "https://github.com/oblivcheck/l4d2_plugins/blob/master/mpds_shop"

#define DEBUG 0
#include "mpds_shop/define.sp"
#include "mpds_shop/options.sp"
#include "mpds_shop/items.sp"
#include "mpds_shop/fuc.sp"
#include "mpds_shop/inc.sp"
#include "mpds_shop/special_items.sp"

/************************************************************************
Changes Log:
2024-03-28 (REV 1.1.2)
  - Add a plugin globe forward: "MSS_OnReceivingRewards"
  - Auto find first item index in Sub-Shop.

2024-03-25 (REV 1.1.1)
  - Organize the code.

2024-03-23 (REV 1.1.0)
  - Organize the code.
  - Add more plugin options.
  - Menu can now be quickly opened by simultaneously pressing the +USE and RELOAD buttons(game def = E+R).
  - Fixed: "inconsistent indentation" compile warning.
  - Item prices can now be dynamic.
  - Modify Plugin Native.
    - Will fill a string instead of returning an integer value.

2024-03-20 (REV 1.0.3 Beta)
  - Fixed: command "!ldw" occasionally fail to kill player.
  - Fixed: players can rejoin the server to refresh store item inventory.
  - Allow dynamic setting of item prices
      - Imperfect functionality.
  - Updated chat messages && Changed some plugin options.
    - Latest version on my server.
  - Add shop special items
    * Launch firework.
      - Required plugin: [l4d2_fireworks]
        - (https://forums.alliedmods.net/showthread.php?p=1441088)
    * Spawn and control a Tank.
      - Required plugin: [l4dinfectedbots]
        - Need to use my fork (based v2.8.8)
        - (https://github.com/oblivcheck/l4d2_plugins/blob/master/l4dinfectedbots)
    * Many known issues exist, and we should utilize the latest version of 'l4dinfectedbots' and re-implement this functionality.
  -  Code adjustments
    - (i < MaxClients) -> (i <= MaxClients)
  
2024-02-03 (REV 1.0.2 Not Release)
  - Command "!buy"
    - Rmove chat info “testing"
  - Command "ldw" 
    - now has a chance to kill the player.

2024-01-31 (REV 1.0.1)
  - Fixed：For special infected, kills without reward will still send msg to the player.
  - Fixed："SHOP_STOCK_SHARE" compile warning.
  - Modify some comments.

2024-01-30 (REV 1.0.0)
  - Modify some comments.
  - Command "sm_hreset" is no longer executed when the plugin start.
  - Set HL2 random stream when executing function LDW()
  - Fixed: Item price display error in realism mode.
  - Add some new macro definitions to modify the plugin settings.
  - Add item stock type display to sub-shop menu title.
    - Unfinished feature.

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

  CreatePluginCall();

  return APLRes_Success;
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
  HookEvent("tank_spawn", Event_Tank_Spawn);
  HookEvent("tank_killed", Event_Tank_Killed);  
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
  else  IsRealismMode = false;
  hIsRealismMode.AddChangeHook(Event_ConVarChanged);

  chPlayerPT = RegClientCookie("mpds_pt_re3", "该玩家拥有的商店点数", CookieAccess_Protected);
  RegConsoleCmd("sm_buy", cmd_buy);
  RegConsoleCmd("sm_ldw", cmd_ldw);
  RegAdminCmd("sm_hreset", cmd_hreset, ADMFLAG_ROOT);  

  CacheShopItem();
  SubShop_FindFirstValidItem();

  ResetClientShopItemInventory();
  ResetClientCount_LDW();
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
  else  IsRealismMode = false;
}
// 服务器运行中重新加载插件需要执行一次此命令
Action cmd_hreset(int client, int args)
{
  ResetClientShopItemInventory();
  ResetClientCount_LDW();

  for(int i=1; i<=MaxClients; i++)
  {
    g_bCookieCached[i] = true;
    if(IsClientInGame(i) )
      if(!IsFakeClient(i) )
      {
        char cC[16];
        GetClientCookie(i, chPlayerPT, cC, sizeof(cC) );
        int cookieValue = StringToInt(cC);
        ReplyToCommand(client, "%d#%N: %s#%d", i, i, cC, cookieValue);
        
        char sPt[16];
        if(PT_Get(i, sPt) )
          g_iPlayerPT[i] = StringToInt(sPt);

        int id = GetSteamAccountID(i);
        if(id != 0)
        {
          int idx = ShopItemInventory_GetClientIndexOfSteamID(id);
          if(idx == -1)
          {
            for(int p=0;p<SingleMapMaxPlayers;p++)
              if(g_iClientShopItemRemainingQuantity[p][SHOP_ITEM_NUM] == 0 || g_iClientShopItemRemainingQuantity[p][SHOP_ITEM_NUM] == -1)
              {
                g_iClientShopItemRemainingQuantity[p][SHOP_ITEM_NUM] = id;
                PrintToServer("\n%N#库存记录idx=%d",client, p);
                break;
              }
          }
          else  PrintToServer("\nERROR: cmd_hreset(); %N# target idx == 0", client);
        }
        else  PrintToServer("\nERROR: cmd_hreset(); %N# id == 0", client);
      }
  }

  ReplyToCommand(client, "sm_hreset: 执行完毕");

  return Plugin_Continue;
}

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

  g_bPlayerOpenShopCooldown[client] = false;
}

//---------------------------------------------------------------------------||
//    使用除颤器复活队友的奖励
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

  _MSSORR_iClient = client;
  _MSSORR_iType = REASON_TYPE_HELP;
  _MSSORR_iReason = REASON_HELP_DEFIB; 
  _MSSORR_iTarget = target;
  _MSSORR_bRealhp = true;
  _MSSORR_bRefThirdStrike = true;
  _MSSORR_bLimit = true;
  _MSSORR_bMsg = true;
  _MSSORR_fTargethp = float(HP +DEFIB_REWARD);

  if(Call_MSS_OnReceivingRewards(_MSSORR_iClient, _MSSORR_bRealhp, _MSSORR_fTargethp, 
    _MSSORR_iType, _MSSORR_iReason, _MSSORR_bRefThirdStrike, _MSSORR_bLimit,
    _MSSORR_bMsg, _MSSORR_iTarget)
      == Plugin_Handled)
    return Plugin_Continue;
    // 除非不对消息进行硬编码，否则原则上不应该将奖励生命值设置为负数，其它情况应设置_MSSORR_bMsg=false阻止消息
  if(_MSSORR_bMsg)
  {
    PrintToChatAll("\x05%N \x03使用除颤器救回 \x05%N", client, target);
    PrintToChatAll("\x03----获得了\x05%d\x03生命值奖励并重置了自己的健康状态.",
      RoundToFloor(_MSSORR_fTargethp) - HP);
  }
  if(!IsFakeClient(client) )
  {
    if(PT_Add(client, DEFIB_REWARD_PT) != -1 )
    CPrintToChat(client, "\x03\x01获得了{blue} %d pt\x01", DEFIB_REWARD_PT);
  }
  else  CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");

  return Plugin_Continue;
}

//---------------------------------------------------------------------------||
//    治愈濒死队友的奖励    
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
    _MSSORR_iClient = client;
    _MSSORR_iType = REASON_TYPE_HELP;
    _MSSORR_iReason = REASON_HELP_HEAL; 
    _MSSORR_iTarget = target;
    _MSSORR_bRealhp = true;
    _MSSORR_bRefThirdStrike = false;
    _MSSORR_bLimit = true;
    _MSSORR_bMsg = true;
    _MSSORR_fTargethp = float(HP + HEAL_REWARD);

    if(Call_MSS_OnReceivingRewards(_MSSORR_iClient, _MSSORR_bRealhp, _MSSORR_fTargethp, 
      _MSSORR_iType, _MSSORR_iReason, _MSSORR_bRefThirdStrike, _MSSORR_bLimit,
      _MSSORR_bMsg, _MSSORR_iTarget) 
        == Plugin_Handled)
      return Plugin_Continue;

    if(_MSSORR_bMsg)  
      PrintToChatAll("\x05%N \x03使用医疗包治愈了处于濒死状态的 \x05%N\x03，获得了\x05%d\x03生命值奖励", 
        client, target, RoundToFloor(_MSSORR_fTargethp) - HP);

    if (!IsFakeClient(client) )
    {
      if(PT_Add(client, HEAL_REWARD_PT) != -1)
        CPrintToChat(client, "\x03\x01获得了{blue} 5 pt\x01", HEAL_REWARD_PT);
      else  CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");
    }
  }
  else    PrintToChatAll("\x05%N \x03使用医疗包治愈了 \x05%N\x03.", client, target);


  return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//    救起队友的奖励    
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
    {
      Add_HP = REVIVE_REWARD;
      _MSSORR_iType = REASON_HELP_HANGING;
    }
    else  
    {
      Add_HP = REVIVE_FAST_REWARD;
      _MSSORR_iType = REASON_HELP_HANGING_EMER;
    }
  }
  else  
  {
      Add_HP = REVIVE_REWARD;
      _MSSORR_iType = REASON_HELP_REVIVE;
  }

  _MSSORR_iClient = client;
  _MSSORR_iReason = REASON_HELP_HEAL; 
  _MSSORR_iTarget = target;
  _MSSORR_bRealhp = true;
  _MSSORR_bRefThirdStrike = false;
  _MSSORR_bLimit = true;
  _MSSORR_bMsg = true;
  _MSSORR_fTargethp = float(HP + Add_HP);

  if(Call_MSS_OnReceivingRewards(_MSSORR_iClient, _MSSORR_bRealhp, _MSSORR_fTargethp, 
    _MSSORR_iType, _MSSORR_iReason, _MSSORR_bRefThirdStrike, _MSSORR_bLimit,
    _MSSORR_bMsg, _MSSORR_iTarget) 
      == Plugin_Handled)
    return Plugin_Continue;


  if(_MSSORR_bMsg) 
    PrintToChatAll("\x05%N \x03救起了 \x05%N\x03，获得了\x05%d\x03生命值奖励",
      client, target, RoundToFloor(_MSSORR_fTargethp) - HP);

  if(Add_HP == REVIVE_REWARD)
  {
    if(!IsFakeClient(client) )
    {
      if(PT_Add(client, REVIVE_REWARD_PT) != -1 )
        CPrintToChat(client, "\x03\x01获得了{blue} %d pt\x01", REVIVE_REWARD_PT);
      else  CPrintToChat(client, "{blue}你的点数设置未成功：Cookie未加载？");
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
  //SubShop_FindFirstValidItem();
  fuc_Precache();  
}

public OnMapEnd()
{
  ResetClientCount_LDW();
  ResetClientShopItemInventory();
  g_iTankAliveTime = 0;
  g_iTankPTChanged = 0;
  On = false;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
  CreateTimer(0.5, tDelaySwitchteam, -1);

  if(On)
  {
    return Plugin_Continue;
  }
  On = true;

  return Plugin_Continue;
}

public Action Event_PluginReset(Event event, const char[] name, bool dontBroadcast)
{

  if(g_iTank_player != -1)
  {
    SDKHooks_TakeDamage(g_iTank_player, 0, 0, 100000.0, DMG_FALL);
  }

  if(!On)
  {
    return Plugin_Continue;
  }
  On = false;

  return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//      击杀特殊感染者的奖励
//---------------------------------------------------------------------------||
public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
  int tank_player = GetClientOfUserId(GetEventInt(event, "userid") );

  if(tank_player == g_iTank_player)
  {

    CreateTimer(0.1, tDelaySwitchteam, tank_player);
    g_iTank_player = -1;

    int killer  = GetClientOfUserId(GetEventInt(event, "attacker"));
    if(killer <= 0 || killer > MaxClients || !IsClientInGame(killer) || GetClientTeam(killer) != 2 )
      return Plugin_Continue;

    CPrintToChatAll("\x03一只由玩家控制的Tank已经死亡，所有幸存者获得了{blue} %d pt的奖励.", TANK_REWARD*2);

    int value = TANK_REWARD * 2;

    for(int i=1; i<=MaxClients; i++)
    {
      if(!IsClientInGame(i) )
        continue;

      if(GetClientTeam(i) != 2)
        continue;

      PT_Add(i, value);
    }

    g_iTankPTChanged = g_iTankPTChanged + value;

    return Plugin_Continue;
  }

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
      case  2:{
          Format(sTarget, sizeof(sTarget), "Boomer");
          Add_Health = BOOMER_REWARD;
      }
      case  4:{
          Format(sTarget, sizeof(sTarget), "Spitter");
          Add_Health = SPITTER_REWARD;
      }
      case  1:{
          Format(sTarget, sizeof(sTarget), "Smoker");
          Add_Health = SMOKER_REWARD;
      }
      case  5:{
          Format(sTarget, sizeof(sTarget), "Jockey");
          Add_Health = JOCKEY_REWARD;
      }
      case  3:{  
          Format(sTarget, sizeof(sTarget), "Hunter");
          Add_Health = HUNTER_REWARD;
      }

      case  6:{ 
          Format(sTarget, sizeof(sTarget), "Charger");
          Add_Health = CHARGER_REWARD;
      }
    }

    if(!sTarget[0])
      return Plugin_Continue;

    float HP = float(ML4D_GetPlayerTempHealth(client) ); 
    _MSSORR_iClient = client;
    _MSSORR_iType = REASON_TYPE_SI;
    _MSSORR_iReason = iClass; 
    _MSSORR_iTarget = target;
    _MSSORR_bRealhp = false;
    _MSSORR_bRefThirdStrike = false;
    _MSSORR_bLimit = true;
    _MSSORR_bMsg = true;
    _MSSORR_fTargethp = Add_Health + HP;

    if(Call_MSS_OnReceivingRewards(_MSSORR_iClient, _MSSORR_bRealhp, _MSSORR_fTargethp, 
      _MSSORR_iType, _MSSORR_iReason, _MSSORR_bRefThirdStrike, _MSSORR_bLimit,
      _MSSORR_bMsg, _MSSORR_iTarget) 
        == Plugin_Handled)
      return Plugin_Continue;

    if(_MSSORR_bMsg) 
      PrintToChat(client, "\x05杀死了\x03%s\x05, 获得了\x03%.f\x01临时生命值.", 
        sTarget,  _MSSORR_fTargethp - HP);

  }

  return Plugin_Continue;
}

Action tDelaySwitchteam(Handle Timer, any client)
{
  if(client == -1)
  {
    for(int i=1; i<=MaxClients; i++)
    {
      if(IsClientInGame(i) )
      {
        if(GetClientTeam(i) == 3)
        {
          // 此命令会在下一帧才传送机器人
          ExecuteRootCommand(i, "sm_muladdbot");
          CreateTimer(0.1, tDelayExecuteRootCommand, i);      
          return Plugin_Continue;
        }
      }
    }
    return Plugin_Continue;
  }

  if(IsClientInGame(client) )
  {
    if(GetClientTeam(client) == 3)
    {
      ExecuteRootCommand(client, "sm_muladdbot");
      CreateTimer(0.1, tDelayExecuteRootCommand, client);
    }
  }
  return Plugin_Continue;
}

Action  tDelayExecuteRootCommand(Handle Timer, any client)
{
  if(IsClientInGame(client) )
    if(GetClientTeam(client) == 3)
      ExecuteRootCommand(client, "sm_js");

  return Plugin_Continue;
}
//---------------------------------------------------------------------------||
//      pt系统
//---------------------------------------------------------------------------||
public void OnClientCookiesCached(int client)
{
  if(IsFakeClient(client) )
    return;

  int id = GetSteamAccountID(client);
  if(id != 0)
  {
    int idx = ShopItemInventory_GetClientIndexOfSteamID(id);
    if(idx == -1)
    {
      for(int i=0;i<SingleMapMaxPlayers;i++)
        if(g_iClientShopItemRemainingQuantity[i][SHOP_ITEM_NUM] == 0 || g_iClientShopItemRemainingQuantity[i][SHOP_ITEM_NUM] == -1)
        {
          g_iClientShopItemRemainingQuantity[i][SHOP_ITEM_NUM] = id;
          PrintToServer("\n%N#库存记录idx=%d",client, i);
          break;
        }
    }
    else  PrintToServer("\nERROR: OnClientCookiesCached(); %N# target idx == 0", client);
  }
  else  PrintToServer("\nERROR: OnClientCookiesCached(); %N# id == 0", client);

  g_bCookieCached[client] = true;

  char sPT[16];
  chPlayerPT = FindClientCookie("mpds_pt_re3");
  GetClientCookie(client, chPlayerPT, sPT, sizeof(sPT) );
  PrintToServer("商店：OnClientCookiesCached: %s", sPT);
  g_iPlayerPT[client] = StringToInt(sPT);
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
  
        static char sPt[16];
        PT_Get(i, sPt);
        PrintToServer("## %N 点数剩余：%s", i, sPt );
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
              PrintToServer("#%N: 目前拥有：%s | 设置点数变化： %d", target, PT_Get(target, _PTS),  pt );
              PT_Add(target, pt);
            }
          }
        }
        else  PrintToServer("使用方法： sm_buy userid 要增加的pt数量");
      }
      return Plugin_Continue;
    }
    if(!g_bCookieCached[client])
    {
      CPrintToChat(client, "{blue}[商店]\x01 相关数据正在加载，请稍后再试...");
      return Plugin_Continue;
    }  
    PT_Get(client, _PTS);
    CPrintToChat(client, "{blue}[商店]\x01 同时按下\x04E\x01+\x04R\x01可以快速打开此菜单", _PTS);
    CPrintToChat(client, "{blue}[商店]\x01 拥有的点数(pt)剩余 {blue}%s", _PTS);
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
    static char sPt[16];
    static int pt;

    PT_Get(client, sPt);
    pt = StringToInt(sPt);

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

void DisplayShopMenu(int client)
{
  Menu shop = CreateMenu(Menu_Shop);
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

void DisplayShopMenu_Sub(int client, int type)
{
  Menu shop_sub = CreateMenu(Menu_Shop_Sub);
  PT_Get(client, _PTS);
#if SHOP_STOCK_SHARE
  shop_sub.SetTitle("拥有[%spt] | 商店 - %s | 库存计算方式[%s]", _PTS, g_sShopType[type], g_sShopStockType[0]);
#else
  shop_sub.SetTitle("拥有[%spt] | 商店 - %s | 库存计算方式[%s]", _PTS, g_sShopType[type], g_sShopStockType[1]);
#endif
  for(int i=0; i< GetSubShopItemNum(type); i++)
  {
    static char buffer[32], title[64], sCount[8], sPrice[8];
    static int targetItemIndex, iCount, iPrice;

    targetItemIndex = g_iShopArrayIndexOffest[type] + i;
    SubShop_ItemDisplayName.GetString(targetItemIndex, buffer, sizeof(buffer) );

    iCount = GetClientShopItemInventory(client, targetItemIndex);
    IntToString(iCount, sCount, sizeof(sCount) );
    iPrice = Get_SubShopItemWeaponPrice(targetItemIndex, client);
    SubShop_ItemPrice.GetString(targetItemIndex, sPrice, sizeof(sPrice) );    
    
    if(iCount == -2)
      Format(sCount, sizeof(sCount), "无限");

    if(strncmp(sPrice, "l", 1, false) == 0)
        Format(sPrice, sizeof(sPrice), "锁定");
    else if(iPrice == 0)
      Format(sPrice, sizeof(sPrice), "免费");
    else
    {
      if(IsRealismMode)
        Format(sPrice, sizeof(sPrice), "%dpt", RoundToNearest(iPrice * REALISM_MODE_SPENT_MULT) );
      else  Format(sPrice, sizeof(sPrice), "%dpt", iPrice );
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
bool SetItems(int client, const char[] weapon, int ShopItemIndex=-1, int RandomPrice = -1)
{
  bool value;

  if(strncmp(weapon, "other_spawntk", 13, false) == 0)
  {
    if(SetItems_AllowSpawnTank(client) )
      return Sitems_SpawnPlayerTank(client, ShopItemIndex);
    else
    {
      PrintToChat(client, "\x04 不满足生成Tank的条件.");
      return false;
    }
  }

  if(strncmp(weapon, "other", 5, false) == 0)
    value = false;

  if(strncmp(weapon, "cmd", 3, false) == 0)
  {
    Sitems_Fireworks(client, weapon);
    return true;
  }

  char buffer[2][16];
  bool IsMelee;
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
  else  entity_weapon = CreateEntityByName(weapon);

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
    else  PT_Subtract(client, Get_SubShopItemWeaponPrice(ShopItemIndex, client) );
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
  // 不知道是否可能，以防万一
  if(!g_bCookieCached[client])
  {
    CPrintToChat(client, "{blue}[商店]\x01 Cookie尚未加载完成，请稍后再试...");
    return;  
  }

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

  static char sPt[16];
  PT_Get(client, sPt);
  int own_pt = StringToInt(sPt);
  int targetIteamIndex = g_iShopArrayIndexOffest[g_iClientViewShopType[client]] + SubShopItemIndex;
  int item_price = Get_SubShopItemWeaponPrice(targetIteamIndex, client);
  static char sPrice[16];
  SubShop_ItemPrice.GetString(targetIteamIndex, sPrice, sizeof(sPrice) );

  if(strncmp(sPrice, "l", 1, false) == 0 )
  {
    CPrintToChat(client, "{blue}[商店]\x01 不可购买的物品！", own_pt);
    return;
  }
#if DEBUG
  PrintToChatAll("需要的点数:%d", item_price);
#endif
  if(GetClientShopItemInventory(client, targetIteamIndex) == 0 )
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

    while(Get_SubShopItemWeaponPrice(targetIteamIndex, client) == -1)
      targetIteamIndex = GetRandomInt(MinItemIndex, MaxItemIndex);

    SubShop_ItemName.GetString(targetIteamIndex, sWeapon, sizeof(sWeapon) );
#if DEBUG
    PrintToChatAll("targetIteamIndex:%d 选定的物品: %s", targetIteamIndex, sWeapon);
#endif
  }
  else  SubShop_ItemName.GetString(targetIteamIndex, sWeapon, sizeof(sWeapon) );

  if(IsRealismMode)  item_price =  RoundToNearest(item_price * REALISM_MODE_SPENT_MULT);

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
      PT_Get(client, _PTS);
      CPrintToChat(client, "{blue}[商店]\x01 购买了 %s，剩余点数:{blue} %s ", sWeapon_RandomName, _PTS );  
    }
    else
    {
      PT_Get(client, _PTS);
      CPrintToChat(client, "{blue}[商店]\x01 购买了 %s，剩余点数:{blue} %s ", sWeapon_DisplayName, _PTS );
    }

    if(IsRealismMode)  CPrintToChat(client, "{blue} \x01写实模式的点数花费：\x05%.2fx", REALISM_MODE_SPENT_MULT);

    int count = GetClientShopItemInventory(client, targetIteamIndex);
    if(count != -2)      
      SetClientShopItemInventory(client, targetIteamIndex, count - 1 );
  }
  else  CPrintToChat(client, "{blue}[商店]\x01 设置物品失败，所有花费已返还.");
}


//---------------------------------------------------------------------------||
//      周期性检查Tank是否存活
//---------------------------------------------------------------------------||
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

  if(g_bTankFind[tank])  g_bTankFind[tank] = false;

  if(!IsValidHandle(g_hTankAliveTimer) )
    g_hTankAliveTimer = CreateTimer(TANK_ALIVE_TIMER_INTERVAL, tTankAlive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Event_Tank_Killed(Event event, const char[] name, bool dontBroadcast)
{
  // 创建sm_ji命令的插件似乎会杀死tank然后重新生成
  if(g_bSpawnPlayerTank)
  {
    g_bSpawnPlayerTank = false;
    return;
  }

#if Tank_SpecialKilled
  int killer = GetClientOfUserId(event.GetInt("attacker") );
  bool solo = event.GetBool("solo");
  bool melee = event.GetBool("melee_only");
#endif

#if DEBUG
  PrintToChatAll("Event_Tank_Killed: %N#%d", killer, killer);
#endif

#if Tank_SpecialKilled
  if(solo && melee && IsClientInGame(killer) )
  {
    ServerCommand("[%s]: %N Event_Tank_Killed: solo AND melee", PLUGIN_NAME, killer);
    PT_Add(killer, TANK_SOLO_MELEE_REWARD);
    CPrintToChatAll("\x03%N\x01仅使用近战武器杀死了一只Tank, 且没有其他人的伤害贡献！");
    CPrintToChatAll("\x03%N\x01 获得了{blue} %d pt\x01的奖励！", TANK_SOLO_MELEE_REWARD);
    return;
  }
#endif

  CPrintToChatAll("\x03一只Tank已经死亡，所有幸存者获得了{blue} %d pt的奖励.", TANK_REWARD);

  int value = TANK_REWARD;

#if Tank_SpecialKilled
  if(melee)
  {
    CPrintToChatAll("\x03所有幸存者因Tank仅受到了近战伤害而得到的额外奖励: {blue} %d pt", TANK_ONLY_MELEE_REWARD);
    value = value + TANK_ONLY_MELEE_REWARD;
  }
#endif

  for(int i=1; i<=MaxClients; i++)
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

  for(int i=1; i<=MaxClients; i++)
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
        else  g_bTankFind[i] = false;
      }
    }
  }

  if(alive)
  {
    if(find)
    {
      g_iTankAliveTime++;

      if( !(TANK_ALIVE_TIMER_COUNT < g_iTankAliveTime) )
        return Plugin_Continue;

      int value = TANK_ALIVE_DEDUCT_PT;

      for(int i=1; i<=MaxClients; i++)
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
//      打开商店的快捷键
//---------------------------------------------------------------------------||
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
  if(IsFakeClient(client) )
    return Plugin_Continue;

  if(!g_bPlayerOpenShopCooldown[client])
  {
    if(buttons & IN_USE && buttons & IN_RELOAD)
    {
      FakeClientCommand(client, "sm_buy");
      g_bPlayerOpenShopCooldown[client] = true;
      CreateTimer(OPENSHOPLOCKTIME,  tOpenShopLockTime, client);
    }
  }

  return Plugin_Continue;
}

Action tOpenShopLockTime(Handle Timer, any client)
{
  g_bPlayerOpenShopCooldown[client] = false;  
  return Plugin_Continue;
}

//public Action MSS_OnReceivingRewardsint client, bool &bRealhp, float &targethp,
//int &type, int &reason, bool &bRefThirdStrike=false, bool &bLimit=true)
//{
//  return Plugin_Continue;
//}
