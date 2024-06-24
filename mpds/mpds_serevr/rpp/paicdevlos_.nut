printl("Loaded PreventAICharge" + "\n" + "By Solved/Devlos aka Timonenluca")

PAICDevlos_ <- {}

PAICDevlos_findClosestNumber <- function (givenNumber, numbers) 
{
    local closestNumber = null;
    local closestDifference = null;
    
    foreach (number in numbers) 
    {
        local difference = abs(number - givenNumber);
        
        if (closestDifference == null || difference < closestDifference) 
        {
            closestNumber = number;
            closestDifference = difference;
        }
    }
    
    return closestNumber;
}

PAICDevlos_invertQAngle <- function (qAngle) 
{
    local invertedPitch = -qAngle.x;
    local invertedYaw = -qAngle.y;
    local invertedRoll = -qAngle.z;

    local invertedQAngle = QAngle(invertedPitch, invertedYaw, invertedRoll);
    return invertedQAngle;
}

PAICDevlos_CompassAngle <- function (ent , inverse)
{
    local Test = null;

    if(inverse == false){
    Test = abs((ent.GetAngles().y % 360) + 360) % 360;
    }
    else if(inverse == true){
    Test = abs((PAICDevlos_invertQAngle(ent.GetAngles()).y % 360) + 360) % 360;
    }

    //printl("Current Degrees: " + Test)

    local givenNumber = Test;
    local numbers = [0 , 45 , 90 , 135 , 180 , 225 , 270 , 315 , 360];
    local closest = PAICDevlos_findClosestNumber(givenNumber, numbers);

    //printl("Closest Number: " + closest)

    return closest;
    
}

PAICDevlos_IsDeadly <- function (Aent , ent , inverse)
{
    local CurrentArea = Aent.GetLastKnownArea()
    
    local ent_pos = ent.GetOrigin();
    local ent_z = ent_pos.z;
    local delta = 180;

    local CompassAngle = PAICDevlos_CompassAngle(ent, inverse);

    local TableAreas = {}
    local TableLen = TableAreas.len()
    //printl(TableLen)

    //CurrentArea.DebugDrawFilled(0 , 255 , 0 , 155 , 2.5 , true)

    if(CompassAngle != null && Aent != null && Aent.IsValid() && ent != null && ent.IsValid() && CurrentArea != null && CurrentArea.IsValid())
    {
        if(CompassAngle == 315 || CompassAngle == 270)
        {
            CurrentArea.GetAdjacentAreas(0 , TableAreas)

            foreach(area in TableAreas)
            {
                if(abs(area.GetCenter().z - ent_z) > delta || area.IsEdge(0) || CurrentArea.IsEdge(0))
                {
                    //area.DebugDrawFilled(255 , 0 , 0 , 155 , 2.5 , true)
                    return true;
                }
            }
        }
        else if(CompassAngle == 315 || CompassAngle == 45 || CompassAngle == 360 || CompassAngle == 0)
        {
            CurrentArea.GetAdjacentAreas(1 , TableAreas)
            
            foreach(area in TableAreas)
            {
                if(abs(area.GetCenter().z - ent_z) > delta || area.IsEdge(1) || CurrentArea.IsEdge(1))
                {
                    //area.DebugDrawFilled(255 , 0 , 0 , 155 , 2.5 , true)
                    return true;
                }
            }
        }
        else if(CompassAngle == 45 || CompassAngle == 90)
        {
            CurrentArea.GetAdjacentAreas(2 , TableAreas)
            
            foreach(area in TableAreas)
            {
                if(abs(area.GetCenter().z - ent_z) > delta || area.IsEdge(2) || CurrentArea.IsEdge(2))
                {
                    //area.DebugDrawFilled(255 , 0 , 0 , 155 , 2.5 , true)
                    return true;
                }
            }
        }
        else if(CompassAngle == 225 || CompassAngle == 135 || CompassAngle == 180)
        {
            CurrentArea.GetAdjacentAreas(3 , TableAreas)
            
            foreach(area in TableAreas)
            {
                if(abs(area.GetCenter().z - ent_z) > delta || area.IsEdge(3) || CurrentArea.IsEdge(3))
                {
                    //area.DebugDrawFilled(255 , 0 , 0 , 155 , 2.5 , true)
                    return true;
                }
            }
        }
    }
    return false;
}

PAICDevlos_Chance <- function (V1 , V2)
{
    local floatValue = (V1.GetOrigin()-V2.GetOrigin()).Length();

    local percentage = abs(floatValue / 960.0 * 100); 
    local difference = 100 - percentage;

    difference = difference > 100 ? 100 : (difference < 0 ? 0 : difference);

    return difference;
}

