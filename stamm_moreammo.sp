/**
 * -----------------------------------------------------
 * File        stamm_moreammo.sp
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
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <stamm>
#include <updater>

#pragma semicolon 1




new ammo;

new Handle:c_ammo;
new Handle:thetimer;

new bool:WeaponEdit[MAXPLAYERS + 1][2024];




public Plugin:myinfo =
{
	name = "Stamm Feature MoreAmmo",
	author = "Popoklopsi",
	version = "1.2.1",
	description = "Give VIP's more ammo",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};



// Add feature
public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) 
	{
		SetFailState("Can't Load Feature, Stamm is not installed!");
	}

	if (STAMM_GetGame() == GameTF2)
	{
		HookEvent("teamplay_round_start", RoundStart);
		HookEvent("arena_round_start", RoundStart);
	}
	

	if (STAMM_GetGame() == GameDOD)
	{
		HookEvent("dod_round_start", RoundStart);
	}

	else
	{
		HookEvent("round_start", RoundStart);
	}

	STAMM_LoadTranslation();
	STAMM_AddFeature("VIP MoreAmmo", "");
}



// Create config and hook round start
public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);

	// Config
	AutoExecConfig_SetFile("moreammo", "stamm/features");
	
	c_ammo = AutoExecConfig_CreateConVar("ammo_amount", "20", "Ammo increase in percent each block!");
	
	AutoExecConfig(true, "moreammo", "stamm/features");
	AutoExecConfig_CleanFile();
}



// Feature loaded, add desc. and auto updater
public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:haveDescription[64];
	decl String:urlString[256];

	Format(urlString, sizeof(urlString), "http://popoklopsi.de/stamm/updater/update.php?plugin=%s", basename);

	if (LibraryExists("updater") && STAMM_AutoUpdate())
	{
		Updater_AddPlugin(urlString);
	}

	// Add dscriptions for block
	for (new i=1; i <= STAMM_GetBlockCount(); i++)
	{
		Format(haveDescription, sizeof(haveDescription), "%T", "GetMoreAmmo", LANG_SERVER, ammo * i);
		
		STAMM_AddFeatureText(STAMM_GetLevel(i), haveDescription);
	}
}



// Reset on mapstart
public OnMapStart()
{
	if (thetimer != INVALID_HANDLE) 
	{
		KillTimer(thetimer);
	}

	// Create check timer
	thetimer = CreateTimer(1.0, CheckWeapons, _, TIMER_REPEAT);
}



// Load config
public OnConfigsExecuted()
{
	ammo = GetConVarInt(c_ammo);
}



// Reset on death
public PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (new x=0; x < 2024; x++) 
	{
		WeaponEdit[client][x] = false;
	}
}



public RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	// Reset on round start
	for (new x=0; x < 2024; x++)
	{
		for (new i=0; i <= MaxClients; i++) 
		{
			WeaponEdit[i][x] = false;
		}
	}
}



// Check weapons
public Action:CheckWeapons(Handle:timer, any:data)
{
	// Client loop
	for (new i = 1; i <= MaxClients; i++)
	{
		new client = i;
		
		// Client valid?
		if (STAMM_IsClientValid(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			// Block loop
			for (new j=STAMM_GetBlockCount(); j > 0; j--)
			{
				// Client have block?
				if (STAMM_HaveClientFeature(client, j))
				{
					// Weapon loop
					for (new x=0; x < 2; x++)
					{
						// Player carry weapon?
						new weapon = GetPlayerWeaponSlot(client, x);

						if (weapon != -1 && !WeaponEdit[client][weapon])
						{
							// Get ammo index
							new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

							// Found ammo?
							if (ammotype != -1)
							{
								// Get ammo count
								new cAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
								
								// Found ammo count
								if (cAmmo > 0)
								{
									// Calculate new Ammo
									new newAmmo;
									
									newAmmo = RoundToZero(cAmmo + ((float(cAmmo)/100.0) * (j * ammo)));
									
									// Set ammo
									SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
									
									WeaponEdit[client][weapon] = true;
								}
							}
						}
					}

					break;
				}
			}
		}
	}
	
	return Plugin_Continue;
}