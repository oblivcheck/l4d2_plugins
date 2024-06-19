Convars.SetValue("sv_consistency", 0);
Convars.SetValue("sv_pure_kick_clients", 0);

if (!("MANACAT" in getroottable())){
	::MANACAT <- {}
}

local scriptver = 20240410;
if(!("rng_item" in ::MANACAT) || ::MANACAT.rng_item.ver <= scriptver){
	::MANACAT.rng_item <- {
		ver = scriptver
	}
	::MANACAT.slot50 <- function(ent){
		local msg = Convars.GetClientConvarValue("cl_language", ent.GetEntityIndex());
		switch(msg){
			case "korean":case "koreana":	msg = "아이템 스킨 확장";	break;
			case "japanese":				msg = "アイテムスキン拡張";	break;
		//	case "spanish":					msg = "Extended Items Skin Pack";	break;
			case "schinese":				msg = "物品皮肤增加";	break;
			case "tchinese":				msg = "物品皮膚增加";	break;
			default:						msg = "Extended Items Skin Pack";	break;
		}
		ClientPrint( ent, 5, "\x02 - "+msg+" \x01 v"+::MANACAT.rng_item.ver);
	};
}else if(::MANACAT.rng_item.ver > scriptver){
	return;
}

printl( "<MANACAT> RNG items Loaded. v"+::MANACAT.rng_item.ver);

IncludeScript("manacat_rng_item/info");
if (!("manacatInfo" in getroottable())){
	IncludeScript("manacat/info");
}

