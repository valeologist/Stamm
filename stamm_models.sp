#include <sourcemod>
#include <sdktools>
#include <colors>
#include <autoexecconfig>
#undef REQUIRE_PLUGIN
#include <stamm>

#pragma semicolon 1

new PlayerHasModel[MAXPLAYERS + 1];
new LastTeam[MAXPLAYERS + 1];
new model_change;
new same_models;
new admin_model;

new String:PlayerModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH + 1];
new String:T_1_MODEL[PLATFORM_MAX_PATH + 1];
new String:T_1_NAME[128];
new String:T_2_MODEL[PLATFORM_MAX_PATH + 1];
new String:T_2_NAME[128];
new String:CT_1_MODEL[PLATFORM_MAX_PATH + 1];
new String:CT_1_NAME[128];
new String:CT_2_MODEL[PLATFORM_MAX_PATH + 1];
new String:CT_2_NAME[128];
new String:model_change_cmd[32];

new Handle:c_model_change_cmd;
new Handle:c_model_change;
new Handle:c_same_models;
new Handle:c_admin_model;

new bool:Loaded;

public Plugin:myinfo =
{
	name = "Stamm Feature Vip Models",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's VIP Models",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
		SetFailState("Can't Load Feature, Stamm is not installed!");
	
	if (STAMM_GetGame() == GameTF2) 
		SetFailState("Can't Load Feature, not Supported for your game!");

	if (!CColorAllowed(Color_Lightgreen) && CColorAllowed(Color_Lime))
 	 	CReplaceColor(Color_Lightgreen, Color_Lime);
		
	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP Models", "");
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	
	if (model_change)
		Format(description, sizeof(description), "%T", "GetModelChange", LANG_SERVER, model_change_cmd);
	else 
		Format(description, sizeof(description), "%T", "GetModel", LANG_SERVER);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("stamm/features/vip_models");

	c_model_change = AutoExecConfig_CreateConVar("model_change", "1", "0 = Players can only change models, when changing team, 1 = Players can always change it");
	c_admin_model = AutoExecConfig_CreateConVar("model_admin_model", "1", "Should Admins also get a VIP Skin 1 = Yes, 0 = No");
	c_model_change_cmd = AutoExecConfig_CreateConVar("model_change_cmd", "sm_smodel", "Command to change model");
	c_same_models = AutoExecConfig_CreateConVar("model_models", "0", "1 = Vip's get always the same Skin 0 = Random Skin every Round");

	AutoExecConfig(true, "vip_models", "stamm/features");
	AutoExecConfig_CleanFile();
	
	HookEvent("player_team", eventPlayerTeam);
	HookEvent("player_spawn", eventPlayerSpawn);
	
	ModelDownloads();
	
	Loaded = false;
}

