--[[
if C_Container.GetContainerItemInfo then
	_G.GetContainerItemInfo = function(...)
		local itemTable = C_Container.GetContainerItemInfo(...)
		if itemTable then
			return itemTable.texture,
					itemTable.stackCount,
					itemTable.isLocked,
					itemTable.quality,
					itemTable.isReadable,
					itemTable.hasLoot,
					itemTable.hyperlink,
					itemTable.isFiltered,
					itemTable.hasNoValue,
					itemTable.itemID,
					itemTable.isBound
		end
	end
end

if C_Container.GetBagSlotFlag and not _G.GetBankBagSlotFlag then
	_G.GetBankBagSlotFlag = function(slot, flag)
		return C_Container.GetBagSlotFlag(slot + NUM_BAG_SLOTS,flag)
	end
end
for i,v in pairs(C_Container) do
	if not _G[i] then
		_G[i] = v
	end
end

GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
]]
local addonName,addon = ...
local _, class = UnitClass("player");
local _,race = UnitRace("player")
local Frame = CreateFrame("Frame");

Frame:RegisterEvent("CINEMATIC_START")
Frame:RegisterEvent("ADDON_LOADED")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("QUEST_ACCEPTED")

addon.Frame = Frame

LoadAddOn("Blizzard_MacroUI")

local consoleVariables = {};

local GetContainerNumFreeSlots = C_Container and C_Container.GetContainerNumFreeSlots or _G.GetContainerNumFreeSlots

local function SaveSettings(name)
	local tbl = getglobal(name)
	if tbl then
		addon[name] = tbl
	end
	_G[name] = nil
end

local function LoadSettings(name)
	if addon[name] and not _G[name] then
		_G[name] = addon[name]
	end
	addon[name] = nil
end

SaveSettings('L1QS_macroPlacement')
SaveSettings('L1QS_Bindings')
SaveSettings('L1QS_characterMacros')
SaveSettings('L1QS_Settings')
SaveSettings('WeakAurasSaved')


function createMacros(arg)
	local profile = class
	if arg ~= nil then
		profile = arg
	end
	local i,j = GetNumMacros()
	if not(L1QS_characterMacros[profile]) then return end
	for index,macro in pairs(L1QS_characterMacros[profile]) do 
		local characterMacro = 1
		if macro[4] ~= nil then
			characterMacro = nil
		end
		if GetMacroInfo(macro[1]) == nil and (profile ~= class or characterMacro ~= nil) then 
			CreateMacro(macro[1], macro[2], macro[3], characterMacro)
		end
	end
end



if not GuidelimeDataChar then
	GuidelimeDataChar = {}
end

--LoadAddOn("Blizzard_CompactRaidFrames")
--local initFunc
local initialized = false
function RXPOnInitialize(m)
	local t = RXP and RXP.settings
	local db = t and (t.db and t.db.profile or t.profile)
	if db and not initialized and UnitLevel('player') == 1 and UnitXP("player") == 0 and L1QS_Settings[class].RXPDB then
		initialized = true
		--print(123123123)
		for i,v in pairs(L1QS_Settings[class].RXPDB) do
			print(i)
			if type(v) ~= "table" then
				db[i] = v
			end
		end
		RXPCData = RXPCData or {}
		RXPCData.currentGuideName = L1QS_Settings[race].currentGuideName
		RXPCData.currentGuideGroup = L1QS_Settings[race].currentGuideGroup
		RXPCData.currentStep = 1
	end
	--print(m or 3333333)
end
--print('121212',RXP and RXP.settings and RXP.settings.db)

local eventHandler = {}
addon.eventHandler = eventHandler

function LoadCVars()
	for var,value in pairs(consoleVariables) do 
		SetCVar(var,value)
	end
end

eventHandler["CINEMATIC_START"] = function()
	if UnitLevel('player') == 1 then
		local a=true SetActionBarToggles(a,a,a,a,0) SHOW_MULTI_ACTIONBAR_1=a SHOW_MULTI_ACTIONBAR_2=a SHOW_MULTI_ACTIONBAR_3=a SHOW_MULTI_ACTIONBAR_4 = a MultiActionBar_Update()
		createMacros()

		LoadCVars()
		
		StopCinematic()
		CameraZoomOut(50)
		
		loadKeyBinds()
		
		loadActionButtons()
	end
