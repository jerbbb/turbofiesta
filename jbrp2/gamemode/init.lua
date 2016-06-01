AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("ClientSync")
util.AddNetworkString("ChatSent")

-- Database Commands
function Synchronize()
	sql.Query("UPDATE jbrp_data SET universe = '"..util.TableToJSON(Universe).."'") --file.Write("jbm.txt", util.TableToJSON(Universe))
	net.Start("ClientSync")
	net.WriteTable(Universe)
	net.Broadcast()
	
end

concommand.Add("adminsynchronize", Synchronize) --Temporary testing command

function Load()
	local Value = sql.QueryValue("SELECT universe FROM jbrp_data")
	if Value == false then
		Value = {}
		
	else
		Value = util.JSONToTable(Value)
		
	end
	Universe = Value--Universe = util.JSONToTable(file.Read("jbm.txt"))
	
	Synchronize()
	
end

concommand.Add("adminload", Load) --Temporary testing command

concommand.Add("checkserver", function() PrintTable(Universe)end) --Temporary testing command

concommand.Add("adminwipe", function() --Temporary testing command
sql.Query("DROP TABLE jbrp_data")
print(sql.LastError())
end)

--GM Hooks

function GM:Initialize()
	Universe = {}
	
	if sql.TableExists("jbrp_data") then--if file.Exists("jbm.txt", "DATA") then
		Universe = util.JSONToTable(sql.QueryValue("SELECT universe FROM jbrp_data"))
		
	else
		local Template = {}
		Template.Players = {}
		Template.Objects = {}
		Template.Joined = {}
		Universe = Template
		sql.Query("CREATE TABLE jbrp_data (universe longtext)")
		sql.Query("INSERT INTO jbrp_data ('universe') VALUES ('"..util.TableToJSON(Universe).."')")
		
	end
	
	Synchronize()
	
end

function GM:PlayerSpawn(Player)
	local Joined = false
	
	for k, v in pairs(Universe.Joined) do
		if v == Player:SteamID() then
			Joined = true
			
		end
		
	end
	
	if not Joined then
		table.insert(Universe.Joined, #Universe.Joined + 1, Player:SteamID())
		local Template = {}
		Template.Characters = {}
		Template.CurrentCharacter = ""
		Universe.Players[Player:SteamID()] = Template
		
	end
	
	if not Player.CharSelected then
		Player.CharSelected = false
		Player:KillSilent()
		Player:ConCommand("characterselect")
		
	end
	
	Synchronize()
	Player:SetModel("models/player/odessa.mdl")
	
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
	print(Words[1])
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
			
			for k2, v2 in pairs(v1.KnownPlayers) do
				if k2 == Player.CharID then
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
		CreateCharacter(Player, Args[1], Args[2])
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
	PrintTable(Player.KnownPlayers)
	print(GetCharID(Player))
end)

--Intermediate Commands

function Recognize(Recognized, Name, Range)
	
	for k, Recognizer in pairs(GetPlayersWithinRange(Recognized, Range)) do
			Recognizer.KnownPlayers[Recognized.CharID] = Name
			GetCharacter(Recognizer).KnownPlayers[Recognized.CharID] = Name
		
	end
	
	Synchronize()
	
end

function CreateCharacter(Player, Character, Description)
	local Template = {}
	Template.Description = Description
	Template.Inventory = {}
	Template.CharID = Player:SteamID()..Character
	Template.KnownPlayers = {}
	Template.KnownPlayers[Template.CharID] = Character
	Universe.Players[Player:SteamID()].Characters[Character] = Template
	SetCharacter(Player, Character)
	Synchronize()
	
end

function SetCharacter(Player, Character)
	Universe.Players[Player:SteamID()].CurrentCharacter = Character
	Player.CurrentName = Character --may be deprecated
	Player.CurrentDescription = Universe.Players[Player:SteamID()].Characters[Character].Description --may be deprecated
	Player.KnownPlayers = Universe.Players[Player:SteamID()].Characters[Character].KnownPlayers
	Player.CharID = Universe.Players[Player:SteamID()].Characters[Character].CharID
	Player.CharSelected = true
	Player:Spawn()
	Synchronize()
	
end

function SetDescription(Player, NewDescription)
	Player.CurrentDescription = NewDescription --may be deprecated
	GetCharacter(Player).Description = NewDescription
	Synchronize()
	
end