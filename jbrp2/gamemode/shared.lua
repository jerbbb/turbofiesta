GM.Name = "JBRP"
GM.Author = "N/A"
GM.Email = "N/A"
GM.Website = "N/A"
DeriveGamemode("sandbox")

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
	return Universe.Players[Player:SteamID()].CurrentCharacter
	
end

function GetCharacter(Player)
	return Universe.Players[Player:SteamID()].Characters[GetName(Player)]
	
end

function GetDescription(Player)
	return GetCharacter(Player).Description
	
end

function GetCharID(Player)
	return GetCharacter(Player).CharID
	
end