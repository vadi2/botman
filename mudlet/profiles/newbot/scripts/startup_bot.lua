--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	          This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

debugger = require "debug"
local debug

-- record start and end execution times of code and report it.  At the moment I'm sending the timing info to the bot's lists window.
benchmarkBot = false

function dbugi(text)
	-- send text to the watch irc channel
	if server ~= nil then
		irc_chat(server.ircWatch, text)
	end
end


function dbug(text)
	-- send text to the debug window we created in Mudlet.
	if server == nil then
		display(text .. "\n")
		return
	end

	if server.windowLists then
		windowMessage(server.windowLists, text .. "\n")
	end
end

function checkData()
	local benchStart = os.clock()

	if server.botName == nil then
		loadServer()
		botman.botStarted = nil
		login()
	end

	if tablelength(shopCategories) == 0 then
		loadShopCategories()		
	end

	if tablelength(owners) == 0 then
		send("admin list")
	end

	if tonumber(server.ServerPort) == 0 then
		send("gg")
	end

	if (botman.playersOnline > 0) then
		if 	tablelength(igplayers) == 0 then
			igplayers = {}
			send("lp")
		end
	end
	
	if not server.allocs then
		alertAdmins("Alloc's mod appears to be missing and is required to run the bot (and the server).", "warn")
		irc_chat(name, "Alloc's mod appears to be missing and is required to run the bot (and the server).")	
	end
	
	if not server.allocs then
		irc_chat(name, "Coppi's mod appears to be missing.  While not essential, it adds many great features.  Grab it here https://onedrive.live.com/?authkey=%21AGmv1pqf4fK2Oto&id=CD9F5C1DCDA5845%21111316&cid=0CD9F5C1DCDA5845")	
	end	
	
	if not botman.customMudlet then		
		irc_chat(name, "You appear to not be using the custom Mudlet build by TheFae or an old version. The latest version adds several nice automation features and better IRC support. You can get here https://github.com/itsTheFae/FaesMudlet2")
		return
	end	
	
	if benchmarkBot then	
		dbug("function checkData elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end	
end


function getServerData(getAllPlayers)
	local benchStart = os.clock()

	--read mods
	send("version")
	
	--read the ban list
	tempTimer( 4, [[send("ban list")]] )

	--list known players
	if getAllPlayers then
		tempTimer( 6, [[send("lkp")]] )	
	else
		tempTimer( 6, [[send("lkp -online")]] )
	end

	--read admin list
	tempTimer( 8, [[send("admin list")]] )

	--get the bot's IP
	tempTimer( 10, [[send("pm IPCHECK")]] )

	--read gg
	tempTimer( 12, [[send("gg")]] )

	--list the zombies		
	tempTimer( 15, [[send("se")]] )
	
	--register the bot in the bots database
	tempTimer( 18, [[registerBot()]] )	
	
	if benchmarkBot then	
		dbug("function getServerData elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end		
end


function login()
	local benchStart = os.clock()
	local getAllPlayers = false	

	debug = false
	debugdb = false
	
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end		
	
	if type(botman) ~= "table" then
		botman = {}
	end	
	
	if type(server) ~= "table" then
		server = {}
		getAllPlayers = true
		botman.scheduledRestartPaused = false
		botman.scheduledRestartForced = false
		botman.scheduledRestart = false
		botman.scheduledRestartTimestamp = os.time()
		botman.lastBlockCommandOwner =	0
		server.lagged = false
	end	
	
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end			

	if reloadBotScripts == nil then
		dofile(homedir .. "/scripts/reload_bot_scripts.lua")
		reloadBotScripts()
	end
	
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end			

	tempTimer( 60, [[checkData()]] )
	stackLimits = {}

	if (botman.botStarted == nil) then	
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end				
		botman.botStarted = os.time()
		initBot()
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					
		openDB()
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					
		openBotsDB()
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					
		initDB()		
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					
		botman.dbConnected = isDBConnected()
		botman.db2Connected = isDBBotsConnected()
		botman.initError = true
		botman.serverTime = ""
		botman.feralWarning = false
		botman.playersOnline = -1
		botman.userHome = string.sub(homedir, 1, string.find(homedir, ".config") - 2)
		loadServer()
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					
		botman.ignoreAdmins	= true
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end				
		
		if server.botID == nil then
			server.botID = 0		
		end
		
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end							
		
		botman.webdavFolderExists = true
		
		if botman.chatlogPath == nil then
			botman.chatlogPath = webdavFolder
			conn:execute("UPDATE server SET chatlogPath = '" .. escape(webdavFolder) .. "'")
		end		

		if not isDir(botman.chatlogPath) then
			botman.webdavFolderExists = false
		end

		openUserWindow(server.windowGMSG) 
		openUserWindow(server.windowDebug) 
		openUserWindow(server.windowLists) 
		openUserWindow(server.windowPlayers) 
		openUserWindow(server.windowAlerts)
		
	if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end							
		
		if ircReconnect ~= nil then
			botman.customMudlet = true
		 	loadWindowLayout()		
		end

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end			

		fixTables()				

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end			

		-- add your steam id here so you can debug using your name
		Smegz0r = "76561197983251951"

		if (botman.ExceptionCount == nil) then
			botman.ExceptionCount = 0
		end

		botman.announceBot = true
		botman.alertMods = true		
		botman.faultyGimme = false
		botman.faultyGimmeNumber = 0
		botman.faultyChat = false
		botman.gimmeHell = 0
		botman.scheduledRestartPaused  = false
		botman.scheduledRestart = false
		botman.ExceptionRebooted = false
		server.scanZombies = false
		
		fixMissingStuff()		
		
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					

		-- load tables
		loadTables()

		-- join the irc server
		if botman.customMudlet then
			joinIRCServer()			
		end
		
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					

		-- set all players to offline in shared db
		cleanupBotsData()

		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end			

		botman.nextRebootTest = nil
		botman.initError = false
		startLogging(true)		
		getServerData(getAllPlayers)
		
		-- Flag all players as offline
		if tonumber(server.botID) > 0 then
			connBots:execute("UPDATE players set online = 0 WHERE botID = " .. server.botID)		
		end
		
		if (debug) then display("debug login line " .. debugger.getinfo(1).currentline .. "\n") end					
	end

	if debug then display("debug login end\n") end
	
	if benchmarkBot then	
		dbug("function login elapsed time: " .. string.format("%.2f", os.clock() - benchStart))
	end		
end
