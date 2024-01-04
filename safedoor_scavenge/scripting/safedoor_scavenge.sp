#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_NAME             "Safe Door Scavenge"
#define PLUGIN_DESCRIPTION      "不想让多人服务器变成跑图比赛"
#define PLUGIN_VERSION          "1.1 (fork by version 1.0.5)"
#define PLUGIN_AUTHOR           "sorallll, oblivcheck/Iciaria"
#define PLUGIN_URL              "https://github.com/oblivcheck/l4d2_plugins/tree/master/safedoor_scavenge"

public Plugin myinfo = 
{
	name =		PLUGIN_NAME,
	author =	PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =	PLUGIN_VERSION,
	url =		PLUGIN_URL
}


#define		SDS_Music		"music/scavenge/level_09_01.wav"
#define		SDS_Hint		"ui/gascan_spawn.wav"
#define		SDS_Music_F		"music/scavenge/gascanofvictory.wav"
//#define		SDS_Music_FF		"music/wam_music.mp3"
#define		SDS_Music_FF		"music/zombat/not_a_laughing_matter.wav"

#define 	MODEL_SHIELD "models/props_unique/airport/atlas_break_ball.mdl"

#define 	ReactionTime	8.0

#define		USERANGE		128.0

// https://developer.valvesoftware.com/wiki/List_of_L4D_Series_Nav_Mesh_Attributes:zh-cn
#define NAV_MESH_MOSTLY_FLAT	536870912
#define TERROR_NAV_CHECKPOINT	2048
#define GAMEDATA		"safedoor_scavenge"

Handle
	g_hPanicTimer,
	g_hSDKIsCheckpointDoor,
	g_hSDKIsCheckpointExitDoor,
	g_hSDKNextBotCreatePlayerBot,
	g_hSDKSurvivorBotIsReachable,
	g_hSpawnGascanTimer;

DynamicHook
	g_dDynamicHook;

Address
	g_pTheNavAreas;

ArrayList
	g_aLastDoor,
	g_aSpawnArea,
	g_aScavengeItem;

ConVar
	g_hGascanUseRange,
	g_hNumCansNeeded,
	g_hMinTravelDistance,
	g_hMaxTravelDistance,
	g_hCansNeededPerPlayer,
	g_hAllowMultipleFill,
	g_hScavengePanicTime,
	g_hMin,
	g_hMax,
	g_hNext_MinTravelDistance,	
	g_hNext_MaxTravelDistance,
	g_hNext_NumCansNeeded,
	g_hNext_CansNeededPerPlayer,
	g_hNextSpwanDelay;

int
	g_iTheCount,
	g_iRoundStart, 
	g_iPlayerSpawn,
	g_iSpawnAttributesOffset,
	g_iFlowDistanceOffset,
	g_iNumCansNeeded,
	g_iNumGascans,
	g_iTargetDoor,
	g_iGameDisplay,
	g_iFuncNavBlocker,
	g_iPourGasAmount,
	g_iPropUseTarget[MAXPLAYERS + 1],
	g_iNext_SpawnArea_ArrayIndex,
	g_iGameFrame_SpawnCount,
	g_iSkip,
	g_iNext_NumGascans,
	g_iMin,
	g_iMax,
	g_iNext_NumCansNeeded;

int	g_iSpawnGroupCount = 1;
int	g_iShield[MAXPLAYERS+1];
int	g_iTankid[MAXPLAYERS+1];

float
	g_fGascanUseRange,
	g_fMinTravelDistance,
	g_fMaxTravelDistance,
	g_fCansNeededPerPlayer,
	g_fScavengePanicTime,
	g_fBlockGascanTime[MAXPLAYERS + 1],
	g_fNext_MinTravelDistance,
	g_fNext_MaxTravelDistance,
	g_fNextSpwanDelay,
	g_fNext_CansNeededPerPlayer;

bool
	g_bInTime,
	g_bFirstRound,
	g_bSpawnGascan,
	g_bBlockOpenDoor,
	g_bAllowMultipleFill,
	g_bStartSpawnGascans,
	g_bIsNextSpawnReq,
	g_bAllowSpawnTank;

methodmap CNavArea
{
	public bool IsNull()
	{
		return view_as<Address>(this) == Address_Null;
	}

	public void Mins(float result[3])
	{
		result[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(4), NumberType_Int32));
		result[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(8), NumberType_Int32));
		result[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(12), NumberType_Int32));
	}

	public void Maxs(float result[3])
	{
		result[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(16), NumberType_Int32));
		result[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(20), NumberType_Int32));
		result[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(24), NumberType_Int32));
	}

	public void Center(float result[3])
	{
		float vMins[3];
		float vMaxs[3];
		this.Mins(vMins);
		this.Maxs(vMaxs);

		AddVectors(vMins, vMaxs, result);
		ScaleVector(result, 0.5);
	}

	public void FindRandomSpot(float result[3])
	{
		L4D_FindRandomSpot(view_as<int>(this), result);

		/*float vMins[3];
		float vMaxs[3];
		this.Mins(vMins);
		this.Maxs(vMaxs);

		result[0] = GetRandomFloat(vMins[0], vMaxs[0]);
		result[1] = GetRandomFloat(vMins[1], vMaxs[1]);
		result[2] = GetRandomFloat(vMins[2], vMaxs[2]);*/
	}

	property int BaseAttributes
	{
		public get()
		{
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(84), NumberType_Int32);
		}
	}

	property int SpawnAttributes
	{
		public get()
		{
			return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iSpawnAttributesOffset), NumberType_Int32);
		}
		/*
		public set(int value)
		{
			StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iSpawnAttributesOffset), value, NumberType_Int32);
		}*/
	}

	property float Flow
	{
		public get()
		{
			return view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iFlowDistanceOffset), NumberType_Int32));
		}
	}
};

