-- LoaMod by Atreyyo @ VanillaGaming.org

LoaMod = CreateFrame("Frame"); -- Event Frame
LoaMod.MainTank = CreateFrame("Frame","MTFrame",LoaMod)
LoaModtooltip = CreateFrame("GAMETOOLTIP", "LoaModtooltip", UIParent, "GameTooltipTemplate")

-- vars

LoaMod.Healers = {}
LoaMod.Heal = {}
LoaMod.Ignore = {}
LoaMod.Frames = {}
LoaMod.MT = {}
LoaMod.Settings = {
	["MainFrameX"] = 159,
	["MainFrameY"] = 25,
}

-- events

LoaMod:RegisterEvent("ADDON_LOADED")
LoaMod:RegisterEvent("RAID_ROSTER_UPDATE")
LoaMod:RegisterEvent("CHAT_MSG_WHISPER")
LoaMod:RegisterEvent("UNIT_PORTRAIT_UPDATE")
LoaMod:RegisterEvent("CHAT_MSG_ADDON") 

function LoaMod:OnEvent()
	if event == "ADDON_LOADED" and arg1 == "LoaMod" then
		LoaMod:print("Successfully Loaded!")
		LoaMod:print("Type /loa or /loamod to show/hide")
		LoaMod:CreateFrame()
		LoaMod.MainTank:CreateFrame()
		LoaMod:UnregisterEvent("ADDON_LOADED")
	elseif event == "RAID_ROSTER_UPDATE" then 
		LoaMod:UpdateHealers()
	elseif event ==	"UNIT_PORTRAIT_UPDATE" then
		LoaMod:UpdateHealers()
	elseif (event == "CHAT_MSG_ADDON") then
		if string.sub(arg1,1,6) == "LoaMod" and UnitName("player") ~= arg4 then
			--LoaMod:print(arg1)
			if string.sub(arg1,7,string.len(arg1)) == "Healers" then
				LoaMod.Healers = {}
				for text in string.gfind(arg2,"%d%a+") do	
					--LoaMod:print("Adding "..text.." healer list")
					if not LoaMod:IsInHealTable(name) then
						table.insert(LoaMod.Healers,string.sub(text,2,string.len(text)))
					end
				end
				LoaMod:UpdateHealers()
			elseif string.sub(arg1,7,string.len(arg1)) == "Ignore" then
				LoaMod.Ignore = {}
				for text in string.gfind(arg2,"%d%a+") do
					--LoaMod:print("Adding "..text.." to ignore list")
					LoaMod.Ignore[string.sub(text,2,string.len(text))] = 1
				end
				LoaMod:UpdateHealers()
			end
		end
	end	
end

-- frames

