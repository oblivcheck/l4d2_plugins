#include "mpds_shop.inc"

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

void CreatePluginNative()
{
  CreateNative("MPDS_Shop_PT_Change", Native_MPDS_Shop_PT_Change);
  CreateNative("MPDS_Shop_PT_Get", Native_MPDS_Shop_PT_Get);
}