public void OnPluginStart()
{
	vLoadGameData();
	LoadTranslations("safedoor_scavenge.phrases");

	g_aLastDoor = new ArrayList();
	g_aSpawnArea = new ArrayList();
	g_aScavengeItem = new ArrayList();

	g_hGascanUseRange = FindConVar("gascan_use_range");

	g_hNumCansNeeded = CreateConVar("safedoor_scavenge_needed", "8", "How many barrels of oil need to be added to unlock the safe room door by default", _, true, 0.0);
	g_hMinTravelDistance = CreateConVar("safedoor_scavenge_min_dist", "1000.0", "The minimum distance between the brushed oil drum and the land mark", _, true, 0.0);
	g_hMaxTravelDistance = CreateConVar("safedoor_scavenge_max_dist", "5000.0", "The maximum distance between the brushed oil drum and the land mark", _, true, 0.0);
	g_hCansNeededPerPlayer = CreateConVar("safedoor_scavenge_per_player", "1.0", "How many barrels of oil does each player need to unlock the safe room door (the value greater than 0 will override the value of safedoor_scavenge_needed. 0=use the default setting)", _, true, 0.0);
	g_hAllowMultipleFill = CreateConVar("safedoor_scavenge_multiple_fill", "0", "Allow multiple gascans to be filled at the same time?");
	g_hScavengePanicTime = CreateConVar("safedoor_scavenge_panic_time", "10.0", "How long is the panic event interval after the scavenge starts?(0.0=off)", _, true, 0.0);
	g_hMin = CreateConVar("safedoor_scavenge_Min", "0.5", "Next Spawn, The minimum time to wait for the oil barrel to be generated\nSeconds.");
	g_hMax = CreateConVar("safedoor_scavenge_Max", "5.0", "Next Spawn, The maximum time to wait for the oil barrel to be generated\nSeconds.");
	g_hNext_MinTravelDistance = CreateConVar("safedoor_scavenge_next_min_dist", "3000.0", "Next Spawn\nThe minimum distance between the brushed oil drum and the land mark.");	
	g_hNext_MaxTravelDistance = CreateConVar("safedoor_scavenge_next_max_dist", "5000.0", "Next Spawn\nThe maximum distance between the brushed oil drum and the land mark.");
	g_hNext_NumCansNeeded = CreateConVar("safedoor_scavenge_next_needed", "2", "Next Spawn\nHow many barrels of oil need to be added to unlock the safe room door by default");
	g_hNext_CansNeededPerPlayer= CreateConVar("safedoor_scavenge_next_per_player", "0.25", "Next Spawn\nHow many barrels of oil does each player need to unlock the safe room door (the value greater than 0 will override the value of safedoor_scavenge_next_needed.");
	g_hNextSpwanDelay = CreateConVar("safedoor_scavenge_spawn_delay", "80.0", "Next Spawn Delay\nSeconds.");

	g_hGascanUseRange.AddChangeHook(vConVarChanged);
	g_hNumCansNeeded.AddChangeHook(vConVarChanged);
	g_hMinTravelDistance.AddChangeHook(vConVarChanged);
	g_hMaxTravelDistance.AddChangeHook(vConVarChanged);
	g_hCansNeededPerPlayer.AddChangeHook(vConVarChanged);
	g_hAllowMultipleFill.AddChangeHook(vConVarChanged);
	g_hScavengePanicTime.AddChangeHook(vConVarChanged);
	g_hMin.AddChangeHook(vConVarChanged);
	g_hMax.AddChangeHook(vConVarChanged);
	g_hNext_MinTravelDistance.AddChangeHook(vConVarChanged);
	g_hNext_MaxTravelDistance.AddChangeHook(vConVarChanged);
	g_hNext_NumCansNeeded.AddChangeHook(vConVarChanged);
	g_hNext_CansNeededPerPlayer.AddChangeHook(vConVarChanged);
	g_hNextSpwanDelay.AddChangeHook(vConVarChanged);

	AutoExecConfig(true, "safedoor_scavenge");

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("weapon_drop", Event_WeaponDrop);

	RegAdminCmd("sm_sd", cmdSd, ADMFLAG_ROOT, "Test");

}

Action cmdSd(int client, int args)
{
//	vSetNeededDisplay(4);
//	return Plugin_Handled;

	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;

	float vPos[3];
	GetClientAbsOrigin(client, vPos);
	int area = L4D_GetNearestNavArea(vPos);
	if(area)
		ReplyToCommand(client, "BaseAttributes->%d SpawnAttributes->%d SpawnArea Count->%d", view_as<CNavArea>(area).BaseAttributes, view_as<CNavArea>(area).SpawnAttributes, g_aSpawnArea.Length);

	/*Event event = CreateEvent("gascan_pour_blocked", true);
	event.SetInt("userid", GetClientUserId(client));
	event.FireToClient(client);*/

	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	vGetCvars();
}

void vConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	vGetCvars();
}

void vGetCvars()
{
	g_fGascanUseRange = g_hGascanUseRange.FloatValue + USERANGE;
	g_iNumCansNeeded = g_hNumCansNeeded.IntValue;
	g_fMinTravelDistance = g_hMinTravelDistance.FloatValue;
	g_fMaxTravelDistance = g_hMaxTravelDistance.FloatValue;
	g_fCansNeededPerPlayer = g_hCansNeededPerPlayer.FloatValue;
	g_bAllowMultipleFill = g_hAllowMultipleFill.BoolValue;
	g_fScavengePanicTime = g_hScavengePanicTime.FloatValue;
	g_fNext_MinTravelDistance = g_hNext_MinTravelDistance.FloatValue;
	g_fNext_MaxTravelDistance = g_hNext_MaxTravelDistance.FloatValue;
	g_iNext_NumCansNeeded = g_hNext_NumCansNeeded.IntValue;
	g_fNext_CansNeededPerPlayer = g_hNext_CansNeededPerPlayer.FloatValue;
	g_fNextSpwanDelay = g_hNextSpwanDelay.FloatValue;

	g_iMin = RoundToFloor(GetConVarInt(FindConVar("sv_minupdaterate") ) * g_hMin.FloatValue);
	g_iMax = RoundToFloor(GetConVarInt(FindConVar("sv_minupdaterate") ) * g_hMax.FloatValue);
}

public void OnMapStart()
{
	g_bFirstRound = true;

	vLateLoadGameData();
	PrecacheModel("models/props_junk/gascan001a.mdl", true);

	PrefetchSound(SDS_Music);
	PrecacheSound(SDS_Music);

	PrefetchSound(SDS_Hint);
	PrecacheSound(SDS_Hint);

	PrefetchSound(SDS_Music_F);
	PrecacheSound(SDS_Music_F);

	PrefetchSound(SDS_Music_FF);
	PrecacheSound(SDS_Music_FF);

	PrecacheModel(MODEL_SHIELD, true);
}

public void OnMapEnd()
{
	vResetPlugin();
	g_aSpawnArea.Clear();
}

void vResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_iPourGasAmount = 0;

	g_bSpawnGascan = false;
	g_bBlockOpenDoor = false;

	g_aLastDoor.Clear();
	g_aScavengeItem.Clear();

	delete g_hPanicTimer;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(bIsValidEntRef(g_iPropUseTarget[i]))
			RemoveEntity(g_iPropUseTarget[i]);

		g_iPropUseTarget[i] = 0;

		g_fBlockGascanTime[i] = 0.0;
	}

	if(IsValidHandle(g_hSpawnGascanTimer) )
		delete g_hSpawnGascanTimer;

	g_iSpawnGroupCount = 1;
	g_iGameFrame_SpawnCount = 0;
	g_bStartSpawnGascans = false;
	g_bIsNextSpawnReq = false;
	g_iSkip = 0;

	for(int i=0;i<MaxClients;i++)
	{
		g_iTankid[i] = 0;
		g_iShield[i] = 0;
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bFirstRound = false;
	g_bAllowSpawnTank = false;

	int iLength = g_aScavengeItem.Length;
	if(iLength > 0)
	{
		int iEntRef;
		for(int i; i < iLength; i++)
		{
			if(bIsValidEntRef((iEntRef = g_aScavengeItem.Get(i))))
				RemoveEntity(iEntRef);
		}
	}

	if(bIsValidEntRef(g_iGameDisplay))
		AcceptEntityInput(g_iGameDisplay, "TurnOff");

	vResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hPanicTimer;

	if(g_iRoundStart == 0 && g_iPlayerSpawn == 1)
		CreateTimer(1.0, tInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iRoundStart == 1 && g_iPlayerSpawn == 0)
		CreateTimer(1.0, tInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!bIsValidEntRef(g_iPropUseTarget[client]))
		return;

	int propid = event.GetInt("propid");
	if(propid <= MaxClients || !IsValidEntity(propid))
		return;

	char classname[14];
	GetEntityClassname(propid, classname, sizeof(classname));
	if(strcmp(classname[7], "gascan") == 0)
	{
		int entity = g_iPropUseTarget[client];
		g_iPropUseTarget[client] = 0;

		RemoveEntity(entity);
	}
}

Action tInitPlugin(Handle Timer)
{
	vFindSafeRoomDoors();

	if(g_bFirstRound)
		RequestFrame(OnNextFrame_FindTerrorNavAreas);

	return Plugin_Continue;
}

void OnNextFrame_FindTerrorNavAreas()
{
	vFindTerrorNavAreas();
}


