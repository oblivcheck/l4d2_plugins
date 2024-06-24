::manacatInfo<-{//12.19.2023
	function OnGameEvent_player_connect(params){
		if(!("name" in params) || !("networkid" in params))return;
		if(params.networkid != "BOT"){
			local p = null;
			while (p = Entities.FindByClassname(p, "player")){
				if(p != null && p.IsValid()){
					local msg = Convars.GetClientConvarValue("cl_language", p.GetEntityIndex());
					switch(msg){
						case "korean":case "koreana":	msg = params["name"]+" 님이 게임에 참가하고 있습니다.";	break;
						case "japanese":				msg = "プレイヤー "+params["name"]+" がゲームに参加しています";	break;
						case "spanish":					msg = "El jugador "+params["name"]+" se está uniendo a la partida";	break;
						case "schinese":				msg = params["name"]+" 正在加入游戏"; break;//간체
						case "tchinese":				msg = params["name"]+" 正在加入遊戲"; break;//번체
						default:						msg = "Player "+params["name"]+" is joining the game";	break;
					}
					ClientPrint(p, 5, "\x01"+msg);
				}
			}
		}
	}

	function OnGameEvent_player_say(params){
		local player = GetPlayerFromUserID(params.userid);
		local chat = params.text.tolower();
		chat = split(chat," ");
		local chatlen = chat.len();
		if(chatlen > 0){
			switch(chat[0]){
				case "!addon" : case "!add-on" : case "!mod" : case "!info" :
					local msg = Convars.GetClientConvarValue("cl_language", player.GetEntityIndex());
					switch(msg){
						case "korean":case "koreana":	msg = "이 세션에 적용된 애드온 목록입니다.";	break;
						case "japanese":				msg = "このセッションに適用されたアドオンのリストです。";	break;
						case "spanish":					msg = "Lista de add-ons aplicados a esta sesión.";	break;
						case "schinese":				msg = "适用于此会话的附加组件列表。";
						case "tchinese":				msg = "適用於此會話的附加組件列表。";
						default:						msg = "List of add-ons applied to this session.";	break;
					}
					ClientPrint(player, 5, "\x03"+msg);
					local slotn = 0;
					for(local i = 0; i < 9999; i++){
						if(("slot"+i) in ::MANACAT){
							::MANACAT["slot"+i](player);
							slotn++;
						}
					}
				break;
			}
		}
	}
}

__CollectEventCallbacks(::manacatInfo, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);