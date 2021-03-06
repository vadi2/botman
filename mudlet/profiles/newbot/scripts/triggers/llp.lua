--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2017  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     mdwyer@snap.net.nz
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function llp(line)
	local pos, temp, x, y, z
	
	if string.find(line, "Executing command 'llp ") then
		llpid = string.sub(line, string.find(line, "llp") + 4, string.find(line, " by ") - 2)
		players[llpid].keystones = 0
		return
	end

	-- depreciated in latest Allocs. Here for backwards compatibility
	if string.find(line, "keystones (protected", nil, true) then
		llpid = string.sub(line, string.find(line, "7656"), string.find(line, "7656") + 16)		
		players[llpid].keystones = string.sub(line, string.find(line, "owns ") + 5, string.find(line, " keyst") - 1)
		conn:execute("UPDATE players SET keystones = " .. players[llpid].keystones .. " WHERE steam = " .. llpid)
	end

	-- New format of output
	if string.find(line, "LandProtectionOf:") then
		--LandProtectionOf: id=76561197983251951,  location=-99, 128, 192
		temp = string.split(line, ",")		

		pos = string.find(temp[1], "=") + 1
		llpid = string.sub(temp[1], pos)

		x = string.sub(temp[2], string.find(temp[2], "=") + 1)
		y = temp[3]
		z = temp[4]

		if players[llpid].removedClaims == nil then
			players[llpid].removedClaims = 0
		end

		conn:execute("UPDATE keystones SET remove = 1 WHERE steam = " .. llpid .. " AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z .. " AND remove > 1")
		conn:execute("UPDATE keystones SET removed = 0 WHERE steam = " .. llpid .. " AND x = " .. x .. " AND y = " .. y .. " AND z = " .. z)

		if accessLevel(llpid) > 3 then
			region = getRegion(x, z)
			loc, reset = inLocation(x, z)

			if (resetRegions[region]) or reset or players[llpid].removeClaims == true then
				conn:execute("INSERT INTO keystones (steam, x, y, z, remove) VALUES (" .. llpid .. "," .. x .. "," .. y .. "," .. z .. ",1) ON DUPLICATE KEY UPDATE remove = 1")
			else
				conn:execute("INSERT INTO keystones (steam, x, y, z) VALUES (" .. llpid .. "," .. x .. "," .. y .. "," .. z .. ")")
			end		
		else
			conn:execute("INSERT INTO keystones (steam, x, y, z) VALUES (" .. llpid .. "," .. x .. "," .. y .. "," .. z .. ")")
		end
	end
end


function llpTrigger(line)
	if botman.botDisabled then
		return
	end

	if string.find(line, "LandProtectionOf") or string.find(line, "Executing command 'llp") or string.find(line, "keystones (protected", nil, true) then
		llp(line)
	end
end