::manacat_rng_item <- {
	debug = false
	startflag = false
	classnameList = [
		"weapon_first_aid_kit_spawn", 4,
		"weapon_defibrillator_spawn", 2,
		"weapon_upgradepack_incendiary_spawn", 1,
		"upgrade_ammo_incendiary", 1,
		"weapon_upgradepack_explosive_spawn", 1,
		"upgrade_ammo_explosive", 1,
		"weapon_pain_pills_spawn", 3,
		"weapon_adrenaline_spawn", 3,
		"weapon_molotov_spawn", 14,
		"weapon_pipe_bomb_spawn", 3,
		"weapon_vomitjar_spawn", 5,
		
		"weapon_chainsaw_spawn", 2,
	]
	meleeList = {}

	itemclass = ""
	itemskin = ""
	itemx = ""
	itemy = ""
	itemz = ""
	itemlen = 0
	meleemodel = ""
	meleeskin = ""
	meleex = ""
	meleey = ""
	meleez = ""
	meleelen = 0
	sessionData = {}

	function OnGameEvent_spawner_give_item(params){
		local player = GetPlayerFromUserID(params.userid);
		if(!player.IsValid() || NetProps.GetPropIntArray( player, "m_iTeamNum", 0) != 2)return;
		local itemSpawn = EntIndexToHScript(params.spawner);
		if(itemSpawn == null || !itemSpawn.IsValid())return;
		local invTable = {};
		GetInvTable(player, invTable);
		/*if(params.item == "weapon_rifle_m60" || params.item == "weapon_grenade_launcher"){

		}else */if(params.item == "weapon_chainsaw"){
			invTable.slot1.Kill();
			player.GiveItemWithSkin("weapon_chainsaw", NetProps.GetPropInt(itemSpawn, "m_nSkin"));
		}else if(params.item == "weapon_molotov" || params.item == "weapon_pipe_bomb" || params.item == "weapon_vomitjar"){
			itemSpawn.ValidateScriptScope();
			local rng = itemSpawn.GetScriptScope();
			if("rngskin" in rng)rng = RandomInt(0, rng.rngskin);
			else rng = NetProps.GetPropInt(itemSpawn, "m_nSkin");
			NetProps.SetPropInt(invTable.slot2, "m_nSkin", rng);
			::manacat_rng_item.chkThrows(player);
		}else if(params.item == "weapon_first_aid_kit" || params.item == "weapon_defibrillator" || params.item == "weapon_upgradepack_explosive" || params.item == "weapon_upgradepack_incendiary"){
			NetProps.SetPropInt(invTable.slot3, "m_nSkin", NetProps.GetPropInt(itemSpawn, "m_nSkin"));
			::manacat_rng_item.chkPacks(player);
			NetProps.SetPropInt(invTable.slot3, "m_nWeaponSkin", NetProps.GetPropInt(itemSpawn, "m_nSkin"));
		}else if(params.item == "weapon_pain_pills" || params.item == "weapon_adrenaline"){
			itemSpawn.ValidateScriptScope();
			local rng = itemSpawn.GetScriptScope();
			if("rngskin" in rng)rng = RandomInt(0, rng.rngskin);
			else rng = NetProps.GetPropInt(itemSpawn, "m_nSkin");
			NetProps.SetPropInt(invTable.slot4, "m_nSkin", rng);
			NetProps.SetPropInt(invTable.slot4, "m_nWeaponSkin", rng);
		}
	}

	function OnGameEvent_player_spawn(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.userid));
	}
	function OnGameEvent_player_team(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.userid));
	}
	function OnGameEvent_player_first_spawn(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.userid));
	}
	function OnGameEvent_player_entered_start_area(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.userid));
	}
	function OnGameEvent_player_transitioned(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.userid));
	}
	function OnGameEvent_item_pickup(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.userid));
	}
	function OnGameEvent_bot_player_replace(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.player));
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.bot));
	}
	function OnGameEvent_player_bot_replace(params){
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.player));
		::manacat_rng_item.chkThrows(GetPlayerFromUserID(params.bot));
	}

	function chkThrows(player){
		local invTable = {};
		GetInvTable(player, invTable);
		if("slot2" in invTable){
			local weapon = invTable.slot2;
			local wclass = weapon.GetClassname();
			if(wclass == "weapon_molotov" || wclass == "weapon_pipe_bomb" || wclass == "weapon_vomitjar"){
				NetProps.SetPropInt(weapon, "m_nWeaponSkin", NetProps.GetPropInt( weapon, "m_nSkin"));
				player.ValidateScriptScope();
				local scrScope = player.GetScriptScope();
				scrScope.throwSkin <- NetProps.GetPropInt( weapon, "m_nSkin");
			}
		}
		if("slot3" in invTable){
			local weapon = invTable.slot3;
			local wclass = weapon.GetClassname();
			if(wclass == "weapon_first_aid_kit" || wclass == "weapon_defibrillator" || wclass == "weapon_upgradepack_explosive" || wclass == "weapon_upgradepack_explosive"){
				NetProps.SetPropInt(weapon, "m_nWeaponSkin", NetProps.GetPropInt( weapon, "m_nSkin"));
			}
		}
	}

	function chkPacks(player){
		local invTable = {};
		GetInvTable(player, invTable);
		if(!("slot3" in invTable))return;
		local weapon = invTable.slot3;
		local wclass = weapon.GetClassname();
		if(wclass == "weapon_first_aid_kit" || wclass == "weapon_defibrillator" || wclass == "weapon_upgradepack_explosive" || wclass == "weapon_upgradepack_incendiary"){
			NetProps.SetPropInt(weapon, "m_nWeaponSkin", NetProps.GetPropInt( weapon, "m_nSkin"));
		}
	}

	function OnGameEvent_weapon_fire(params){
		if(params.weapon == "molotov" || params.weapon == "pipe_bomb" || params.weapon == "vomitjar")
			DoEntFire("!self", "RunScriptCode", "g_ModeScript.manacat_rng_item.throwsSkin("+params.userid+", \""+params.weapon+"\", 15)" , 0.15 , null, Entities.First()); //Worldspawn
	}

	
	function throwsSkin(userid, throwstype, count){
		local player = GetPlayerFromUserID(userid);
		player.ValidateScriptScope();
		local scrScope = player.GetScriptScope();

		for (local ent = null; (ent = Entities.FindByClassname(ent , throwstype+"_projectile")) != null && ent.IsValid();){
			if(NetProps.GetPropEntity( ent, "m_hThrower" ) == player && ent.GetContext("throwskin") == null){
				ent.SetContext("throwskin", "chk", 15.0);
				NetProps.SetPropInt( ent, "m_nSkin", scrScope.throwSkin );return;
			}
		}
		if(--count > 0)DoEntFire("!self", "RunScriptCode", "g_ModeScript.manacat_rng_item.throwsSkin("+userid+", \""+throwstype+"\", "+count+")" , 0.033 , null, Entities.First());
	}

	function OnGameEvent_upgrade_pack_begin(params){
		local player = GetPlayerFromUserID(params.userid);
		local ammo = player.GetActiveWeapon();
		if(ammo != null && ammo.IsValid()){
			player.ValidateScriptScope();
			local scrScope = player.GetScriptScope();
			scrScope.ammopack <- NetProps.GetPropInt( ammo, "m_nSkin");
		}
	}

	function OnGameEvent_upgrade_pack_used(params){
		local player = GetPlayerFromUserID(params.userid);
		local ammo = Ent(params.upgradeid);
		if(ammo != null && ammo.IsValid()){
			player.ValidateScriptScope();
			local scrScope = player.GetScriptScope();
			if("ammopack" in scrScope)NetProps.SetPropInt( ammo, "m_nSkin", scrScope.ammopack);
		}
	}

	function OnGameEvent_round_start_post_nav(params){
		::manacat_rng_item.meleeList["models/weapons/melee/w_fireaxe.mdl"] <- 3
		::manacat_rng_item.meleeList["models/weapons/melee/w_crowbar.mdl"] <- 3
		::manacat_rng_item.meleeList["models/weapons/melee/w_bat.mdl"] <- 2
		::manacat_rng_item.meleeList["models/weapons/melee/w_cricket_bat.mdl"] <- 3
		::manacat_rng_item.meleeList["models/weapons/melee/w_frying_pan.mdl"] <- 1
		::manacat_rng_item.meleeList["models/weapons/melee/w_tonfa.mdl"] <- 1
		::manacat_rng_item.meleeList["models/weapons/melee/w_katana.mdl"] <- 2
		::manacat_rng_item.meleeList["models/weapons/melee/w_golfclub.mdl"] <- 2
		::manacat_rng_item.meleeList["models/weapons/melee/w_electric_guitar.mdl"] <- 2
		::manacat_rng_item.meleeList["models/weapons/melee/w_machete.mdl"] <- 2
		::manacat_rng_item.meleeList["models/w_models/weapons/w_knife_t.mdl"] <- 2
		::manacat_rng_item.meleeList["models/weapons/melee/w_pitchfork.mdl"] <- 2
		::manacat_rng_item.meleeList["models/weapons/melee/w_shovel.mdl"] <- 2
		
		local gamemode = ::manacat_rng_item.gamemode();
		local currentTime = Time();
		RestoreTable("rngitemspawn", ::manacat_rng_item.sessionData);
		local gamerules = Entities.FindByClassname(null, "terror_gamerules");

		if(::manacat_rng_item.sessionData.len() == 0 || (gamemode == "coop" && currentTime < 10 && Director.IsSessionStartMap()) || 
		(gamemode == "versus" && currentTime < 10
		&& NetProps.GetPropInt(gamerules, "terror_gamerules_data.m_iCampaignScore.000") == 0
		&& NetProps.GetPropInt(gamerules, "terror_gamerules_data.m_iCampaignScore.001") == 0)){
			::manacat_rng_item.sessionData.clear();
		}
		SaveTable("rngitemspawn", ::manacat_rng_item.sessionData);

		::manacat_rng_item.ResetSkinSupplies();

		local door = null;
		while (door = Entities.FindByClassname(door,"prop_door_rotating_checkpoint")){
			if(GetFlowPercentForPosition(door.GetOrigin(), false) > 90){
				door.ValidateScriptScope();
				local scrScope = door.GetScriptScope();
				scrScope["InputLock"] <- function(){
					// The game locks the exit checkpoint doing transitions.
				//	if (activator == null && caller == null)printl("Probably the game locking the exit checkpoint");

					/*while (player = Entities.FindByClassname(player, "player")){
						local isinchkp = (ResponseCriteria.GetValue(player,"incheckpoint").tointeger() > 0) ? true : false;//ent_show_response_criteria

						if(!isinchkp)return;
					}*/

					local entity = null
					local entity = null;
					for(local i = 0; i < 12; i++)
						while(entity = Entities.FindByClassname(entity, ::manacat_rng_item.classnameList[i*2]))::manacat_rng_item.FixSkin(entity);
					return true;
				}
				door.ConnectOutput("OnBlockedClosing","InputLock");
			}
		}
	}

	function OnGameEvent_round_end(params){
		local player = null;
		while (player = Entities.FindByClassname(player, "player")){
			local isinchkp = (ResponseCriteria.GetValue(player,"incheckpoint").tointeger() > 0) ? true : false;//ent_show_response_criteria
			if(!isinchkp)return;
		}
	}

	function OnGameEvent_round_freeze_end(params){
		::manacat_rng_item.startflag = true;
	}

	function OnGameEvent_player_entered_start_area(params){
		::manacat_rng_item.startflag = true;
	}

	function OnGameEvent_player_entered_checkpoint(params){
		::manacat_rng_item.startflag = true;
	}

	function OnGameEvent_player_left_safe_area(params){
		::manacat_rng_item.startflag = true;
		local gamemode = ::manacat_rng_item.gamemode();
		if(gamemode == "versus"){
			RestoreTable("rngitemspawn", ::manacat_rng_item.sessionData);
			SaveTable("rngitemspawn", ::manacat_rng_item.sessionData);
		}
	}

	function OnGameEvent_weapon_spawn_visible(params){
		local weapon = Ent(params.subject);
		local wclass = weapon.GetClassname();
		if(wclass == "weapon_first_aid_kit_spawn"
		|| wclass == "weapon_defibrillator_spawn"
		|| wclass == "weapon_upgradepack_incendiary_spawn"
		|| wclass == "upgrade_ammo_incendiary"
		|| wclass == "weapon_upgradepack_explosive_spawn"
		|| wclass == "upgrade_ammo_explosive"
		|| wclass == "weapon_pain_pills_spawn"
		|| wclass == "weapon_adrenaline_spawn"
		|| wclass == "weapon_molotov_spawn"
		|| wclass == "weapon_pipe_bomb_spawn"
		|| wclass == "weapon_vomitjar_spawn")
		NetProps.SetPropInt(weapon, "m_nWeaponSkin", -1);
	}

	function OnGameEvent_foot_locker_opened(params){
		//EntFire( "worldspawn", "RunScriptCode", "g_ModeScript.manacat_rng_item.foot_locker_rng()", 0.1 );
		DoEntFire("!self", "RunScriptCode", "g_ModeScript.manacat_rng_item.foot_locker_rng()" , 0.1 , null, Entities.First()); //Worldspawn
	}

	function foot_locker_rng(){
		local entity = null;
		for(local i = 6; i < 10; i++)
			while(entity = Entities.FindByClassname(entity, ::manacat_rng_item.classnameList[i*2]))::manacat_rng_item.SetSkin(entity, ::manacat_rng_item.classnameList[(i*2)+1], true);
		
		local dummy = {};
		dummy["models/w_models/weapons/w_eq_painpills.mdl"] <- 3;
		dummy["models/w_models/weapons/w_eq_adrenaline.mdl"] <- 3;
		dummy["models/w_models/weapons/w_eq_molotov.mdl"] <- 14;
		dummy["models/w_models/weapons/w_eq_pipebomb.mdl"] <- 3;

		for(local i = 0; i < 3; i++)
			while(entity = Entities.FindByClassname(entity, "prop_dynamic")){
				if(entity == null || !entity.IsValid())continue;
				local model = entity.GetModelName();
				if(model in dummy)::manacat_rng_item.SetSkin(entity, dummy[model], true);
			}
	}

	function FixSkin(entity){
		NetProps.SetPropInt(entity, "m_nWeaponSkin", NetProps.GetPropInt( entity, "m_nSkin"));
	}

	function SetSkin(entity, r, dummy = false){
		entity.ValidateScriptScope();
		local scrScope = entity.GetScriptScope();
		if("rngchk" in scrScope)return;
		scrScope.rngchk <- true;
		local nearnav = NavMesh.GetNearestNavArea(entity.GetOrigin(), 80.0, true, true);
		local skin = RandomInt(0, r);
		if((nearnav != null && (!nearnav.HasSpawnAttributes(2048)/*checkpoint*/ || (nearnav.HasSpawnAttributes(2048) && GetFlowPercentForPosition(nearnav.GetCenter(), false) > 90))) || Director.IsSessionStartMap()){
			NetProps.SetPropInt(entity, "m_nSkin", skin);
			NetProps.SetPropInt(entity, "m_nWeaponSkin", skin);
		}
		if(!dummy){
			::manacat_rng_item.itemclass += entity.GetClassname() + "|";
			::manacat_rng_item.itemskin += skin + "|";
			local itempos = entity.GetOrigin();
			::manacat_rng_item.itemx += itempos.x + "|";		::manacat_rng_item.itemy += itempos.y + "|";		::manacat_rng_item.itemz += itempos.z + "|";
		}else{
			scrScope.rngskin <- r;
			NetProps.SetPropInt(entity, "m_nWeaponSkin", -1);
		}
	}

	function SetSkinMelee(entity, r){
		local nearnav = NavMesh.GetNearestNavArea(entity.GetOrigin(), 80.0, true, true);
		local skin = RandomInt(0, r);
		if((nearnav != null && (!nearnav.HasSpawnAttributes(2048)/*checkpoint*/ || (nearnav.HasSpawnAttributes(2048) && GetFlowPercentForPosition(nearnav.GetCenter(), false) > 90))) || Director.IsSessionStartMap()){
			NetProps.SetPropInt(entity, "m_nSkin", skin);
			NetProps.SetPropInt(entity, "m_nWeaponSkin", skin);
		}
		::manacat_rng_item.meleemodel += entity.GetModelName() + "|";
		::manacat_rng_item.meleeskin += skin + "|";
		local itempos = entity.GetOrigin();
		::manacat_rng_item.meleex += itempos.x + "|";		::manacat_rng_item.meleey += itempos.y + "|";		::manacat_rng_item.meleez += itempos.z + "|";
	}

	function RestoreSkin(entity, eclass){
		local entpos = entity.GetOrigin();
		for(local i = 0; i < ::manacat_rng_item.itemlen; i++){
			if(::manacat_rng_item.itemclass[i] == eclass){
				local tgpos = Vector(::manacat_rng_item.itemx[i].tofloat(), ::manacat_rng_item.itemy[i].tofloat(), ::manacat_rng_item.itemz[i].tofloat());
				if((entpos-tgpos).Length() < 3){
					if(::manacat_rng_item.debug)DebugDrawBoxAngles(tgpos, Vector(-15, -15, -15), Vector(15, 15, 15), QAngle(0, 0, 0), Vector(255, 0, 255), 64, 30.0);
					NetProps.SetPropInt(entity, "m_nSkin", ::manacat_rng_item.itemskin[i].tointeger());
					::manacat_rng_item.itemclass[i] = "X";
				}
			}
		}
		return;
	}

	function RestoreSkinMelee(entity, emodel){
		local entpos = entity.GetOrigin();
		for(local i = 0; i < ::manacat_rng_item.meleelen; i++){
			if(::manacat_rng_item.meleemodel[i] == emodel){
				local tgpos = Vector(::manacat_rng_item.meleex[i].tofloat(), ::manacat_rng_item.meleey[i].tofloat(), ::manacat_rng_item.meleez[i].tofloat());
				if((entpos-tgpos).Length() < 3){
					if(::manacat_rng_item.debug)DebugDrawBoxAngles(tgpos, Vector(-15, -15, -15), Vector(15, 15, 15), QAngle(0, 0, 0), Vector(255, 0, 255), 64, 30.0);
					NetProps.SetPropInt(entity, "m_nSkin", ::manacat_rng_item.meleeskin[i].tointeger());
					::manacat_rng_item.meleemodel[i] = "X";
				}
			}
		}
		return;
	}

	function GetMapName(){
		local map = Director.GetMapName();
	
		if(map == "c4m3_sugarmill_b")map = "c4m2_sugarmill_a";
		else if(map == "c4m4_milltown_b" || map == "c4m5_milltown_escape")map = "c4m1_milltown_a";

		return [map, Director.GetMapName()];
	}

	function gamemode(){
		local mp_gamemodebase = Director.GetGameModeBase();
		local mp_gamemode = Convars.GetStr("mp_gamemode").tolower();

		if(mp_gamemodebase == "coop" || mp_gamemodebase == "realism")return "coop";
		else if(mp_gamemodebase == "versus" || mp_gamemode == "mutation15")return "versus";
		else return "coop";
	}

	function ResetSkinSupplies(){
		if(!::manacat_rng_item.startflag || ("itemSpawner" in ::MANACAT && !::MANACAT.itemSpawner.check)){
			DoEntFire("!self", "RunScriptCode", "g_ModeScript.manacat_rng_item.ResetSkinSupplies()" , 0.1 , null, Entities.First()); //Worldspawn
			return;
		}

		local map = ::manacat_rng_item.GetMapName();

		local save = false;

		RestoreTable("rngitemspawn", ::manacat_rng_item.sessionData);
		local gamemode = ::manacat_rng_item.gamemode();
		//대전이 아니라면 현재 맵 세이브 지워줌
		if(gamemode != "versus"){
			if("maps" in ::manacat_rng_item.sessionData){
				local maparray = "";
				local maps = split(::manacat_rng_item.sessionData["maps"], "|");
				local mapslen = maps.len();
				for(local i = 0; i < mapslen; i++){
					if(maps[i] != map[1])maparray += maps[i]+"|";
				}
				local maparraylen = maparray.len()-1;
				if(maparraylen > 0 && maparray[maparraylen].tochar() == "|")maparray = maparray.slice(0, maparraylen);
				::manacat_rng_item.sessionData["maps"] <- maparray;
				::manacat_rng_item.sessionData.rawdelete(map[1]);
			}
		}

		map = map[0];
		//맵리스트에 현재 플레이중인 맵이 있으면 세이브 있는 걸로 인식
		if("maps" in ::manacat_rng_item.sessionData){
			local maps = split(::manacat_rng_item.sessionData["maps"], "|");
			local mapslen = maps.len();
			for(local i = 0; i < mapslen; i++){
				if(maps[i] == map){	save = true;	break;	}
			}
		}

		::manacat_rng_item.itemclass = "";		::manacat_rng_item.itemskin = "";
		::manacat_rng_item.itemx = "";		::manacat_rng_item.itemy = "";		::manacat_rng_item.itemz = "";		::manacat_rng_item.itemlen = 0;
		::manacat_rng_item.meleemodel = "";		::manacat_rng_item.meleeskin = "";
		::manacat_rng_item.meleex = "";		::manacat_rng_item.meleey = "";		::manacat_rng_item.meleez = "";		::manacat_rng_item.meleelen = 0;

		if(save){
			::manacat_rng_item.itemclass = split(::manacat_rng_item.sessionData[map+"|ic"], "|");			::manacat_rng_item.itemskin = split(::manacat_rng_item.sessionData[map+"|is"], "|");
			::manacat_rng_item.itemx = split(::manacat_rng_item.sessionData[map+"|ix"], "|");			::manacat_rng_item.itemy = split(::manacat_rng_item.sessionData[map+"|iy"], "|");			::manacat_rng_item.itemz = split(::manacat_rng_item.sessionData[map+"|iz"], "|");
			::manacat_rng_item.itemlen = ::manacat_rng_item.itemclass.len();
			::manacat_rng_item.meleemodel = split(::manacat_rng_item.sessionData[map+"|mm"], "|");			::manacat_rng_item.meleeskin = split(::manacat_rng_item.sessionData[map+"|ms"], "|");
			::manacat_rng_item.meleex = split(::manacat_rng_item.sessionData[map+"|mx"], "|");			::manacat_rng_item.meleey = split(::manacat_rng_item.sessionData[map+"|my"], "|");			::manacat_rng_item.meleez = split(::manacat_rng_item.sessionData[map+"|mz"], "|");
			::manacat_rng_item.meleelen = ::manacat_rng_item.meleemodel.len();
			local entity = null;
			while(entity = Entities.FindByClassname(entity, "weapon_melee_spawn"))if(entity.GetModelName() in ::manacat_rng_item.meleeList)::manacat_rng_item.RestoreSkinMelee(entity, entity.GetModelName());
			for(local i = 0; i < 12; i++)
				while(entity = Entities.FindByClassname(entity, ::manacat_rng_item.classnameList[i*2]))::manacat_rng_item.RestoreSkin(entity, ::manacat_rng_item.classnameList[i*2]);
		}else{
			local entity = null;
			while(entity = Entities.FindByClassname(entity, "weapon_melee_spawn"))if(entity.GetModelName() in ::manacat_rng_item.meleeList)::manacat_rng_item.SetSkinMelee(entity, ::manacat_rng_item.meleeList[entity.GetModelName()]);
			for(local i = 0; i < 12; i++)
				while(entity = Entities.FindByClassname(entity, ::manacat_rng_item.classnameList[i*2]))::manacat_rng_item.SetSkin(entity, ::manacat_rng_item.classnameList[(i*2)+1]);
			
			::manacat_rng_item.sessionData[map+"|ic"] <- ::manacat_rng_item.itemclass;			::manacat_rng_item.sessionData[map+"|is"] <- ::manacat_rng_item.itemskin;
			::manacat_rng_item.sessionData[map+"|ix"] <- ::manacat_rng_item.itemx;			::manacat_rng_item.sessionData[map+"|iy"] <- ::manacat_rng_item.itemy;			::manacat_rng_item.sessionData[map+"|iz"] <- ::manacat_rng_item.itemz;
			::manacat_rng_item.sessionData[map+"|mm"] <- ::manacat_rng_item.meleemodel;			::manacat_rng_item.sessionData[map+"|ms"] <- ::manacat_rng_item.meleeskin;
			::manacat_rng_item.sessionData[map+"|mx"] <- ::manacat_rng_item.meleex;			::manacat_rng_item.sessionData[map+"|my"] <- ::manacat_rng_item.meleey;			::manacat_rng_item.sessionData[map+"|mz"] <- ::manacat_rng_item.meleez;
		
			//맵 이름도 맵 리스트에 저장
			if("maps" in ::manacat_rng_item.sessionData)map = ::manacat_rng_item.sessionData["maps"]+"|"+map;
			::manacat_rng_item.sessionData["maps"] <- map;
		}
		DoEntFire("!self", "RunScriptCode", "g_ModeScript.manacat_rng_item.ResetSkinProcess()" , 0.1 , null, Entities.First()); //Worldspawn
		SaveTable("rngitemspawn", ::manacat_rng_item.sessionData);
		if(::manacat_rng_item.debug && "maps" in ::manacat_rng_item.sessionData){
			local maps = split(::manacat_rng_item.sessionData["maps"], "|");
			local mapslen = maps.len();
			printl("<RNG supplies> Map List");
			printl("---------------");
			for(local i = 0; i < mapslen; i++){
				printl(maps[i])
				if((maps[i]+"|ic") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|ic"])
				if((maps[i]+"|is") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|is"])
				if((maps[i]+"|ix") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|ix"])
				if((maps[i]+"|iy") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|iy"])
				if((maps[i]+"|iz") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|iz"])
				if((maps[i]+"|mm") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|mm"])
				if((maps[i]+"|ms") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|ms"])
				if((maps[i]+"|mx") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|mx"])
				if((maps[i]+"|my") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|my"])
				if((maps[i]+"|mz") in ::manacat_rng_item.sessionData)printl(::manacat_rng_item.sessionData[maps[i]+"|mz"])
			}
			printl("---------------");
		}
	}
	
	function ResetSkinProcess(){
		local entity = null;
		for(local i = 0; i < 12; i++)
			while(entity = Entities.FindByClassname(entity, ::manacat_rng_item.classnameList[i*2]))NetProps.SetPropInt(entity, "m_nWeaponSkin", -1);
	}
}

__CollectEventCallbacks(::manacat_rng_item, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);