LAC = LAC or {}

function LAC.ReceiveDataCvar(len, ply)

	if ( IsValid( ply ) and ply:IsPlayer() ) then
		local cvarName = net.ReadString()
		local cvarData = net.ReadString()
		local pTable = LAC.GetPTable(ply)
		if (!pTable) then return end
		
		if (cvarName == nil or cvarData == nil) then 
			local clError = string.Format("LAC has detected a malformed cvar message! PlayerName: %s SteamID: %s", pTable.pInfo.Name, pTable.pInfo.SteamID32)
			LAC.LogNeutralEvent(clError)
			return
		end
		
		local serverValue = GetConVar( cvarName ):GetString()
		if (serverValue == "" or serverValue == nil) then return end
		
		if (serverValue != cvarData) then
			local DetectionString = string.format("Detected %s with an incorrect console variable! %s = %s.", pTable.pInfo.Name, cvarName, cvarData);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.OBVIOUS, ply, true)
			return
		end
		
	end
end
net.Receive("LACDataC", LAC.ReceiveDataCvar)

function LAC.BeginDataCvarChallenge(ply)

	if ( !IsValid(ply) or ply:IsBot() ) then return end

	--[[ 
		We cannot rely on a client to send their cvars via a callback, it's better to ask them occasionally, for the hell of it.

		It is possible to request CVar data via server-side module without running lua, but I've yet to write that.
	]]
	local possibleCvars = 
	{
		"sv_cheats",
		"sv_allowcslua",
		"mat_wireframe",
		"mat_fullbright",
	}

	local chosenCvar = possibleCvars[math.random(1, #possibleCvars)]
	local chosenCvarString = "tostring(cvars.String(\"" .. chosenCvar .. "\"))" -- jesus christ 
	local challengeCode = 
	[[
	net.Start("LACDataC")
		net.WriteString("]] .. chosenCvar .. [[")
		net.WriteString(]] .. chosenCvarString .. [[)
	net.SendToServer()
	]]

	--print(challengeCode)
	ply:SendLua(challengeCode)
end

function LAC.ChooseRandomPlayerForCvarChallenge()
	local plys = player.GetHumans()
	local chosenPlayer = plys[math.random(1, #plys)]
	LAC.BeginDataCvarChallenge(chosenPlayer)
end
timer.Create("LAC_CvarRandomChallenge", 5, 0, LAC.ChooseRandomPlayerForCvarChallenge)

--[[
	Im actually mortified this catches people.
	checks random commandtables once in awhile/on spawn n shit.

	incoming huge shit table from some weird ass source
]]

local cc_badcmds = { -- Credits to HeX, I didn't make this table
"lenny_menu","******ff","******fl","******i","******mxsh","******npc","******on","******sd","******shd","******shit","******sz","******w","****_admins","+ATMenu","+Aim","+AimAssist","+AimBHOP","+Ares_Aim","+Ares_Nikes","+Ares_Pointer","+Ares_PropKill","+Ares_SlowNikes","+BMaimbot","+BUTT****","+BUTTFUCK","+BaconToggle",
"+Bacon_Menu","+Bacon_Trigger_Bot","+Bacon_triggerbot_toggle","+CBon_menu","+DragonBot_Aim","+Hax_Menu","+Hax_Zoom","+Hax_aimbot","+Helix_Menu","+Ink_Aim","+Isis_Aim","+Isis_Menu","+Isis_Speed","+MAim","+MPause","+MSpeed","+Mawpos","+Neon_Aim","+Neon_PropKill","+Neon_SpeedHack","+Nis_Menu","+Propkill","+SethHackToggle",
"+SethHack_Menu","+SethHack_Speed","+Sethhacks_Aim","+Sethhacks_Menu","+Sethhacks_Speed","+TB_Aim","+TB_Bhop","+TB_Menu","+TB_RapidFire","+TB_Speed","+aa","+ah_menu","+aim","+aimbot","+aimbot_scan","+anthrax_floodserver","+asb","+asb_bot","+autofire","+bb_menu","+bc_aimbot","+bc_spamprops","+bc_speedshoot","+bs_getpos","+bs_getview","+butt****","+buttfuck","+cal_aim",
"+cal_menu","+cb_aim","+cf_aim","+cf_bunnyhop","+cf_speed","+elebot","+enabled","+entinfo","+falco_makesound","+fap_aim","+follow_aim","+fox_aim","+gen_aim","+gen_bhop","+gen_speed","+gofast","+goslow","+gzfaimbot","+hax_admin","+hax_rapidfire","+helix_aim","+helix_speed","+hera_aim","+hera_menu","+hera_speed","+hermes_aim","+hermes_menu","+hermes_speed","+ihaimbot","+jbf_scan","+kenny","+kilos_aim",
"+leetbot","+li_aim","+li_bhop","+li_menu","+makesound","+nBot","+name_changer","+namechanger","+nbot_Options","+nbot_options","+neon_menu","+nou","+odius_aim","+odius_pkmode","+pb_aim","+pk","+qq_aimbot_enabled","+qq_nospread_triggerbot","+qq_speedhack_speed","+save_replay","+sh_aim","+sh_bhop","+sh_menu","+sh_speed","+sh_triggerbot","+shenbot_aimbot","+slobpos","+sykranos_is_really_sexy",
"+sykranos_is_sexier_then_hex","+sykranos_is_sexy","+triggerbot","+trooper_menu","+ubot_viser","+wots_menu","+wots_spinhack","+wots_toggleimmunity","+wowspeed","+zumg","-bc_aimbot","-shenbot_aimbot","-ubot_viser","2a1f3e4r5678j9r9w8j7d54k6r2a84","AGT_AimBotToggle","AGT_AutoshootToggle","AGT_RandomName","Ares_Clear_IPs","Ares_ForceImpulse","Ares_Menu_AimBot","Ares_Menu_ESP","Ares_Menu_Misc","Ares_Print_IPs","BMaimbot","BMpublicaimbot_menu","BMpublicaimbot_reload","BMpublicaimbot_toggle","BaconToggle",
"Bacon_AntiSnap","Bacon_EntTriggerBot","Bacon_FF_Toggle","Bacon_Ignore_SteamFriends","Bacon_Mode","Bacon_Reload_Script","Bacon_TriggerBotDelay","Bacon_Trigger_Bot","Bacon_load","Bacon_triggerbot_toggle","BlankNCON","CBon_Reload_Script","CrashTheServer","DragonBot_menu","ForceLaunch_BB","GAT_RandomName","GayOn","Ink_LoadMenu","Ink_menu","Inkbot_Crack","Isis_InteractC4","Isis_Menu_Reload","Isis_Spin","JBF_enemysonly_off","JBF_enemysonly_on","JBF_headshots_off","JBF_headshots_on","JBF_lagcompensation","JBF_off",
"JBF_offset","JBF_on","JBF_playersonly_off","JBF_playersonly_on","JBF_suicidehealth","Kenny_noclip","Monster_Menu","NameGenDerma","Neon_ForceCheats","Neon_LoadMenu","Neon_SayTraitors","Orgflashstyle1","Orgflashstyle2","PsaySpamOn","RLua","RandomNCOn","RatingSpammerOn","ReloadAA","SE_AddFile","SE_ByPass","SE_LoadScripts","SE_RemoveFile","SetCV","SethHackToggle","SethHack_AddNPCfriend","SethHack_Clear_All","SethHack_ff_toggle","SethHack_lua_openscript","SethHack_lua_run","SethHack_panic","SethHack_triggerbot_toggle",
"SethHack_wallhack_player","SethHack_wallhack_wire","Smelly_Clear_IPs","Smelly_Print_IPs","SpamMenu","SpamTime","Spam_Chat","Spam_Chat-v2","Spam_Props","Spam_Props-V2","SpinBot_on","TB_Console","ThermHack_ToggleMenu","ThrowMagneto","UltraCrashTheServer","_JBF_lagcompensation","_PoKi_menu_reload","_aimbot","_aimbot_headshots","_fap_initshit","_fap_menu_reload","_fap_reload","_fap_reload_menu","_timescale","aa_enabled","aa_menu","aa_reload","aa_toggle","aah_setupspeedhack","ah_aimbot",
"ah_aimbot_friends","ah_antihook","ah_changer","ah_chatspammer","ah_cheats","ah_hookhide","ah_hooks","ah_name","ah_reload","ah_spammer","ah_speed","ah_timestop","ahack_menu","aimbot","aimbot_headshots_on","aimbot_hitbox","aimbot_off","aimbot_offset","aimbot_on","aimbot_scan","aimbot_target_clear","aimbot_target_closest","aimbot_target_teamates","anthrax_banadmins","anthrax_demoteadmins","anthrax_filemenu","asb","asb_base_reload","asb_base_unload","asb_bot","asb_nospread","asb_options","asb_players","asb_reload","asb_shoot",
"asb_unload","at_autoaim_off","at_autoaim_on","at_autoshoot_off","at_autoshoot_on","at_changer_off","at_changer_on","at_menu","at_norecoil_off","at_norecoil_on","bacon_autoreload","bacon_chatspam","bacon_chatspam_interval","bacon_lua_openscript","bacon_namechange","bacon_norecoil","bacon_toggle","bb","bc_ips","bc_reload","bc_unload","bs_force_load","bs_inject","bs_reload","bs_unload","bypass_se","cf_aim_toggle","cf_freeze","cf_menu","cf_menu_toggle","change_name","cl_docrash","cl_name","cs_lua",
"cub_toggle","deathrun_qq","discord1","discord2","download_file","dump_remote_lua2","elebot_boxsize","elebot_filledbox","elebot_maxview","elebot_minview","elebot_offset","elebot_showadmin","elebot_simplecolors","elebot_targetteam","entinfo_target","entinfo_targetplayer","entinfo_targetplayer","entx_camenable","entx_run1","entx_run2","entx_run3","entx_run4","entx_setvalue","entx_spazoff","entx_spazon","entx_traceget","exploit",
"exploit_admin","exploit_bans","exploit_cfg","exploit_rcon","falco_hotkey","falco_hotkeyList","falco_makesound","falco_openlooah","falco_rotate1","falco_rotate2","falco_runlooah","fap_aim","fap_aim_antisnap","fap_aim_antisnapspeed","fap_aim_autofire","fap_aim_autoreload","fap_aim_bonemode","fap_aim_enabled","fap_aim_friendlyfire","fap_aim_maxdistance","fap_aim_norecoil","fap_aim_nospread","fap_aim_targetadmins","fap_aim_targetfriends","fap_aim_targetmode","fap_aim_targetnpcs",
"fap_aim_targetsteamfriends","fap_aim_toggle","fap_aimbot_toggle","fap_bind","fap_checkforupdates","fap_enablekeybinding","fap_menu","fap_reload","fap_unbind","fl_fillhp","force_cvar","formatlaser","frotate","gen_aim","gen_autoshoot","gen_speed","getrcon","go_unconnected","gzfaimbot","gzfaimbot_enabled","gzfaimbot_menu","gzfaimbot_reload","gzfaimbot_toggle","h_bo_thirdperson","h_firewall","h_gtower_debug","h_helxa_decrypt","h_helxa_encrypt","h_name","h_openscript",
"h_runscript","helix_admins","helix_aim_bone","helix_aim_crosshair","helix_aim_fov","helix_aim_los","helix_aim_norecoil","helix_aim_players","helix_aim_shoot","helix_aim_team","helix_aim_trigger","helix_barrelbomb","helix_blocklua","helix_chatspammer","helix_crypto_binary","helix_cvarmenu","helix_forcerandomname_off","helix_forcerandomname_on","helix_propspam","helix_propspam_mdl",
"helix_propspammer2","helix_reload","helix_rpnamespammer","helix_speed","helix_troll","helix_undo","helix_unload","hera_convar_get","hera_convar_set","hera_include","hera_runstring","ihpublicaimbot_menu","ihpublicaimbot_reload","ihpublicaimbot_toggle","inc_g","jonsuite_unblockx","kenny_addhit","kenny_bodyshots","kenny_tagasshole","kenny_team","kennykill","kon_chatspam","kon_stopspam","lagoff","lagon","leetbot_boxsize",
"leetbot_filledbox","leetbot_maxview","leetbot_minview","leetbot_offset","leetbot_showadmin","leetbot_simplecolors","leetbot_targetteam","li_menu","lix_lesp_rotate","lix_lesp_rotate1","lix_lesp_rotate2","lix_lesp_rotate3","lol_****this","lol_adminalert","lol_admins","lol_aim","lol_barrel","lol_cancel","lol_chat","lol_copy","lol_fuckthis","lol_headshot","lol_help","lol_name","lol_rcon","lol_setchat","lol_teamshot","lol_togglestick","lua_dofile_cl",
"lua_dostring_cl","lua_logo_reload","lua_openscript_cl2","lua_run_quick","lua_se2_load","makesound","metalslave_aimbot_menu","metalslave_aimbot_reload","metalslave_aimbot_toggle","metalslave_chams_reload","mh_esp_rehook","mh_keypad","mh_open","mh_owners","mh_toggleflag","mh_turn180","mh_unlock","ms_pato","ms_sv_cheats","name_change","name_changer","name_menu","namechanger_on","nbot_Options","nbot_UseSelectedPerson","nbot_aimfixer","nbot_autoshoot","nbot_speedoffset","niggerff",
"niggerfl","niggeri","niggermxsh","niggernpc","niggeron","niggersd","niggershd","niggershit","niggersz","niggerw","odius_menu","pb_aim_trigger","pb_load","pb_menu","ph0ne_aim","ph0ne_aimcancel","ph0ne_autoshoot","plugin_load","pp_pixelrender","print_file","print_file_listing_load","print_server_cfg","qq_menu","raidbot_predictcheck","rs","sb_toggle","se_add","se_on","send_file","server_command","setconvar","sethhack_load","sh_luarun","sh_menu","sh_print_traitors","sh_runscripts","sh_showips","sh_toggleaim","sh_togglemenu","sh_triggerbot",
"shenbot_bunnyhoptoggle","shenbot_menu","sm_fexec","spamchair","spamchat","spamjeeps","speedhack_speed","spinlol","st_jumpspam","startspam","stopspam","sv_add1","sv_printdir","sv_printdirfiles","sv_run1","sykranos_is_sexy_menu","target_menu","toggle_target","upload_file","vlua_run","wire_button_model","wots_attack","wots_crash","wots_lag_off","wots_lag_on","wots_megaspam","wots_menu","wots_namecracker_menu","wots_namecracker_off","wots_namecracker_on","wots_namegen_off","wots_namegen_on","wots_spinhack","x_menu","x_reload"
}

local cc_custom_badcmds = {
	"external",
	"neko",
	"nethack_menu",
	"ace_menu",
}

function LAC.CheckIdiotsCommandTableAll()
	net.Start("LACCI")
	net.Broadcast()
end
hook.Add("TTTPrepareRound", "LAC_PISIC", LAC.CheckIdiotsCommandTableAll)

function LAC.ReceiveIdiotsCommandTable(len, ply)
	if ( !IsValid( ply ) and !ply:IsPlayer() ) then return end

	local pTable = LAC.GetPTable(ply);
	if (pTable == nil) then return end

	local tab1 = net.ReadTable()
	local tab2 = net.ReadTable()

	local newtab = {}
	-- Put the split tables back together
	for i = 1, #tab1 do
		newtab[i] = tab1[i]
	end

	for i = #tab1 + 1, #tab2 do
		newtab[i] = tab2[i]
	end

	for k, v in ipairs( newtab ) do
		if ( table.HasValue( cc_badcmds, v ) or table.HasValue( cc_custom_badcmds, v ) ) then
			local DetectionString = string.format("Detected %s with a black-listed console variable! %s.", pTable.pInfo.Name, v);
			LAC.PlayerDetection(DetectionString, LAC.DetectionValue.OBVIOUS, ply, true)
		end
	end

end
net.Receive("LACCI", LAC.ReceiveIdiotsCommandTable)