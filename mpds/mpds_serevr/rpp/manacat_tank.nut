if (!("MANACAT" in getroottable())){
	::MANACAT <- {}
}

local scriptver = 20240518;
if(!("tank" in ::MANACAT) || ::MANACAT.tank.ver <= scriptver){
	::MANACAT.tank <- {
		ver = scriptver
	}
	::MANACAT.slot28 <- function(ent){
		local msg = Convars.GetClientConvarValue("cl_language", ent.GetEntityIndex());
		switch(msg){
			case "korean":case "koreana":	msg = "탱크 AI";	break;
			case "japanese":				msg = "Tank AI";	break;
			case "spanish":					msg = "Tank AI";	break;
			case "schinese":				msg = "Tank AI";	break;
			case "tchinese":				msg = "Tank AI";	break;
			default:						msg = "Tank AI";	break;
		}
		ClientPrint( ent, 5, "\x02 - "+msg+" \x01 v"+::MANACAT.tank.ver);
	};
}else if(::MANACAT.tank.ver > scriptver){
	return;
}

printl( "<MANACAT> Tank AI Loaded. v"+::MANACAT.tank.ver);

IncludeScript("rpp/manacat_tank/manacatTimer");
if (!("manacatTimers" in getroottable())){
	IncludeScript("manacat/manacatTimer");
}

IncludeScript("rpp/manacat_tank/info");
if (!("manacatInfo" in getroottable())){
	IncludeScript("manacat/info");
}
IncludeScript("rpp/manacat_tank/rngitem");
if (!("manacat_rng_item" in getroottable())){
	IncludeScript("manacat/rngitem");
}

::manacat_tank_lang<-{
set_kr = "현재 탱크 설정은 다음과 같습니다."
set_jp = "現在のTank設定は次のとおりです。"
set_es = "La configuración actual del tank es la siguiente:"
set_sc = "当前Tank设置如下："
set_tc = "目前Tank設置如下："
set_en = "The current tank settings are as follows:"

ladder_kr = "사다리를 타는 속도 증가"
ladder_jp = "Tankの梯子登り速度の増加"
ladder_es = "Acelerar la subida de escalera"
ladder_sc = "梯子时移动速度增加"//간체
ladder_tc = "梯子時移動速度增加"//번체
ladder_en = "Ladder climbing speed up"

burn_kr = "불타는 탱크의 이동속도 증가"
burn_jp = "燃えるTankの移動速度の増加"
burn_es = "Acelerar la Tanque en llamas"
burn_sc = "着火时移动速度增加"//간체
burn_tc = "著火時移動速度增加"//번체
burn_en = "Burning tank's speed up"

door_kr = "은신처 출입문 강제개방"
door_jp = "セーフルームのドアを強制開放"
door_es = "Forzar una puertas de refugios abierta"
door_sc = "强行打开安全室的门"//간체
door_tc = "強行打開安全室的門"//번체
door_en = "Checkpoint door breaching"

prop_kr = "물체 타격 궤도 보정"
prop_jp = "物体打撃時の軌道を補正"
prop_es = "Ajuste de trayectoria de utilería"
prop_sc = "物体撞击轨迹修正"//간체
prop_tc = "物體撞擊軌跡修正"//번체
prop_en = "Prop trajectory adjustment"

incap_kr = "펀치에 의한 무력화 시 넉백"
incap_jp = "パンチで戦闘不能になった時のノックバック"
incap_es = "Retroceso cuando está incapacitado por un puñetazo"
incap_sc = "被拳头击倒时会被击退"//간체
incap_tc = "被拳頭擊倒時會被擊退"//번체
incap_en = "Knockback when incapacitated by punch"

pound_kr = "무력화된 생존자를 뭉갤 때 주변을 함께 공격"
pound_jp = "戦闘不能状態の生存者を潰す時、周りも一緒に攻撃"
pound_es = "Golpear a un incapacitado afecta a los sobrevivientes cercanos"
pound_sc = "当碾压一名被制的幸存者时，也要攻击附近的人"//간체
pound_tc = "當碾壓一名被制的倖存者時，也要攻擊附近的人"//번체
pound_en = "Ground pounding an incapped also hits nearby survivors"

punchjump_kr = "펀치와 동시에 점프"
punchjump_jp = "パンチしながらジャンプ"
punchjump_es = "Mientras balancea un puño, salto"
punchjump_sc = "出拳时跳跃"
punchjump_tc = "出拳時跳躍"
punchjump_en = "While punching, jump"

punchrock_kr = "펀치와 동시에 파편 던지기"
punchrock_jp = "パンチと破片投げを同時に"
punchrock_es = "Mientras balancea un puño, arrojar escombros"
punchrock_sc = "出拳时投掷"
punchrock_tc = "出拳時投擲"
punchrock_en = "While punching, throw rubble"

rockjump_kr = "파편을 던짐와 동시에 점프"
rockjump_jp = "破片を投げながらジャンプ"
rockjump_es = "Mientras lanzando escombros, salto"
rockjump_sc = "投掷时跳跃"
rockjump_tc = "投擲時跳躍"
rockjump_en = "While throwing rubble, jump"

rockaim_kr = "파편을 던질 표적을 수시로 변경"
rockaim_jp = "破片を投げる時にターゲットを引き続き変更"
rockaim_es = "Mientras lanzando escombros, cambiar de objetivo con frecuencia"
rockaim_sc = "投掷时更改目标"
rockaim_tc = "投擲時更改目標"
rockaim_en = "While throwing rubble, change target frequently"

rock_kr = "파편 던지기 정확도 조정"
rock_jp = "破片を投げる精度を調整"
rock_es = "Mientras lanzando escombros, ajusta la trayectoria"
rock_sc = "投掷精度调整"
rock_tc = "投擲精度調整"
rock_en = "While throwing rubble, adjust the trajectory"

block_kr = "사다리를 이용한 탱크 블로킹 파훼"
block_jp = "はしごを使ったブロッキングを突破"
block_es = "Romper el bloqueo de la escalera"
block_sc = "突破梯子封锁"
block_tc = "突破梯子封鎖"
block_en = "Break through ladder blocking"

dmg_kr = "탱크가 입는 피해량 조정"
dmg_jp = "Tankが受けるダメージの調整"
dmg_es = "Ajusta el daño que recibe el tank"
dmg_sc = "调整Tank受到的伤害"//간체
dmg_tc = "調整Tank受到的傷害"//번체
dmg_en = "Adjust of damage the tank takes"

	function lang(l){
		switch(l){
			case "korean":case "koreana":return "kr";
			case "japanese":return "jp";
			case "spanish":return "es";
			case "schinese":return "sc";
			case "tchinese":return "tc";
			default:return "en";
		}
	}
}