end

eventHandler["ADDON_LOADED"] = function(arg1)
	--print(arg1,RXPData)
	if arg1 == "WeakAuras" then
		LoadSettings('WeakAurasSaved')
	elseif arg1 == "RXPGuides" then
		RXPOnInitialize()
	elseif arg1 == "Scrap" and UnitLevel('player') == 1 then
		Scrap_CharSets = nil
	elseif arg1 == "Peddler" and UnitLevel('player') == 1 then
		ItemsToSell = {}
		UnmarkedItems = {}
    elseif arg1 == "ActionbarPlus" and ABP_PLUS_DB then
        --local _, class = UnitClass('player')
		local pkey = UnitName("player") .. " - " .. GetRealmName()
		if not ABP_PLUS_DB.profileKeys[pkey] and ABP_PLUS_DB.profiles[class] then
			ABP_PLUS_DB.profileKeys[pkey] = class
		end
	elseif arg1 ~= addonName then
		return
	end
	LoadSettings('L1QS_macroPlacement')
	LoadSettings('L1QS_Bindings')
	LoadSettings('L1QS_characterMacros')
	LoadSettings('L1QS_Settings')
	--if arg1 ~= addonName then return end
	if L1QS_macroPlacement == nil then 
		L1QS_macroPlacement = {}
	end
	if L1QS_Bindings == nil then 
		L1QS_Bindings = {}
	end
	if L1QS_characterMacros == nil then 
		L1QS_characterMacros = {}
	end
	if L1QS_Settings == nil then 
		L1QS_Settings = {}
	end
	L1QS_Settings.HSbatch = L1QS_Settings.HSbatch or 9.996
	if L1QS_Settings[class] == nil then
		L1QS_Settings[class] = {}
	end
	if L1QS_Settings[race] == nil then
		L1QS_Settings[race] = {}
	end
	if not L1QS_Settings["Guidelime"] then
		L1QS_Settings["Guidelime"] = {}
	end
	if UnitLevel('player') == 1 and UnitXP("player") == 0 then
		for line in addon.config_cache:gmatch("[^\n\r]+") do
			var,value = string.match(line,"%s*SET%s+(%a+)%s+\"(.*)\"")
			if var and var ~= "" then
				consoleVariables[var] = value
			end
		end
		
		LoadCVars()
					
		if GuidelimeDataChar then
			for i,v in pairs(L1QS_Settings["Guidelime"]) do
				if type(v) == "table" then
					GuidelimeDataChar[i] = {}
				else
					GuidelimeDataChar[i] = v
				end
			end
			
			--GuidelimeDataChar = L1QS_Settings["Guidelime"]
			if GuidelimeDataChar["guideSkip"] then
				for i,v in pairs(GuidelimeDataChar["guideSkip"]) do
					GuidelimeDataChar["guideSkip"][i] = {}
				end
			end
			if L1QS_Settings[race]["currentGuide"] then
				GuidelimeDataChar["currentGuide"] = L1QS_Settings[race]["currentGuide"]
			end
		end
		
	end
end

eventHandler["PLAYER_ENTERING_WORLD"] = function()
	--print('EWO')
	if Bug then 
		Bug:GetParent():SetScale(0.75)
	end

	--DEFAULT_CHAT_FRAME:AddMessage("Rested Bonuses: "..tostring(GetXPExhaustion()))
	
	if UnitLevel('player') == 1 and UnitXP("player") == 0 then
		local frames = L1QS_Settings[class].RXPframes
		if frames then
			for name,point in pairs(frames) do
				if _G[name] then
					local a1,a2,a3,a4,a5 = unpack(point)
					a2 = UIParent
					_G[name]:ClearAllPoints()
					_G[name]:SetPoint(a1,a2,a3,a4,a5)
				end
			end
		end
	end
end