PAICDevlos_Float_ProtectedDiv <- function (val1, val2)
{
	if (val1 == 0.0 || val2 == 0.0)
	{
		return 0.0;
	}
	return val1/val2;
}

PAICDevlos_LookingAtAngles <- function (pos1, pos2)
{
	local posDiff = Vector(0,0,0);

	posDiff.x = pos2.x - pos1.x;
	posDiff.y = pos2.y - pos1.y;
	posDiff.z = pos2.z - pos1.z;

	return PAICDevlos_AnglesFromVector(posDiff);
}

PAICDevlos_RadianToDegrees <- function (radian)
{
	return PAICDevlos_Float_ProtectedDiv(radian * 180, PI);
}

PAICDevlos_DegreesToRadian <- function (degrees)
{
	return PAICDevlos_Float_ProtectedDiv(degrees * PI, 180);
}

PAICDevlos_SignAngleInc <- function (vecX)
{
	if (vecX>-1)
	{
		return 0;	
	}
	else
	{
		return 180;
	}
}

PAICDevlos_AnglesFromVector <- function (vector)
{
	return QAngle(PAICDevlos_RadianToDegrees(atan(PAICDevlos_Float_ProtectedDiv(vector.z,vector.Length2D())))*-1, PAICDevlos_RadianToDegrees(atan(PAICDevlos_Float_ProtectedDiv(vector.y,vector.x)))+PAICDevlos_SignAngleInc(vector.x), 0);
}

PAICDevlos_SetBotLookDirection <- function (player, pos)
{
	local playerPos = player.EyePosition();

	local lookingAngle = PAICDevlos_LookingAtAngles(playerPos, pos);

	player.SnapEyeAngles(lookingAngle);
}

PAICDevlos_VectorFromQAngle <- function (angles, radius = 1.0)
{
	local function ToRad(angle)
	{
		return (angle * PI) / 180;
	}
   
	local yaw = ToRad(angles.Yaw());
	local pitch = ToRad(-angles.Pitch());
   
	local x = radius * cos(yaw) * cos(pitch);
	local y = radius * sin(yaw) * cos(pitch);
	local z = radius * sin(pitch);
   
	return Vector(x, y, z);
}

PAICDevlos_ChargeTime <- function (self , CurrentTarget){
    local timeTaken = 2.5;  
    local distanceCovered = 960;  
    local targetDistance = (self.GetOrigin() - CurrentTarget.GetOrigin()).Length();  

    local x = (timeTaken / distanceCovered) * targetDistance;

    if(x < 0.01){
       // printl("<")
        x = 0.00
    }
    
    local Xstring = x.tostring()
    if(Xstring.len() >= 3){
        Xstring = Xstring.slice(0, 3)
    }

    local number = Xstring.tofloat()
//    printl("Time: "+number);
    return number;
}

