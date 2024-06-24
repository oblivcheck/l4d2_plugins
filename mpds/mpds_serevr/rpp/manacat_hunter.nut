if (!("MANACAT" in getroottable())){
	::MANACAT <- {}
}

if(!("hunter" in ::MANACAT)){
	::MANACAT.hunter <- {
		ver = "01/21/2024"
	}
	::MANACAT.slot23 <- function(ent){
		local msg = Convars.GetClientConvarValue("cl_language", ent.GetEntityIndex());
		switch(msg){
			case "korean":case "koreana":	msg = "헌터 AI";	break;
			case "japanese":				msg = "ハンターAI";	break;
			case "spanish":					msg = "Hunter AI";	break;
			case "schinese":				msg = "Hunter AI";	break;
			case "tchinese":				msg = "Hunter AI";	break;
			default:						msg = "Hunter AI";	break;
		}
		ClientPrint( ent, 5, "\x02 - "+msg+" \x01 v"+::MANACAT.hunter.ver);
	};
}

printl( "<MANACAT Hunter> AI Loaded. v"+::MANACAT.hunter.ver);

IncludeScript("rpp/manacat_hunter/manacatTimer");
if (!("manacatTimers" in getroottable())){
	IncludeScript("manacat/manacatTimer");
}

IncludeScript("rpp/manacat_hunter/info");
if (!("manacatInfo" in getroottable())){
	IncludeScript("manacat/info");
}