Frame:SetScript("OnEvent",function(self,event,...)
	--print('EWORLD')
	if eventHandler[event] then
		return eventHandler[event](...)
	end
    --[[
	elseif event == "QUEST_ACCEPTED" then
		if arg1 == 9542 then
			Stopwatch_StartCountdown(0,1,11)
			Stopwatch_Play()
		elseif arg1 == 9541 then
			Stopwatch_StartCountdown(0,0,30)
			Stopwatch_Play()
		end
    elseif event == "GROUP_ROSTER_UPDATE" then
            /run function sp(f,i) tr="TOPRIGHT";f2=f.debuffFrames;s=f2[1]:GetWidth();f3=f2[i];f3:SetSize(s,s);f3:ClearAllPoints();if i>6 then f3:SetPoint("BOTTOMRIGHT",f2[i-3],tr,0,0) else f3:SetPoint(tr,f2[1],tr,-(s*(i-3)),0) end end

            /run function CBF(f,i) bf=CreateFrame("Button",f:GetName().."Debuff"..i,f,"CompactDebuffTemplate");bf.baseSize=22;bf:SetSize(f.buffFrames[1]:GetSize()) end;function mv(f) for i=4,12 do sp(f,i) end end

             /run function mv3(f) CompactUnitFrame_SetMaxDebuffs(f,12); if not f.debuffFrames[4] then for i=4,12 do CBF(f,i) end end mv(f) end;hooksecurefunc("CompactUnitFrame_UpdateDebuffs",function(f) if f:GetName():match("^Compact") then mv3(f) end end);
            ]]
end)



-- Fast loot function
--[[
local tDelay = 0
local function FastLoot()
    if GetTime() - tDelay >= 0.3 then
        tDelay = GetTime()
        if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
            for i = GetNumLootItems(), 1, -1 do
                LootSlot(i)
            end
            tDelay = GetTime()
        end
    end
end

-- event frame
local faster = CreateFrame("Frame")
faster:RegisterEvent("LOOT_READY")
faster:SetScript("OnEvent", FastLoot)]]

function reportActionButtons()
	local lActionSlot = 0;
	for lActionSlot = 1, 120 do
		local lActionText = GetActionText(lActionSlot);
		local lActionTexture = GetActionTexture(lActionSlot);
		if lActionTexture then
			local lMessage = "Slot " .. lActionSlot .. ": [" .. lActionTexture .. "]";
			if lActionText then
				lMessage = lMessage .. " \"" .. lActionText .. "\"";
			end
			DEFAULT_CHAT_FRAME:AddMessage(lMessage);
		end
	end
end

function loadActionButtons(arg)
	local profile = class
	if arg ~= nil then
		profile = arg
	end
	if L1QS_macroPlacement[profile] then
		for slot,macro in pairs(L1QS_macroPlacement[profile]) do 
			local spellId = tonumber(macro)
			if GetMacroIndexByName(macro) > 0 then
				PickupMacro(macro) 
				if GetCursorInfo() == "macro" then PlaceAction(slot) end
				ClearCursor()
			elseif spellId then 
				PickupSpell(spellId)
				if GetCursorInfo() == "spell" then PlaceAction(slot) end
				ClearCursor()
			end
		end
	end
end

-- /run saveActionButtons() print(L1QS_macroPlacement["HUNTER"][1])
-- /run print(L1QS_macroPlacement["HUNTER"][1])

function saveActionButtons(arg)
	local profile = class
	if arg ~= nil then
		profile = arg
	end
	L1QS_macroPlacement[profile] = {}
	local lActionSlot = 0;
	for lActionSlot = 1, 120 do
		local actionType,Id = GetActionInfo(lActionSlot)
		local lActionText = GetActionText(lActionSlot);
		local lActionTexture = GetActionTexture(lActionSlot);
		if lActionText ~= nil and actionType == "macro" then
			L1QS_macroPlacement[profile][lActionSlot] = lActionText
		elseif actionType == "spell" then 
			L1QS_macroPlacement[profile][lActionSlot] = Id
		end
	end
end


