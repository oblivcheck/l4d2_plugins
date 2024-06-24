if (!("manacatTimers" in getroottable())){
	printl( "<MANACAT> Timer Loaded. v09/30/2021");
}

::manacatTimers <- {
	TimersList = {}
	TimersID = {}
	ClockList = {}
	count = 0
}

::manacatAddTimerByName <- function(strName, delay, repeat, func, paramTable = null, flags = 0, value = {}){
	::manacatRemoveTimerByName(strName);
	::manacatTimers.TimersID[strName] <- ::manacatAddTimer(delay, repeat, func, paramTable, flags, value);
	return strName;
}

::manacatRemoveTimerByName <- function(strName){
	if (strName in ::manacatTimers.TimersID)
	{
		::manacatRemoveTimer(::manacatTimers.TimersID[strName]);
		delete ::manacatTimers.TimersID[strName];
	}
}

::manacatRemoveTimer <- function(idx){
	if (idx in ::manacatTimers.TimersList)
		delete ::manacatTimers.TimersList[idx];
}

::manacatAddTimer <- function(delay, repeat, func, paramTable = null, flags = 0, value = {}){
	local TIMER_FLAG_COUNTDOWN = (1 << 2);
	local TIMER_FLAG_DURATION = (1 << 3);
	local TIMER_FLAG_DURATION_VARIANT = (1 << 4);
	local countN = ::manacatTimers.count;
	
	delay = delay.tofloat();
	repeat = repeat.tointeger();
	
	local rep = (repeat > 0) ? true : false;
	
	if (paramTable == null)paramTable = {};
	
	if (typeof value != "table")
	{
		printl("- - - - - - - - - - - - - Timer Error: Illegal parameter: 'value' parameter needs to be a table.");
		return -1;
	}
	else if (flags & TIMER_FLAG_COUNTDOWN && !("countN" in value))
	{
		printl("- - - - - - - - - - - - - Timer Error: Could not create the countdown timer because the 'count' field is missing from 'value'.");
		return -1;
	}
	else if ((flags & TIMER_FLAG_DURATION || flags & TIMER_FLAG_DURATION_VARIANT) && !("duration" in value))
	{
		printl("- - - - - - - - - - - - - Timer Error: Could not create the duration timer because the 'duration' field is missing from 'value'.");
		return -1;
	}
	
	// Convert the flag into countdown
	if (flags & TIMER_FLAG_DURATION)
	{
		flags = flags & ~TIMER_FLAG_DURATION;
		flags = flags | TIMER_FLAG_COUNTDOWN;
		
		value["countN"] <- floor(value["duration"].tofloat() / delay);
	}
	
	++countN;
	::manacatTimers.TimersList[countN] <-
	{
		_delay = delay
		_func = func
		_params = paramTable
		_startTime = Time()
		_baseTime = Time()
		_repeat = rep
		_flags = flags
		_opval = value
	}
	
	::manacatTimers.count = countN;
	return countN;
}

::manacat_thinkFunc <- function(){
	local TIMER_FLAG_COUNTDOWN = (1 << 2);
	local TIMER_FLAG_DURATION_VARIANT = (1 << 4);
	
	// current time
	local curtime = Time();
	
	// Execute timers as needed
	foreach (idx, timer in ::manacatTimers.TimersList){
		if ((curtime - timer._startTime) >= timer._delay){
			if (timer._flags & TIMER_FLAG_COUNTDOWN){
				timer._params["TimerCount"] <- timer._opval["count"];
				
				if ((--timer._opval["count"]) <= 0)
					timer._repeat = false;
			}
			
			if (timer._flags & TIMER_FLAG_DURATION_VARIANT && (curtime - timer._baseTime) > timer._opval["duration"]){
				delete ::manacatTimers.TimersList[idx];
				continue;
			}
			
			try{
				if (timer._func(timer._params) == false)
					timer._repeat = false;
			}
			catch (id)
			{
				if(id == null)return;
				//printl("Timer caught exception; closing timer "+idx+". Error was: "+id.tostring());
				local deadFunc = timer._func;
				local params = timer._params;
				delete ::manacatTimers.TimersList[idx];
				deadFunc(params); // this will most likely throw
				continue;
			}
			
			if (timer._repeat)
				timer._startTime = curtime;
			else
				if (idx in ::manacatTimers.TimersList) // recheck-- timer may have been removed by timer callback
					delete ::manacatTimers.TimersList[idx];
		}
	}
	foreach (idx, timer in ::manacatTimers.ClockList){
		if ( Time() > timer._lastUpdateTime ){
			local newTime = Time() - timer._lastUpdateTime;
			
			if ( timer._command == 1 )
				timer._value += newTime;
			else if ( timer._command == 2 ){
				if ( timer._allowNegTimer )
					timer._value -= newTime;
				else{
					if ( timer._value > 0 )
						timer._value -= newTime;
				}
			}
			
			timer._lastUpdateTime <- Time();
		}
	}
}

if (!("_thinkTimer" in ::manacatTimers))
{
	::manacatTimers._thinkTimer <- SpawnEntityFromTable("info_target", { targetname = "manacat_timer" });
	if (::manacatTimers._thinkTimer != null){
		::manacatTimers._thinkTimer.ValidateScriptScope();
		local scrScope = ::manacatTimers._thinkTimer.GetScriptScope();
		scrScope["ThinkTimer"] <- ::manacat_thinkFunc;
		AddThinkToEnt(::manacatTimers._thinkTimer, "ThinkTimer");
	}
	else
		return;
}