void vFindSafeRoomDoors()
{
	int entity = INVALID_ENT_REFERENCE;
	if((entity = FindEntityByClassname(MaxClients + 1, "info_changelevel")) == INVALID_ENT_REFERENCE)
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");
	
	if(entity != INVALID_ENT_REFERENCE)
	{
		int iChangeLevel = entity;
	
		int iFlags;
		entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
		{
			iFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
			if(iFlags & 8192 == 0 || iFlags & 32768 != 0)
				continue;

			if(!SDKCall(g_hSDKIsCheckpointDoor, entity))
				continue;
			
			if(!SDKCall(g_hSDKIsCheckpointExitDoor, entity))
			{
				g_aLastDoor.Push(EntIndexToEntRef(entity));

				AcceptEntityInput(entity, "Close");
				AcceptEntityInput(entity, "forceclosed");
				HookSingleEntityOutput(entity, "OnOpen", vOnOpen);
			}
		}

		if(g_aLastDoor.Length)
		{
			g_bBlockOpenDoor = true;

			float vOrigin[3], vMins[3], vMaxs[3];
			GetEntPropVector(iChangeLevel, Prop_Send, "m_vecOrigin", vOrigin);
			GetEntPropVector(iChangeLevel, Prop_Send, "m_vecMins", vMins);
			GetEntPropVector(iChangeLevel, Prop_Send, "m_vecMaxs", vMaxs);

			vMins[0] -= 33.0;
			vMins[1] -= 33.0;
			vMins[2] -= 33.0;
			vMaxs[0] += 33.0;
			vMaxs[1] += 33.0;
			vMaxs[2] += 33.0;

			DataPack dPack = new DataPack();
			dPack.WriteFloatArray(vOrigin, 3);
			dPack.WriteFloatArray(vMins, 3);
			dPack.WriteFloatArray(vMaxs, 3);
			CreateTimer(0.1, tmrBlockNav, dPack, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

// [L4D2] Saferoom Lock: Scavenge (https://forums.alliedmods.net/showthread.php?t=333086)
void vOnOpen(const char[] output, int caller, int activator, float delay)
{
	if(!g_bSpawnGascan)
	{
		int iMaxSpawnArea = g_aSpawnArea.Length;
		if(!iMaxSpawnArea)
		{
			g_bBlockOpenDoor = false;
			vUnhookAllCheckpointDoor();

			if(bIsValidEntRef(g_iFuncNavBlocker))
				AcceptEntityInput(g_iFuncNavBlocker, "UnblockNav");
	
			return;
		}

		g_bSpawnGascan = true;

		g_iTargetDoor = EntIndexToEntRef(caller);

		SetEntProp(g_iTargetDoor, Prop_Send, "m_glowColorOverride", iGetColorInt(255, 0, 0));
		AcceptEntityInput(g_iTargetDoor, "StartGlowing");

		g_iNumGascans = g_fCansNeededPerPlayer != 0.0 ? RoundToCeil(float(iCountSurvivorTeam()) * g_fCansNeededPerPlayer) : g_iNumCansNeeded;

		// 显示需要的油桶数量
		vSetNeededDisplay(g_iNumGascans);
		
		SetRandomSeed(GetTime() );
		// 设置标记，在OnGaneFrame()处理
		g_bStartSpawnGascans = true;

		g_bAllowSpawnTank = true;

		EmitSoundToAll(SDS_Hint, SOUND_FROM_PLAYER);
		PrintToChatAll("\x04      ========Safe Door Scavenge=======");	
		PrintToChatAll("\x04[SDS]\x05  %.f\x01 %t", g_fNextSpwanDelay * 2.0, "First", g_iSpawnGroupCount + 1);
		PrintToChatAll("\x04[SDS]  一只Tank将很快生成...");
		PrintToChatAll("\x04      ---------------------------------");

		g_hSpawnGascanTimer = CreateTimer(g_fNextSpwanDelay * 2.0, tSpawnGascan);
		// 开启EMS HUD提示
		HudSet(5);
		UpdateHUD(5, "Tank 即将降临到 ???? 的身边");
		
		// 创建加油指导提示
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
			{
				Event event = CreateEvent("explain_scavenge_goal", true);
				event.SetInt("userid", GetClientUserId(i));
				event.SetInt("subject", caller);
				event.FireToClient(i);
			}
		}

		if(g_fScavengePanicTime)
		{
			// 生成Tank
			CreateTimer(GetRandomFloat(0.0, g_fNextSpwanDelay / 4.0), tSpawnTank, _, TIMER_FLAG_NO_MAPCHANGE);

			vExecuteCheatCommand("director_force_panic_event");

			delete g_hPanicTimer;
			//g_hPanicTimer = CreateTimer(g_fScavengePanicTime, tmrScavengePanic, _, TIMER_REPEAT);
			// 依据人数设置尸潮间隔
			g_hPanicTimer = CreateTimer(GetPanicTime(), tmrScavengePanic, _, TIMER_REPEAT);
		}
	}

	if(g_bBlockOpenDoor && !g_bInTime)
	{
		g_bInTime = true;
		RequestFrame(OnNextFrame_CloseDoor, EntIndexToEntRef(caller));
	}

	EmitSoundToAll(SDS_Music, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 6.0);
}

float GetPanicTime()
{
	int count = GetPlayerNum();
	if( count > 4)
	{
		return 60.0 - (float(count-4) * 4.0);
	}
	return 60.0;
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
	                        if(!IsFakeClient(i) )
        	                        count++;
                }
        }
        return count;
}

Action tSpawnTank(Handle Timer)
{
	if(g_bAllowSpawnTank)
	{
		PrintToServer("\n*测试 g_bAllowSpawnTank : %d \n", g_bAllowSpawnTank);

		if(GetAllPlayersInServer() >= MaxClients)
		{
			CreateTimer(2.0, tSpawnTank, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			return Plugin_Continue;
		}

		if(GetRandomFloat(0.00, 100.000) <= 66.000)
			SpawnTank(true, 0.0);
		else	SpawnTank(false, 0.0);
	}
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if(g_bStartSpawnGascans)
	{
		if((++g_iSkip) < GetRandomInt(g_iMin, g_iMax))
			return;
		g_iSkip = 0;

		float vOrigin[3];
		// 这里不考虑首次生成请求与下一次生成请求间隔极短的情况.
		g_iGameFrame_SpawnCount++;

		if(!g_bIsNextSpawnReq)
		{
			// 重置油桶生成计数并退出生成动作，下同
			if(g_iGameFrame_SpawnCount > g_iNumGascans)
			{
				g_iGameFrame_SpawnCount = 0;
				g_bStartSpawnGascans = false;
				return;
			}
			view_as<CNavArea>(g_aSpawnArea.Get(RoundToNearest(GetRandomFloat(float(0), float(g_iNext_SpawnArea_ArrayIndex - 1))))).FindRandomSpot(vOrigin);
		}
		else
		{
			if(g_iGameFrame_SpawnCount > g_iNext_NumGascans)
			{
				g_iGameFrame_SpawnCount = 0;
				g_bStartSpawnGascans = false;
				g_bIsNextSpawnReq = false;
				return;
			}

			int iMaxSpawnArea = g_aSpawnArea.Length;
			view_as<CNavArea>(g_aSpawnArea.Get(RoundToNearest(GetRandomFloat(float(g_iNext_SpawnArea_ArrayIndex - 1), float(iMaxSpawnArea - 1))))).FindRandomSpot(vOrigin);
			// 只发出一次提示
			if(g_iGameFrame_SpawnCount == 1)
			{
				EmitSoundToAll(SDS_Hint, SOUND_FROM_PLAYER);
				PrintToChatAll("\x04      --------------------");	
				PrintToChatAll("\x04[SDS]\x01  %t \x05%d\x01 %t \x05%.f\x01 %t",  "Next_1", g_iSpawnGroupCount + 1, "Next_2", g_fNextSpwanDelay, "Next_3", g_iSpawnGroupCount + 2);
		//		PrintToChatAll("\x04[SDS]    注意：", g_fNextSpwanDelay);	
		//		PrintToChatAll("\x04[SDS]\x01  一只\x05小Tank\x03可能\x01将在\x04%.f秒\x01内抵达...", g_fNextSpwanDelay);	
				PrintToChatAll("\x04      --------------------");
				g_iSpawnGroupCount++;
		//		if(GetRandomFloat(0.000, 1000.000) > 500.000)
		//		{
		//			CreateTimer(GetRandomFloat(g_fNextSpwanDelay / 2.0, g_fNextSpwanDelay), tSpawnTank_Next, _, TIMER_FLAG_NO_MAPCHANGE);
		//		}
			}
		}

		vSpawnScavengeItem(vOrigin);
	}
}

Action tSpawnTank_Next(Handle Timer)
{
	if(g_bAllowSpawnTank)
		SpawnTank(true, 0.0);

	return Plugin_Continue;
}

Action tSpawnGascan(Handle timer)
{
	g_iNext_NumGascans = g_fNext_CansNeededPerPlayer != 0.0 ? RoundToCeil(float(iCountSurvivorTeam()) * g_fNext_CansNeededPerPlayer) : g_iNext_NumCansNeeded;
	g_bStartSpawnGascans = true;
	g_bIsNextSpawnReq = true;
	g_hSpawnGascanTimer = CreateTimer(g_fNextSpwanDelay, tSpawnGascan_Next, _, TIMER_REPEAT);

	return Plugin_Continue;
}

Action tSpawnGascan_Next(Handle timer)
{
	g_iNext_NumGascans = g_fNext_CansNeededPerPlayer != 0.0 ? RoundToCeil(float(iCountSurvivorTeam()) * g_fNext_CansNeededPerPlayer) : g_iNext_NumCansNeeded;
	g_bStartSpawnGascans = true;
	g_bIsNextSpawnReq = true;
	return Plugin_Continue;
}

Action tmrScavengePanic(Handle timer)
{
	vExecuteCheatCommand("director_force_panic_event");
	return Plugin_Continue;
}


void OnNextFrame_CloseDoor(int entity)
{
	if((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
	{
		SetEntPropString(entity, Prop_Data, "m_SoundClose", "");
		SetEntPropString(entity, Prop_Data, "m_SoundOpen", "");
		AcceptEntityInput(entity, "Close");
		SetEntPropString(entity, Prop_Data, "m_SoundClose", "Doors.Checkpoint.FullClose1");
		SetEntPropString(entity, Prop_Data, "m_SoundOpen", "Doors.Checkpoint.FullOpen1");
	}
	g_bInTime = false;
}

Action tmrBlockNav(Handle timer, DataPack dPack)
{
	dPack.Reset();
	float vMins[3], vMaxs[3], vOrigin[3];
	dPack.ReadFloatArray(vOrigin, 3);
	dPack.ReadFloatArray(vMins, 3);
	dPack.ReadFloatArray(vMaxs, 3);
	delete dPack;

	int entity = CreateEntityByName("func_nav_blocker");
	DispatchKeyValue(entity, "solid", "2");
	DispatchKeyValue(entity, "teamToBlock", "2");

	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);

	SetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);

	AcceptEntityInput(entity, "BlockNav");

	g_iFuncNavBlocker = EntIndexToEntRef(entity);

	return Plugin_Continue;
}

void vFindTerrorNavAreas()
{
	if(!g_aLastDoor.Length)
		return;

	int iLandArea;
	float fLandFlow;
	float fMapMaxFlow = L4D2Direct_GetMapMaxFlowDistance();

	float vOrigin[3];
	int entity = MaxClients + 1;
	while((entity = FindEntityByClassname(entity, "info_landmark")) != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vOrigin);
		iLandArea = L4D_GetNearestNavArea(vOrigin);
		if(!iLandArea)
			continue;

		fLandFlow = view_as<CNavArea>(iLandArea).Flow;
		if(fLandFlow > fMapMaxFlow * 0.5)
			break;
	}

	bool bCreated;
	int iBot = iFindSurvivorBot();
	if(iBot == -1)
	{
		iBot = iCreateSurvivorBot();
		if(iBot == -1)
			return;

		bCreated = true;
	}

	float fMinFlow, fMaxFlow;

	fMinFlow = g_fMinTravelDistance;
	if(fMinFlow > fMapMaxFlow)
		fMinFlow = fMapMaxFlow * 0.75;

	fMaxFlow = g_fMaxTravelDistance;
	if(fMaxFlow > fMapMaxFlow)
		fMaxFlow = fMapMaxFlow;

	if(fMinFlow >= fMaxFlow)
		fMinFlow = fMaxFlow * 0.5;

	CNavArea area;

	float fFlow;
	float fDistance;
	float vCenter[3];

	// 获取两组不同参数的可用区域
	for(int p; p < 2; p++)
	{
		// 用于下一次生成请求
		if(p == 1)
		{
			g_iNext_SpawnArea_ArrayIndex = g_aSpawnArea.Length;		

			fMinFlow = g_fNext_MinTravelDistance;
			if(fMinFlow > fMapMaxFlow)
				fMinFlow = fMapMaxFlow * 0.75;

			fMaxFlow = g_fNext_MaxTravelDistance;
			if(fMaxFlow > fMapMaxFlow)
				fMaxFlow = fMapMaxFlow;

			if(fMinFlow >= fMaxFlow)
				fMinFlow = fMaxFlow * 0.5;			
		}

		fLandFlow -= fMaxFlow;

		for(int i; i < g_iTheCount; i++)
		{
			if((area = view_as<CNavArea>(LoadFromAddress(g_pTheNavAreas + view_as<Address>(i * 4), NumberType_Int32))).IsNull() == true)
				continue;

			if(area.BaseAttributes & NAV_MESH_MOSTLY_FLAT == 0 || area.SpawnAttributes & TERROR_NAV_CHECKPOINT != 0)
				continue;

			fFlow = area.Flow;
			if(fFlow == -9999.0 || area.Flow < fLandFlow)
				continue;

			if(!SDKCall(g_hSDKSurvivorBotIsReachable, iBot, iLandArea, area)) //有往返程之分, 这里只考虑返程. 往程area->iLandArea 返程iDoorArea->area 有些地图从安全门开始的返程不能回去，例如c2m1, c7m1, c13m1等
				continue;

			area.Center(vCenter);
			fDistance = L4D2_NavAreaTravelDistance(vOrigin, vCenter, true); //有往返程之分, 这里只考虑返程. 往程vCenter->vOrigin 返程vOrigin->vCenter
			if(fDistance < fMinFlow || fDistance > fMaxFlow)
				continue;

			g_aSpawnArea.Push(area);
		}
	}

	if(bCreated)
	{
		vRemovePlayerWeapons(iBot);
		KickClient(iBot);
	}
}

int iFindSurvivorBot()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			return i;
	}
	return -1;
}