function saveKeyBinds(arg)
	local profile = class
	if arg ~= nil then
		profile = arg
	end
	L1QS_Bindings[profile] = {}
	for index = 1, GetNumBindings() do
	  local command,_,key1,key2 = GetBinding(index)
	  if key1 then
		L1QS_Bindings[profile][key1] = command;
	  end
	  if key2 then
		L1QS_Bindings[profile][key2] = command;
	  end
	end
end

function loadKeyBinds(arg)
	local profile = class
	if arg ~= nil then
		profile = arg
	end
	if L1QS_Bindings[profile] then
		SaveBindings(2) --characer specific keybinds
		LoadBindings(2)
		for index = 1, GetNumBindings() do
			local command,_,key1,key2 = GetBinding(index)
			if key1 then
				SetBinding(key1);
			end
			if key2 then
				SetBinding(key2);
			end
		end
		for key,command in pairs(L1QS_Bindings[profile]) do 
			SetBinding(key,command)
		end
		SaveBindings(2)
	end
end
--/dump C_SpellBook.HasPetSpells()

function EditPetRanks(editGlobal)
if InCombatLockdown() then return end
	local HasPetSpells = _G.HasPetSpells or C_SpellBook.HasPetSpells
	local spells = {}
	local rstring
	for i = 1, HasPetSpells() do
	   local spellType, id = GetSpellBookItemInfo(i, BOOKTYPE_PET)
	   local spellID = bit.band(0xFFFFFF, id)
	   -- not sure what the non-spell IDs are
	   local spellName, spellRank, properId = GetSpellBookItemName(i, BOOKTYPE_PET)
	   spellRank = spellRank or ""
	   spellName = spellName or ""
	   --local hasActionButton = C_ActionBar.HasPetActionButtons(id)
	   --print(i, spellType, id, spellID, spellName, subtext, hasActionButton)
	   if not rstring and spellRank:find(" %d+") then
		rstring = string.gsub(spellRank,"%d+","%%d+")
	   end
	   print(spellName,spellRank)
	   spells[spellName] = spellRank
	end
	
	local i,j = GetNumMacros()
	if i == 0 and j == 0 then return end
	--L1QS_characterMacros[profile] = {}
	for sname,srank in pairs(spells) do
		if sname:find("^%S") then
			--local globalMacro = true
			if editGlobal then
				for index = 1, i do
					local name,icon,body = GetMacroInfo(index)
					local new = body:gsub("(/%w+%s+.-" .. sname .. "%()" .. rstring,"%1"..srank)
					if new ~= body then 
						print(new:len(),'----\n', new) 
						EditMacro(index,name,nil,new)
					end
					--L1QS_characterMacros[profile][index] = {name,icon,body,globalMacro}
				end
			end
			--globalMacro = nil
			for index = 1, j do
				local name,icon,body = GetMacroInfo(index+120)
				local new = body:gsub("(/%w+%s+.-" .. sname .. "%()" .. rstring,"%1"..srank)
				if new ~= body then 
					print(index,new:len(),'----\n',new) 
					EditMacro(index+120,nil,nil,new)
				end
				--L1QS_characterMacros[profile][index] = {name,icon,body,globalMacro}
			end
		end
	end

end


function saveMacros(arg)
	local profile = class
	if arg ~= nil then
		profile = arg
	end
	
	local i,j = GetNumMacros()
	if i == 0 and j == 0 then return end
	L1QS_characterMacros[profile] = {}
	local globalMacro = true
	for index = 1, i do
		local name,icon,body = GetMacroInfo(index)
		L1QS_characterMacros[profile][index] = {name,icon,body,globalMacro}
	end
	globalMacro = nil
	for index = 1, j do
		local name,icon,body = GetMacroInfo(index+120)
		L1QS_characterMacros[profile][index] = {name,icon,body,globalMacro}
	end
end