public OnConfigsExecuted()
{
	model_change = GetConVarInt(c_model_change);
	same_models = GetConVarInt(c_same_models);
	admin_model = GetConVarInt(c_admin_model);
	
	GetConVarString(c_model_change_cmd, model_change_cmd, sizeof(model_change_cmd));

	if (!FileExists("cfg/stamm/features/ModelSettings.txt"))
		SetFailState("Couldn't load Stamm Models. ModelSettings.txt missing.");
	
	new Handle:model_settings = CreateKeyValues("ModelSettings");
	FileToKeyValues(model_settings, "cfg/stamm/features/ModelSettings.txt");
	
	KvGetString(model_settings, "T_1_MODEL", T_1_MODEL, sizeof(T_1_MODEL));
	KvGetString(model_settings, "T_1_NAME", T_1_NAME, sizeof(T_1_NAME));
	KvGetString(model_settings, "T_2_MODEL", T_2_MODEL, sizeof(T_2_MODEL));
	KvGetString(model_settings, "T_2_NAME", T_2_NAME, sizeof(T_2_NAME));
	KvGetString(model_settings, "CT_1_MODEL", CT_1_MODEL, sizeof(CT_1_MODEL));
	KvGetString(model_settings, "CT_1_NAME", CT_1_NAME, sizeof(CT_1_NAME));
	KvGetString(model_settings, "CT_2_MODEL", CT_2_MODEL, sizeof(CT_2_MODEL));
	KvGetString(model_settings, "CT_2_NAME", CT_2_NAME, sizeof(CT_2_NAME));
	
	CloseHandle(model_settings);
	
	if (!Loaded)
	{
		RegConsoleCmd(model_change_cmd, CmdModel);
		Loaded = true;
	}
	
	if (!StrContains(model_change_cmd, "sm_") || StrContains(model_change_cmd, "!") != 0)
	{
		ReplaceString(model_change_cmd, sizeof(model_change_cmd), "sm_", "");
		Format(model_change_cmd, sizeof(model_change_cmd), "!%s", model_change_cmd);
	}
	
	if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ")) 
		PrecacheModel(T_1_MODEL, true);
		
	if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ")) 
		PrecacheModel(T_2_MODEL, true);
		
	if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ")) 
		PrecacheModel(CT_1_MODEL, true);
		
	if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ")) 
		PrecacheModel(CT_2_MODEL, true);
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (STAMM_IsClientValid(client))
	{
		if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		{
			if (LastTeam[client] != GetClientTeam(client))
			{
				PlayerHasModel[client] = 0;
				
				Format(PlayerModel[client], PLATFORM_MAX_PATH + 1, "");
			}
			
			LastTeam[client] = GetClientTeam(client);
			
			if (STAMM_HaveClientFeature(client))
			{
				if (same_models) 
					PrepareSameModels(client);
				else 
					PrepareRandomModels(client);
			}
		}
	}
}

public Action:eventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		PlayerHasModel[client] = 0;
		
		Format(PlayerModel[client], PLATFORM_MAX_PATH + 1, "");
	}
}

public ModelDownloads()
{
	if (!FileExists("cfg/stamm/features/ModelDownloads.txt"))
	{
		STAMM_WriteToLog(false, "Couldn't find ModelDownloads.txt");

		return;
	}

	new Handle:downloadfile = OpenFile("cfg/stamm/features/ModelDownloads.txt", "rb");
	
	if (downloadfile != INVALID_HANDLE)
	{
		while (!IsEndOfFile(downloadfile))
		{
			decl String:filecontent[PLATFORM_MAX_PATH + 10];
			
			ReadFileLine(downloadfile, filecontent, sizeof(filecontent));
			ReplaceString(filecontent, sizeof(filecontent), " ", "");
			ReplaceString(filecontent, sizeof(filecontent), "\n", "");
			ReplaceString(filecontent, sizeof(filecontent), "\t", "");
			ReplaceString(filecontent, sizeof(filecontent), "\r", "");
			
			if (!StrEqual(filecontent, "")) 
				AddFileToDownloadsTable(filecontent);
		}

		CloseHandle(downloadfile);
	}
}

public Action:CmdModel(client, args)
{
	if (STAMM_IsClientValid(client))
	{
		if (model_change && PlayerHasModel[client])
		{
			PlayerHasModel[client] = 0;
			
			Format(PlayerModel[client], PLATFORM_MAX_PATH+1, "");
			
			CPrintToChat(client, "{lightgreen}[ {green}Stamm {lightgreen}] %T", "NewModel", LANG_SERVER);
		}
	}
	
	return Plugin_Handled;
}

public ModelMenuCall(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (STAMM_IsClientValid(param1))
		{
			decl String:ModelChoose[128];
			
			GetMenuItem(menu, param2, ModelChoose, sizeof(ModelChoose));
			
			if (!StrEqual(ModelChoose, "standard"))
			{
				SetEntityModel(param1, ModelChoose);
				
				PlayerHasModel[param1] = 1;
				
				Format(PlayerModel[param1], PLATFORM_MAX_PATH + 1, ModelChoose);
			}
			if (StrEqual(ModelChoose, "standard")) 
			{
				PlayerHasModel[param1] = 1;
				
				Format(PlayerModel[param1], PLATFORM_MAX_PATH + 1, "");
			}
		}
	}
	else if (action == MenuAction_End) 
		CloseHandle(menu);
}