void vRemovePlayerWeapons(int client)
{
	int iWeapon;
	for(int i; i < 5; i++)
	{
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			if(RemovePlayerItem(client, iWeapon))
				RemoveEdict(iWeapon);
		}
	}
}

void vUnhookAllCheckpointDoor()
{
	int iEntRef;
	int iLength = g_aLastDoor.Length;
	for(int i; i < iLength; i++)
	{
		if(bIsValidEntRef((iEntRef = g_aLastDoor.Get(i, 0))))
			UnhookSingleEntityOutput(iEntRef, "OnOpen", vOnOpen);
	}
}

int iGetColorInt(int red, int green, int blue)
{
	return red + (green << 8) + (blue << 16);
}

int iCountSurvivorTeam()
{
	int iSurvivors;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
			iSurvivors++;
	}
	return iSurvivors;
}

void vSpawnScavengeItem(const float vOrigin[3])
{
	int entity = CreateEntityByName("weapon_scavenge_item_spawn");
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "glowstate", "3");
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "disableshadows", "1");

	char sSkin[2];
	IntToString(GetRandomInt(1, 3), sSkin, sizeof(sSkin));
	DispatchKeyValue(entity, "weaponskin", sSkin);
	
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);

	SetEntityMoveType(entity, MOVETYPE_NONE);

	AcceptEntityInput(entity, "SpawnItem");
	AcceptEntityInput(entity, "TurnGlowsOn");
	g_aScavengeItem.Push(EntIndexToEntRef(entity));
}

//static char ReloadEntityScript[] = "ent_fire game_scavenge_progress_display runscriptfile plugin_sds_game_scavenge_progress_display";
void vSetNeededDisplay(int iNumCans)
{
//	int target = FindEntityByClassname(MaxClients+1, "game_scavenge_progress_display");
//	if(target != -1)
//		RemoveEntity(target);

	int entity = CreateEntityByName("game_scavenge_progress_display");

	char sNumCans[8];
	IntToString(iNumCans, sNumCans, sizeof(sNumCans));
	DispatchKeyValue(entity, "Max", sNumCans);
	DispatchSpawn(entity);

	AcceptEntityInput(entity, "TurnOn");

	// 重置HUD显示的已经填充的油桶计数
	int test = FindEntityByClassname(MaxClients+1, "terror_gamerules");
	if(test != -1)
		GameRules_SetProp("m_iScavengeTeamScore", 0);

	g_iGameDisplay = EntIndexToEntRef(entity);	
}

bool bIsValidEntRef(int entity)
{
	return entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE;
}