function LoaMod:CreateFrame()
	LoaMod.Drag = {}
	function LoaMod.Drag:StartMoving()
		LoaMod:StartMoving()
		this.drag = true
	end
	
	function LoaMod.Drag:StopMovingOrSizing()
		LoaMod:StopMovingOrSizing()
		this.drag = false
	end
	
	local backdrop = {
			--edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="16",
			edgeSize="4",
			insets={
				left="0",
				right="0",
				top="0",
				bottom="0"
			}
	}
	
	self:SetFrameStrata("BACKGROUND")
	self:SetWidth(LoaMod.Settings["MainFrameX"]) 
	self:SetHeight(LoaMod.Settings["MainFrameY"]) 
	self:SetPoint("CENTER",0,0)
	self:SetMovable(1)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")
	self:SetBackdrop(backdrop) --border around the frame
	self:SetBackdropColor(0,0,0,1)
	self:SetScript("OnDragStart",LoaMod.Drag.StartMoving)
	self:SetScript("OnDragStop", LoaMod.Drag.StopMovingOrSizing)	
	self:SetScript("OnUpdate", function()
	--[[
		if LoaMod:IsRaidInCombat() then
			LoaMod.Settings["MT"] == nil then
				for i=1,GetNumRaidMembers() do 
					if UnitName("raid"..i.."target") == "Loatheb" and UnitName("raid"..i.."target".."target") == UnitName("raid"..i) then
						LoaMod.Settings["MT"] = UnitName("raid"..i)
					end
				end
			else
			
			end
		else
			if LoaMod.Settings["MT"] ~= nil then
				LoaMod.Settings["MT"] = nil
				
			end
		end
		]]--
		LoaMod:DebuffCheck()
		LoaMod:GetMT()
		for n,name in pairs(LoaMod.Healers) do
			local id = LoaMod:GetRaidID(name)
			local frame = LoaMod.Frames[name]
			if LoaMod.Heal[name] == nil and (UnitIsConnected(id) or not UnitIsDeadOrGhost(id)) then
				frame.cooldown:SetWidth(frame.hpbar:GetWidth())
				frame.cooldown:SetTexture(0.0, 0.44, 0.87, 1)
				frame.text:SetText("Ready to heal!")
			else
				local timeleft = 60-(GetTime()-LoaMod.Heal[name])
				local p = (timeleft/60)
				local R,G,B=0,255,0
				if p < 0.5 then
					R = p*5.1
					G = 2.55
				else
					R = 2.55
					G = (1-p)*2.5
				end
				frame.cooldown:SetWidth(p*frame.hpbar:GetWidth())
				if math.floor(timeleft) >= 0 then
					frame.text:SetText("Corrupted Mind "..math.floor(timeleft))
				end
				frame.cooldown:SetTexture(R,G,B,1)
			end
			if not UnitIsConnected(id) then
				frame.text:SetText("Offline")
				frame.cooldown:SetTexture(1,1,1,0.5)
			end
			if UnitIsDeadOrGhost(id) then
				frame.text:SetText("Dead")
				frame.cooldown:SetTexture(1,1,1,0.5)			
			end
		end
	end)
	self:SetScript("OnShow", function()
		LoaMod:UpdateHealers()
	end)
	
	self.title = self:CreateFontString(nil, "OVERLAY")
	self.title:SetPoint("TOPLEFT",2, 0)
	self.title:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.title:SetTextColor(1, 1, 1, 1)
	self.title:SetShadowOffset(1,-1)
	--self.title:SetText("LoaMod 1.0")
	
	self.info = self:CreateFontString(nil, "OVERLAY")
	self.info:SetPoint("LEFT", 3, -5)
	self.info:SetFont("Fonts\\FRIZQT__.TTF", 12)
	self.info:SetTextColor(1, 1, 1, 1)
	self.info:SetShadowOffset(1,-1)
	self.info:SetText("Healers:")
	
	-- Print Rotatio Button
	self.RotationButton = CreateFrame("Button",nil,self) -- 
	self.RotationButton:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
	self.RotationButton:SetBackdropColor(0,0,0,0.6)
	self.RotationButton:SetFrameStrata("HIGH")
	self.RotationButton:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -5, -2)
	self.RotationButton:SetWidth(45)
	self.RotationButton:SetHeight(15)
	self.RotationButton:SetScript("OnClick", function() 
		if IsRaidOfficer("player") then
			LoaMod:PrintRotation()
		else
			LoaMod:print("You are not a raid officer.")
		end
	end)
	self.RotationButton:SetScript("OnEnter", function() 
		self.RotationButton:SetBackdropColor(1,1,1,0.6)
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
		GameTooltip:SetText("Announce Healing Rotation for the raid", 255, 255, 0, 1, 1);
		GameTooltip:Show()
	end)
	self.RotationButton:SetScript("OnLeave", function() 
		self.RotationButton:SetBackdropColor(0,0,0,0.6)
		GameTooltip:Hide()
	end)
	
	local text = self.RotationButton:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER", 0, 0)
	text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	text:SetTextColor(1, 1, 1, 1)
	text:SetShadowOffset(2,-2)
	text:SetText("[Rotation]")	
	
	-- checkbox
	
	local Checkbox = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
	Checkbox:SetPoint("TOPRIGHT",0,0)
	Checkbox:SetWidth(15)
	Checkbox:SetHeight(15)
	Checkbox:SetFrameStrata("MEDIUM")
	Checkbox:SetScript("OnClick", function () 
		if Checkbox:GetChecked() == nil then 
			LoaMod.Settings["announce"] = nil
		elseif Checkbox:GetChecked() == 1 then 
			LoaMod.Settings["announce"] = 1 
		end
		end)
	Checkbox:SetScript("OnEnter", function() 
		GameTooltip:SetOwner(Checkbox, "ANCHOR_RIGHT");
		GameTooltip:SetText("Turns on/off announcing next healer in raidchat", 255, 255, 0, 1, 1);
		GameTooltip:Show()
	end)
	Checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
	Checkbox:SetChecked(1)
	LoaMod.Settings["announce"] = 1
	
	self.bg = CreateFrame("Frame", nil,self)
	self.bg:SetFrameStrata("BACKGROUND")
	self.bg:SetWidth(LoaMod.Settings["MainFrameX"])
	self.bg:SetHeight(25)
	self.bg:SetBackdrop(backdrop)
	self.bg:SetBackdropColor(0,0,0,1)
	self.bg:SetPoint("BOTTOMLEFT",0,-26)
	LoaMod:UpdateHealers()
	self:Hide()
end

