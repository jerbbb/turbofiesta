AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("CharacterList")
util.AddNetworkString("ChatSent")
function checkerror() print(sql.LastError()) end
concommand.Add("adminwipe", function() sql.Query("DROP TABLE player_data") sql.Query("DROP TABLE character_data") checkerror() end)
--GM Hooks

function GM:Initialize()
	
	if not sql.TableExists("player_data") then
		sql.Query("CREATE TABLE player_data (player_uniqueid INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, steamid varchar(20), player_flags varchar(100))")
		--checkerror()
	end
	
	if not sql.TableExists("character_data") then
		sql.Query("CREATE TABLE character_data (character_uniqueid INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, creator_uniqueid mediumint, name varchar(255), description varchar(255), character_flags varchar(100), alias_table text, model varchar(255))")
		--checkerror()
	end
	
end

function GM:PlayerInitialSpawn(Player)
	
	if not sql.Query("SELECT 1 from player_data WHERE steamid = '"..Player:SteamID().."'") then
		sql.Query("INSERT INTO player_data (steamid, player_flags) VALUES ('"..Player:SteamID().."', '')")
		--checkerror()
	end
	
	Player:SetNWInt("UniqueID", sql.QueryValue("SELECT player_uniqueid FROM player_data WHERE steamid = '"..Player:SteamID().."'"))
	
	UpdateCharacterList(Player)
	
	Player:KillSilent()
	Player:ConCommand("characterselect")
	Player.CharSelected = false

end

function GM:PlayerSpawn(Player)
	
end

hook.Add("PlayerDeathThink", "PreventSpawning", function(Player)
	
	if Player.CharSelected == false then
		Player.NextSpawnTime = CurTime() + 1
		
	else
		Player.NextSpawnTime = CurTime() - 1
		
	end
	
end)

function GM:PlayerSay(Player, Text, Team)
	local SpeakType = "says"
	local SpeakRange = 500
	local Words = {}
	Words[1], Words[2] = Text:match("(%w+)(.+)")
	local Commands = {}
	Commands["rec"] = "recognize"
	Commands["recognize"] = "recognize"
	Commands["chardesc"] = "chardesc"
	Commands["chardescription"] = "chardesc"
	Commands["charphysdesc"] = "chardesc"
	Commands["characterphysdesc"] = "chardesc"
	Commands["characterphysicaldescription"] = "chardesc"
	Commands["recy"] = "recognizey"
	Commands["recognizey"] = "recognizey"
	Commands["recw"] = "recognizew"
	Commands["recognizew"] = "recognizew"
	
	if Text:sub(1,1) == "/" and Words[1] != "y" and Words[1] != "w" then
		
		if Commands[Words[1]] then
			Player:ConCommand(Commands[Words[1]]..' "'..Words[2]:sub(2)..'"')
			return false
			
		else
			Player:ConCommand(Text:sub(2))
			return false
			
		end
		
	else
		
		if Text:sub(1,1) == "/" then
			
			if Words[1] == "y" then
				SpeakType = "yells"
				SpeakRange = 1000
				Text = Words[2]:sub(2)
				
			elseif Words[1] == "w" then
				SpeakType = "whispers"
				SpeakRange = 100
				Text = Words[2]:sub(2)
				
			end
			
		end
	
		local Message = ""
		
		for k1, v1 in pairs(GetPlayersWithinRange(Player, SpeakRange)) do
			local Known = false
			local Name = ""
			
			for k2, v2 in pairs(v1.AliasTable) do
			
				if tonumber(k2) == tonumber(GetCharID(Player)) then
					Known = true
					Name = v2
					
				end
				
			end
				
			if Known == false then
				Name = '['..GetDescription(Player):sub(1, 20)..'...]'
				
			end
			
			Message = Name..' '..SpeakType..' "'..Text..'"'
			net.Start("ChatSent")
			net.WriteString(Message)
			net.Send(v1)
		
		end
		return false
	end
	
end

--Console Commands