PAICDevlos_.OnGameEvent_player_spawn <- function ( params )
{
    local Player = GetPlayerFromUserID( params.userid );

    if(Player.GetZombieType() == 6 && IsPlayerABot(Player))
    {
        Player.ValidateScriptScope()
        Player.GetScriptScope()["CheckNav"] <- function()
        {

            local PummelVictim = NetProps.GetPropEntity( self , "m_pummelVictim")
            local CarryVictim = NetProps.GetPropEntity( self , "m_carryVictim")

            local CurrentTarget = NetProps.GetPropEntity( self , "m_lookatPlayer")

            if(self != null && self.IsValid() && CurrentTarget != null && CurrentTarget.IsValid() && self.GetHealth() > 0)
            {
                local ability = NetProps.GetPropEntity(self, "m_customAbility");
                local Charge_Used = NetProps.GetPropInt(ability , "m_hasBeenUsed");
                local IsCharging =  NetProps.GetPropInt(ability , "m_isCharging")

                if(CurrentTarget.GetVelocity().z != 0){
                DoEntFire("!self", "RunScriptCode", @"CommandABot( { bot = self , cmd = DirectorScript.BOT_CMD_RESET} );" , 0.00 , null, self);
                }

                local headPos = self.EyePosition()
                local headAng = PAICDevlos_VectorFromQAngle(self.EyeAngles())
                local traceTable = {start = headPos , end = headPos + headAng * 999999 , ignore = self , mask = 33570827}

                if(TraceLine(traceTable))
                {
                    local entity = traceTable.enthit
                    local ChargeChance = PAICDevlos_Chance(self , CurrentTarget)
                    local IsDeadlySS = PAICDevlos_IsDeadly(self , self , false)
                    local IsDeadlyCS = PAICDevlos_IsDeadly(CurrentTarget , self , true)
                    local NavBuildPath = NavMesh.NavAreaBuildPath(self.GetLastKnownArea() , CurrentTarget.GetLastKnownArea() , CurrentTarget.GetOrigin() , (self.GetOrigin()-CurrentTarget.GetOrigin()).Length() , 3 , true)
                    local ChargeTime = PAICDevlos_ChargeTime(self , CurrentTarget)

                    if(CarryVictim != CurrentTarget || PummelVictim != CurrentTarget){
                        if(IsCharging){
                            NetProps.SetPropInt(ability , "m_hasBeenUsed" , 0); // Reset to 0 , does not update after first charge.
                            if(ChargeChance < 60 && ChargeTime > 1.5){
                                PAICDevlos_SetBotLookDirection(self , CurrentTarget.GetCenter())
                            }
                        }
                        else if(!IsCharging){
                            PAICDevlos_SetBotLookDirection(self , CurrentTarget.GetCenter())
                        }
                    }

                    if(IsDeadlySS || IsDeadlyCS)
                    {
                        if(entity == CurrentTarget)
                        {
                            if(NavBuildPath)
                            {
                                //DebugDrawLine(traceTable.start, traceTable.end, 0 , 255 , 0, false, 5);
                                DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonDisabled"" , NetProps.GetPropInt(self , ""m_afButtonDisabled"") & ~1)" , 0.00 , null, self);
                            }
                            else if(!NavBuildPath)
                            {
                                //DebugDrawLine(traceTable.start, traceTable.end, 255 , 255 , 0, false, 5);
                                NetProps.SetPropInt(self , "m_afButtonDisabled", 1);
                            }
                            else
                            {
                                //DebugDrawLine(traceTable.start, traceTable.end, 0 , 0 , 255 , false, 5);
                                DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonDisabled"" , NetProps.GetPropInt(self , ""m_afButtonDisabled"") & ~1)" , 0.00 , null, self);
                            }
                        }
                        else
                        {
                            //DebugDrawLine(traceTable.start, traceTable.end, 255 , 0 , 0, false, 5);
                            DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonDisabled"" , NetProps.GetPropInt(self , ""m_afButtonDisabled"") & ~1)" , 0.00 , null, self);
                        }
                    }
                    else if(!IsDeadlySS && !IsDeadlyCS)
                    {
                        DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonDisabled"" , NetProps.GetPropInt(self , ""m_afButtonDisabled"") & ~1)" , 0.00 , null, self);

                        if(ChargeChance > 75)
                        {
                            if(entity == CurrentTarget)
                            {
                                if(Charge_Used == 0)
                                {
                                    NetProps.SetPropInt(self , "m_afButtonForced", 1);  DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonForced"" , NetProps.GetPropInt(self , ""m_afButtonForced"") & ~1)" , 0.01 , null, self);
                                }
                                else if(Charge_Used == 1)
                                {
                                    NetProps.SetPropInt(self , "m_afButtonForced", 2048); DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonForced"" , NetProps.GetPropInt(self , ""m_afButtonForced"") & ~2048)" , 0.01 , null, self);
                                }
                            }
                        }
                    }

                    if(IsDeadlySS && IsDeadlyCS)
                    {
                        DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonDisabled"" , NetProps.GetPropInt(self , ""m_afButtonDisabled"") & ~1)" , 0.00 , null, self);

                        if(entity == CurrentTarget)
                        {
                            if(ChargeChance > 90)
                            {
                                if(Charge_Used == 0)
                                {
                                    NetProps.SetPropInt(self , "m_afButtonForced", 1);  DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonForced"" , NetProps.GetPropInt(self , ""m_afButtonForced"") & ~1)" , 0.01 , null, self);
                                }
                                else if(Charge_Used == 1)
                                {
                                    NetProps.SetPropInt(self , "m_afButtonForced", 2048); DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonForced"" , NetProps.GetPropInt(self , ""m_afButtonForced"") & ~2048)" , 0.01 , null, self);
                                }
                            }
                            else
                            {
                                DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonDisabled"" , NetProps.GetPropInt(self , ""m_afButtonDisabled"") & ~1)" , 0.00 , null, self);
                            }
                        }
                    }
                }
            }
            return 0.11
        }
        AddThinkToEnt(Player , "CheckNav");
    }
}

__CollectGameEventCallbacks(PAICDevlos_);