function LoaMod:AddFrame(name)

	local unit = LoaMod:GetRaidID(name)
	local frame = CreateFrame('Button', name, LoaMod.bg)
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	

	frame.model = CreateFrame("PlayerModel",nil,frame)
	frame.model:SetScript("OnShow",function() 
		if UnitIsVisible(unit) then 
			frame.model:SetCamera(0) 
		else
			--frame.model:SetModel("Interface\\Buttons\\talktomequestionmark.mdx")
			--frame.model:SetModelScale(4.25)
			--frame.model:SetPosition(0, 0, -1)
		end 
	end)
	frame.model:SetWidth(25)
	frame.model:SetHeight(25)
	frame.model:SetPoint("TOPLEFT",frame,"TOPLEFT", 26, 0)
	frame.model:SetUnit(unit)
	frame.model:SetCamera(0)
	frame.model:SetFrameLevel(1);	
	frame.model:Show()
	
	frame.portrait = frame:CreateTexture(nil, 'ARTWORK')
	frame.portrait:SetWidth(25)
	frame.portrait:SetHeight(25)
	frame.portrait:SetPoint("TOPLEFT",frame,"TOPLEFT", 26, 0)	
	
	frame:SetWidth(150)
	frame:SetHeight(25)	
	
	frame.hpbar = CreateFrame('Button', nil, frame)
	frame.hpbar:SetWidth(frame:GetWidth()-61)
	frame.hpbar:SetHeight(25)
	frame.hpbar:SetPoint('TOPLEFT', 52,-2)
	frame.hpbar:SetFrameLevel(1)
	
	frame.texture = frame.hpbar:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetWidth(frame.hpbar:GetWidth())
	frame.texture:SetHeight(12.5)
	frame.texture:SetPoint('TOPLEFT', 0,0)
	frame.texture:SetTexture(LoaMod:GetClassColors(name,"rgb"))
	frame.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	--frame.texture:SetVertexColor(LoaMod:GetClassColors(name,"rgb"))
	
	frame.cooldown = frame.hpbar:CreateTexture(nil, 'ARTWORK')
	frame.cooldown:SetWidth(frame.hpbar:GetWidth())
	frame.cooldown:SetHeight(12.5)
	frame.cooldown:SetPoint('TOPLEFT', 0,-12.5)
	frame.cooldown:SetTexture(0.0, 0.44, 0.87, 1)
	frame.cooldown:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	--frame.cooldown:SetVertexColor(LoaMod:GetClassColors(name,"rgb"))
	
	frame.name = frame.hpbar:CreateFontString(nil, "OVERLAY")
	frame.name:SetPoint("CENTER",0, 7)
	frame.name:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame.name:SetTextColor(1, 1, 1, 1)
	frame.name:SetShadowOffset(1,-1)
	frame.name:SetText(name)

	frame.text = frame.hpbar:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER",0, -5)
	frame.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	frame.text:SetTextColor(1, 1, 1, 1)
	frame.text:SetShadowOffset(1,-1)
	frame.text:SetText("Ready to heal!")

	frame.nr = CreateFrame('Button', nil, frame)
	frame.nr:SetWidth(25)
	frame.nr:SetHeight(25)
	frame.nr:SetPoint('TOPLEFT', 0,0)
	frame.nr:SetFrameLevel(1)
	
	frame.n = frame.nr:CreateFontString(nil, "OVERLAY")
	frame.n:SetPoint("CENTER", 0, 0)
	frame.n:SetFont("Fonts\\FRIZQT__.TTF", 15)
	frame.n:SetTextColor(1, 1, 1, 1)
	frame.n:SetShadowOffset(1,-1)
	frame.n:SetText("nr")
	
	-- arrows

	frame.uparrow = CreateFrame('Button', "uparrow", frame)
	frame.uparrow:SetWidth(20)
	frame.uparrow:SetHeight(15)
	frame.uparrow:SetPoint('TOPLEFT', frame:GetWidth()-10,0)
	--frame.uparrow:Hide()
	frame.uparrow:SetFrameLevel(3)
	
	frame.uparrow:SetScript("OnMouseDown", function()
		if IsRaidOfficer("player") then
			local name = frame:GetName()
			if LoaMod.Ignore[name] == nil then
				local n = tonumber(frame.n:GetText())
				if n ~= 1 and LoaMod.Ignore[name] == nil then
					frame.uparrowtexture:SetTexture("Interface/CHATFRAME/UI-ChatIcon-ScrollUp-Down")			
				end
			end
		end
	end)
	frame.uparrow:SetScript("OnMouseUp", function()
		if IsRaidOfficer("player") then
			local name = frame:GetName()
			if LoaMod.Ignore[name] == nil then
				local n = tonumber(frame.n:GetText())
				if n ~= 1 then
					frame.uparrowtexture:SetTexture("Interface/CHATFRAME/UI-ChatIcon-ScrollUp-Up")
					table.remove(LoaMod.Healers,n)
					table.insert(LoaMod.Healers,n-1,name)
					LoaMod:UpdateHealers()
					LoaMod:SendHealers()
				end
			end
		end
	end)
	
	frame.uparrowtexture = frame.uparrow:CreateTexture(nil, 'ARTWORK')
	frame.uparrowtexture:SetWidth(20)
	frame.uparrowtexture:SetHeight(15)
	frame.uparrowtexture:SetPoint('CENTER', 0,0)
	frame.uparrowtexture:SetTexture("Interface/CHATFRAME/UI-ChatIcon-ScrollUp-Up")

	frame.downarrow = CreateFrame('Button', "downarrow", frame)
	frame.downarrow:SetWidth(20)
	frame.downarrow:SetHeight(15)
	frame.downarrow:SetPoint('BOTTOMLEFT', frame:GetWidth()-10,-3)
	frame.downarrow:SetFrameLevel(3)	
	
	frame.downarrow:SetScript("OnMouseDown", function()
		if IsRaidOfficer("player") then
			local name = frame:GetName()
			if LoaMod.Ignore[name] == nil then
				local n = tonumber(frame.n:GetText())
				if n ~= getn(LoaMod.Healers) then
					frame.downarrowtexture:SetTexture("Interface/CHATFRAME/UI-ChatIcon-ScrollDown-Down")
				end
			end
		end
	end)
	frame.downarrow:SetScript("OnMouseUp", function()
		if IsRaidOfficer("player") then
			local name = frame:GetName()
			if LoaMod.Ignore[name] == nil then
				local n = tonumber(frame.n:GetText())
				if n ~= getn(LoaMod.Healers) then
					frame.downarrowtexture:SetTexture("Interface/CHATFRAME/UI-ChatIcon-ScrollDown-Up")
					table.remove(LoaMod.Healers,n)
					table.insert(LoaMod.Healers,n+1,name)
					LoaMod:UpdateHealers()
					LoaMod:SendHealers()
				end
			end
		end
	end)
	
	frame.downarrowtexture = frame.downarrow:CreateTexture(nil, 'ARTWORK')
	frame.downarrowtexture:SetWidth(20)
	frame.downarrowtexture:SetHeight(15)
	frame.downarrowtexture:SetPoint('CENTER', 0,0)
	frame.downarrowtexture:SetTexture("Interface/CHATFRAME/UI-ChatIcon-ScrollDown-Up")	

	frame:EnableMouse(1)

	frame:SetScript("OnClick", function()
		if IsRaidOfficer("player") then
			local name = this:GetName()
			if LoaMod.Ignore[name] == nil then
				local n = tonumber(frame.n:GetText())
				LoaMod.Ignore[name] = 1
				table.remove(LoaMod.Healers,n)
				LoaMod:UpdateHealers()
				LoaMod:SendHealers()
			else
				--LoaMod:print("Adding "..name)
				LoaMod.Ignore[name] = nil
				if not LoaMod:IsInHealTable(name) then
					table.insert(LoaMod.Healers,name)
				end
				LoaMod:UpdateHealers()
				LoaMod:SendHealers()
			end
		end
	end)
	
	frame:SetScript("OnEnter", function()
		--DEFAULT_CHAT_FRAME:AddMessage(this:GetName())
		--frame.uparrow:Show()
		--frame.downarrow:Show()
	end)	

	frame:SetScript("OnLeave", function()
		if GetMouseFocus():GetName() ~= "uparrow" or GetMouseFocus():GetName() ~= "downarrow" then
		--frame.uparrow:Hide()
		--frame.downarrow:Hide()
		--DEFAULT_CHAT_FRAME:AddMessage(GetMouseFocus():GetName())
		end
	end)	
	
	frame.unit = unit
	return frame