::manacat_tank<-{
	debug = false
	spawned = false
	kkangList = []
	door_pound = 0 //은신처 문을 3번 두드리면 강제로 열린다
	door_pound_time = 0 //탱크가 은신처 문을 두드린 시간, 갱신 텀은 1초
	door_pound_hint = null //게임교사 힌트메시지가 존재하지 않고 있다면 null

	codeLen = 12
	codeTable = [	"ladder", "speed_ladder"
					"burn", "speed_burn"
					"door", "breaching"
					"prop", "hittable"
					"incap", "incap_fly"
					"pound", "incap_pound"
					"punchjump", "punch_jump"
					"punchrock", "punch_rock"
					"rockjump", "rock_jump"
					"rock", "rock_trajectory"
					"rockaim", "rock_aim"
					"block", "block_ignore"]
					//"dmg", "dmg_adjust"]
	speed_ladder = true //구현함
	speed_burn = true //구현함
	punch_jump = true //구현함
	punch_rock = true //구현함
	rock_jump = true //구현함
	rock_trajectory = true //구현함
	rock_aim = true //구현함
	breaching = true //미묘하게 구현됨
	hittable = true //구현함
	incap_fly = true //구현함
	incap_pound = true //구현함
	block_ignore = true //구현함
	dmg_adjust = true
/*
	function OnGameEvent_player_say(params){
		local chat = params.text.tolower();
		local player = GetPlayerFromUserID(params.userid);
		local host = GetListenServerHost();

		chat = split( chat, " " );
		local len = chat.len();
		if(len == 1){
			if(chat[0] == "!tank"){
				local loc = ::manacat_tank_lang.lang(Convars.GetClientConvarValue("cl_language", player.GetEntityIndex()));
				local msg = ::manacat_tank_lang["set_"+loc];
				ClientPrint(player, 5, "MANACAT TANK: \x01"+msg);
				for(local i = 0; i < ::manacat_tank.codeLen; i++){
					if(::manacat_tank.codeTable[i*2+1] in ::manacat_tank && ::manacat_tank[::manacat_tank.codeTable[i*2+1]]){
						msg = "\x05✔";
					}else{
						msg = "\x04✖";
					}
					if(player == host)	msg += "\x01  !tank " + ::manacat_tank.codeTable[i*2] + " | " + ::manacat_tank_lang[::manacat_tank.codeTable[i*2]+"_"+loc];
					else				msg += "\x01  | " + ::manacat_tank_lang[::manacat_tank.codeTable[i*2]+"_"+loc];
					ClientPrint(player, 5, msg);
				}
			}
		}else if(len == 2){
			if(chat[0] == "!tank"){
				for(local i = 0; i < ::manacat_tank.codeLen; i++){
					if(chat[1] == ::manacat_tank.codeTable[i*2] && player == host){
						::manacat_tank.settings(chat[1], player);break;
					}
				}
			}
		}
	}
*/
	function settings(cmd, p){
		local loc = ::manacat_tank_lang.lang(Convars.GetClientConvarValue("cl_language", p.GetEntityIndex()));
		local msg = "";
		for(local i = 0; i < ::manacat_tank.codeLen; i++){
			if(cmd == ::manacat_tank.codeTable[i*2]){
				::manacat_tank[::manacat_tank.codeTable[i*2+1]] = !::manacat_tank[::manacat_tank.codeTable[i*2+1]];
				if(::manacat_tank[::manacat_tank.codeTable[i*2+1]])	msg = "\x01✖ → \x05✔";
				else							msg = "\x01✔ → \x04✖";
				ClientPrint(p, 5, "MANACAT TANK: \x01"+::manacat_tank_lang[cmd+"_"+loc]+" : "+msg);
			}
		}
		if(::manacat_tank.hittable)	Convars.SetValue("tank_swing_physics_prop_force",0);
		else						Convars.SetValue("tank_swing_physics_prop_force",4.0);
		local set = ::MANACAT.tank.ver+"|";
		for(local i = 0; i < ::manacat_tank.codeLen; i++){
			if(::manacat_tank[::manacat_tank.codeTable[i*2+1]])set += ::manacat_tank.codeTable[i*2+1]+"|";
		}
		StringToFile("rpp/manacat_tank/ai_settings.txt", set);
	}

	function OnGameEvent_round_start_post_nav(params){
		local vars = FileToString("rpp/manacat_tank/ai_settings.txt");
		local load = true;
		if(vars != null){
			vars = split(vars, "|");
			if(vars[0].tointeger() < ::MANACAT.tank.ver)load = false;
		}
		if(vars == null || !load){
			vars = ::MANACAT.tank.ver+"|";
			for(local i = 0; i < ::manacat_tank.codeLen; i++){
				vars += ::manacat_tank.codeTable[i*2+1]+"|";
			}
			StringToFile("rpp/manacat_tank/ai_settings.txt", vars);
			vars = split(vars, "|");
		}
		foreach(parse in vars){
			for(local i = 0; i < ::manacat_tank.codeLen; i++){
				if(parse == ::manacat_tank.codeTable[i*2+1])::manacat_tank[::manacat_tank.codeTable[i*2+1]] = true;
			}
		}

		for(local player = null; (player = Entities.FindByClassname(player, "player")) != null && player.IsValid();){
			if(NetProps.GetPropInt( player, "m_iTeamNum" ) != 2)continue;
			NetProps.SetPropIntArray(player, "m_NetGestureSequence", player.LookupSequence(""), 5);
			NetProps.SetPropIntArray(player, "m_NetGestureActivity", player.LookupActivity(""), 5);
			NetProps.SetPropFloatArray(player, "m_NetGestureStartTime", 0, 5);
			NetProps.SetPropIntArray(player, "m_NetGestureSequence", player.LookupSequence(""), 6);
			NetProps.SetPropIntArray(player, "m_NetGestureActivity", player.LookupActivity(""), 6);
			NetProps.SetPropFloatArray(player, "m_NetGestureStartTime", 0, 6);
		}

	}

	function punchDmg(){
		switch(Convars.GetStr("z_difficulty").tolower()){
			case "easy":case "normal":return 24;
			case "hard":return 33;
			case "impossible":return 100;
		}
	}

	function damage_adjust(tank, attacker, dmg, dmg_type){
		if(tank == null || !tank.IsValid() || tank.IsDead() || tank.IsIncapacitated())return;
		if(attacker == null || !attacker.IsValid())return;
		if(dmg_type == "prop_physics"){//모두 회복
		}/*else if(dmg_type == "grenade_launcher_projectile"){
			if(dmg > 125){
				dmg_restore = dmg-125;
				dmg_restore /= 4;
				dmg_restore += 125;
				dmg_restore = dmg-dmg_restore;
			}
		}*/else{
			local scrScope = tank.GetScriptScope();
			scrScope.health_limit;
			printl(dmg_type);
			if(dmg_type == "melee"){
				dmg = scrScope.health_limit/20;
				printl(dmg);
			}else if(dmg_type == "prop_minigun"){
				dmg = 5;
			}else if(dmg_type == "prop_minigun_l4d1"){
				dmg = 4;
			}
			local activity = tank.GetSequenceActivityName(tank.GetSequence());
			if(activity == "ACT_TANK_OVERHEAD_THROW" || activity == "ACT_TERROR_RAGE_AT_KNOCKDOWN"){
				dmg -= dmg/2;
			}else if(activity == "ACT_CLIMB_UP" || activity == "ACT_CLIMB_DOWN" || activity == "ACT_CLIMB_DISMOUNT"
				|| activity == "ACT_TERROR_CLIMB_36_FROM_STAND" || activity == "ACT_TERROR_CLIMB_38_FROM_STAND" || activity == "ACT_TERROR_CLIMB_50_FROM_STAND" || activity == "ACT_TERROR_CLIMB_70_FROM_STAND"
				|| activity == "ACT_TERROR_CLIMB_115_FROM_STAND" || activity == "ACT_TERROR_CLIMB_130_FROM_STAND" || activity == "ACT_TERROR_CLIMB_150_FROM_STAND" || activity == "ACT_TERROR_CLIMB_166_FROM_STAND"){
				dmg -= dmg/4;
			}
			local dist = (attacker.GetOrigin() - tank.GetOrigin()).Length();
			if(dist > 350){
				dist -= 350;
				if(dist > 500)dist = 500;
				dmg -= (dmg/200)*(100/(500/dist));
			}
		}
		if(dmg != 0){
			local scrScope;
			if(tank != attacker){
				attacker.ValidateScriptScope();
				scrScope = attacker.GetScriptScope();
				printl(scrScope.DamageToTank);
				scrScope.DamageToTank += dmg;
				printl("내 딜 정정" + NetProps.GetPropInt( attacker, "m_checkpointDamageToTank") + "->" + scrScope.DamageToTank);
				NetProps.SetPropInt( attacker, "m_checkpointDamageToTank", scrScope.DamageToTank);
				printl("와이? "+NetProps.GetPropInt( attacker, "m_checkpointDamageToTank"));
			}
			scrScope = tank.GetScriptScope();
			scrScope.health_current -= dmg;
			if(scrScope.health_current <= 0){
				tank.TakeDamage(NetProps.GetPropInt( tank, "m_iHealth" ), 129, tank);
			}else{
				NetProps.SetPropInt( tank, "m_iHealth", 65535 );
			}
		}
	}

	function OnGameEvent_player_hurt(params){
		local victim = GetPlayerFromUserID(params.userid);
		local attacker = GetPlayerFromUserID(params.attacker);
		if("GetZombieType" in victim && "weapon" in params){
			local ztype = victim.GetZombieType();
			if(ztype==8){			
				if(params.weapon == "tank_rock"){
					victim.SetHealth(victim.GetHealth()+params.dmg_health);
					for(local rock = null; (rock = Entities.FindByClassname(rock, "tank_rock")) != null && rock.IsValid();){
						local pos = rock.GetOrigin();
						local breaker = SpawnEntityFromTable("prop_dynamic",
						{
							model = "models/props/de_nuke/crate_extralarge.mdl"
							origin = pos
							angles = Vector(0, 0, 0)
							solid = "6"
							rendermode = "1"
							renderamt = "0"
						});
						DoEntFire("!self", "Kill", "", 0.002, null, breaker);
					}
				}else if(params.weapon == "melee" || params.weapon == "chainsaw"){
					if(NetProps.GetPropFloatArray( victim.GetActiveWeapon(), "m_flNextPrimaryAttack", 0) < Time())return;
					local attacker = GetPlayerFromUserID(params.attacker);
					CommandABot( { cmd = 0, target = attacker, bot = victim } );
					local viewAngle = ::manacat_tank.SI_control_eye({si = victim, tgVector = attacker.EyePosition()});
					victim.SnapEyeAngles(viewAngle);
				}
				//if(::manacat_tank.dmg_adjust)::manacat_tank.damage_adjust(victim, attacker, params.dmg_health, params.weapon);
			}else if(ztype==9 && params.weapon == "tank_claw"){
				local tank = GetPlayerFromUserID(params.attacker);
				local scrScope = tank.GetScriptScope();
				scrScope.hitTarget <- victim;
				if(Time() > scrScope.hitTime+1){
					scrScope.hitTime <- Time();
					scrScope.hitSplash <- [];
				}
				local splashlen = scrScope.hitSplash.len();
				for(local i = 0; i < splashlen; i++)if(victim == scrScope.hitSplash[i])return;//이미 펀치 피해 받았으므로 중복피해 취소

				local survs = [];	local survsidx = 0;
				for(local player = null; (player = Entities.FindByClassname(player, "player")) != null && player.IsValid();){
					if(player == victim || player.IsDead() || player.IsIncapacitated() || player.IsDominatedBySpecialInfected()
					|| NetProps.GetPropInt( player, "m_iTeamNum" ) != 2)continue;
					survs.append([player, player.GetOrigin()+Vector(0, 0, 40)]);
				//	DebugDrawBoxAngles(player.GetOrigin()+Vector(0, 0, 40), Vector(-10,-10,-10), Vector(10,10,10), QAngle(0, 0, 0), Vector(255, 0, 255), 64, 1.0);
					survsidx++;
				}
				
				local tankPunch = attacker.GetActiveWeapon();	local tankOrigin = tank.GetOrigin();	local tankdmg = ::manacat_tank.punchDmg();

				if(victim.IsIncapacitated() && ::manacat_tank.incap_pound){
					for(local i = 0; i < survsidx; i++){
						if(survs[i][0].IsDead() || survs[i][0].IsIncapacitated()
						|| NetProps.GetPropInt( survs[i][0], "m_iTeamNum" ) != 2)continue;
						local dist = (survs[i][0].GetOrigin() - tankOrigin).Length();			//탱크와의 거리
						local dist2 = (survs[i][0].GetOrigin() - victim.GetOrigin()).Length();	//피해자와의 거리
						if(dist <= 125 && dist2 <= 85){
							scrScope.hitSplash.append(survs[i][0]);
							::manacat_tank.tank_punch_knockback(attacker, survs[i][0], 0);
							survs[i][0].TakeDamageEx(tankPunch, attacker, tankPunch, tankOrigin, tankOrigin, tankdmg, 129);
							survs[i][0] = null;		survs[i][1] = null;
						}
					}
				}
				//DebugDrawBoxAngles(tank.EyePosition(), Vector(-10,-10,-10), Vector(10,10,10), QAngle(0, 0, 0), Vector(255, 0, 255), 64, 5.0);
				local attackpos = tank.EyePosition();	local attackang = tank.EyeAngles();
				
				local attackp = [];
				for(local i = 0; i < 5; i++){
					attackp.append(attackpos+(attackang+QAngle(0, 25*(i-2), 0)).Forward().Scale(30));
				//	DebugDrawBoxAngles(attackpos+(attackang+QAngle(0, 25*(i-2), 0)).Forward().Scale(30), Vector(-10,-10,-10), Vector(10,10,10), attackang+QAngle(0, 15*(i-2), 0), Vector(255, 0, 255), 64, 0.2);
				}
				for(local i = 0; i < survsidx; i++){
					if(survs[i][0] == null)continue;
					local hit = false;
					for(local j = 0; j < 5; j++){
						if(!hit){
							if((survs[i][1] - attackp[j]).Length() < 50){
								scrScope.hitSplash.append(survs[i][0]);
								::manacat_tank.tank_punch_knockback(attacker, survs[i][0], 1);
								survs[i][0].TakeDamageEx(tankPunch, attacker, tankPunch, tankOrigin, tankOrigin, tankdmg, 129);
								hit = true;
								break;
							}
						}
					}
				}
				return;
			}
		}
	}

	function tank_punch_knockback(tank, player, punchtype = 0){
		local invTable = {};
		GetInvTable( player, invTable );
		if ( "slot0" in invTable )
			NetProps.SetPropEntity( invTable["slot0"], "m_hOwner", null );
		if ( "slot1" in invTable )
			NetProps.SetPropEntity( invTable["slot1"], "m_hOwner", null );
		if ( "slot2" in invTable )
			NetProps.SetPropEntity( invTable["slot2"], "m_hOwner", null );
		if ( "slot3" in invTable )
			NetProps.SetPropEntity( invTable["slot3"], "m_hOwner", null );
		if ( "slot4" in invTable )
			NetProps.SetPropEntity( invTable["slot4"], "m_hOwner", null );
		if ( "slot5" in invTable )
			player.DropItem(invTable["slot5"].GetClassname());

		local viewmodel;	local weaponModel = 0;
		while (viewmodel = Entities.FindByClassname(viewmodel, "predicted_viewmodel")){
			if(viewmodel.IsValid() && NetProps.GetPropEntityArray( viewmodel, "m_hOwner", 0 ) == player){
				weaponModel = NetProps.GetPropIntArray( viewmodel, "m_nModelIndex", 0 );
				NetProps.SetPropIntArray( viewmodel, "m_hWeapon", 0, 0 );
				NetProps.SetPropIntArray( viewmodel, "m_nModelIndex", 0, 0 );
			}
		}

		local game_ui = SpawnEntityFromTable("game_ui",
		{
			FieldOfView = "-1.0"
			spawnflags = "32"
		});
		DoEntFire("!self", "Activate", "", 0.0, player, game_ui);
		DoEntFire("!self", "PlayerOff", "", 0.0, player, game_ui);
		
		::manacatAddTimer(0.2, false, ::manacat_tank.tank_punch_knockback_stop, { tgp = player, tgui = game_ui });

		NetProps.SetPropIntArray(player, "m_NetGestureSequence", player.LookupSequence("ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH"), 5);
		NetProps.SetPropIntArray(player, "m_NetGestureActivity", player.LookupActivity("ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH"), 5);
		NetProps.SetPropFloatArray(player, "m_NetGestureStartTime", Time(), 5);

		local impulseVec = ::manacat_tank.SI_control_eye({si = player, tgVector = tank.GetOrigin()});
		if(punchtype == 0){//쓰러진 사람 주변 스플
			impulseVec = impulseVec.Forward().Scale(-520);
			impulseVec.z = 265;
		}else{//통상펀치 주변 스플
			impulseVec = impulseVec.Forward().Scale(-800);
			impulseVec.z = 265;
		}

		player.SetVelocity(Vector(0, 0, 0));
		player.ApplyAbsVelocityImpulse(impulseVec);
	}

	function tank_punch_knockback_stop(params){
		local flag = NetProps.GetPropInt(params.tgp,"m_fFlags");
		local isOnGround = flag == ( flag | 1 );

		if(isOnGround){
			if("ground" in params){
				if(params.tgp.IsIncapacitated()){
					NetProps.SetPropIntArray(params.tgp, "m_NetGestureSequence", params.tgp.LookupSequence("ACT_DIESIMPLE"), 6);
					NetProps.SetPropIntArray(params.tgp, "m_NetGestureActivity", params.tgp.LookupActivity("ACT_DIESIMPLE"), 6);
					NetProps.SetPropFloatArray(params.tgp, "m_NetGestureStartTime", Time(), 6);
				}
				DoEntFire("!self", "Deactivate", "", 0.0, params.tgp, params.tgui);
				DoEntFire("!self", "Kill", "", 0.0, null, params.tgui);

				//params.tgp.SetModel(params.tgp.GetModelName());

				local game_ui = SpawnEntityFromTable("game_ui",
				{
					FieldOfView = "-1.0"
					spawnflags = "96"
				});
				DoEntFire("!self", "Activate", "", 0.0, params.tgp, game_ui);
				DoEntFire("!self", "PlayerOff", "", 0.0, params.tgp, game_ui);
				DoEntFire("!self", "Deactivate", "", 0.0, params.tgp, game_ui);
				DoEntFire("!self", "Kill", "", 0.0, null, game_ui);
				local invTable = {};
				GetInvTable( params.tgp, invTable );
				if ( "slot0" in invTable )
					NetProps.SetPropEntity( invTable["slot0"], "m_hOwner", params.tgp );
				if ( "slot1" in invTable )
					NetProps.SetPropEntity( invTable["slot1"], "m_hOwner", params.tgp );
				if ( "slot2" in invTable )
					NetProps.SetPropEntity( invTable["slot2"], "m_hOwner", params.tgp );
				if ( "slot3" in invTable )
					NetProps.SetPropEntity( invTable["slot3"], "m_hOwner", params.tgp );
				if ( "slot4" in invTable )
					NetProps.SetPropEntity( invTable["slot4"], "m_hOwner", params.tgp );
			}else{
				NetProps.SetPropIntArray(params.tgp, "m_NetGestureSequence", params.tgp.LookupSequence("ACT_TERROR_TANKPUNCH_LAND"), 5);
				NetProps.SetPropIntArray(params.tgp, "m_NetGestureActivity", params.tgp.LookupActivity("ACT_TERROR_TANKPUNCH_LAND"), 5);
				NetProps.SetPropFloatArray(params.tgp, "m_NetGestureStartTime", 0, 5);
				EmitSoundOnClient("Player.JumpLand", params.tgp)
				params.ground <- true;
				::manacatAddTimer(1.2, false, ::manacat_tank.tank_punch_knockback_stop, params);
			}
		}else{
			::manacatAddTimer(0.1, false, ::manacat_tank.tank_punch_knockback_stop, params);
		}
	}

	function OnGameEvent_player_incapacitated(params){
		if(::manacat_tank.incap_fly){
			local player = GetPlayerFromUserID(params.userid);
			if("weapon" in params){
				local weapon = params.weapon;
				if(weapon == "tank_claw"){
					local attacker = GetPlayerFromUserID(params.attacker);
				//	::manacat_tank.player.append([attacker, player])
					local eyeVector = player.EyePosition();

					local vector = attacker.EyePosition() - eyeVector;
					local qy = Quaternion();	local qx = Quaternion();
					qy.SetPitchYawRoll(0, 90-atan2(vector.x, vector.y)*180/PI, 0);
					qx.SetPitchYawRoll(atan2(vector.z, sqrt(vector.x*vector.x+vector.y*vector.y))*-180/PI, 0, 0);
					local qr = Quaternion(
						qy.x*qx.x - qy.y*qx.y - qy.z*qx.z - qy.w*qx.w,
						qy.x*qx.y + qy.y*qx.x + qy.z*qx.w - qy.w*qx.z,
						qy.x*qx.z - qy.y*qx.w + qy.z*qx.x + qy.w*qx.y,
						qy.x*qx.w + qy.y*qx.z + qy.z*qx.y + qy.w*qx.x
					).ToQAngle();

					local impulseVec = QAngle(qr.x, qr.y*-1, 0);
					impulseVec = impulseVec.Forward().Scale(-800);
					impulseVec.z = 265;

					player.SetVelocity(Vector(0, 0, 0));
					player.ApplyAbsVelocityImpulse(impulseVec);
				}
			}
		}
	}

	function OnGameEvent_tank_spawn(params){
		::manacat_tank.kkangList <- [];
		if(::manacat_tank.hittable)	Convars.SetValue("tank_swing_physics_prop_force",0);
		else						Convars.SetValue("tank_swing_physics_prop_force",4.0);
		local tank = GetPlayerFromUserID(params.userid);
		tank.ValidateScriptScope();
		local scrScope = tank.GetScriptScope();
		scrScope.ThrowTime <- 0;//돌 던진 시간
		scrScope.ThrowTimeNext <- 0;//다음 돌 던질 시간
		scrScope.PunchCooltime <- false;//펀치 쿨타임중인지
		scrScope.hitTarget <- null;//때리기 성공한 타겟
		scrScope.hitSplash <- [];//때린 타겟 주변의 스플래시 타겟
		scrScope.hitTime <- 0;//때리기 성공한 시간
		scrScope.ThrowTarget <- null;//돌 던질 타겟
		scrScope.ThrowPose <- 0;//돌 던지는 모션
		scrScope.Retreat <- false;//헛방치고 후퇴중인지
		scrScope.ledgeJump <- 0;//난간을 넘으려고 점프한 시간

		/*dmg_adjust
		local mode = Convars.GetStr("mp_gamemode").tolower();
		if(mode == "survival"){
			scrScope.health_limit <- 4000;	scrScope.health_current <- 4000;
		}else if(mode == "versus" || mode == "mutation12" || mode == "tankrun"){
			scrScope.health_limit <- 6000;	scrScope.health_current <- 6000;
		}else{
			mode = Convars.GetStr("z_difficulty").tolower();
			if(mode == "easy"){
				scrScope.health_limit <- 3000;	scrScope.health_current <- 3000;
			}else if(mode == "normal"){
				scrScope.health_limit <- 4000;	scrScope.health_current <- 4000;
			}else{
				scrScope.health_limit <- 8000;	scrScope.health_current <- 8000;
			}
		}
		NetProps.SetPropInt( tank, "m_iMaxHealth", 65535 );
		NetProps.SetPropInt( tank, "m_iHealth", 65535 );
		*/
		::manacatAddTimer(0.1, false, ::manacat_tank.control, { si = tank });

		if(!::manacat_tank.spawned){
			::manacat_tank.spawned = true;
			local player = null;
			while (player = Entities.FindByClassname(player, "player")){
				if(NetProps.GetPropInt( player, "m_iTeamNum" ) == 2){
					player.ValidateScriptScope();
					local scrScope = player.GetScriptScope();
					scrScope.DamageToTank <- 0;
				//	NetProps.SetPropInt( player, "m_checkpointDamageToTank", 0);
				}
			}
		}
	}

	function control(params){
		if(params.si.IsValid() && !params.si.IsDead() && !params.si.IsIncapacitated()){
			if(!IsPlayerABot(params.si)){
				printl("<MANACAT> Since the tank player("+params.si+") is human, AI is disabled.");
				return;
			}
			::manacatAddTimer(0.1, false, ::manacat_tank.control, params);
			if(params.si.GetHealth()==1){
				params.si.TakeDamage(1, 129, params.si);
				return;
			}
			local scrScope = params.si.GetScriptScope();

			local origin = params.si.GetOrigin();		local mindist = 99999;
			/*local player = null;
			while (player = Entities.FindByClassname(player, "player")){
				if(!player.IsValid() || player.IsDead())continue;
				local dist = (player.GetOrigin() - origin).Length();
				if(dist < mindist)	mindist = dist;
			}*/

			local nearSurv = ::manacat_tank.findNearSurv({from = params.si, visible = true, noincap = true});
			local nearDist = nearSurv[1];	local nearVisible = nearSurv[2];	local mindist = nearSurv[3];	nearSurv = nearSurv[0];
			if(nearSurv == null || !nearSurv.IsValid())return;

			local aggro = Director.IsTankInPlay();
			local siSeq = NetProps.GetPropInt( params.si, "m_nSequence");
			local activity = params.si.GetSequenceActivityName(params.si.GetSequence());
			local movetype = NetProps.GetPropInt( params.si, "movetype");
		//	printl(" 시퀀스 "+siSeq);
			//printl(params.si.GetActiveWeapon().SetNetProp("m_flNextPrimaryAttack", Time() + 2.0);)

			/*//탱크 투석지점 예상
			local rockOrigin = params.si.EyePosition();
			local rockDist = (params.si.EyePosition() - nearSurv.GetOrigin()).Length();
			local targetPos = nearSurv.EyePosition()+nearSurv.GetVelocity().Scale(0.4)+Vector(0,0,rockDist/6.2);
			local tankViewAngle = ::manacat_tank.SI_control_eye({si = params.si, tgVector = targetPos});
			tankViewAngle.z += rockDist/400;
			local newForce = tankViewAngle.Forward().Scale(800);
			DebugDrawLine(rockOrigin, rockOrigin+newForce, 255, 0, 0, true, 0.1);
			DebugDrawBox(targetPos, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 0.1);
			*/

			//사다리에 매달려있는채로 머리 위에 있으면 그냥 밀어내면서 올라가기
			if(::manacat_tank.block_ignore){
				if("ladder_chase" in params){
					if(params.ladder_chase == null || !params.ladder_chase.IsValid() || params.ladder_chase.IsDead()
					|| params.ladder_chase.IsIncapacitated() || params.ladder_chase.IsDominatedBySpecialInfected()
					|| NetProps.GetPropInt( params.ladder_chase, "movetype") != 9){
						params.rawdelete("ladder_chase");
						CommandABot( { cmd = 0, target = nearSurv, bot = params.si } );
					}
					return;
				}else{
					if(NetProps.GetPropInt( nearSurv, "movetype") == 9){
						if(::manacat_tank.visionCheck(params.si, nearSurv.EyePosition(), nearSurv, 15, params.si.GetAngles().Up())){
							local tankground = NavMesh.GetNearestNavArea(origin, 150.0, true, true);
							if(tankground != null){
								local tankladder = {}
								for(local i = 0; i < 4; i++){
									tankground.GetLadders(i, tankladder);
									if(tankladder.len() != 0){
										foreach(ladder in tankladder){
											local top = NavMesh.GetNearestNavArea(ladder.GetTopOrigin(), 150.0, true, true);
											if(top != null){
												CommandABot( { cmd = 1, pos = top.GetCenter(), bot = params.si } );
												params.ladder_chase <- nearSurv;
												return;
											}
										}
									}
								}
							}
							return;
						}
					}
				}
			}

			//사다리탈때 주변에 있으면 밀어내기
			if(movetype == 9)::manacat_tank.tank_ladder_push(params.si);

			//위치 갱신
			local currentTime = Time();
			if(aggro && ::manacat_tank.GetTankThrowTime(params.si)[0]+5 < currentTime){
				if(!("originArray" in params)){
					params.originArray <- [origin];
					params.originRecord <- 0;
				}else{
					if(params.originRecord < 5){
						params.originRecord++;
					}else{
						params.originRecord = 0;
						params.originArray.insert(0, origin);
						local len = params.originArray.len();
						if(len > 4)params.originArray.pop();	len--;
						local stuck = 0;
						for(local i = 1; i < len; i++){
							local dist = (params.originArray[0]-params.originArray[i]).Length();
							if(dist < 15)stuck++;
						}
						if(stuck >= 3){
							//위치가 그대로면 점프펀치 한번 날리고 주변 장애물 제거
							NetProps.SetPropIntArray( params.si, "m_afButtonForced", 3, 0);
							local ent = null;
							while (ent = Entities.FindByClassname(ent, "prop_physics")){
								if(ent != null && ent.IsValid() && (ent.GetOrigin()-params.originArray[0]).Length() < 80){
									ent.TakeDamage(100, 128, params.si);
								}
							}
							while (ent = Entities.FindByClassname(ent, "func_breakable")){
								if(ent != null && ent.IsValid() && (ent.GetOrigin()-params.originArray[0]).Length() < 300){
									DoEntFire("!self", "break", "", 0.0, null, ent);
								}
							}
							return;
						}else{
							local key = (NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0) & ~3);
							NetProps.SetPropIntArray( params.si, "m_afButtonForced", key.tointeger(), 0);
						}
					}
				}
			}

			//징검다리 점프해서 건너기
			local vel = params.si.GetVelocity();
			local velNorm = Vector(vel.x, vel.y, vel.z);
			//velNorm.x -= origin.x;	velNorm.y -= origin.y;	velNorm.z -= origin.z;
			velNorm.x = velNorm.x/velNorm.Norm();
			velNorm.y = velNorm.y/velNorm.Norm();
			velNorm.z = velNorm.z/velNorm.Norm();
			if(velNorm.Length() > 0.9){
				local front = origin + Vector(0, 0, 30) + velNorm.Scale(0);//params.si.GetAngles().Forward().Scale(40);
				local front_trace = { start = front, end = front + Vector(0, 0, -1000), mask = 33579137 };
				local front2 = origin + Vector(0, 0, 30) + velNorm.Scale(45);//params.si.GetAngles().Forward().Scale(40);
				local front_trace2 = { start = front2, end = front2 + Vector(0, 0, -1000), mask = 33579137 };
				local front3 = origin + Vector(0, 0, 30) + velNorm.Scale(90);//params.si.GetAngles().Forward().Scale(40);
				local front_trace3 = { start = front3, end = front3 + Vector(0, 0, -1000), mask = 33579137 };
				local front_end = origin + Vector(0, 0, 30) + velNorm.Scale(135);//params.si.GetAngles().Forward().Scale(40);
				local front_trace_end = { start = front_end, end = front_end + Vector(0, 0, -1000), mask = 33579137 };
				local front_end2 = origin + Vector(0, 0, 30) + velNorm.Scale(180);//params.si.GetAngles().Forward().Scale(40);
				local front_trace_end2 = { start = front_end2, end = front_end2 + Vector(0, 0, -1000), mask = 33579137 };
				TraceLine(front_trace);
				TraceLine(front_trace2);
				TraceLine(front_trace3);
				TraceLine(front_trace_end);
				TraceLine(front_trace_end2);
				if(("hit" in front_trace && front_trace.hit) || ("hit" in front_trace2 && front_trace2.hit)){
					if(::manacat_tank.debug){
					//	DebugDrawBox(front, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 1.0);
						DebugDrawBox(front_trace.pos, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 0.2);
						DebugDrawBox(front_trace2.pos, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 0.2);
						DebugDrawBox(front_trace3.pos, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 0.2);
					//	DebugDrawBox(front_end, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 1.0);
						DebugDrawBox(front_trace_end.pos, Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 255, 0, 64, 0.2);
					}
					local front_bottom_len = (front-front_trace.pos).Length();
					local front_bottom_len2 = (front2-front_trace2.pos).Length();
					local front_bottom_len3 = (front3-front_trace3.pos).Length();
					local front_bottom_end_len = (front_end-front_trace_end.pos).Length();
					local front_bottom_end_len2 = (front_end2-front_trace_end2.pos).Length();
					if(front_bottom_len < front_bottom_len2)front_bottom_len = front_bottom_len2;
					if(front_bottom_len < front_bottom_len3)front_bottom_len = front_bottom_len3;
					if(front_bottom_end_len < front_bottom_end_len2)front_bottom_end_len = front_bottom_end_len2;
					local flag = NetProps.GetPropInt(params.si,"m_fFlags");
					local isOnGround = flag == ( flag | 1 );
					local key = NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0).tointeger();
					if(front_bottom_len > 60 && front_bottom_end_len < 40 && isOnGround && scrScope.ledgeJump+0.2 < currentTime && params.si.GetVelocity().Length() > 40 && ((key & ~2) == key)){//점프 안누르고 있음
					//	NetProps.SetPropIntArray( params.si, "m_afButtonForced", key+2, 0);//점프
						scrScope.ledgeJump <- currentTime;
						
						local impulseVec = ::manacat_tank.SI_control_eye({si = params.si, tgVector = origin+velNorm.Scale(105)});
						impulseVec = impulseVec.Forward().Scale(290);
						impulseVec.z = 285;

						params.si.SetVelocity(Vector(0, 0, 0));
						params.si.ApplyAbsVelocityImpulse(impulseVec);
					}//else{
					//	key = key & ~2;//점프 빼기
					//	NetProps.SetPropIntArray( params.si, "m_afButtonForced", key, 0);
					//}
				}
			}

			/*if(params.si.IsOnFire()){
				local waterside = ::manacat_tank.waterManage(params.si);
				if(waterside != null){
					CommandABot( { cmd = 1, pos = waterside, bot = params.si } );
				}
				//불에 타면 물로 들어가라고
			}*/

			local speed = 0;
			speed = 1.0;
			
			if(mindist > 700)									speed = 1.0+((mindist-700)/1000);

			if(speed > 1.5)speed = 1.5;
			
			if(movetype == 9 && ::manacat_tank.speed_ladder)														speed = 1.5;
			else if(movetype == 11 && speed < 2.5 &&
			(activity == "ACT_TERROR_CLIMB_36_FROM_STAND" || activity == "ACT_TERROR_CLIMB_38_FROM_STAND" || activity == "ACT_TERROR_CLIMB_50_FROM_STAND" || activity == "ACT_TERROR_CLIMB_70_FROM_STAND"
			|| activity == "ACT_TERROR_CLIMB_115_FROM_STAND" || activity == "ACT_TERROR_CLIMB_130_FROM_STAND" || activity == "ACT_TERROR_CLIMB_150_FROM_STAND" || activity == "ACT_TERROR_CLIMB_166_FROM_STAND"))
																					speed = 2.5;
			else if(params.si.IsOnFire() && ::manacat_tank.speed_burn && speed < 1.2)							speed = 1.2;
			else if(speed < 1.0)													speed = 1.0;

		//	printl("스피드 : "+speed + " 무브타입 : " + movetype + " 시퀀스 : " + siSeq);

			NetProps.SetPropFloatArray( params.si, "m_flLaggedMovementValue", speed, 0 );

			if(siSeq == 60){//시퀀스  60은 빨리감기 할 시 멈추므로
				params.si.SetSequence(54);
			}else if(activity == "ACT_TERROR_RAGE_AT_ENEMY" || activity == "ACT_TERROR_RAGE_AT_KNOCKDOWN"){//탱크 돌던지기 후 숨고르기, 시퀀스 54~57(에너미) / 58~60(넉다운)
				NetProps.SetPropFloatArray( params.si, "m_flCycle", 1000.0, 0);
			}

			local punch = false;	local attack = false;
			if(!attack){
				if(mindist < 90
				//&& ::manacat_tank.visionCheck(params.si, player.EyePosition(), player, 45)
				){
					punch = true;//	printl("펀치 발진" + (NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0) < Time()) + "  " + (::manacat_tank.GetTankThrowTime(params.si)[1] < Time()));
				//	printl("시간" + Time() + "  " + (NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0)) + "  " + (::manacat_tank.GetTankThrowTime(params.si)[1]));
					local viewAngle = ::manacat_tank.SI_control_eye({si = params.si, tgVector = nearSurv.EyePosition()});
					params.si.SnapEyeAngles(viewAngle);
				}

				if(punch && NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0) < Time()
				&& ::manacat_tank.GetTankThrowTime(params.si)[1] < Time()){
					if(::manacat_tank.punch_rock)	::manacat_tank.attack_start({si = params.si, attack = 2049});//점펀돌
					else							::manacat_tank.attack_start({si = params.si, attack = 1});//그냥 펀치
					attack = true;
				}
			}
			
			if(!attack && ::manacat_tank.hittable){
				//주변에 깡이 있으면 공격
				if(::manacat_tank.kkangListManage(params.si)){
					::manacat_tank.attack_start({si = params.si, attack = 1});
				}
			}
		}
	}

	function tank_ladder_push(tank){
		if(!tank.IsValid() || tank.IsDead() || tank.IsIncapacitated())return;

		local player = null;
		while (player = Entities.FindByClassname(player, "player")){
			if(!player.IsValid() || player.IsDead() || NetProps.GetPropInt( player, "m_iTeamNum" ) != 2
			|| player.IsIncapacitated() || player.IsDominatedBySpecialInfected()
			|| player.GetActiveWeapon() == null)continue;
			local dist = (player.GetOrigin() - tank.GetOrigin()).Length();
			if(dist < 65){
				local impulseVec = ::manacat_tank.SI_control_eye({si = player, tgVector = tank.GetOrigin()});
				impulseVec = impulseVec.Forward().Scale(-320);
				impulseVec.z = 100;

				player.SetVelocity(Vector(0, 0, 0));
				player.ApplyAbsVelocityImpulse(impulseVec);
			}
		}
	}

	function OnGameEvent_weapon_fire(params){
		if(params.weapon == "tank_claw"){
			local tank = GetPlayerFromUserID(params.userid);
			local tankOrigin = tank.GetOrigin();
			local front = tank.EyePosition() + tank.EyeAngles().Forward().Scale(25);
			local back = tankOrigin + tank.EyeAngles().Forward().Scale(-40);
			local normdoor = Entities.FindByClassnameNearest("prop_door_rotating", front, 45.0);
			if(normdoor != null && NetProps.GetPropInt( normdoor, "m_eDoorState" ) == 0){
				if(::manacat_tank.door_pound_time <= Time()){
					::manacat_tank.door_pound_time = Time()+1;
					local doorang = normdoor.GetAngles();	local fwd = doorang.Forward();
					local doorOrigin = normdoor.GetOrigin();
					local product = (tankOrigin.x - doorOrigin.x)*fwd.x
									+ (tankOrigin.y - doorOrigin.y)*fwd.y
									+ (tankOrigin.z - doorOrigin.z)*fwd.z;
					local dir = "0";
					if(product > 0.0)	dir = "2";
					else				dir = "1";

					::manacatAddTimer(1.0, false, ::manacat_tank.doorOpenFail, { door = normdoor, angle = doorang, opener = tank, dir = dir });
				}
			}
			if(::manacat_tank.breaching){
				local chkpdoor = Entities.FindByClassnameNearest("prop_door_rotating_checkpoint", front, 45.0);
				if(chkpdoor != null && NetProps.GetPropInt( chkpdoor, "m_eDoorState" ) == 0){
					::manacat_tank.door_open_try({chkpdoor = chkpdoor, back = back, openerPos = tankOrigin, opener = tank, tank = true});
					return;	//문을 두들기면 펀치 유효성을 체크하지 않는다 (헛방 후퇴하지 않는다)
				}
			}

			local siSeq = NetProps.GetPropIntArray( tank, "m_nSequence", 0);
			if(siSeq < 16 || 21 < siSeq){
				local scrScope = tank.GetScriptScope();
				if(scrScope.PunchCooltime == true)return;
				scrScope.PunchCooltime <- true;
				::manacatAddTimer(0.6, false, ::manacat_tank.punchCheck, { si = tank });
				::manacatAddTimer(1.0, false, ::manacat_tank.punchRemove, { si = tank });

				if(::manacat_tank.punch_jump){
					local speed = NetProps.GetPropFloatArray( tank, "m_flGroundSpeed", 0);
					if(speed > 150){
						local nearSurv = ::manacat_tank.findNearSurv({from = tank, visible = true, noincap = true});
						local nearDist = nearSurv[1];// nearSurv = nearSurv[0];
						if(nearDist < 160){
							local fv = tank.GetForwardVector();
							local fx = fv.x*(speed+5);		local fy = fv.y*(speed+5);
							local pushVec = Vector(fx,fy,255);

							tank.SetVelocity(pushVec);
						}
					}
				}
			}

			::manacatAddTimer(0.4, false, ::manacat_tank.punchObject, { tank = tank });
		}
	}

	function attack_start(params){
		local scrScope = params.si.GetScriptScope();
		if(NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0) < Time()
		&& scrScope.ThrowTimeNext < Time()){
			local chkPunchButton = NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0) == ( NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0) | params.attack );

			NetProps.SetPropIntArray( params.si, "m_afButtonForced", 0, 0);

		//	if(!::CanTraceToLocation(params.si, tgOri))return;
			if(!chkPunchButton){
				NetProps.SetPropIntArray( params.si, "m_afButtonForced", params.attack, 0); //1 = 펀치 2048 = 투석
			}
			::manacatAddTimer(0.1, false, ::manacat_tank.attack_end, params);
		}
	}

	function attack_end(params){
		local key = (NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0) & ~2049);
		NetProps.SetPropIntArray( params.si, "m_afButtonForced", key.tointeger(), 0);
	}

	function door_open_try(params){
		local chkpdoor = params.chkpdoor;
		local back = params.back;
		local openerPos = params.openerPos;
		if(::manacat_tank.door_pound_time <= Time()){//m_eDoorState = 0:닫힘 1:열리는중 2:열림 3:닫히는중
			::manacat_tank.door_pound_time = Time()+1;
			chkpdoor.__KeyValueFromString("spawnflags", "32768");
			::manacat_tank.door_pound++;
			local nav = NavMesh.GetNearestNavArea(back, 100.0, true, true);
			if(::manacat_tank.door_pound < 5 && nav != null && !nav.HasSpawnAttributes(2048)){
				local delay = 0.3;
				if(!params.tank)delay = 0.0;
				::manacatAddTimer(delay, false, ::manacat_tank.door_shake, {door = chkpdoor, origin = chkpdoor.GetOrigin(), angles = chkpdoor.GetAngles()});
				::manacatAddTimer(delay+0.2, false, ::manacat_tank.door_pound_sound, { door = chkpdoor });

				if(params.tank && (::manacat_tank.door_pound_hint == null || !::manacat_tank.door_pound_hint.IsValid())){
					::manacat_tank.hintView({chkpdoor = chkpdoor, tank = true});
				}
			}else{
				if(::manacat_tank.door_pound_hint != null && ::manacat_tank.door_pound_hint.IsValid())DoEntFire("!self", "Kill", "", 0.0, null, ::manacat_tank.door_pound_hint);
				local doorang = chkpdoor.GetAngles();	local fwd = doorang.Forward();
				local doorOrigin = chkpdoor.GetOrigin();
				local product = (openerPos.x - doorOrigin.x)*fwd.x
								+ (openerPos.y - doorOrigin.y)*fwd.y
								+ (openerPos.z - doorOrigin.z)*fwd.z;
				local dir = "0";
				chkpdoor.__KeyValueFromString("speed", "800");
				local open_f = NetProps.GetPropVector( chkpdoor, "m_angRotationOpenForward" );
				local open_b = NetProps.GetPropVector( chkpdoor, "m_angRotationOpenBack" );
				
				if(product > 0.0)	dir = "2";
				else				dir = "1";
				chkpdoor.__KeyValueFromString("opendir", dir);

				::manacatAddTimer(0.3, false, ::manacat_tank.doorOpen, { door = chkpdoor, open_f = open_f, open_b = open_b });
				open_f += Vector(0,-9,0);
				open_b += Vector(0,9,0);
				NetProps.SetPropVector( chkpdoor, "m_angRotationOpenForward", open_f);
				NetProps.SetPropVector( chkpdoor, "m_angRotationOpenBack", open_b);
				::manacatAddTimer(1.0, false, ::manacat_tank.doorOpenFail, { door = chkpdoor, angle = doorang, opener = params.opener, dir = dir });
			}
		}
	}

	function door_pound_sound(params){
		local doormodel = params.door.GetModelName();		local poundsound = "Breakable.MatMetal";
		if(doormodel == "models/lighthouse/checkpoint_door_lighthouse02.mdl"){
			poundsound = "WoodenDoor.Break";
		}
		EmitAmbientSoundOn("HulkZombie.Punch", 1.0, 350, 100, params.door);
		params.door.PrecacheScriptSound(poundsound);
		EmitAmbientSoundOn(poundsound, 1.0, 350, 100, params.door);
	}

	function doorOpen(params){
		::manacat_tank.door_pound_sound({door = params.door});
		::manacat_tank.door_pound = 0;
		DoEntFire("!self", "Open", "", 0.1, null, params.door);
		local doorOrigin = params.door.GetOrigin();
		
		::manacatAddTimer(0.1, false, ::manacat_tank.tank_punch_knockback_door, { door = params.door });
		::manacatAddTimer(3.0, false, ::manacat_tank.doorReset, { door = params.door, open_f = params.open_f, open_b = params.open_b });
	}

	function doorOpenFail(params){//탱크가 문을 두드려도 열리지 않으면 탱크를 문 앞으로 워프
		if(params.door == null || !params.door.IsValid() || params.opener == null || !params.opener.IsValid())return;
		local currentAngle = params.door.GetAngles()
		if(currentAngle.x == params.angle.x && currentAngle.y == params.angle.y && currentAngle.z == params.angle.z){
			local openerOrigin = params.opener.GetOrigin();
			local doorOrigin = params.door.GetOrigin();
			local doorang = params.door.GetAngles();	local fwd = doorang.Forward();

			local product = (openerOrigin.x - doorOrigin.x)*fwd.x
							+ (openerOrigin.y - doorOrigin.y)*fwd.y
							+ (openerOrigin.z - doorOrigin.z)*fwd.z;
			
			local warpOrigin = doorOrigin + currentAngle.Left().Scale(-27);
			warpOrigin.z = openerOrigin.z;

			if(product > 0.0)	params.opener.SetOrigin(warpOrigin + params.angle.Forward().Scale(-30));
			else				params.opener.SetOrigin(warpOrigin + params.angle.Forward().Scale(30));
		}
	}

	function tank_punch_knockback_door(params){
		if(params.door == null || !params.door.IsValid())return;
		local doorOrigin = params.door.GetOrigin() + params.door.GetAngles().Left().Scale(-25) + Vector(0,0,-25);
	//	printl(doorOrigin);
		local player = null;
		while (player = Entities.FindByClassname(player, "player")){
			if(!player.IsValid() || player.IsDead() || player.IsIncapacitated() || NetProps.GetPropInt( player, "m_iTeamNum" ) != 2)continue;
			local dist = (player.GetOrigin() - doorOrigin).Length();
			if(dist < 90){
				player.Stagger(doorOrigin);
			}
		}
	}

	function doorReset(params){
		if(params.door == null || !params.door.IsValid())return;
		params.door.__KeyValueFromString("opendir", "0");
		params.door.__KeyValueFromString("speed", "200");
		params.door.__KeyValueFromString("spawnflags", "8192");
		NetProps.SetPropFloat( params.door, "m_flDistance", 90.0);
		NetProps.SetPropVector( params.door, "m_angRotationOpenForward", params.open_f);
		NetProps.SetPropVector( params.door, "m_angRotationOpenBack", params.open_b);
	}

	function door_shake(params){//문이 흔들리는 효과
		if(!("repeat" in params)){
			params.repeat <- 0;
			params.oriF <- 0.4-(RandomInt(0,1)*0.8);
			params.oriL <- 0.45-(RandomInt(0,1)*0.9);
			params.angY <- 2-(RandomInt(0,1)*4);
			params.angZ <- 0.5-(RandomInt(0,1)*1.0);
		}else{
			params.repeat++;
			local n = ((6.0-params.repeat)/6.0);
			if(params.repeat == 1 || params.repeat == 3 || params.repeat == 5){
				params.door.SetOrigin(params.origin+params.door.GetAngles().Forward().Scale(params.oriF*n)+params.door.GetAngles().Left().Scale(-1*params.oriL*n));
				params.door.SetAngles(params.angles+QAngle(0,params.angY*n,-1*params.angZ*n));
			}else if(params.repeat == 2 || params.repeat == 4 || params.repeat == 6){
				params.door.SetOrigin(params.origin+params.door.GetAngles().Forward().Scale(-1*params.oriF*n)+params.door.GetAngles().Left().Scale(params.oriL*n));
				params.door.SetAngles(params.angles+QAngle(0,-1*params.angY*n,params.angZ*n));
			}else{
				params.door.SetOrigin(params.origin);
				params.door.SetAngles(params.angles);
				params.door.__KeyValueFromString("spawnflags", "8192");
				return;
			}
		}
		::manacatAddTimer(0.02, false, ::manacat_tank.door_shake, params);
	}

	function hintView(params){
		local chkpdoor = params.chkpdoor;
		local tank = params.tank;
		local tgname =  "hdmd_hint_tank_door";
		local hintpoint = {
			classname = "info_target_instructor_hint",
			targetname = tgname,
			origin = chkpdoor.GetOrigin() + chkpdoor.GetAngles().Left().Scale(-26)// + Vector(0,0,-25)
		};

	//	DebugDrawBox(chkpdoor.GetOrigin() + chkpdoor.GetAngles().Left().Scale(-26), Vector(-3.0,-3.0,-3.0), Vector(3.0,3.0,3.0), 255, 0, 0, 64, 5.0);

		local doorname = "";
		local msg = [];
		local hint_pos = "0";
		::manacat_tank.door_pound_hint = g_ModeScript.CreateSingleSimpleEntityFromTable(hintpoint);
		doorname = ::manacat_tank.door_pound_hint.GetName();
		msg = [
			"The tank is hitting the door! Be prepared for invasion.", 
			"탱크가 문을 두드리고 있습니다! 침입에 대비하십시오.",
			"タンクがドアを叩いています！ 侵入に備えてください。",
			"¡El Tank está golpeando la puerta! Prepárense para invadir."
			"一辆坦克车正在敲击安全屋的门！ 做好入侵的准备。"
			"一輛坦克車正在敲擊安全屋的門！ 做好入侵的準備。"];

		local playerLangList = [[],[],[],[]];
		local hintList = [null,null,null,null];
		local listener = null;
		while (listener = Entities.FindByClassname(listener, "player")){
			if(listener.IsValid() && !IsPlayerABot(listener)){
				local lang = 0;
				switch(Convars.GetClientConvarValue("cl_language", listener.GetEntityIndex())){
					case "korean":case "koreana":	lang = 1;	break;
					case "japanese":				lang = 2;	break;
					case "spanish":					lang = 3;	break;
					case "schinese":				lang = 4;	break;
					case "tchinese":				lang = 5;	break;
					default:						lang = 0;	break;
				}
				playerLangList[lang].append(listener);
			}
		}
	//	local door = Entities.FindByModel(null, "models/props_doors/checkpoint_door_02.mdl");
	//	printl(door.GetName());
		local langlen = playerLangList.len();
		for(local i = 0; i < langlen; i++){
			local playerlen = playerLangList[i].len();
			if(playerlen > 0){
				local hinttbl ={
					classname = "env_instructor_hint",
					hint_allow_nodraw_target = "1",
					hint_alphaoption = "3",
					hint_caption = msg[i],
					hint_color = "255 255 255",
					hint_forcecaption = "1",//0이면 벽 통과 안함, 1이면 벽 통과해서 표시
					hint_icon_offscreen = "icon_alert_red",
					hint_icon_onscreen = "icon_door",
					hint_instance_type = "2",
					hint_pulseoption = "1",
					hint_static = hint_pos,//0이면 타겟에, 1이면 화면고정
					hint_target = doorname,
					targetname = "hdmd_hint",
				};
				hintList[i] = g_ModeScript.CreateSingleSimpleEntityFromTable(hinttbl);
				for(local j = 0; j < playerlen; j++){
					local nav = NavMesh.GetNearestNavArea(playerLangList[i][j].GetOrigin(), 100.0, true, true);
					if(nav != null && nav.HasSpawnAttributes(2048)){
						DoEntFire("!self", "ShowHint", "", 0.0, playerLangList[i][j], hintList[i]);
					}
				}
				DoEntFire("!self", "Kill", "", 10.0, null, hintList[i]);
			}
		}
		DoEntFire("!self", "Kill", "", 10.0, null, ::manacat_tank.door_pound_hint);
	}

	function OnGameEvent_ability_use(params){
		if(params.ability == "ability_throw"){
			local tank = GetPlayerFromUserID(params.userid);
			NetProps.SetPropIntArray( tank, "m_afButtonDisabled", 2048, 0);
			::manacatAddTimer(8.0, false, ::manacat_tank.throw_allow, {si = tank});
			local scrScope = tank.GetScriptScope();
			::manacat_tank.SetTankThrowTime(tank);

			::manacatAddTimer(1.9, false, ::manacat_tank.SI_control_tank_rock_adjust, {si = tank});
			::manacatAddTimer(0.5, false, ::manacat_tank.SI_control_tank_rock, {si = tank});

			if(::manacat_tank.rock_jump){
				local speed = NetProps.GetPropFloatArray( tank, "m_flGroundSpeed", 0);
				if(speed > 100){
					local fv = tank.GetForwardVector();
					local fx = fv.x*(speed+5);		local fy = fv.y*(speed+5);
					local pushVec = Vector(fx,fy,255);

					tank.SetVelocity(pushVec);
				}
			}
		}
		//if(GetPlayerFromUserID(params.userid).GetClassname())
	}

	function throw_allow(params){
		if(params.si == null || !params.si.IsValid()
		|| params.si.IsDead() || params.si.IsIncapacitated())return;
		NetProps.SetPropIntArray( params.si, "m_afButtonDisabled", 0, 0);
	}

	function SI_control_tank_rock(params){
		if(params.si == null || !params.si.IsValid() || !::manacat_tank.rock_aim)return;
		local nearSurv = ::manacat_tank.findNearSurv({from = params.si, visible = true, noincap = true});
		local nearDist = nearSurv[1]; nearSurv = nearSurv[0];
		local siSeq = NetProps.GetPropIntArray( params.si, "m_nSequence", 0);
		if(siSeq == 49 || siSeq == 50 || siSeq == 51){
			::manacatAddTimer(0.1, false, ::manacat_tank.SI_control_tank_rock, params);
			if(nearSurv == null || !nearSurv.IsValid())return;
			CommandABot( { cmd = 0, target = nearSurv, bot = params.si } );
			NetProps.SetPropEntity( params.si, "m_lookatPlayer", nearSurv );
			local scrScope = params.si.GetScriptScope();
			scrScope.ThrowTarget <- nearSurv;
			scrScope.ThrowPose <- siSeq;
		}
	}

	function SI_control_tank_rock_adjust(params){
		if(params.si == null || !params.si.IsValid())return;
		local find = false;
		for(local rock = null; (rock = Entities.FindByClassname(rock, "tank_rock")) != null && rock.IsValid();){
			if(NetProps.GetPropEntityArray( rock, "m_hThrower", 0 ) == params.si){
				::manacatAddTimer(0.0, false, ::manacat_tank.SI_control_tank_rock_adjust_trajectory, {rock = rock, si = params.si, siOrigin = params.si.GetOrigin()});
				return;
			}
		}

		if(!find){
			::manacatAddTimer(0.0, false, ::manacat_tank.SI_control_tank_rock_adjust, params);
		}
	}

	function SI_control_tank_rock_adjust_trajectory(params){
		if(params.rock == null || !params.rock.IsValid() || !::manacat_tank.rock_trajectory)return;
		local rockOrigin = params.rock.GetOrigin();
		if(rockOrigin.x != params.siOrigin.x || rockOrigin.y != params.siOrigin.y || rockOrigin.z != params.siOrigin.z){
			local seq = 0;
			local targetSurv = null;
			local scrScope = params.si.GetScriptScope();
			targetSurv = scrScope.ThrowTarget;
			seq = scrScope.ThrowPose;
			if(targetSurv == null || !targetSurv.IsValid())return;
			
			if(seq == 50 || RandomInt(1,3) != 1){//밑돌이거나 66%의 확률 꺾돌
				local rockDist = (params.si.EyePosition() - targetSurv.GetOrigin()).Length();
				local targetPos = targetSurv.EyePosition()+Vector(0,0,rockDist/6.2);
				if(seq == 50)targetPos += Vector(0,0,rockDist/55);//밑돌은 좀 더 높게
				local prediction = targetSurv.GetVelocity();	prediction.z = 0;	prediction = prediction.Scale(0.4);
				targetPos += prediction;
				local flag = NetProps.GetPropInt(targetSurv,"m_fFlags");
				local isOnGround = flag == ( flag | 1 );
				if(isOnGround)targetPos.z -= 30;
				local tankViewAngle = ::manacat_tank.SI_control_eye({si = params.rock, tgVector = targetPos});
				tankViewAngle.z += rockDist/500;
				local newForce = tankViewAngle.Forward().Scale(800);
				//DebugDrawLine(rockOrigin, rockOrigin+newForce, 0, 255, 0, true, 5);
				
				params.rock.SetVelocity(Vector(0, 0, 0));
				params.rock.ApplyAbsVelocityImpulse(newForce);
			}
			return;
		}else{
			::manacatAddTimer(0.0, false, ::manacat_tank.SI_control_tank_rock_adjust_trajectory, params);
		}
	}

	function punchCheck(params){
		local scrScope = params.si.GetScriptScope();
		local miss = true;
		if(scrScope.hitTarget != null){
			miss = false;
			scrScope.hitTarget <- null;
		}

		if(miss)::manacatAddTimer(0.1, false, ::manacat_tank.punchRetreat, { si = params.si });
	}

	function punchRetreat(params){
	//	printl(Time()+"  "+NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0));
		if(params.si == null || !params.si.IsValid())return;
		local scrScope = params.si.GetScriptScope();
		if(NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0)-0.5 < Time()){
			if(scrScope.Retreat)scrScope.Retreat <- false;
			local nearSurv = ::manacat_tank.findNearSurv({from = params.si, visible = true, noincap = true});
			local nearDist = nearSurv[1]; nearSurv = nearSurv[0];
			CommandABot( { cmd = 0, target = nearSurv, bot = params.si } );
		//	printl("후퇴 종료");
			return;
		}
		//	printl("후퇴");
		::manacatAddTimer(0.1, false, ::manacat_tank.punchRetreat, params);

		local player = null;
		while (player = Entities.FindByClassname(player, "player")){
			if(!player.IsValid() || player.IsDead()
			|| player.IsIncapacitated() || player.IsDominatedBySpecialInfected()
			|| player.GetActiveWeapon() == null)continue;
			local dist = (player.GetOrigin() - params.si.GetOrigin()).Length();
		//	::printlang(" ",
		//				"\x03<탱크> 거리 "+dist,
		//				" ",
		//				" ",
		//				1);
			local playerWeapon = player.GetActiveWeapon().GetClassname();
			if(dist < 250 && (playerWeapon == "weapon_melee" || playerWeapon == "weapon_chainsaw")){
				if(!scrScope.Retreat){
					scrScope.Retreat <- true;
					local vecVision = player.EyePosition();
				//	local siVision = params.si.EyePosition();
				//	local vecTargetNorm = Vector(vecVision.x, vecVision.y, vecVision.z);
				//	vecTargetNorm.x -= siVision.x;
				//	vecTargetNorm.y -= siVision.y;
				//	vecTargetNorm.z -= siVision.z;
				//	vecTargetNorm.x = vecTargetNorm.x/vecTargetNorm.Norm();
				//	vecTargetNorm.y = vecTargetNorm.y/vecTargetNorm.Norm();
				//	vecTargetNorm.z = vecTargetNorm.z/vecTargetNorm.Norm();

				//	if(180/PI*acos(params.si.EyeAngles().Forward().Dot(vecTargetNorm)) < 135){//탱크가 생존자를 보는 범위
						local eyeAngle = player.EyeAngles();
						eyeAngle.x = 0;
						local targetPos = vecVision + eyeAngle.Forward().Scale(220);
					//	targetPos.z = params.si.GetOrigin().z+40;

						local m_trace = { start = params.si.EyePosition(), end = targetPos, ignore = params.si, mask = 33636363 };
						TraceLine(m_trace);
						if(m_trace.hit){
							targetPos = m_trace.pos + eyeAngle.Forward().Scale(-40);
						//	DebugDrawLine(params.si.EyePosition(), targetPos, 255, 0, 255, true, 5);
						}else{
						//	DebugDrawLine(params.si.EyePosition(), targetPos, 255, 0, 255, true, 5);
						}

						local targetPosBottom = Vector(targetPos.x, targetPos.y, targetPos.z-1000);
						local m_trace2 = { start = targetPos, end = targetPosBottom, ignore = params.si, mask = 33636363 };
						TraceLine(m_trace2);
						if(m_trace2.hit){
						//	DebugDrawLine(targetPos, m_trace2.pos, 255, 0, 255, true, 5);
							if(m_trace2.hit)targetPos = m_trace2.pos;
						}

						local tgnav = NavMesh.GetNearestNavArea(targetPos, 150.0, true, true);
						if(tgnav != null){
							//targetPos = tgnav.GetCenter();	
							CommandABot( { cmd = 1, pos = targetPos, bot = params.si } );
							
						//	DebugDrawLine(params.si.EyePosition(), tgnav, 255, 0, 255, true, 5);
						//	DebugDrawBoxAngles(tgnav, Vector(-10,-10,-10), Vector(10,10,10), QAngle(0, 0, 0), Vector(255, 0, 255), 64, 5.0);
						}
				//	}
				}
			}
		}
	}

	function punchRemove(params){
		if(params.si != null && params.si.IsValid()){
			if(NetProps.GetPropFloatArray( params.si.GetActiveWeapon(), "m_flNextPrimaryAttack", 0)-0.25 < Time()){
				local scrScope = params.si.GetScriptScope();
				scrScope.PunchCooltime <- false;
			//	printl("펀치 제거");
				return;
			}
			::manacatAddTimer(0.1, false, ::manacat_tank.punchRemove, params);
		}
	}

	function punchObject(params){
		if(!::manacat_tank.hittable)return;
		local tank = params.tank;	local tankOrigin = tank.GetOrigin();
		::manacat_tank.kkangListManage();	local frontEnt = false;
		local fwd = tank.GetAngles().Forward();
		local kkanglen = ::manacat_tank.kkangList.len();	local kkangListFB = [];//true면 앞, false면 뒤
		for(local i = 0; i < kkanglen; i++){
			local entOrigin = ::manacat_tank.kkangList[i].GetOrigin();	entOrigin.z += 20;
			if(::manacat_tank.kkangList[i] != null && ::manacat_tank.kkangList[i].IsValid() && (entOrigin-tankOrigin).Length() < 180){
				if(::manacat_tank.CanSee(tank, entOrigin, 131083)){
					local o1 = tankOrigin;
					local o2 = entOrigin;
					local product = (o1["x"] - o2["x"]) * fwd["x"] + (o1["y"] - o2["y"]) * fwd["y"] + (o1["z"] - o2["z"]) * fwd["z"];
					if (product > 0.0)		{//printl("뒤");
						kkangListFB.append([::manacat_tank.kkangList[i],false]);
					}else					{//printl("앞");
						kkangListFB.append([::manacat_tank.kkangList[i],true]);
						frontEnt = true;
					}
				}
			}
		}
		kkanglen = kkangListFB.len();
		for(local i = 0; i < kkanglen; i++){
			if(kkangListFB[i][1] == frontEnt){//앞에 있는 오브젝트가 있으면 앞에 있는 것들, 없으면 뒤에 있는 오브젝트들
				local ent = kkangListFB[i][0];
				ent.SetVelocity(Vector(0, 0, 0));
				if(ent != null && ent.IsValid()){
					local activity = tank.GetSequenceActivityName(tank.GetSequence());
					if(activity == "ACT_TANK_OVERHEAD_THROW"
					|| activity == "ACT_TERROR_CLIMB_36_FROM_STAND" || activity == "ACT_TERROR_CLIMB_38_FROM_STAND" || activity == "ACT_TERROR_CLIMB_50_FROM_STAND" || activity == "ACT_TERROR_CLIMB_70_FROM_STAND"
					|| activity == "ACT_TERROR_CLIMB_115_FROM_STAND" || activity == "ACT_TERROR_CLIMB_130_FROM_STAND" || activity == "ACT_TERROR_CLIMB_150_FROM_STAND" || activity == "ACT_TERROR_CLIMB_166_FROM_STAND")return;
					EmitAmbientSoundOn("HulkZombie.Punch", 1.0, 350, 100,params.tank);
				//	DoEntFire("!self", "break", "", 0.0, null, ent);
					ent.TakeDamage(100, 128, tank);
					local tgV = tank.EyePosition() + tank.EyeAngles().Forward().Scale(2000) + tank.GetVelocity().Scale(0.8);
					local fv = ::manacat_tank.SI_control_eye({si = ent, tgVector = tgV}).Forward();//tank.GetForwardVector();
					local fx = fv.x*(1000);		local fy = fv.y*(1000);		local fz = fv.z*(1000);
					local pushVec = Vector(fx,fy,fz+100);

				//	ent.SetVelocity(pushVec);
					ent.ApplyAbsVelocityImpulse(pushVec);
					ent.ApplyLocalAngularVelocityImpulse(Vector(100+(RandomInt(0,1)*-200),100+(RandomInt(0,1)*-200),550+(RandomInt(0,1)*-1100)));
				}
				/*//탱크의 앞으로 끌어와서 치기
				if(ent != null && ent.IsValid() && (ent.GetOrigin()-tankOrigin).Length() < 180){
					local front = ::manacat_tank.visionCheck(tank, ent.GetOrigin(), null, 30);
					if (!front){
					//	DoEntFire("!self", "break", "", 0.0, null, ent);
						ent.TakeDamage(100, 128, tank);
						local tgV = tank.EyePosition() + tank.EyeAngles().Forward().Scale(50) + tank.GetVelocity().Scale(0.8);
						printl(tgV);
						local fv = ::manacat_tank.SI_control_eye({si = ent, tgVector = tgV}).Forward();//tank.GetForwardVector();
						printl("fv"+ fv + "  "+tank.GetForwardVector());
						local fx = fv.x*(245);		local fy = fv.y*(245);
						local pushVec = Vector(fx,fy,175);

					//	ent.SetVelocity(pushVec);
						ent.SetVelocity(Vector(0, 0, 0));
						ent.ApplyAbsVelocityImpulse(pushVec);
						ent.ApplyLocalAngularVelocityImpulse(Vector(250,0,0));
					}
				}
				*/
			}
		}
	}

	function SetTankThrowTime(tank){
		if(tank == null || !tank.IsValid())return;
		local scrScope = tank.GetScriptScope();
		scrScope.ThrowTime <- Time();
		scrScope.ThrowTimeNext <- Time()+Convars.GetFloat("z_tank_throw_interval");
		return;
	}

	function GetTankThrowTime(tank){
		if(tank == null || !tank.IsValid())return [-100, -100];
		local scrScope = tank.GetScriptScope();
		if(scrScope.ThrowTime == 0)return [-100, -100];
		return [scrScope.ThrowTime, scrScope.ThrowTimeNext];
	}

	function kkangListManage(tank = null){
		local kkanglen = ::manacat_tank.kkangList.len();
		if(kkanglen == 0){
			local ent = null;
			while (ent = Entities.FindByClassname(ent, "prop_physics")){
				local entOrigin = ent.GetOrigin();	entOrigin.z += 20;
				if((NetProps.GetPropInt( ent, "m_spawnflags" ) & 4) != 4 && (NetProps.GetPropInt( ent, "m_spawnflags" ) & 32768) != 32768
				&& NetProps.GetPropInt(ent, "m_hasTankGlow") == 1 && NetProps.GetPropInt(ent, "m_breakableType") != 2)::manacat_tank.kkangList.append(ent);
			}

			while (ent = Entities.FindByClassname(ent, "prop_physics_multiplayer")){
				local entOrigin = ent.GetOrigin();	entOrigin.z += 20;
				if((NetProps.GetPropInt( ent, "m_spawnflags" ) & 4) != 4
				&& NetProps.GetPropInt(ent, "m_hasTankGlow") == 1)::manacat_tank.kkangList.append(ent);
			}

			while (ent = Entities.FindByClassname(ent, "prop_car_alarm")){
				local entOrigin = ent.GetOrigin();	entOrigin.z += 20;
				if((NetProps.GetPropInt( ent, "m_spawnflags" ) & 4) != 4
				&& NetProps.GetPropInt(ent, "m_hasTankGlow") == 1)::manacat_tank.kkangList.append(ent);
			}
		}else{
			if(tank == null){
				for(local i = kkanglen-1; i >= 0; i--){
					if(::manacat_tank.kkangList[i] == null || !::manacat_tank.kkangList[i].IsValid()){
						::manacat_tank.kkangList.remove(i);
					}
				}
			}else{
				local origin = tank.GetOrigin();
				for(local i = 0; i < kkanglen; i++){
					if(::manacat_tank.kkangList[i] != null && ::manacat_tank.kkangList[i].IsValid()){
						local entOrigin = ::manacat_tank.kkangList[i].GetOrigin();	entOrigin.z += 20;
						if(::manacat_tank.CanSee(tank, entOrigin, 131083) && (entOrigin-origin).Length() < 180)return true;
					}
				}
			}
		}
		return false;
	}

	function SI_control_eye(params){
		local eyeVector = params.si.GetOrigin();
		if("EyePosition" in params.si)eyeVector = params.si.EyePosition();

		local vector = params.tgVector - eyeVector;
		local qy = Quaternion();	local qx = Quaternion();
		qy.SetPitchYawRoll(0, 90-atan2(vector.x, vector.y)*180/PI, 0);
		qx.SetPitchYawRoll(atan2(vector.z, sqrt(vector.x*vector.x+vector.y*vector.y))*-180/PI, 0, 0);
		local qr = Quaternion(
			qy.x*qx.x - qy.y*qx.y - qy.z*qx.z - qy.w*qx.w,
			qy.x*qx.y + qy.y*qx.x + qy.z*qx.w - qy.w*qx.z,
			qy.x*qx.z - qy.y*qx.w + qy.z*qx.x + qy.w*qx.y,
			qy.x*qx.w + qy.y*qx.z + qy.z*qx.y + qy.w*qx.x
		).ToQAngle();

		return QAngle(qr.x, qr.y*-1, 0);
	}

	function visionCheck(viewer, target, targetEnt=null, tolerance=50, viewerAng=0){
		local startpos = viewer.EyePosition();
		local targetNorm = Vector(target.x, target.y, target.z);
		targetNorm.x -= startpos.x;	targetNorm.y -= startpos.y;	targetNorm.z -= startpos.z;
		targetNorm.x = targetNorm.x/targetNorm.Norm();
		targetNorm.y = targetNorm.y/targetNorm.Norm();
		targetNorm.z = targetNorm.z/targetNorm.Norm();

		if(viewerAng == 0)viewerAng = viewer.EyeAngles().Forward();

		if(180/PI*acos(viewerAng.Dot(targetNorm)) < tolerance){
			if(targetEnt != null){
				local m_trace = { start = startpos, end = target, ignore = viewer, mask = 33579137 };
				TraceLine(m_trace);
				if("enthit" in m_trace && m_trace.enthit == targetEnt){
					return true;
				}else{
					return false;
				}
			}else{
				return true;
			}
		}
		return false;
	}

	function findNearSurv(params){
		if(!("visible" in params))params.visible <- false;
		local tgDist = 50000;		local tgDistSub = 50000;		local mindist = 50000;
		local tgSurv = null;		local tgSurvSub = null;
		local fromOrigin = params.from.GetOrigin();
		local fromVision = fromOrigin;
		if("EyePosition" in params.from)fromVision = params.from.EyePosition();
		local player = null;
		while (player = Entities.FindByClassname(player, "player")){
			if(!player.IsValid() || NetProps.GetPropInt( player, "m_iTeamNum" ) != 2)continue;
			if("novomit" in params && params.novomit && player.IsIT())continue;
			if("noincap" in params && params.noincap && player.IsIncapacitated())continue;
			if(player.IsDead() || player.IsDominatedBySpecialInfected() || player.IsGettingUp())continue;
			local dist = (player.GetOrigin() - fromOrigin).Length();
			if(dist < mindist)	mindist = dist;

			local look = false;
			local finish = player.EyePosition();
			local m_trace = { start = fromVision, end = finish, ignore = params.from, mask = 33636363 };//mask = 33579137 <- 펜스 통과하는 시야
			TraceLine(m_trace);
			if(("enthit" in m_trace && m_trace.enthit == player) || (m_trace.pos.x == finish.x && m_trace.pos.y == finish.y && m_trace.pos.z == finish.z))	look = true;

			dist = (player.GetOrigin() - fromOrigin).Length();
			if((params.visible && look) || !params.visible){
				if(dist < tgDist){
					tgDist = dist;
					tgSurv = player;
				}
			}
			if(dist < tgDistSub){
				tgDistSub = dist;
				tgSurvSub = player;
			}
		}
		if(tgSurv != null)	return [tgSurv, tgDist, true, mindist];
		else				return [tgSurvSub, tgDistSub, false, mindist];	//보이는 생존자가 아무도 없을땐 가장 가까운 생존자
	}

	function CanSee(ent, finish, traceMask = 33636363){
		local begin = ent.GetOrigin();
		if(ent.GetClassname() == "player")begin = ent.EyePosition();
		
		local m_trace = { start = begin, end = finish, ignore = ent, mask = traceMask };
		TraceLine(m_trace);
		
		if (m_trace.pos.x == finish.x && m_trace.pos.y == finish.y && m_trace.pos.z == finish.z)
			return true;
		
		return false;
	}
}

__CollectEventCallbacks(::manacat_tank, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