::manacat_hunter<-{
	function OnGameEvent_player_spawn(params){
		local hunter = GetPlayerFromUserID(params.userid);
		if(hunter.GetZombieType() == 3){
			hunter.ValidateScriptScope();
			local scrScope = hunter.GetScriptScope();
			scrScope.jump_height <- hunter.GetOrigin().z;
			scrScope.KNOCKOFF_shoved <- 0;
			scrScope.KNOCKOFF_R <- 0;
			::manacatAddTimer(0.1, false, ::manacat_hunter.control, { si = hunter });
		}
	}

	function OnGameEvent_ability_use(params){
		if(params.ability == "ability_lunge"){
			local hunter = GetPlayerFromUserID(params.userid);
			if(NetProps.GetPropInt(hunter, "m_isAttemptingToPounce") != 1){
				StopAmbientSoundOn("HunterZombie.Pounce", hunter);
				EmitAmbientSoundOn("HunterZombie.Pounce", 1.0, 350, 100, hunter);
				NetProps.SetPropInt(hunter, "m_isAttemptingToPounce", 1);
			}
			::manacatAddTimer(0.0, false, ::manacat_hunter.control_lunge, { si = hunter });

			local hunterPos = hunter.GetOrigin();
			hunter.ValidateScriptScope();
			local scrScope = hunter.GetScriptScope();
			scrScope.jump_height <- hunterPos.z;
		}
	}

	function OnGameEvent_player_shoved(params){
		//밀쳤을 때 손톱공격 금지
		local si = GetPlayerFromUserID(params.userid);
		if(si.GetZombieType() == 3){
			si.ValidateScriptScope();
			local scrScope = si.GetScriptScope();
			scrScope.KNOCKOFF_shoved <- Time();//밀쳐진 시간 기록(cvar랑 무관하게 빠른 자세회복을 위함)
			local buttons = NetProps.GetPropIntArray( si, "m_afButtonDisabled", 0)
			NetProps.SetPropIntArray( si, "m_afButtonDisabled", (buttons | 2048), 0);
			local function allowAttack(si){
				if(!si.IsValid())return;
				NetProps.SetPropIntArray( si, "m_afButtonDisabled", 0, 0);
			}

			::manacatAddTimer(1.5, false, allowAttack, si);
		}
	}

	function control(params){
		if(params.si == null || !params.si.IsValid() || params.si.IsDead() || params.si.IsDying())return;
		if(!IsPlayerABot(params.si)){
			printl("<MANACAT> Since the hunter player("+params.si+") is human, AI is disabled.");
			return;
		}
		::manacatAddTimer(0.1, false, ::manacat_hunter.control, params);

		local nearSurv = ::manacat_hunter.findNearSurv({from = params.si, visible = true, noincap = true});
		local nearDist = nearSurv[1]; nearSurv = nearSurv[0];
		if(nearSurv == null) return;

		return;
		
		params.si.ValidateScriptScope();
		local scrScope = params.si.GetScriptScope();
		local currentTime = Time();

		local activity = params.si.GetSequenceActivityName(params.si.GetSequence());
		if(activity == "ACT_TERROR_HUNTER_POUNCE_MELEE"){//쥐어뜯다 밀쳐졌을 때 롤링
			local tgV = nearSurv.EyePosition();
			local viewAngle = ::manacat_hunter.SI_control_eye({si = params.si, tgVector = tgV});
			viewAngle.y += 270+RandomInt(-15,15);
			if(viewAngle.y > 360)viewAngle.y -= 360;
			viewAngle.x = 0;
		//	DebugDrawLine(params.si.EyePosition(), params.si.EyePosition()+viewAngle.Forward().Scale(30), 255, 0, 0, true, 0.2);
			params.si.SnapEyeAngles(viewAngle);

			return;
		}else if(activity == "ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_R"){
			if(scrScope.KNOCKOFF_R+0.7 < currentTime){
				scrScope.KNOCKOFF_R <- currentTime;
				::manacatAddTimer(0.6, false, ::manacat_hunter.activity_skip, {si = params.si, act = activity});
			}
			return;
		}else if(activity == "ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_BACKWARD" || activity == "ACT_TERROR_SHOVED_BACKWARD" || activity == "ACT_TERROR_SHOVED_LEFTWARD" || activity == "ACT_TERROR_SHOVED_RIGHTWARD" || activity == "ACT_TERROR_SHOVED_FORWARD"){
			::manacatAddTimer(1.1, false, ::manacat_hunter.activity_skip, {si = params.si, act = activity});
			return;
		}
		local flag = NetProps.GetPropInt(params.si,"m_fFlags");
		local isOnGround = flag == ( flag | 1 );

		local hunterPos = params.si.GetOrigin();

		if(activity == "ACT_TERROR_HUNTER_POUNCE_IDLE"){//급습 피해 계산에 활용할 활공 높이 기록
			if(scrScope.jump_height < hunterPos.z)scrScope.jump_height <- hunterPos.z;
		}

		local chkLungeButton = NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0) == ( NetProps.GetPropIntArray( params.si, "m_afButtonForced", 0) | 1 );

		local hunterMoveSeq = ["ACT_CROUCHIDLE", "ACT_RUN_CROUCH", "ACT_JUMP", "ACT_TERROR_HUNTER_POUNCE", "ACT_TERROR_HUNTER_POUNCE_IDLE"];
		local hunterMoveLen = hunterMoveSeq.len();

		local tgOri = nearSurv.GetOrigin()+Vector(0,0,35);
		local tgOriUp = tgOri+Vector(0,0,65);

		NetProps.SetPropInt( params.si, "m_afButtonForced", 0);

		local look = false;
		if(::manacat_hunter.CanSee(params.si, tgOri) || (::manacat_hunter.CanSee(params.si, tgOriUp) && ::manacat_hunter.CanSee(nearSurv, tgOriUp))){
			look = true;
			local key = (NetProps.GetPropInt( params.si, "m_afButtonForced") | 4);
			NetProps.SetPropIntArray( params.si, "m_afButtonForced", key.tointeger(), 0); //4 = 쪼그리기 키
		}else{
			local key = (NetProps.GetPropInt( params.si, "m_afButtonForced") & ~4);
			NetProps.SetPropIntArray( params.si, "m_afButtonForced", key.tointeger(), 0); //4 = 쪼그리기 키
		}

		for(local i = 0; i < hunterMoveLen; i++){
			if(activity == hunterMoveSeq[i]){
				if(!chkLungeButton && look){
					local tgV = nearSurv.EyePosition();
					tgV += nearSurv.GetVelocity().Scale(0.5);
					local viewAngle = ::manacat_hunter.SI_control_eye({si = params.si, tgVector = tgV});
					if(-80 < viewAngle.x && viewAngle.x < -35)viewAngle.x -= 4;
					else if(-35 < viewAngle.x && viewAngle.x < 30)viewAngle.x -= 2;
					else if(30 < viewAngle.x && viewAngle.x < 60)viewAngle.x -= 4;
					else viewAngle.x -= 6;
					params.si.SnapEyeAngles(viewAngle);
					local key = (NetProps.GetPropInt( params.si, "m_afButtonForced") | 9); //1 = 급습키, 8 = 앞으로 키, 합쳐서 9
					NetProps.SetPropInt( params.si, "m_afButtonForced", key.tointeger());
				}else{
					local key = (NetProps.GetPropInt( params.si, "m_afButtonForced") & ~9);
					NetProps.SetPropInt( params.si, "m_afButtonForced", key.tointeger());
				}
				return;
			}
		}
	}

	function control_lunge(params){//헌터의 기만점프
		local nearSurv = ::manacat_hunter.findNearSurv({from = params.si, visible = true, noincap = true});
		local nearDist = nearSurv[1]; nearSurv = nearSurv[0];
		if(nearSurv == null) return;

		local impulseVec = params.si.GetVelocity();
		if(::manacat_hunter.visionCheck(nearSurv, params.si.EyePosition(), params.si, 30)){
			if(RandomInt(1,5)==1)return;
			local angleAd = 180/RandomInt(10,20);
			if(RandomInt(1,2)==1)angleAd *= -1;
			local impulseVecMag = sqrt(impulseVec.x*impulseVec.x + impulseVec.y*impulseVec.y);
			local angle = (atan2(impulseVec.y, impulseVec.x) + (PI/angleAd));
			impulseVec.x = cos(angle)*impulseVecMag;
			impulseVec.y = sin(angle)*impulseVecMag;
		//	impulseVec.z += RandomInt(-20,60)*3;
			
		}
		local targetOrigin = nearSurv.GetOrigin();
		local hunterOrigin = params.si.GetOrigin();
	//	printl("높이차이" + (hunterOrigin.z-targetOrigin.z));
		if(targetOrigin.z < hunterOrigin.z && (targetOrigin - hunterOrigin).Length() > 300){
			if(RandomInt(1,2)==1){
				targetOrigin.z = 0;	hunterOrigin.z = 0;
				impulseVec.z += (targetOrigin - hunterOrigin).Length()/3;
			}
		}
		params.si.SetVelocity(Vector(0, 0, 0));
		params.si.ApplyAbsVelocityImpulse(impulseVec);
	}

	function activity_skip(params){
		if(!params.si.IsValid() || params.si == null)return;
		if(params.si.IsDead() || params.si.IsDying() || params.si.IsDominatedBySpecialInfected() || params.si.IsGettingUp())return;
		local activity = params.si.GetSequenceActivityName(params.si.GetSequence());
		if(activity == params.act || activity == "ACT_TERROR_SHOVED_BACKWARD" || activity == "ACT_TERROR_SHOVED_LEFTWARD" || activity == "ACT_TERROR_SHOVED_RIGHTWARD" || activity == "ACT_TERROR_SHOVED_FORWARD"){
			if(params.act != "ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_R" && NetProps.GetPropInt( params.si, "m_iTeamNum" ) != 2){
				params.si.ValidateScriptScope();
				local scrScope = params.si.GetScriptScope();

				if(scrScope.KNOCKOFF_shoved+1.0 > Time())return;
			}
			NetProps.SetPropFloatArray( params.si, "m_flCycle", 1000.0, 0);
		}
		return;
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

	function OnGameEvent_lunge_pounce(params){
		local victim = GetPlayerFromUserID(params.victim);
		local attacker = GetPlayerFromUserID(params.userid);

		local min = 150;	local max = 1000;
		local distDmg = floor(3.0 + (12*(params.distance-min)/max));

		attacker.ValidateScriptScope();
		local scrScope = attacker.GetScriptScope();

		local heightDmg = (scrScope.jump_height - attacker.GetOrigin().z) / 40;
		if(heightDmg > 1)distDmg += heightDmg;


		if(distDmg < 1) distDmg = 1;
		else if(distDmg >= 25) distDmg = 25;

		if(distDmg >= 5){
			EmitSoundOnClient("HunterZombie.Pounce.Hit", attacker)
			EmitAmbientSoundOn("HunterZombie.Pounce.Hit", 1.0, 350, 100,victim);
		}

	//	victim.TakeDamage(distDmg, 129, attacker);
		
		if(Convars.GetFloat("z_pounce_stumble_radius") < 30){
			local vicPos = victim.GetOrigin();
			local player = null;
			while (player = Entities.FindByClassname(player, "player")){
				if(!player.IsValid() || NetProps.GetPropInt( player, "m_iTeamNum" ) != 2
				|| player.IsDead() || player.IsDying() || player.IsDominatedBySpecialInfected() || player.IsGettingUp())continue;
				local dist = (player.GetOrigin() - vicPos).Length();
				if(dist < 160){
					local m_trace = { start = player.EyePosition(), end = attacker.EyePosition(), ignore = player, mask = 33636363 };
					TraceLine(m_trace);
					local m_trace2 = { start = player.EyePosition(), end = victim.EyePosition(), ignore = player, mask = 33636363 };
					TraceLine(m_trace2);
					if(("enthit" in m_trace && m_trace.enthit == attacker)
					|| ("enthit" in m_trace2 && m_trace2.enthit == victim)){
						player.Stagger(vicPos);
						if(Convars.GetFloat("z_max_stagger_duration") > 0.8)::manacatAddTimer(0.8, false, ::manacat_hunter.activity_skip, {si = player, act = null});
					}
				}
			}
		}
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
			if(player.IsDead() || player.IsDying() || player.IsDominatedBySpecialInfected() || player.IsGettingUp())continue;
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

__CollectEventCallbacks(::manacat_hunter, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