end

function LoaMod.MainTank:CreateFrame()
	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	
	--
	
	LoaMod.MainTank.Drag = {}
	function LoaMod.MainTank.Drag:StartMoving()
		LoaMod.MainTank:StartMoving()
		this.drag = true
	end
	
	function LoaMod.MainTank.Drag:StopMovingOrSizing()
		LoaMod.MainTank:StopMovingOrSizing()
		this.drag = false
	end
	
	self:SetWidth(124)
	self:SetHeight(40)
	self:SetBackdrop(backdrop) --border around the frame
	self:SetBackdropColor(0,0,0,1)	
	self:SetPoint("TOPLEFT",0,60)
	self:SetMovable(1)
	self:EnableMouse(1)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart",LoaMod.MainTank.Drag.StartMoving)
	self:SetScript("OnDragStop", LoaMod.MainTank.Drag.StopMovingOrSizing)	
	
	self.text = self:CreateFontString(nil, "OVERLAY")
	self.text:SetPoint("CENTER",0, 14)
	self.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	self.text:SetTextColor(1, 1, 1, 1)
	self.text:SetShadowOffset(1,-1)
	self.text:SetText("Loatheb Main Tank")
	
	--
end

function LoaMod:MTFrame(name)

	local unit = LoaMod:GetRaidID(name)
	local frame = CreateFrame('Button', name, LoaMod.MainTank)
	
	frame:SetWidth(150)
	frame:SetHeight(35)
	frame:SetPoint("TOPLEFT",0,0)
	--

	frame.model = CreateFrame("PlayerModel",nil,frame)
	frame.model:SetScript("OnShow",function() 
		if UnitIsVisible(unit) then 
			frame.model:SetCamera(0) 
		else
			--frame.model:SetModel("Interface\\Buttons\\talktomequestionmark.mdx")
			--frame.model:SetModelScale(4.25)
			--frame.model:SetPosition(0, 0, -1)
		end 
	end)
	frame.model:SetWidth(25)
	frame.model:SetHeight(25)
	frame.model:SetPoint("TOPLEFT",frame,"TOPLEFT", 5, -8)
	frame.model:SetUnit(unit)
	frame.model:SetCamera(0)
	frame.model:SetFrameLevel(2);	
	frame.model:Show()
	
	frame.portrait = frame:CreateTexture(nil, 'ARTWORK')
	frame.portrait:SetWidth(25)
	frame.portrait:SetHeight(25)
	frame.portrait:SetPoint("TOPLEFT",frame,"TOPLEFT", 26, 0)	
	
	frame.hpbar = CreateFrame('Button', nil, frame)
	frame.hpbar:SetWidth(frame:GetWidth()-61)
	frame.hpbar:SetHeight(25)
	frame.hpbar:SetPoint('TOPLEFT', 30,-8)
	frame.hpbar:SetFrameLevel(2)
	
	frame.texture = frame.hpbar:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetWidth(frame.hpbar:GetWidth())
	frame.texture:SetHeight(12.5)
	frame.texture:SetPoint('TOPLEFT', 0,0)
	frame.texture:SetTexture(LoaMod:GetClassColors(name,"rgb"))
	frame.texture:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	--frame.texture:SetVertexColor(LoaMod:GetClassColors(name,"rgb"))
	
	frame.health = frame.hpbar:CreateTexture(nil, 'ARTWORK')
	frame.health:SetWidth(frame.hpbar:GetWidth())
	frame.health:SetHeight(12.5)
	frame.health:SetPoint('TOPLEFT', 0,-12.5)
	frame.health:SetTexture(0, 0.72, 0, 1)
	frame.health:SetGradientAlpha("Vertical", 1,1,1, 0, 1, 1, 1, 1)
	--frame.cooldown:SetVertexColor(LoaMod:GetClassColors(name,"rgb"))
	
	frame.name = frame.hpbar:CreateFontString(nil, "OVERLAY")
	frame.name:SetPoint("CENTER",0, 7)
	frame.name:SetFont("Fonts\\FRIZQT__.TTF", 12)
	frame.name:SetTextColor(1, 1, 1, 1)
	frame.name:SetShadowOffset(1,-1)
	frame.name:SetText(name)

	frame.text = frame.hpbar:CreateFontString(nil, "OVERLAY")
	frame.text:SetPoint("CENTER",0, -5)
	frame.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
	frame.text:SetTextColor(1, 1, 1, 1)
	frame.text:SetShadowOffset(1,-1)
	frame.text:SetText("hp")
	
	frame:EnableMouse(1)
	
	frame:SetScript("OnUpdate", function()
		local unit = LoaMod:GetRaidID(name)
		local hp = UnitHealth(unit)/UnitHealthMax(unit)
		frame.text:SetText(UnitHealth(unit))
		frame.health:SetWidth(frame.hpbar:GetWidth()*hp)
	end)
	
	frame:SetScript("OnClick", function()
		TargetUnit(LoaMod:GetRaidID(name))
	end)
	
	frame.unit = unit
	return frame
