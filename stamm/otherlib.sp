#pragma semicolon 1

new Handle:otherlib_inftimer;

public otherlib_PrepareFiles()
{
	if (!StrEqual(g_lvl_up_sound, "0")) 
	{
		otherlib_DownloadLevel();	
		PrecacheSound(g_lvl_up_sound, true);
	}
}

public otherlib_DownloadLevel()
{
	decl String:downloadfile[PLATFORM_MAX_PATH + 1];
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", g_lvl_up_sound);
	
	AddFileToDownloadsTable(downloadfile);
}

public otherlib_getGame()
{
	return g_gameID;
}

public otherlib_saveGame()
{
	new String:GameName[12];
	g_gameID = 0;
	
	GetGameFolderName(GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "cstrike")) 
		g_gameID = 1;
	if (StrEqual(GameName, "csgo")) 
		g_gameID = 2;
	if (StrEqual(GameName, "tf")) 
		g_gameID = 3;
	if (StrEqual(GameName, "dod"))
		g_gameID = 4;
}

public Action:otherlib_PlayerInfoTimer(Handle:timer)
{
	CPrintToChatAll("%s %t", g_StammTag, "InfoTyp", g_texttowrite_f);
	CPrintToChatAll("%s %t", g_StammTag, "InfoTypInfo", g_sinfo_f);
	
	return Plugin_Continue;
}

public otherlib_MakeHappyHour(client)
{
	g_happynumber[client] = 1;
	
	CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyTime");
	CPrintToChat(client, "%s %t", g_StammTag, "WriteHappyTimeInfo");
}

public otherlib_EndHappyHour()
{
	if (g_happyhouron)
	{
		decl String:query[128];

		Format(query, sizeof(query), "DELETE FROM `%s_happy`", g_tablename);
		
		if (g_debug) 
			LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
		
		SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);

		g_points = 1;
		g_happyhouron = 0;
		
		g_HappyTimer = otherlib_checkTimer(g_HappyTimer);
		
		CPrintToChatAll("%s %t", g_StammTag, "HappyEnded");
		
		nativelib_HappyEnd();
		
		clientlib_CheckPlayers();
	}
}

public otherlib_StartHappyHour(time, factor)
{
	decl String:query[128];

	Format(query, sizeof(query), "INSERT INTO `%s_happy` (`end`, `factor`) VALUES (%i, %i)", g_tablename, GetTime() + time, factor);
	
	if (g_debug) 
		LogToFile(g_DebugFile, "[ STAMM DEBUG ] Execute %s", query);
	
	SQL_TQuery(sqllib_db, sqllib_SQLErrorCheckCallback, query);

	g_points = factor;

	g_happyhouron = 1;
	
	CPrintToChatAll("%s %t", g_StammTag, "HappyActive", g_points);
	
	otherlib_checkTimer(g_HappyTimer);

	g_HappyTimer = CreateTimer(float(time), otherlib_StopHappyHour);
	
	nativelib_HappyStart(time/60, g_points);
}

public Action:otherlib_StopHappyHour(Handle:timer)
{
	otherlib_EndHappyHour();
}

public Action:otherlib_StartHappy(args)
{
	if (GetCmdArgs() == 2 && !g_happyhouron)
	{
		decl String:timeString[25];
		decl String:factorString[25];
		
		GetCmdArg(1, timeString, sizeof(timeString));
		GetCmdArg(2, factorString, sizeof(factorString));
		
		new time = StringToInt(timeString);

		if (time > 1 && StringToInt(factorString) > 1)
			otherlib_StartHappyHour(time*60, StringToInt(factorString));
		else
			ReplyToCommand(0, "[ STAMM ] Time and Factor have to be greater than 1 !");
	}
	else
		ReplyToCommand(0, "Usage: stamm_start_happyhour <time> <factor>");
}

public Action:otherlib_StopHappy(args)
{
	otherlib_EndHappyHour();
}

public Handle:otherlib_checkTimer(Handle:timer)
{
	if (timer != INVALID_HANDLE)
		KillTimer(timer);
	
	return INVALID_HANDLE;
}