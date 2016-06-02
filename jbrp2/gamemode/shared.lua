GM.Name = "JBRP"
GM.Author = "N/A"
GM.Email = "N/A"
GM.Website = "N/A"
DeriveGamemode("sandbox")

--GM Hooks
function GM:PlayerDeath( ply, inflictor, attacker )

	-- Don't spawn for at least 2 seconds
	ply.NextSpawnTime = CurTime() + 2
	ply.DeathTime = CurTime()
	
	return
	
end

--"Get" functions

function GetPlayersWithinRange(Player, Range)
	local Result = {}
	
	for k, v in pairs(player.GetAll()) do
		
		if v:GetPos():Distance(Player:GetPos()) < Range then
			Result[#Result + 1] = v
			
		end
		
	end
	
	return Result
	
end

function GetName(Player)
	return Player:GetNWString("Name")
	
end

function GetDescription(Player)
	return Player:GetNWString("Description")
	
end

function GetCharID(Player)
	return Player:GetNWString("CharID")
	
end
