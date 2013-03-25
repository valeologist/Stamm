/**
 * -----------------------------------------------------
 * File        stamm_lessgravity.sp
 * Authors     David <popoklopsi> Ordnung
 * License     GPLv3
 * Web         http://popoklopsi.de
 * -----------------------------------------------------
 * 
 * Copyright (C) 2012-2013 David <popoklopsi> Ordnung
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */


// Includes
#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1

new grav;
new Handle:c_grav;


// Details
public Plugin:myinfo =
{
	name = "Stamm Feature LessGravity",
	author = "Popoklopsi",
	version = "1.2.2",
	description = "Give VIP's less gravity",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};




// Add the Feature
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP Less Gravity", "");
}




// Create the config
public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);

	AutoExecConfig_SetFile("lessgravity", "stamm/features");
	
	c_grav = AutoExecConfig_CreateConVar("gravity_decrease", "10", "Gravity decrease in percent each block!");
	
	AutoExecConfig(true, "lessgravity", "stamm/features");
	AutoExecConfig_CleanFile();
}



// And load it
public OnConfigsExecuted()
{
	grav = GetConVarInt(c_grav);
}




// Add to auto update and set description
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}

	// Add dsecription for each feature
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetLessGravity", LANG_SERVER, grav * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}




// A Player spawned, change his gravity
public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	STAMM_OnClientChangedFeature(client, true);
}




// Also change it, if he cahnged the state
public STAMM_OnClientChangedFeature(client, bool:mode)
{
	if (STAMM_IsClientValid(client) && IsPlayerAlive(client))
	{
		new Float:newGrav;
		
		// Client want it
		if (mode)
		{
			// Block loop
			for (new i=STAMM_GetBlockCount(); i > 0; i--)
			{
				// Have the client the block?
				if (STAMM_HaveClientFeature(client, i))
				{
					// Calculate new gravity
					newGrav = 1.0 - float(grav)/100.0 * i;

					if (newGrav < 0.1) 
					{
						newGrav = 0.1;
					}

					SetEntityGravity(client, newGrav);

					break;
				}
			}
		}
		else
		{
			// Else reset gravity
			SetEntityGravity(client, 1.0);
		}
	}
}