end

function LoaMod:GetMT()
	for i=1,GetNumRaidMembers() do
		local name = UnitName("raid"..i)
		if UnitName("raid"..i.."target") == "Loatheb" and UnitName("raid"..i.."targettarget") == UnitName("raid"..i) then
			LoaMod.MT[name] = LoaMod.MT[name] or LoaMod:MTFrame(name)
			local frame = LoaMod.MT[name]
			if not frame:IsVisible() then
				frame:SetPoint("TOPLEFT",0,-5)
				frame:Show()
			end
		else
			if LoaMod.MT[name] and LoaMod.MT[name]:IsVisible() then
				LoaMod.MT[name]:Hide()
			end
		end
	end
end

function LoaMod:GetDebuff(debuff, id)
	local i=1
	while UnitDebuff(id,i) do
		local _, s = UnitDebuff(id,i)
   		LoaModtooltip:SetOwner(UIParent, "ANCHOR_NONE");
		LoaModtooltip:ClearLines()
   		LoaModtooltip:SetUnitDebuff(id,i)
		local text = LoaModtooltipTextLeft1:GetText()
		if text == debuff then 
			return true 
		end
		i=i+1
	end
	return false
end

function LoaMod:GetBuff(buff, id)
	local i=1
	while UnitBuff(id,i) do
		local _, s = UnitBuff(id,i)
   		LoaModtooltip:SetOwner(UIParent, "ANCHOR_NONE");
		LoaModtooltip:ClearLines()
   		LoaModtooltip:SetUnitBuff(id,i)
		local text = LoaModtooltipTextLeft1:GetText()
		if text == buff then 
			return true 
		end
		i=i+1
	end
	return false
end