void vExecuteCheatCommand(const char[] sCommand, const char[] sValue = "")
{
	int iCmdFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iCmdFlags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", sCommand, sValue);
	ServerExecute();
	SetCommandFlags(sCommand, iCmdFlags);
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_iSpawnAttributesOffset = hGameData.GetOffset("TerrorNavArea::ScriptGetSpawnAttributes");
	if(g_iSpawnAttributesOffset == -1)
		SetFailState("Failed to find offset: TerrorNavArea::ScriptGetSpawnAttributes");

	g_iFlowDistanceOffset = hGameData.GetOffset("CTerrorPlayer::GetFlowDistance::m_flow");
	if(g_iSpawnAttributesOffset == -1)
		SetFailState("Failed to find offset: CTerrorPlayer::GetFlowDistance::m_flow");

	StartPrepSDKCall(SDKCall_Entity);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CPropDoorRotatingCheckpoint::IsCheckpointDoor") == false)
		SetFailState("Failed to find offset: CPropDoorRotatingCheckpoint::IsCheckpointDoor");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKIsCheckpointDoor = EndPrepSDKCall();
	if(g_hSDKIsCheckpointDoor == null)
		SetFailState("Failed to create SDKCall: CPropDoorRotatingCheckpoint::IsCheckpointDoor");

	StartPrepSDKCall(SDKCall_Entity);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CPropDoorRotatingCheckpoint::IsCheckpointExitDoor") == false)
		SetFailState("Failed to find offset: CPropDoorRotatingCheckpoint::IsCheckpointExitDoor");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKIsCheckpointExitDoor = EndPrepSDKCall();
	if(g_hSDKIsCheckpointExitDoor == null)
		SetFailState("Failed to create SDKCall: CPropDoorRotatingCheckpoint::IsCheckpointExitDoor");

	StartPrepSDKCall(SDKCall_Static);
	Address pAddr = hGameData.GetAddress("NextBotCreatePlayerBot<SurvivorBot>");
	if(pAddr == Address_Null)
		SetFailState("Failed to find address: NextBotCreatePlayerBot<SurvivorBot> in CDirector::AddSurvivorBot");
	if(hGameData.GetOffset("OS") == 1) // 1 - windows, 2 - linux. it's hard to get uniq. sig in windows => will use XRef.
		pAddr += view_as<Address>(LoadFromAddress(pAddr + view_as<Address>(1), NumberType_Int32) + 5); // sizeof(instruction)
	if(PrepSDKCall_SetAddress(pAddr) == false)
		SetFailState("Failed to find address: NextBotCreatePlayerBot<SurvivorBot>");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKNextBotCreatePlayerBot = EndPrepSDKCall();
	if(g_hSDKNextBotCreatePlayerBot == null)
		SetFailState("Failed to create SDKCall: NextBotCreatePlayerBot<SurvivorBot>");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::IsReachable") == false)
		SetFailState("Failed to find signature: SurvivorBot::IsReachable");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKSurvivorBotIsReachable = EndPrepSDKCall();
	if(g_hSDKSurvivorBotIsReachable == null)
		SetFailState("Failed to create SDKCall: SurvivorBot::IsReachable");

	vSetupDynamicHooks(hGameData);

	delete hGameData;
}

void vSetupDynamicHooks(GameData hGameData = null)
{
	g_dDynamicHook = DynamicHook.FromConf(hGameData, "CGasCan::GetTargetEntity");
	if(g_dDynamicHook == null)
		SetFailState("Failed to load offset: CGasCan::GetTargetEntity");
}

MRESReturn mreGasCanGetTargetEntityPre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	if(!g_bSpawnGascan)
		return MRES_Ignored;

	int client = hParams.Get(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return MRES_Ignored;

	// https://forums.alliedmods.net/showthread.php?t=333064
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if( weapon != -1 )
	{
		int skin = GetEntProp(weapon, Prop_Send, "m_nSkin");
		if( 1 & (1 << skin) )		
			return MRES_Ignored;
	}

	static float vPos[3], vTarget[3];
	GetClientEyePosition(client, vPos);
	GetEntPropVector(g_iTargetDoor, Prop_Data, "m_vecAbsOrigin", vTarget);
	if(FloatAbs(vPos[2] - vTarget[2]) > g_fGascanUseRange)
		return MRES_Ignored;

	vTarget[2] = vPos[2] = 0.0;
	if(GetVectorDistance(vPos, vTarget) > g_fGascanUseRange)
		return MRES_Ignored;

	MakeVectorFromPoints(vPos, vTarget, vPos);
	NormalizeVector(vPos, vPos);

	static float vAng[3];
	GetClientEyeAngles(client, vAng);
	vAng[0] = vAng[2] = 0.0;
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);

	static float fDegree;
	fDegree = RadToDeg(ArcCosine(GetVectorDotProduct(vAng, vPos)));
	if(fDegree < -120.0 || fDegree > 120.0)
		return MRES_Ignored;

	if(!g_bAllowMultipleFill && bOtherPlayerPouringGas(client))
	{
		g_fBlockGascanTime[client] = GetGameTime() + 2.5;
	
		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(client));
		dPack.WriteCell(EntIndexToEntRef(pThis));
		RequestFrame(OnNextFrame_EquipGascan, dPack);

		return MRES_Ignored;
	}

	vStartPouring(client);

	return MRES_Ignored;
}

// [L4D2] Scavenge Pouring (https://forums.alliedmods.net/showthread.php?t=333064)
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!g_bAllowMultipleFill && g_fBlockGascanTime[client] > GetGameTime() )
		buttons &= ~IN_ATTACK;

	return Plugin_Continue;
}

void OnNextFrame_EquipGascan(DataPack dPack)
{
	dPack.Reset();

	int client = GetClientOfUserId(dPack.ReadCell());
	if(client && IsClientInGame(client))
	{
		int weapon = EntRefToEntIndex(dPack.ReadCell());
		if(weapon != INVALID_ENT_REFERENCE)
		{
			EquipPlayerWeapon(client, weapon);

			// 伪造gascan_pour_blocked事件来调用客户端的特定本地化提示(等一会! 有其他人正在加油..)
			Event event = CreateEvent("gascan_pour_blocked", true);
			event.SetInt("userid", GetClientUserId(client));
			event.FireToClient(client);
		}
	}

	delete dPack;
}

bool bOtherPlayerPouringGas(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && g_iPropUseTarget[i] && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && L4D2_GetPlayerUseAction(i) == L4D2UseAction_PouringGas)
			return true;
	}
	return false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity <= MaxClients)
		return;

	if(classname[0] != 'w' && classname[1] != 'e')
		return;

	if(strcmp(classname, "weapon_gascan") == 0)
        g_dDynamicHook.HookEntity(Hook_Pre, entity, mreGasCanGetTargetEntityPre);
}

