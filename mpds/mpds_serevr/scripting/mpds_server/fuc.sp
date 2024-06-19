//---------------------------------------------------------------------------||
//        VScript
//---------------------------------------------------------------------------||
void LoadVScript()
{
  PrintToServer("\n正在加载 MDPS VScript\n");

  int flag = GetCommandFlags("script_execute");

  if(flag != INVALID_FCVAR_FLAGS)
  {
    if(flag & FCVAR_CHEAT)
    {
      SetCommandFlags("script_execute", flag & ~FCVAR_CHEAT);
      PrintToServer("正在执行 MPDS VScript\n");

      ServerCommand("script_execute rpp/manacat_tank");

      ServerExecute();
      RequestFrame(rWaitFrame, flag);
    }
  }
}

void rWaitFrame(int flag)
{
  SetCommandFlags("script_execute", flag | FCVAR_CHEAT);
}

//---------------------------------------------------------------------------||
//        生成电锯
//---------------------------------------------------------------------------||
#define	CS_MDL		"models/weapons/melee/w_chainsaw.mdl"
#define CS_NAME		"weapon_chainsaw"
void _CCSP_HookEvent()
{
	HookEvent( "round_start", Event_RoundStart);
}

void _CCSP_OnMapStart()
{
	PrecacheModel(CS_MDL, true);
	CreateTimer(10.0, tDelaySpawn, 1, TIMER_FLAG_NO_MAPCHANGE);
}

void _CCSP_RoundStart()
{
  StartSpawn();
  CreateTimer(10.0, tDelaySpawn, 1, TIMER_FLAG_NO_MAPCHANGE);
}

void StartSpawn()
{
  CreateTimer(2.0, tDelaySpawn, 0, TIMER_FLAG_NO_MAPCHANGE);
}

Action tDelaySpawn(Handle Timer, any type)
{	
	FindSpawnPos(type);
	return Plugin_Continue;
}

void FindSpawnPos(int type)
{
  for(int client=1; client<=MaxClients; client++)
  {
    if(!IsClientInGame(client) )
    continue;
    if(GetClientTeam(client) == 2 )
    {
      float pos[3]
      GetClientAbsOrigin(client, pos);
      int count = GetPlayerNum();
      if(type == 1)			
      {
        count = 16
        if(count > 4)
        {
          for(int p=0;p<(count-4);p++)
            SpawnFAK(pos);
        }
      }
      else
      {
        if(count < 5)
        {
        	SpawnCS(pos);
        }
        else if (count < 9)
        {
        	SpawnCS(pos);
        	SpawnCS(pos);
        }
        else
        {
        	SpawnCS(pos);
        	SpawnCS(pos);
        	SpawnCS(pos);
        }
      }
      break;
    }
  }
}

stock void SpawnCS(float vOrigin[3])
{
	int entity_weapon = -1;
	entity_weapon = CreateEntityByName(CS_NAME);
	if( entity_weapon == -1 )
    ThrowError("无法创建实体：weapon_chainsaw");

	DispatchKeyValue(entity_weapon, "solid", "6");
	DispatchKeyValue(entity_weapon, "model", CS_MDL);
	DispatchKeyValue(entity_weapon, "rendermode", "3");
	DispatchKeyValue(entity_weapon, "disableshadows", "1");

	float vPos[3];
	vPos = vOrigin;
	vPos[2] += 3.0;

	TeleportEntity(entity_weapon, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity_weapon);

	// Valve Cvar:ammo_chainsaw_max .def 20
	SetEntProp(entity_weapon, Prop_Send, "m_iExtraPrimaryAmmo", 120, 4);	
}

void SpawnFAK(float vOrigin[3])
{
  int entity_weapon = -1;
  entity_weapon = CreateEntityByName("weapon_first_aid_kit");

  if( entity_weapon == -1 )
    ThrowError("无法创建实体：first_aid_kit");

  float vPos[3];
  vPos = vOrigin;
  vPos[2] += 3.0;

  TeleportEntity(entity_weapon, vPos, NULL_VECTOR, NULL_VECTOR);
  DispatchSpawn(entity_weapon);
}

stock int GetPlayerNum()
{
  int count;
  for(int i =1; i<=MaxClients; i++)
  {
    //https://forums.alliedmods.net/archive/index.php/t-132438.html
    if(IsClientConnected(i) )
    {
    if(!IsFakeClient(i) )
      count++;
    }
  }
  return count;
}

//---------------------------------------------------------------------------||
//        修复倒地起身时有时错误的摄像机角度
//---------------------------------------------------------------------------||
void _AngFix_OnPluginStart()
{
  HookEvent("revive_success", Event_Revive_Success, EventHookMode_Post);
}

void _AngFix_Event_Revive_Success(int target)
{
  if(!IsFakeClient(target) )
  {
    float fAngles[3];
    GetClientEyeAngles(target, fAngles);
    if(fAngles[2] != 0.0)
    {
      PrintToServer("似乎发生倾斜错误，尝试修正 %N %f,%f,%f", target, fAngles[0], fAngles[1], fAngles[2]);
      fAngles[2] = 0.0;
      TeleportEntity(target, NULL_VECTOR, fAngles, NULL_VECTOR);
    }
    RequestFrame(rPostCheck, target);
  }
}

void rPostCheck(any target)
{
  if(IsValidClient(target) )
  {
    PrintToServer("延后帧检查 %N ", target);
    if(GetClientTeam(target) == 2)
    {
      PrintToServer("POSTCHECK Team %N ", target);
      float fAngles[3];
      GetClientEyeAngles(target, fAngles);
      if(fAngles[2] != 0.0)
      {
        fAngles[2] = 0.0;
        TeleportEntity(target, NULL_VECTOR, fAngles, NULL_VECTOR);
        PrintToServer("POSTCHECK 重置Angles %N | %f,%f,%f", target, fAngles[0], fAngles[1], fAngles[2]);
      }
    }
  }
}