function LoaMod:DebuffCheck()
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			local name = UnitName("raid"..i)
			if LoaMod:InHealTab(name) then
				if LoaMod:GetDebuff("Corrupted Mind", "raid"..i) then
				--if LoaMod:GetBuff("Rejuvenation", "raid"..i) then
					if LoaMod.Heal[name] == nil then
						LoaMod.Heal[name] = GetTime()
						LoaMod:Announce(name)
					end
				else
					if LoaMod.Heal[name] ~= nil then
						LoaMod.Heal[name] = nil
					end
				end
			end
		end
	
	end
end

function LoaMod:Announce(name)
	if IsRaidOfficer("player") then
		if LoaMod.Settings["announce"] ~= nil then
			for k, v in pairs(LoaMod.Healers) do
				if v == name then
					local index = k
					for n=1,getn(LoaMod.Healers) do
						if index+n > getn(LoaMod.Healers) then
							index = index-(index+n)+1
						end
						--LoaMod:print(index+n)
						local id = LoaMod:GetRaidID(LoaMod.Healers[index+n])
						if UnitIsConnected(id) and not UnitIsDeadOrGhost(id) and LoaMod.Heal[LoaMod.Healers[index+n]] == nil then
							SendChatMessage("Next healer is "..index+n..": "..LoaMod.Healers[index+n],"RAID_WARNING",nil)
							SendChatMessage("Your turn to heal!","WHISPER",nil,LoaMod.Healers[index+n])	
							return
						end
					end
				end
			end
		end
	end
end

function LoaMod:PrintRotation()
	if GetRaidRosterInfo(1) then
		if getn(LoaMod.Healers) > 0 then
			SendChatMessage("-- Loatheb Healing Rotation --","RAID",nil)
			for i, name in pairs(LoaMod.Healers) do
				SendChatMessage(i..": "..name,"RAID",nil)
			end
		end
	end
end

