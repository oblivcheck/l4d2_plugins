#include <mpds_shop>

int Native_MPDS_Shop_PT_Change(Handle plugin, int numParams)
{
  int client = GetNativeCell(1);
  char sPt[16];
  GetNativeString(2, sPt, sizeof(sPt) );

#if DEBUG
  PrintToServer("%s: 设置[%N]点数变化\"%s\"", PLUGIN_NAME, client, sPt);
#endif

  if(strncmp(sPt, "+", 1, false) == 0)
    ReplaceString(sPt, sizeof(sPt), "+", "", false);
  if(strncmp(sPt, "-", 1, false) != 0)
    return 0;  

#if DEBUG
  PrintToServer("%s: DBUG=\"%s\"", PLUGIN_NAME, sPt);  
#endif

  PT_Add(client, StringToInt(sPt) );
  return 1;
}

int Native_MPDS_Shop_PT_Get(Handle plugin, int numParams)
{
  char sPt[16];
  int Cached = PT_Get(GetNativeCell(1), sPt );
  SetNativeString(2, sPt, GetNativeCell(3) );
  return Cached;
}


//Handle g_hForward_MSS_OnPointsChange;
Handle g_hForward_MSS_OnReceivingRewards;

int _MSSORR_iClient;
int _MSSORR_iType;
int _MSSORR_iReason;
int _MSSORR_iTarget;
bool  _MSSORR_bRealhp;
bool  _MSSORR_bRefThirdStrike;
bool  _MSSORR_bLimit;
bool  _MSSORR_bMsg;
float _MSSORR_fTargethp;

Action Call_MSS_OnReceivingRewards(int client, bool bRealhp, float targethp, 
  int type, int reason, bool bRefThirdStrike, bool bLimit, bool bMsg, int target)
{
  Action aResult = Plugin_Continue;
  Call_StartForward(g_hForward_MSS_OnReceivingRewards); 
  Call_PushCell(client);
  Call_PushCellRef(bRealhp);
  Call_PushCellRef(targethp);
  Call_PushCellRef(type);
  Call_PushCellRef(reason);
  Call_PushCellRef(bRefThirdStrike);
  Call_PushCellRef(bLimit);
  Call_PushCellRef(bMsg);
  Call_PushCell(target);
  Call_Finish(aResult);

  ChangeClientHealth(client, bRealhp, targethp, bRefThirdStrike, bLimit);

  return aResult;
}

void CreatePluginCall()
{
  CreateNative("MPDS_Shop_PT_Change", Native_MPDS_Shop_PT_Change);
  CreateNative("MPDS_Shop_PT_Get", Native_MPDS_Shop_PT_Get);
//  g_hForward_MSS_OnPointsChange = CreateGlobalForward("MSS_OnPointsChange", ET_Event, CellByRef);
  g_hForward_MSS_OnReceivingRewards = CreateGlobalForward("MSS_OnReceivingRewards", 
    ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef, 
    Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef,
    Param_Cell);
}
