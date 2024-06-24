if (!("MANACAT" in getroottable())){
	::MANACAT <- {}
}

if(!("spitfix" in ::MANACAT)){
	::MANACAT.spitfix <- {
		check = false
		ver = "01/07/2024"
	}
	::MANACAT.slot40 <- function(ent){
		local msg = Convars.GetClientConvarValue("cl_language", ent.GetEntityIndex());
		switch(msg){
			case "korean":case "koreana":	msg = "스피터 침 확산 개선";	break;
			case "japanese":				msg = "スピ酸の拡散改善";	break;
			case "spanish":					msg = "Mejorado Propagación de la Saliva Ácida";	break;
			case "schinese":				msg = "酸性唾液扩散改善";	break;
			case "tchinese":				msg = "酸性唾液擴散改善";	break;
			default:						msg = "Spitter Acid Spread Fix";	break;
		}
//		ClientPrint( ent, 5, "\x02 - "+msg+" \x01 v"+::MANACAT.spitfix.ver);
	};
}

printl( "<MANACAT> Spit Spread Fix Loaded. v"+::MANACAT.spitfix.ver);

IncludeScript("rpp/manacat_spitfix/info");
if (!("manacatInfo" in getroottable())){
	IncludeScript("manacat/info");
}

::manacat_spitfix<-{
	debug = false
	
	function particlefire(pos, part = []){
		local plen = part.len();
		for(local i = 0; i < plen; i++){
			local effect = SpawnEntityFromTable("info_particle_system",
			{
				angles = Vector( 0, RandomInt(0,359), 0 )
				effect_name = part[i]
				start_active = "1"
				origin = pos
			});
			DoEntFire("!self", "Kill", "", 7.5, null, effect);
		}
	}
	
	function OnGameEvent_ability_use(params){
		if(params.ability == "ability_spit"){
			local si = GetPlayerFromUserID(params.userid);
			si.ValidateScriptScope();
			local scope = si.GetScriptScope();

			AddThinkToEnt(si, "thinker");

			scope.spit_pos <- si.EyePosition();
			scope.spit_vel <- si.EyeAngles().Forward().Scale(60);
			if(::manacat_spitfix.debug)scope.spit_pos_past <- null;
			scope.thinker <- function(){
				local spit = null;
				while (spit = Entities.FindByClassname(spit, "spitter_projectile")){
					if(NetProps.GetPropEntity(spit, "m_hOwnerEntity") == si){
						if(::manacat_spitfix.debug && scope.spit_pos != null)scope.spit_pos_past <- Vector(scope.spit_pos.x, scope.spit_pos.y, scope.spit_pos.z);
						scope.spit_pos <- spit.GetOrigin();
						scope.spit_vel <- spit.GetVelocity();
						if(::manacat_spitfix.debug){
							if(scope.spit_pos_past != null)DebugDrawLine(scope.spit_pos_past, scope.spit_pos, 255, 0, 255, true, 5.0);
							
							local velNorm = Vector(scope.spit_vel.x, scope.spit_vel.y, scope.spit_vel.z);
						//	velNorm.x = velNorm.x/velNorm.Norm();
						//	velNorm.y = velNorm.y/velNorm.Norm();
						//	velNorm.z = velNorm.z/velNorm.Norm();
							if(velNorm.Length() > 0.9){
								DebugDrawLine(scope.spit_pos, scope.spit_pos + velNorm.Scale(0.15), 0, 255, 255, true, 5.0);
							}
						}
					}
				}
			}
		}
	}

	function OnGameEvent_spit_burst(params){
		if(::manacat_spitfix.debug)g_MapScript.DeepPrintTable(params);

		local spit = EntIndexToHScript(params.subject);
		spit.ValidateScriptScope();
		local scope = spit.GetScriptScope();

		local spitter = NetProps.GetPropEntity(spit, "m_hOwnerEntity");
		local spitterscope = spitter.GetScriptScope();
		if(::manacat_spitfix.debug){
			printl("마지막 포착지점 : "+spitterscope.spit_pos);
			DebugDrawBox(spitterscope.spit_pos, Vector(-5,-0.8,-0.8), Vector(5,0.8,0.8), 255, 100, 0, 150, 5.0);
			DebugDrawBox(spitterscope.spit_pos, Vector(-0.8,-5,-0.8), Vector(0.8,5,0.8), 255, 100, 0, 150, 5.0);
			DebugDrawBox(spitterscope.spit_pos, Vector(-0.8,-0.8,-5), Vector(0.8,0.8,5), 255, 100, 0, 150, 5.0);
		}
		spitterscope.thinker <- null;
		
		scope.spit_pos <- spit.GetOrigin();
		scope.fire_delta <- @(i, cord)NetProps.GetPropIntArray(spit, "m_fire" + cord + "Delta", i);
		scope.extra_spread <- [];
		scope.bursttime <- Time();
		scope.cycle <- 0;

		local spit_exp = Vector(spitterscope.spit_vel.x, spitterscope.spit_vel.y, spitterscope.spit_vel.z);
		spit_exp = spitterscope.spit_pos + spit_exp.Scale(0.15);
		local spit_trace_exp = { start = spitterscope.spit_pos, end = spit_exp, ignore = null, mask = 33570827 };
		TraceLine(spit_trace_exp);
		if(spit_trace_exp.hit){
			spit_exp = spit_trace_exp.pos;
		}

		local spit_trace = { start = spit_exp, end = scope.spit_pos, ignore = null, mask = 33570827 };
		TraceLine(spit_trace);
		if(::manacat_spitfix.debug && spit_trace.hit){
			DebugDrawBox(spit_trace.pos, Vector(-5,-0.8,-0.8), Vector(5,0.8,0.8), 255, 100, 0, 150, 5.0);
			DebugDrawBox(spit_trace.pos, Vector(-0.8,-5,-0.8), Vector(0.8,5,0.8), 255, 100, 0, 150, 5.0);
			DebugDrawBox(spit_trace.pos, Vector(-0.8,-0.8,-5), Vector(0.8,0.8,5), 255, 100, 0, 150, 5.0);
		}
		if((spit_trace.pos - scope.spit_pos).Length() > 40){
			//printl("착점과 발생점 거리가 너무 멀어서 착점에도 파티클 효과 발사");
			::manacat_spitfix.particlefire(spit_trace.pos, ["spitter_projectile_explode"]);
		}

		scope.limitz <- spit_trace.pos.z + 4;
		scope.thinker <- function() {
			scope.cycle++;
		//	DebugDrawClear();
			local firecount = NetProps.GetPropInt(spit, "m_fireCount");
			local delta_pos;
			for(local i = 0; i < firecount; i++) {
				local needextra = true;
				local delta = Vector(fire_delta(i,"X"), fire_delta(i,"Y"), fire_delta(i,"Z"));
				delta_pos = scope.spit_pos + delta;
				if(::manacat_spitfix.debug)DebugDrawBox(delta_pos, Vector(-1.6,-1.6,-0.8), Vector(1.6,1.6,0.8), 255, 100, 0, 150, 0.1);

				local startpos = delta_pos + Vector(0, 0, 4);
				local endpos = delta_pos + Vector(0, 0, 1500);
				local m_trace = { start = startpos, end = endpos, ignore = spit, mask = 33636363 };
				TraceLine(m_trace);
				if(m_trace.hit){
					local enthitclass = m_trace.enthit.GetClassname();
					if(m_trace.enthit != null && enthitclass == "worldspawn"/* || enthitclass == "func_brush" 하는게 맞는지 모르겠고 확인도 안해서 일단 주석처리함*/)continue;
					local world_trace = { start = startpos, end = endpos, ignore = spit, mask = 131083 };
					TraceLine(world_trace);
					if(world_trace.hit)endpos = world_trace.pos;

					if(::manacat_spitfix.debug){
						DebugDrawLine(startpos, m_trace.pos, 255, 0, 255, true, 0.1);
						DebugDrawBox(endpos, Vector(-1.6,-1.6,-0.8), Vector(1.6,1.6,0.8), 0, 100, 255, 150, 0.1);
					}

					if(needextra){
						local ignoremask = null;
						local groundpos = Vector(endpos.x, endpos.y, endpos.z);
						for(local t = 0; t < 5; t++){
							world_trace = { start = groundpos, end = startpos, ignore = ignoremask, mask = 33570827 };
							TraceLine(world_trace);
							if(world_trace.hit){
								local ent = world_trace.enthit;
								local entclass = ent.GetClassname();
								if(entclass == "player" || entclass == "infected" || entclass == "witch"){
									ignoremask = ent;
									world_trace.pos.z = ent.GetOrigin().z - 0.5;
									groundpos = world_trace.pos;
								}else if(entclass == "prop_physics" || entclass == "prop_dynamic" || entclass == "func_physbox"){
									break;
								}else if(entclass == "worldspawn" || entclass == "func_brush"){
									needextra = false;
									if(::manacat_spitfix.debug)printl(entclass);
								}else{
									if(::manacat_spitfix.debug)printl(entclass);
								}
							}
						}
					}

					if(needextra){
						if(::manacat_spitfix.debug)DebugDrawLine(endpos, world_trace.pos, 0, 255, 255, true, 0.1);
						local len = scope.extra_spread.len();
						local extra = false;
						for(local s = 0; s < len; s++){
							if(scope.extra_spread[s][0].x == delta_pos.x && scope.extra_spread[s][0].y == delta_pos.y && scope.extra_spread[s][0].z == delta_pos.z){
								extra = true;
								break;
							}
						}
						if(!extra){
							if(scope.limitz > world_trace.pos.z){
								if((world_trace.pos - delta_pos).Length() > 6){
									scope.extra_spread.append([delta_pos, world_trace.pos]);
									if(::manacat_spitfix.debug)DebugDrawBox(world_trace.pos, Vector(-1.6,-1.6,-0.8), Vector(1.6,1.6,0.8), 255, 0, 100, 150, 6.0);
									::manacat_spitfix.particlefire(world_trace.pos, ["spitter_areaofdenial_base_refract"]);
								}
							}
						}
					}
					//}
				}
			}

			if(::manacat_spitfix.debug)DebugDrawBox(scope.spit_pos, Vector(-3,-3,-3), Vector(3,3,3), 0, 255, 0, 255, 0.1);

			if(scope.cycle == 7 || scope.cycle == 15){
				local surv = null;
				local extralen = scope.extra_spread.len();
				while (surv = Entities.FindByClassname(surv, "player")){
					if(NetProps.GetPropInt( surv, "m_iTeamNum" ) != 2)continue;
					local dmg = false;
					local survpos = surv.GetOrigin();
					local survground = NetProps.GetPropEntity( surv, "m_hGroundEntity" );
					local groundclass = null;
					if(survground != null)groundclass = survground.GetClassname();
					if(groundclass == "worldspawn"){
						if(::manacat_spitfix.debug)printl(survground + "땅에 있으니 원래 기준으로 피해 줌");
						dmg = true;
						continue;
					}
					if(!dmg){
						for(local i = 0; i < firecount; i++){
							local dist = (survpos-(scope.spit_pos+Vector(fire_delta(i,"X"), fire_delta(i,"Y"), fire_delta(i,"Z")))).Length();
							if(dist < 95){
								if(groundclass == "prop_physics" || groundclass == "prop_dynamic" || groundclass == "func_physbox"){
									if(::manacat_spitfix.debug)printl(survground + "원래 영역에서 이탈, 엑스트라 피해 줌");
									//원점과 너무 가까운 거리에 있으면 올라가있어도 원래 피해 영역에 닿아서 피해를 입긴 예외처리 추가 여지가 있음(중복피해가 생기니까)
									break;
								}else{
									if(::manacat_spitfix.debug)printl(survground + "원래 기준 피해");
									dmg = true;break;
								}
							}
						}
					}
					if(!dmg){
						for(local i = 0; i < extralen; i++){
							if(::manacat_spitfix.debug)DebugDrawBox(scope.extra_spread[i][1], Vector(-1.6,-1.6,-0.8), Vector(1.6,1.6,0.8), 0, 100, 255, 150, 6.0);
							local dist = (survpos-scope.extra_spread[i][1]).Length();
							if((dist < 80 && groundclass == null) || (dist < 80 && survpos.z < scope.extra_spread[i][1].z+33 && groundclass != null)) {
								local attacker = NetProps.GetPropEntity(spit, "m_hOwnerEntity");

								surv.TakeDamageEx(spit, attacker, spit, Vector(0, 0, 0), extra_spread[i][1], ::manacat_spitfix.spitdmg(Time() - scope.bursttime), 263168);
								if(::manacat_spitfix.debug)printl("엑스트라 피해 발생 시간 " + Time());
								dmg = true;break;
							}
						}
					}
					if(dmg){
						continue;
					}
				}
			}
			if(scope.cycle == 15)scope.cycle = 0;
			return 0;
		}

		AddThinkToEnt(spit, "thinker");
		//*/
	}

	function spitdmg(t){
		local dmg = 0;
		if(t < 1.4){
			dmg = (0.5*t*t);
		}else if(t < 4){
			dmg = (1.97*t) - 1.91;
		}else if(t < 5){
			dmg = 6;
		}else{
			dmg = (-2.27*t) + 17.35;
		}

		return dmg;
	}
}

__CollectEventCallbacks(::manacat_spitfix, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