function LoaMod:GetClassColors(name,color)
	if color == "rgb" then
		if name == UnitName("player") then
			if UnitClass("player") == "Warrior" then return 0.78, 0.61, 0.43,1
			elseif UnitClass("player") == "Hunter" then return 0.67, 0.83, 0.45,1
			elseif UnitClass("player") == "Mage" then return 0.41, 0.80, 0.94,1
			elseif UnitClass("player") == "Rogue" then return 1.00, 0.96, 0.41,1
			elseif UnitClass("player") == "Warlock" then return 0.58, 0.51, 0.79,1
			elseif UnitClass("player") == "Druid" then return 1, 0.49, 0.04,1
			elseif UnitClass("player") == "Shaman" then return 0.0, 0.44, 0.87,1
			elseif UnitClass("player") == "Priest" then return 1.00, 1.00, 1.00,1
			elseif UnitClass("player") == "Paladin" then return 0.96, 0.55, 0.73,1
			end
		end
		if GetRaidRosterInfo(1) then
			for i=1,GetNumRaidMembers() do
				if UnitName("raid"..i) == name then
					if UnitClass("raid"..i) == "Warrior" then return 0.78, 0.61, 0.43,1
					elseif UnitClass("raid"..i) == "Hunter" then return 0.67, 0.83, 0.45,1
					elseif UnitClass("raid"..i) == "Mage" then return 0.41, 0.80, 0.94,1
					elseif UnitClass("raid"..i) == "Rogue" then return 1.00, 0.96, 0.41,1
					elseif UnitClass("raid"..i) == "Warlock" then return 0.58, 0.51, 0.79,1
					elseif UnitClass("raid"..i) == "Druid" then return 1, 0.49, 0.04,1
					elseif UnitClass("raid"..i) == "Shaman" then return 0.0, 0.44, 0.87,1	
					elseif UnitClass("raid"..i) == "Priest" then return 1.00, 1.00, 1.00,1
					elseif UnitClass("raid"..i) == "Paladin" then return 0.96, 0.55, 0.73,1
					end
				end
			end
		elseif GetNumPartyMembers() > 0 then
			for i=1,GetNumPartyMembers() do
				if UnitName("party"..i) == name then
					if UnitClass("Party"..i) == "Warrior" then return 0.78, 0.61, 0.43,1
					elseif UnitClass("party"..i) == "Hunter" then return 0.67, 0.83, 0.45,1
					elseif UnitClass("party"..i) == "Mage" then return 0.41, 0.80, 0.94,1
					elseif UnitClass("party"..i) == "Rogue" then return 1.00, 0.96, 0.41,1
					elseif UnitClass("party"..i) == "Warlock" then return 0.58, 0.51, 0.79,1
					elseif UnitClass("party"..i) == "Druid" then return 1, 0.49, 0.04,1
					elseif UnitClass("party"..i) == "Shaman" then return 0.0, 0.44, 0.87,1	
					elseif UnitClass("party"..i) == "Priest" then return 1.00, 1.00, 1.00,1
					elseif UnitClass("party"..i) == "Paladin" then return 0.96, 0.55, 0.73,1
					end
				end
			end	
		end
	elseif color == "cff" then
		if name == UnitName("player") then
			if UnitClass("player") == "Warrior" then return "|cffC79C6E"..name.."|r"
			elseif UnitClass("player") == "Hunter" then return "|cffABD473"..name.."|r"
			elseif UnitClass("player") == "Mage" then return "|cff69CCF0"..name.."|r"
			elseif UnitClass("player") == "Rogue" then return "|cffFFF569"..name.."|r"
			elseif UnitClass("player") == "Warlock" then return "|cff9482C9"..name.."|r"
			elseif UnitClass("player") == "Druid" then return "|cffFF7D0A"..name.."|r"
			elseif UnitClass("player") == "Shaman" then return "|cff0070DE"..name.."|r"
			elseif UnitClass("player") == "Priest" then return "|cffFFFFFF"..name.."|r"
			elseif UnitClass("player") == "Paladin" then return "|cffF58CBA"..name.."|r"
			end
		end
		if GetRaidRosterInfo(1) then
			for i=1,GetNumRaidMembers() do
				if UnitName("raid"..i) == name then
					if UnitClass("raid"..i) == "Warrior" then return "|cffC79C6E"..name.."|r"
					elseif UnitClass("raid"..i) == "Hunter" then return "|cffABD473"..name.."|r"
					elseif UnitClass("raid"..i) == "Mage" then return "|cff69CCF0"..name.."|r"
					elseif UnitClass("raid"..i) == "Rogue" then return "|cffFFF569"..name.."|r"
					elseif UnitClass("raid"..i) == "Warlock" then return "|cff9482C9"..name.."|r"
					elseif UnitClass("raid"..i) == "Druid" then return "|cffFF7D0A"..name.."|r"
					elseif UnitClass("raid"..i) == "Shaman" then return "|cff0070DE"..name.."|r"
					elseif UnitClass("raid"..i) == "Priest" then return "|cffFFFFFF"..name.."|r"
					elseif UnitClass("raid"..i) == "Paladin" then return "|cffF58CBA"..name.."|r"
					end
				end
			end
		else
			for i=1,GetNumPartyMembers() do
				if UnitName("party"..i) == name then
					if UnitClass("party"..i) == "Warrior" then return "|cffC79C6E"..name.."|r"
					elseif UnitClass("party"..i) == "Hunter" then return "|cffABD473"..name.."|r"
					elseif UnitClass("party"..i) == "Mage" then return "|cff69CCF0"..name.."|r"
					elseif UnitClass("party"..i) == "Rogue" then return "|cffFFF569"..name.."|r"
					elseif UnitClass("party"..i) == "Warlock" then return "|cff9482C9"..name.."|r"
					elseif UnitClass("party"..i) == "Druid" then return "|cffFF7D0A"..name.."|r"
					elseif UnitClass("party"..i) == "Shaman" then return "|cff0070DE"..name.."|r"
					elseif UnitClass("party"..i) == "Priest" then return "|cffFFFFFF"..name.."|r"
					elseif UnitClass("party"..i) == "Paladin" then return "|cffF58CBA"..name.."|r"
					end
				end
			end
		end
	elseif color == "class" then

		if (name == "Warrior") then 
			return 0.78, 0.61, 0.43
		end
		if(name=="Mage") then
			return 0.41, 0.80, 0.94
		end
		if(name=="Rogue") then 
			return 1.00, 0.96, 0.41
		end
		if(name=="Druid") then 
			return 1, 0.49, 0.04
		end
		if(name=="Hunter") then 
			return 0.67, 0.83, 0.45 
		end
		if(name=="Shaman") then 
			return 0.0, 0.44, 0.87
		end
		if(name=="Priest") then 
			return 1.00, 1.00, 1.00 
		end
		if(name=="Warlock") then 
			return 0.58, 0.51, 0.79
		end
		if(name=="Paladin") then 
			return 0.96, 0.55, 0.73
		end
	elseif color == "mark" then
		if name == "Skull" then return "|cffFFFFFF"..name.."|r" end
		if name == "Cross" then return "|cffFF0000"..name.."|r" end
		if name == "Square" then return "|cff00B4FF"..name.."|r" end
		if name == "Moon" then return "|cffCEECF5"..name.."|r" end
		if name == "Triangle" then return "|cff66FF00"..name.."|r" end
		if name == "Diamond" then return "|cffCC00FF"..name.."|r" end
		if name == "Circle" then return "|cffFF9900"..name.."|r" end
		if name == "Star" then return "|cffFFFF00"..name.."|r" end
	end
end

function LoaMod:GetRaidID(name)
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			if UnitName("raid"..i) == name then
				return "raid"..i
			end
		end
	elseif GetNumPartyMembers() > 0 then
		for i=1,GetNumPartyMembers() do 
			if UnitName("party"..i) == name then
				return "party"..i
			end
		end	
		return "player"
	else
		return "player"
	end
end