// [L4D2] Pour Gas (https://forums.alliedmods.net/showthread.php?p=1729019)
void vStartPouring(int client)
{
	vRemovePropUseTarget(client);

	float vPos[3], vAng[3], vDir[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vPos[0] += vDir[0] * 5.0;
	vPos[1] += vDir[1] * 5.0;
	vPos[2] += vDir[2] * 5.0;

	int entity = CreateEntityByName("point_prop_use_target");
	DispatchKeyValue(entity, "nozzle", "gas_nozzle");
	TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(entity);
	SetVariantString("OnUseCancelled !self:Kill::0.0:-1");
	AcceptEntityInput(entity, "AddOutput");
	SetVariantString("OnUseFinished !self:Kill::0.0:-1");
	AcceptEntityInput(entity, "AddOutput");
	HookSingleEntityOutput(entity, "OnUseCancelled", vOnUseCancelled);
	HookSingleEntityOutput(entity, "OnUseFinished", vOnUseFinished, true);
	SetEntProp(entity, Prop_Data, "m_iHammerID", client);
	g_iPropUseTarget[client] = EntIndexToEntRef(entity);
}

void vRemovePropUseTarget(int client)
{
	int entity = g_iPropUseTarget[client];
	g_iPropUseTarget[client] = 0;

	if(bIsValidEntRef(entity))
		RemoveEntity(entity);
}

void vOnUseCancelled(const char[] output, int caller, int activator, float delay)
{
	g_iPropUseTarget[GetEntProp(caller, Prop_Data, "m_iHammerID")] = 0;
	RemoveEntity(caller);
}

// 加注完成
void vOnUseFinished(const char[] output, int caller, int activator, float delay)
{
	g_iPourGasAmount++;
	if(g_iPourGasAmount == g_iNumGascans)
	{
		delete g_hPanicTimer;
		delete g_hSpawnGascanTimer;

		g_bBlockOpenDoor = false;

		vUnhookAllCheckpointDoor();

		if(bIsValidEntRef(g_iFuncNavBlocker))
			AcceptEntityInput(g_iFuncNavBlocker, "UnblockNav");

		if(bIsValidEntRef(g_iTargetDoor))
			SetEntProp(g_iTargetDoor, Prop_Send, "m_glowColorOverride", iGetColorInt(0, 255, 0));
		
		PrintToChatAll("\x04      ========Safe Door Scavenge=======");	
		PrintToChatAll("\x04[SDS]\x05      %t", "Unlocked");
		PrintToChatAll("\x04      ---------------------------------");

//		for(int i=1; i<MaxClients; i++)
//			StopSound(i, SNDCHAN_AUTO, SDS_Music);
		if(GetRandomInt(0,1))
			EmitSoundToAll(SDS_Music_F, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 25.0);
		else	EmitSoundToAll(SDS_Music_FF, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 23.0);

		g_bAllowSpawnTank = false;
		RemoveGasCans();
	}
	g_iPropUseTarget[GetEntProp(caller, Prop_Data, "m_iHammerID")] = 0;

	RemoveEntity(caller);
}

// https://forums.alliedmods.net/showthread.php?t=333064
void RemoveGasCans()
{
	static char classname[32];

	for(int entity=MaxClients+1; entity < 2048; entity++)
	{
		if(!IsValidEntity(entity) )
			continue;	
		GetEntityClassname(entity, classname, sizeof(classname) );
		if(strncmp(classname, "weapon_", 7, false) == 0 )
		{
			if(StrContains(classname, "gas", false) != -1 )
			{
				if( !((1 << GetEntProp(entity, Prop_Send, "m_nSkin") ) & 1) )
				{
					//PrintToServer("*测试 移除油桶");
					RemoveEntity(entity);
				}

			}
			else if(StrContains(classname, "scavenge") != -1 && StrContains(classname, "spawn") != -1)
			{
				//PrintToServer("*测试 移除生成点");
				RemoveEntity(entity);
			}
		}
	}
}

void vLateLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Address pTheCount = hGameData.GetAddress("TheCount");
	if(pTheCount == Address_Null)
		SetFailState("Failed to find address: TheCount");

	g_iTheCount = LoadFromAddress(pTheCount, NumberType_Int32);
	if(!g_iTheCount)
		PrintToServer("当前地图NavArea数量为0, 可能是某些测试地图");

	g_pTheNavAreas = view_as<Address>(LoadFromAddress(pTheCount + view_as<Address>(4), NumberType_Int32));
	if(g_pTheNavAreas == Address_Null)
		SetFailState("Failed to find address: TheNavAreas");

	delete hGameData;
}

// https://forums.alliedmods.net/showpost.php?p=2729883&postcount=16
int iCreateSurvivorBot()
{
	int iBot = SDKCall(g_hSDKNextBotCreatePlayerBot, NULL_STRING);
	if(IsValidEntity(iBot))
	{
		ChangeClientTeam(iBot, 2);
		
		if(!IsPlayerAlive(iBot))
			L4D_RespawnPlayer(iBot);

		return iBot;
	}
	return -1;
}
//---------------------------------------------------------------------------||
//		生成Tank&&双向免伤&&创建提示
//---------------------------------------------------------------------------||
bool	g_bChangeTankHP;

void SetTankHP(any index)
{
        if(!IsValidEntity(index) )
	{
		LogError("[SDS] : 无效的Tankid");
		return;
	}
        int health = GetClientHealth(index);
//	PrintToChatAll("After Tank:%d Multi:%f, HP:%d", GetClientHealth(index), g_fTankHP_Multi, health );
        SetEntProp(index, Prop_Send, "m_iHealth", RoundToFloor(float(health) / 2.0 ) );
//	PrintToChatAll("After Tank:%d Multi:%f, HP:%d", GetClientHealth(index), g_fTankHP_Multi, health ); 
}

void SpawnTank(bool caller, float TankHP)
{		
	float fOrigin[3];
	int LuckyMan;

	if(!caller)
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsClientConnected(client) )
			{
				if(IsClientInGame(client) )
				{
					if(GetClientTeam(client) == 2)
					{
						if(!LuckyMan)
							LuckyMan = client;			
						else	if(GetRandomFloat(0.00, 100.00) >= 50.00)
						{
							LuckyMan = client;
							break;
						}
					}
				}
			}		
		}
	}
	else	LuckyMan = GetClosestClient();