concommand.Add("choosechar", function (Player, Command, Args)
	SetCharacter(Player, Args[1])
	
end)

concommand.Add("createchar", function( Player, Command, Args)
		CreateCharacter(Player, Args[1], Args[2], "models/player/police.mdl")
end )

concommand.Add("recognize", function(Player, Command, Args)
	if Args[1] != "" then
		Recognize(Player, Args[1], 500)
		
	end
	
end)

concommand.Add("recognizew", function(Player, Command, Args)
	
	if Args[1] != "" then
		Recognize(Player, Args[1], 100)
		
	end
	
end)

concommand.Add("recognizey", function(Player, Command, Args)
	
	if Args[1] != "" then
		Recognize(Player, Args[1], 1000)
		
	end
	
end)

concommand.Add("chardesc", function(Player, Command, Args)
	SetDescription(Player, Args[1])
	
end)

concommand.Add("printdata", function(Player)
	print(GetName(Player))
	print(GetDescription(Player))
	PrintTable(Player.AliasTable)
	print(GetCharID(Player))
	
end)

--Intermediate Commands

function UpdateCharacterList(Player)
	local NameList = {}
	
	if sql.Query("SELECT name from character_data WHERE creator_uniqueid = "..Player:GetNWInt("UniqueID")) then
		for k, v in pairs(sql.Query("SELECT name from character_data WHERE creator_uniqueid = "..Player:GetNWInt("UniqueID"))) do
			NameList[#NameList + 1] = v["name"]
			
		end
		
	end
	net.Start("CharacterList")
	net.WriteTable(NameList)
	net.Send(Player)
	
end

function Recognize(Recognized, Name, Range)
	
	for k, Recognizer in pairs(GetPlayersWithinRange(Recognized, Range)) do
		
		if Recognizer != Recognized then
			Recognizer.AliasTable[GetCharID(Recognized)] = Name
			local NewJSON = util.TableToJSON(Recognizer.AliasTable)
			sql.Query("UPDATE character_data SET alias_table = '"..NewJSON.."' WHERE character_uniqueid = "..GetCharID(Recognizer))
			Recognizer:SetNWString("AliasTable", NewJSON)
			
		end
		
	end
	
end

function CreateCharacter(Player, Name, Description, Model)
	local SelfAliasTable = {}
	sql.Query("INSERT INTO character_data (creator_uniqueid, name, description, character_flags, alias_table, model) VALUES ("..Player:GetNWInt("UniqueID")..", '"..Name.."', '"..Description.."', '', '', '"..Model.."')")
	local NewID = sql.QueryValue("SELECT MAX(character_uniqueid) from character_data")
	SelfAliasTable[NewID] = Name
	local AliasJSON = util.TableToJSON(SelfAliasTable)
	sql.Query("UPDATE character_data SET alias_table = '"..AliasJSON.."' WHERE character_uniqueid = "..NewID)
	checkerror()
	UpdateCharacterList(Player)
	
end

function SetCharacter(Player, Name)
	local CharData = sql.QueryRow("SELECT creator_uniqueid, name, description, character_flags, alias_table, model FROM character_data WHERE name = '"..Name.."'")
	checkerror()
	Player:SetNWInt("CharID", sql.QueryValue("SELECT MAX(character_uniqueid) from character_data"))
	Player:SetNWString("Name", CharData["name"])
	Player:SetNWString("Description", CharData["description"])
	Player:SetNWString("Flags", CharData["character_flags"])
	Player.AliasTable = util.JSONToTable(CharData["alias_table"]) or {}
	Player:SetNWString("AliasTable", CharData["alias_table"])
	Player:SetModel(CharData["model"])
	Player.CharSelected = true
	Player:Spawn()
	
end

function SetDescription(Player, NewDescription)
	Player:SetNWString("Description", NewDescription)
	sql.Query("UPDATE character_data SET description = '"..NewDescription.."' WHERE character_uniqueid = "..Player:GetNWInt("CharID"))
	
end