function LoaMod:SendHealers()
	if IsRaidOfficer("player") and getn(LoaMod.Healers) > 0 then
			--LoaMod:print("Sending ignore list")
			local sendstring = ""
			local n=0
			for k,v in pairs(LoaMod.Ignore) do
				n=n+1
				sendstring=sendstring..n..k
			end
			if n > 0 then
				SendAddonMessage("LoaModIgnore",sendstring,"RAID")	
			end	
		local sendstring = ""
		for k,v in pairs(LoaMod.Healers) do
			sendstring=sendstring..k..v
		end
		SendAddonMessage("LoaModHealers",sendstring,"RAID")
		
	end
end

function LoaMod:IsInRaid(name)
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			if UnitName("raid"..i) == name then
				return true
			end
		end
	elseif GetNumPartyMembers() > 0 then
		for i=1,GetNumPartyMembers() do 
			if UnitName("party"..i) == name then
				return true
			end
		end	
		if UnitName("player") == name then
			return true
		end
	else
		if UnitName("player") == name then
			return true
		end
	end
	return false
end

function LoaMod:IsRaidInCombat()
	if GetRaidRosterInfo(1) then
		for i=1,GetNumRaidMembers() do
			if UnitAffectingCombat("raid"..i) then
				return true
			end
		end
		return false
	end
end

function LoaMod:IsInHealTable(name)
	for k,v in pairs(LoaMod.Healers) do
		if v == name then
			return true
		end
	end
	return false
end

function LoaMod:UpdateHealers()
	if GetRaidRosterInfo(1) then
		for k, name in pairs(LoaMod.Healers) do
			if not LoaMod:IsInRaid(name) then
			table.remove(LoaMod.Healers,k)
			table.sort(LoaMod.Healers)
			LoaMod.Frames[name]:Hide()
			end
		end
		for i=1,GetNumRaidMembers() do
			local name = UnitName("raid"..i)
			if (UnitClass("raid"..i) == "Priest" or UnitClass("raid"..i) == "Paladin" or UnitClass("raid"..i) == "Shaman" or UnitClass("raid"..i) == "Druid") and not LoaMod:InHealTab(name) and LoaMod.Ignore[name] == nil then				
				if not LoaMod:IsInHealTable(name) then
					table.insert(LoaMod.Healers, name)
				end
			end
		end
		--local index = 0
		for index, name in pairs(LoaMod.Healers) do
			local unit = LoaMod:GetRaidID(name)
			--index=index+1
			LoaMod.Frames[name] = LoaMod.Frames[name] or LoaMod:AddFrame(name)
			local frame = LoaMod.Frames[name]	
			frame:SetPoint("TOPLEFT",0,(-26*index)+26)
			frame.unit = unit
			frame:SetAlpha(1)
			if UnitIsVisible(unit) then
				frame.model:SetUnit(unit)
				frame.model:SetCamera(0)
				frame.portrait:SetAlpha(0)				
			else
				SetPortraitTexture(frame.portrait,unit)
				frame.portrait:SetAlpha(1)
			end
			frame.n:SetText(index)
			frame.cooldown:SetDesaturated(false)
			LoaMod.bg:SetHeight(26*index)
			LoaMod.bg:SetPoint("BOTTOMLEFT",0,-(LoaMod.bg:GetHeight()))
			LoaMod.info:SetText("Healers: "..index)
			frame:Show()
		end
		local a=0
		for n, _ in pairs(LoaMod.Ignore) do
			a=a+1
			local frame = LoaMod.Frames[n]
			frame:SetPoint("TOPLEFT", 0,-(LoaMod.bg:GetHeight()+(a*26))+26)
			frame:SetAlpha(0.5)
			frame.n:SetText("")
			frame.cooldown:SetDesaturated(true)
			frame.text:SetText("Ignored")			
		end
	else
		for name, frame in pairs(LoaMod.Frames) do
			LoaMod.Healers[name] = nil
			frame:Hide()
		end
	end
end

function LoaMod:InHealTab(name)
	for k, v in pairs(LoaMod.Healers) do
		if v == name then
			return true
		end
	end
	return false
end

function LoaMod:print(msg)
	if msg then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF01DF01 L|cFF40FF00o|cFF64FE2Ea |cFF01DF01M|cFF40FF00o|cFF64FE2Ed|r: "..msg)
	end
end

function LoaMod:debug()
	for k,v in pairs(LoaMod.Healers) do
		LoaMod:print(k..": "..v)
	end
end

function LoaMod:Slash(arg1)
	if arg1 == nil or arg1 == "" then
		if LoaMod:IsVisible() then
			LoaMod:Hide()
		else
			LoaMod:Show()
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cFF01DF01 L|cFF40FF00o|cFF64FE2Ea |cFF01DF01M|cFF40FF00o|cFF64FE2Ed|r: There are no other commands")
	end
end

SLASH_LOAMOD1, SLASH_LOAMOD2 = "/loamod", "/loa"
function SlashCmdList.LOAMOD(msg, editbox)
	LoaMod:Slash(msg)
end

LoaMod:SetScript("OnEvent", LoaMod.OnEvent)