//	PrintToChatAll("%N # %d", LuckyMan, LuckyMan);
	char msg[128];
	Format(msg, sizeof(msg), "Tank 降临到 %N 身边！", LuckyMan);
	EmitSoundToAll(SDS_Hint, SOUND_FROM_PLAYER);
	UpdateHUD(5, msg);
	CreateTimer(16.0, tRemoveHUD_Text);

	GetClientAbsOrigin(LuckyMan, fOrigin);		
	int tank = L4D2_SpawnTank(fOrigin, NULL_VECTOR);
	CreateTimer(ReactionTime, tReactionTime, tank, TIMER_FLAG_NO_MAPCHANGE);
	// https://forums.alliedmods.net/showthread.php?p=2790482
	SetEntProp(tank, Prop_Data, "m_takedamage", 0, 1);
		
	g_iShield[tank] = vShield(tank);

	for(int i=1;i<MaxClients;i++)
	{
		if(!g_iTankid[i])
		{
			g_iTankid[i] = tank;
			break;
		}
	}
}

Action tRemoveHUD_Text(Handle Timer)
{
	UpdateHUD(5, "");
	return Plugin_Continue;
}

Action tReactionTime(Handle Timer, any tank)
{
        int iShield = EntRefToEntIndex(g_iShield[tank]);

        if (iShield && iShield != INVALID_ENT_REFERENCE && IsValidEntity(iShield))
		AcceptEntityInput(iShield, "Kill");

        g_iShield[tank] = -1;

	for(int i=1;i<MaxClients;i++)
	{
		if(tank == g_iTankid[i])
			g_iTankid[i] = 0;
	}

	bool allow;
	if(IsValidEntity(tank) )
		if(IsClientConnected(tank) )
			if(IsClientInGame(tank) )
				allow = true;
	if(!allow)	return Plugin_Continue;
		
	// https://forums.alliedmods.net/showthread.php?p=2790482
	SetEntProp(tank, Prop_Data, "m_takedamage", 2, 1);

	return Plugin_Continue;
}

int vShield(int client)
{
        float flOrigin[3];
        GetClientAbsOrigin(client, flOrigin);
        flOrigin[2] -= 120.0;

        int iShield = CreateEntityByName("prop_dynamic");

        if (iShield != -1)
        {
                SetEntityModel(iShield, MODEL_SHIELD);

                DispatchKeyValueVector(iShield, "origin", flOrigin);
                DispatchSpawn(iShield);
                vSetEntityParent(iShield, client, true);

                SetEntityRenderMode(iShield, RENDER_TRANSTEXTURE);
                SetEntityRenderColor(iShield, 255, 25, 25, 50);

                SetEntProp(iShield, Prop_Send, "m_CollisionGroup", 1);

                g_iShield[client] = EntIndexToEntRef(iShield);
        }
        return iShield;
}

stock void vSetEntityParent(int entity, int parent, bool owner = false)
{
        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", parent);

        if (owner)
        {
                SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", parent);
        }
}

// 获取距离安全门最近的客户端索引，用于确定Tank生成位置
int GetClosestClient()
{
	float Origin[3];
	float Distance[MAXPLAYERS+1];
	float fDoorOrigin[3];
	int nearest;	

	GetEntPropVector(g_iTargetDoor, Prop_Data, "m_vecOrigin", fDoorOrigin);
//	PrintToChatAll("%.f %.f %.f", fDoorOrigin[0], fDoorOrigin[1], fDoorOrigin[2]);

	for(int client=1; client<MaxClients; client++)
	{
		if(IsClientConnected(client) )
		{
			if(IsClientInGame(client) )
			{
				// 不用考虑机器人，只是为了给开门的玩家惊喜
				if(GetClientTeam(client) == 2 && !IsFakeClient(client) )
				{
					GetClientAbsOrigin(client, Origin);
					Distance[client] = GetVectorDistance(Origin, fDoorOrigin);
				
					for(int i=1; i<MaxClients; i++)
					{
						if(Distance[i] == 0.0)
							continue;
						if(Distance[client] <= Distance[i])
							nearest = client;
					}
				}
			}
		}		
	}
	
	return nearest;		
}

public void OnClientPutInServer(int client)
{
        SDKHook(client, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public Action eOnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!g_bAllowSpawnTank)
		return Plugin_Continue;

	for(int i=1;i<MaxClients;i++)
	{
		if(iAttacker == g_iTankid[i])
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

// https://github.com/accelerator74/sp-plugins/blob/2ce16cfc3abd673ced16e98cf15bc16a7d0a4d11/l4d2_SpeakingList/SpeakingList.sp#L31C1-L48
#define HUD_FLAG_PRESTR                 (1<<0)  //      do you want a string/value pair to start(pre) or end(post) with the static string (default is PRE)
#define HUD_FLAG_POSTSTR                (1<<1)  //      ditto
#define HUD_FLAG_BEEP                   (1<<2)  //      Makes a countdown timer blink
#define HUD_FLAG_BLINK                  (1<<3)  //      do you want this field to be blinking
#define HUD_FLAG_AS_TIME                (1<<4)  //      to do..
#define HUD_FLAG_COUNTDOWN_WARN (1<<5)  //      auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG                   (1<<6)  //      dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER  (1<<7)  //      by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT             (1<<8)  //      Left justify this text
#define HUD_FLAG_ALIGN_CENTER   (1<<9)  //      Center justify this text
#define HUD_FLAG_ALIGN_RIGHT    (3<<8)  //      Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS (1<<10) //      only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED  (1<<11) //      only show to the special infected team
#define HUD_FLAG_TEAM_MASK              (3<<10) //      link HUD_FLAG_TEAM_SURVIVORS and HUD_FLAG_TEAM_INFECTED
#define HUD_FLAG_UNKNOWN1               (1<<12) //      ?
#define HUD_FLAG_TEXT                   (1<<13) //      ?
#define HUD_FLAG_NOTVISIBLE             (1<<14) //      if you want to keep the slot data but keep it from displaying

#define EMSHUD_FLAG                             HUD_FLAG_ALIGN_CENTER | HUD_FLAG_TEXT | HUD_FLAG_NOBG | HUD_FLAG_BLINK

stock void HudSet(int slot)
{
	GameRules_SetProp("m_iScriptedHUDFlags", EMSHUD_FLAG, _, slot);
	GameRules_SetPropFloat("m_fScriptedHUDPosX", 0.0, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", 0.25, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", 1.0, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", 0.05, slot, true);
}

stock void UpdateHUD(int slot, const char[] msg)
{
	GameRules_SetPropString("m_szScriptedHUDStringSet", msg, true, slot);
}

//---------------------------------------------------------------------------||
//
//---------------------------------------------------------------------------||
stock int GetAllPlayersInServer()
{
	int count = 0;
	for(int i = 1; i < MaxClients + 1; i++)
	{
		if(IsClientConnected(i))
			count++;
	}
	return count;
}

