include("shared.lua")

--GM Hooks
function GM:Initialize()
Universe = {}

end

function GM:PlayerDeath( ply, inflictor, attacker )

	-- Don't spawn for at least 2 seconds
	ply.NextSpawnTime = CurTime() + 2
	ply.DeathTime = CurTime()
	
	return
	
end

function GM:OnPlayerChat(Player, Text, TeamOnly, PlayerIsDead)
	return false
end

function GM:HUDDrawTargetID()

	local tr = util.GetPlayerTrace( LocalPlayer() )
	local trace = util.TraceLine( tr )
	if ( !trace.Hit ) then return end
	if ( !trace.HitNonWorld ) then return end
	
	local text = "ERROR"
	local font = "TargetID"
	
	if ( trace.Entity:IsPlayer() ) then
		text = "Unknown"
		local ViewedID = Universe.Players[trace.Entity:SteamID()].Characters[Universe.Players[trace.Entity:SteamID()].CurrentCharacter].CharID
		--if Universe.Players[LocalPlayer():SteamID()].Characters[Universe.Players[LocalPlayer():SteamID()] != nil then
		for k,v in pairs(GetCharacter(LocalPlayer()).KnownPlayers) do
			if k == ViewedID then
				text = v
				
			end
			
		end
		--end
	else
		return
		--text = trace.Entity:GetClass()
	end
	
	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )
	
	local MouseX, MouseY = gui.MousePos()
	
	if ( MouseX == 0 && MouseY == 0 ) then
	
		MouseX = ScrW() / 2
		MouseY = ScrH() / 2
	
	end
	
	local x = MouseX
	local y = MouseY
	
	x = x - w / 2
	y = y + 30
	
	-- The fonts internal drop shadow looks lousy with AA on
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
	draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ) )
	draw.SimpleText( text, font, x, y, self:GetTeamColor( trace.Entity ) )
	
	y = y + h + 5
	
	local text = Universe.Players[trace.Entity:SteamID()].Characters[Universe.Players[trace.Entity:SteamID()].CurrentCharacter].Description
	local font = "TargetIDSmall"
	
	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )
	local x = MouseX - w / 2
	
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
	draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ) )
	draw.SimpleText( text, font, x, y, self:GetTeamColor( trace.Entity ) )

end

--Network Hooks

net.Receive("ClientSync", function()
	Universe = net.ReadTable()
	
end)

net.Receive("ChatSent", function()
	chat.AddText(Color(100, 255, 100), net.ReadString())
	
end)

--UI

concommand.Add("characterselect", function()
	local CharSelectFrame = vgui.Create("DFrame")
	CharSelectFrame:SetSize(ScrW()/2, ScrH()/2)
	CharSelectFrame:SetTitle("Character Selection")
	CharSelectFrame:SetVisible( true )
	CharSelectFrame:SetDraggable( false )
	CharSelectFrame:ShowCloseButton(false)
	CharSelectFrame:Center()
	CharSelectFrame:MakePopup()
	
	local DButton = vgui.Create( "DButton", CharSelectFrame )
	DButton:SetPos( 100, 300 )
	DButton:SetText( "Create New Character" )
	DButton:SetSize( 60, 30 )
	DButton.DoClick = function()
		RunConsoleCommand("charcreation")
		CharSelectFrame:Close()
	end

	local DComboBox = vgui.Create( "DComboBox", CharSelectFrame)
	DComboBox:SetSize( 100, 20 )
	DComboBox:SetValue("Select Character")
	
	for k,v in pairs(Universe.Players[LocalPlayer():SteamID()].Characters) do
		DComboBox:AddChoice(k)
		
	end

	
	DComboBox.OnSelect = function( panel, index, value )
		RunConsoleCommand("choosechar", value)
		CharSelectFrame:Close()
	
	end
	DComboBox:Center()
	
end)

concommand.Add("charcreation", function()
	local CharCreateFrame = vgui.Create( "DFrame" )
	CharCreateFrame:SetSize(ScrW()/2, ScrH()/2)
	CharCreateFrame:SetTitle("Character Selection")
	CharCreateFrame:SetVisible( true )
	CharCreateFrame:SetDraggable( false )
	CharCreateFrame:ShowCloseButton(false)
	CharCreateFrame:Center()
	CharCreateFrame:MakePopup()
	
	local NameEntry = vgui.Create( "DTextEntry", CharCreateFrame )
	NameEntry:SetPos( 25, 50 )
	NameEntry:SetSize(150, 20)
	NameEntry:SetText("Your Name")
	
	local DescEntry = vgui.Create( "DTextEntry", CharCreateFrame )
	DescEntry:SetPos( 25, 200 )
	DescEntry:SetSize(150, 20)
	DescEntry:SetText( "Your Description")
	
	local DButton = vgui.Create( "DButton",  CharCreateFrame )
	DButton:SetPos( 100, 300 )
	DButton:SetText( "Finish" )
	DButton:SetSize( 150, 40 )
	DButton.DoClick = function()
		RunConsoleCommand("createchar", NameEntry:GetValue(), DescEntry:GetValue())
		RunConsoleCommand("choosechar", NameEntry:GetValue())
		CharCreateFrame:Close()
	end
	
end)

-- Database Commands
concommand.Add("checkclient", function() PrintTable(Universe) end)