public PrepareSameModels(client)
{
	if (!PlayerHasModel[client] && (((!admin_model && !STAMM_IsClientAdmin(client)) || admin_model)))
	{ 
		decl String:ModelChooseLang[256];
		decl String:StandardModel[256];
		
		Format(ModelChooseLang, sizeof(ModelChooseLang), "%T", "ChooseModel", LANG_SERVER);
		Format(StandardModel, sizeof(StandardModel), "%T", "StandardModel", LANG_SERVER);
		
		new Handle:ModelMenu = CreateMenu(ModelMenuCall);
		
		SetMenuTitle(ModelMenu, ModelChooseLang);
		SetMenuExitButton(ModelMenu, false);
		
		if (GetClientTeam(client) == 2)
		{
			if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ")) 
				AddMenuItem(ModelMenu, T_1_MODEL, T_1_NAME);
				
			if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ")) 
				AddMenuItem(ModelMenu, T_2_MODEL, T_2_NAME);
		}
		
		if (GetClientTeam(client) == 3)
		{
			if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ")) 	
				AddMenuItem(ModelMenu, CT_1_MODEL, CT_1_NAME);
				
			if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ")) 
				AddMenuItem(ModelMenu, CT_2_MODEL, CT_2_NAME);
		}
		
		AddMenuItem(ModelMenu, "standard", StandardModel);
		
		DisplayMenu(ModelMenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		if (PlayerHasModel[client] && !StrEqual(PlayerModel[client], "")) 
			SetEntityModel(client, PlayerModel[client]);
	}
}

public PrepareRandomModels(client)
{
	new TMODELS = 0;
	new CTMODELS = 0;
	
	if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " "))
		TMODELS++;
		
	if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ")) 
		TMODELS++;
		
	if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ")) 
		CTMODELS++;
		
	if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ")) 
		CTMODELS++;
	
	new RandModelT = GetRandomInt(1, TMODELS);
	new RandModelCT = GetRandomInt(1, CTMODELS);
	
	if ((!admin_model && !STAMM_IsClientAdmin(client)) || admin_model)
	{
		if (GetClientTeam(client) == 2)
		{
			if (TMODELS == 1)
			{
				if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ") && !StrEqual(T_1_MODEL, "\0")) 
					SetEntityModel(client, T_1_MODEL);
					
				else if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ") && !StrEqual(T_2_MODEL, "\0")) 
					SetEntityModel(client, T_2_MODEL);
			}
			
			if (TMODELS == 2)
			{
				if (RandModelT == 1)
				{
					if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ") && !StrEqual(T_1_MODEL, "\0")) 
						SetEntityModel(client, T_1_MODEL);
				}
				if (RandModelT == 2)
				{
					if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ") && !StrEqual(T_2_MODEL, "\0")) 
						SetEntityModel(client, T_2_MODEL);
				}
			}
		}
		if (GetClientTeam(client) == 3)
		{
			if (CTMODELS == 1)
			{
				if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ") && !StrEqual(CT_1_MODEL, "\0")) 
					SetEntityModel(client, CT_1_MODEL);
					
				else if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ") && !StrEqual(CT_2_MODEL, "\0"))
					SetEntityModel(client, CT_2_MODEL);
			}
			
			if (CTMODELS == 2)
			{
				if (RandModelCT == 1)
				{
					if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ") && !StrEqual(CT_1_MODEL, "\0")) 
						SetEntityModel(client, CT_1_MODEL);
				}
				if (RandModelCT == 2)
				{
					if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ") && !StrEqual(CT_2_MODEL, "\0")) 
						SetEntityModel(client, CT_2_MODEL);
				}
			}
		}
	}
}