function saveAll(arg)
	saveMacros(arg)
	saveKeyBinds(arg)
	saveActionButtons(arg)
	if GuidelimeDataChar then
		L1QS_Settings["Guidelime"] = GuidelimeDataChar
		L1QS_Settings[race]["currentGuide"] = GuidelimeDataChar["currentGuide"]
	end
	if RXPCData then
		L1QS_Settings[race].currentGuideName = RXPCData.currentGuideName
		L1QS_Settings[race].currentGuideGroup = RXPCData.currentGuideGroup

		if type(RXP) == "table" and RXP.settings then
		--print('okR')
			local db = RXP.settings.db and RXP.settings.db.profile or RXP.settings.profile
			L1QS_Settings[class].RXPDB = {}
			L1QS_Settings[class].RXPframes = {}
			for i,v in pairs(db) do
				if type(v) ~= "table" then
					L1QS_Settings[class].RXPDB[i] = v
				end
			end
			for _,name in ipairs({'RXPTargetFrame','RXPFrame','RXPItemFrame'}) do
				local frame = getglobal(name)
				local point = {frame:GetPoint()}
				point[2] = false
				L1QS_Settings[class].RXPframes[name] = point
			end
		end
	end
end

function loadAll(arg)
createMacros(arg)
loadKeyBinds(arg)
loadActionButtons(arg)
end

--[[
local swFrame = CreateFrame("Frame")
local sx,sy
local unitToken = "player"

C_Timer.After(3,function()
hooksecurefunc("Stopwatch_Clear",function() 
local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit(unitToken), unitToken)
playing = false
sx = pos.x
sy = pos.y
swFrame:SetScript("OnUpdate",SWhandler)
end)
end)

function SWhandler()
	if StopwatchFrame:IsShown() and not Stopwatch_IsPlaying() then
		local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit(unitToken), unitToken)
		if pos.x ~= sx and pos.y ~= sy then
			Stopwatch_Play()
			swFrame:SetScript("OnUpdate",nil)
		end
	else
		swFrame:SetScript("OnUpdate",nil)
	end
end]]

--[[
local HSframe = CreateFrame("Frame");
local currentFPS = GetCVar("maxfps")
local HSstart = 0
function HStimer(t)
    L1QS_Settings.HSbatch = t
end

local function SwitchBindLocation()
	if GetTime() - HSstart > L1QS_Settings.HSbatch then
		ConfirmBinder()
		HSframe:SetScript("OnUpdate",nil)
		SetCVar("maxfps",currentFPS)
		HSstart = 0
	end
end

local function StartHSTimer()
	if HSstart == 0 then
		currentFPS = GetCVar("maxfps")
		SetCVar("maxfps",0)
		HSstart = GetTime()
		HSframe:SetScript("OnUpdate",SwitchBindLocation)
	end
end

hooksecurefunc("UseContainerItem",function(...)
	if GetContainerItemID(...) == 6948 then
		StartHSTimer()
	end
end)

hooksecurefunc("UseAction",function(...)
	local event,id = GetActionInfo(...)
	if event == "item" and id == 6948 or event == "macro" and IsCurrentSpell(8690) then
		StartHSTimer()
	end
end)
]]

--[[
function rf1()
--LoadAddOn("Blizzard_CompactRaidFrames")

--function sp(f,i) tr="TOPRIGHT";f2=f.debuffFrames;s=f2[1]:GetWidth();f3=f2[i];f3:SetSize(s,s);f3:ClearAllPoints();if i>6 then f3:SetPoint("BOTTOMRIGHT",f2[i-3],tr,0,0) else f3:SetPoint(tr,f2[1],tr,-(s*(i-3)),0) end end

--function CBF(f,i) bf=CreateFrame("Button",f:GetName().."Debuff"..i,f,"CompactDebuffTemplate");bf.baseSize=22;bf:SetSize(f.buffFrames[1]:GetSize()) end;function mv(f) for i=4,12 do sp(f,i) end end

--function mv3(f) CompactUnitFrame_SetMaxDebuffs(f,12); if not f.debuffFrames[4] then for i=4,12 do CBF(f,i) end end mv(f) end;hooksecurefunc("CompactUnitFrame_UpdateDebuffs",function(f) if f:GetName():match("^Compact") then mv3(f) end end);
CRFSort_Group=function(t1, t2) if UnitIsUnit(t1,"player") then return false elseif UnitIsUnit(t2,"player") then return true else return t1 < t2 end end CompactRaidFrameContainer.flowSortFunc=CRFSort_Group

end]]
