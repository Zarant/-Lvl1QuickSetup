local PickupSpell = C_Spell and C_Spell.PickupSpell or _G.PickupSpell

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

local addonName,addon = ...
local _, class = UnitClass("player");
local _,race = UnitRace("player")
local Frame = CreateFrame("Frame");

Frame:RegisterEvent("CINEMATIC_START")
Frame:RegisterEvent("CINEMATIC_STOP")
Frame:RegisterEvent("ADDON_LOADED")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("QUEST_ACCEPTED")

addon.Frame = Frame
local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or _G.LoadAddOn
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
SaveSettings('ForeverAurasSaved')


local needsReload = false


StaticPopupDialogs["L1QS_LAYOUT_CHANGED"] = {
    text = "Edit Mode Layout imported, please reload UI",
    button1 = "Reload",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

function LoadLayout()
	if not EditModeManagerFrame then return end
	print("Loading Edit Mode layout...")
	local name = L1QS_Settings[class].EditModeLayoutName or L1QS_Settings.EditModeLayoutName
	local layoutString = L1QS_Settings[class].EditModeLayout or L1QS_Settings.EditModeLayout
	--print(layoutString)
	--print(name)

	local function SelectLayout()
		local layoutInfo = C_EditMode.GetLayouts()
		local active = layoutInfo.activeLayout
		for n,layout in pairs(EditModeManagerFrame.layoutInfo.layouts) do 
			if layout.layoutName == name then
				if n == active then
					return true
				end
				--EditModeManagerFrame:ClearSelectedSystem()
				C_EditMode.SetActiveLayout(n)
				--EditModeManagerFrame:NotifyChatOfLayoutChange()
				return true
			end
		end
	end

	if name then
		if not SelectLayout() then
			print'438943289'
			needsReload = true
			EditModeManagerFrame:SetEnableAdvancedOptions(true,false)
			-- If the layout doesn't exist, import it
			local importLayoutInfo = C_EditMode.ConvertStringToLayoutInfo(layoutString)
			--importLayoutInfo.interfaceStyle = 59
			if importLayoutInfo then
				C_Timer.After(0,SelectLayout)
				local success = pcall(function()
				EditModeManagerFrame:MakeNewLayout(importLayoutInfo, Enum.EditModeLayoutType.Account, name, true);
				end)

				if not success then
					if not EditModeManagerFrame.highestLayoutIndexByType then
						EditModeManagerFrame.highestLayoutIndexByType = {[59] = 4}
					end
					EditModeManagerFrame:MakeNewLayout(importLayoutInfo, Enum.EditModeLayoutType.Account, name, true);
				end
				C_Timer.After(1,function()
				if StaticPopup_Show then StaticPopup_Show("L1QS_LAYOUT_CHANGED", "") end
				end)
				-- do	
				-- 	local self = EditModeManagerFrame
				-- 	self:PrepareSystemsForSave();
				-- 	C_EditMode.SaveLayouts(self.layoutInfo);
				-- 	self:ClearActiveChangesFlags();
				-- 	EventRegistry:TriggerEvent("EditMode.SavedLayouts")
				-- end

			end
		end

	end
	print("...Ok")
end


function createMacros(arg)

   print("Creating Macros...")
   local profile = class
   if arg ~= nil then
      profile = arg
   end
   local i,j = GetNumMacros()
   if not(L1QS_characterMacros[profile]) then return end
   for index,macro in pairs(L1QS_characterMacros[profile]) do 
      local characterMacro = true

      characterMacro = not macro[4]
      --print(macro[1],characterMacro)
      local n = GetMacroInfo(macro[1])
      if not n then 
         --print('ok',macro[1],characterMacro)
         CreateMacro(macro[1], macro[2], macro[3], characterMacro)
         --else
         --print("Macro already exists:", macro[1],profile)
      end
   end
   print("...Ok")
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
			--print(i)
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

local function LoadCVars()
	for line in addon.config_cache:gmatch("[^\n\r]+") do
		local var,value = string.match(line,"%s*SET%s+(%a+)%s+\"(.*)\"")
		if var and var ~= "" then
			consoleVariables[var] = value
		end
	end
	if L1QS_Settings['cvar'] then
		for var,value in pairs(L1QS_Settings['cvar']) do
			consoleVariables[var] = value
		end
	end
	for var,value in pairs(consoleVariables) do 
		SetCVar(var,value)
	end
end

local optionalCVars = {
	"damageMeterEnabled",
	"nameplateShowSelf",
	"showSwingTimer",
	"enableMovePad",
	"movePadLocked",
	"autointeract",
	"raidFramesDisplayClassColor",
	"enableMultiActionBars",
	"raidFramesDisplayPowerBars",
	"nameplateMaxDistance",

}
local function SaveCVars()
	local cvars = {}
	L1QS_Settings['cvar'] = cvars
	for _,cvar in pairs(optionalCVars) do
		cvars[cvar] = GetCVar(cvar)
	end
end


eventHandler["CINEMATIC_START"] = function()
	if UnitLevel('player') == 1 then
		createMacros()

		LoadCVars()
		C_Timer.After(0.5,function() 
			StopCinematic()
			LoadLayout()
			CameraZoomOut(50)

			loadKeyBinds()

			loadActionButtons()
		end)
	end
end

eventHandler["CINEMATIC_STOP"] = function()
	if UnitLevel('player') == 1 then

		C_Timer.After(0.5,function()
			LoadLayout()
			print("Starter profile Loaded - saved at:",L1QS_Settings.date)
		end)
	end
end

eventHandler["ADDON_LOADED"] = function(arg1)
	--print(arg1,RXPData)
	if arg1 == "WeakAuras" then
		LoadSettings('WeakAurasSaved')
	elseif arg1 == "ForeverAuras" then
		LoadSettings('ForeverAurasSaved')
	elseif arg1 == "RXPGuides" then
		RXPOnInitialize()
	elseif arg1 == "Scrap" and UnitLevel('player') == 1 then
		Scrap_CharSets = nil
	elseif arg1 == "Peddler" and UnitLevel('player') == 1 then
		ItemsToSell = {}
		UnmarkedItems = {}
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
		--local a=true SetActionBarToggles(a,a,a,a,0) SHOW_MULTI_ACTIONBAR_1=a SHOW_MULTI_ACTIONBAR_2=a SHOW_MULTI_ACTIONBAR_3=a SHOW_MULTI_ACTIONBAR_4 = a MultiActionBar_Update()


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
	for lActionSlot = 1, 200 do
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
	
	print("Moving Action Buttons...")
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
	print("...Ok")
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
	for lActionSlot = 1, 200 do
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
	
	print("Changing keybinds...")
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
	print("...Ok")
end

function EditPetRanks(editGlobal)

if InCombatLockdown() then return end

	local HasPetSpells = _G.HasPetSpells or C_SpellBook.HasPetSpells
	local GetSpellBookItemInfo = GetSpellBookItemInfo or C_SpellBook.GetSpellBookItemInfo
	local GetSpellBookItemName = GetSpellBookItemName or C_SpellBook.GetSpellBookItemName
	local BOOKTYPE_PET = _G.BOOKTYPE_PET or Enum.SpellBookSpellBank.Pet

	local spells = {}

	local rstring

	for i = 1, HasPetSpells() do

	   local spellType, id = GetSpellBookItemInfo(i, BOOKTYPE_PET)
		if not id then
			id = spellType.spellID
		end


	   -- not sure what the non-spell IDs are
		if id then
	   		local spellID = bit.band(0xFFFFFF, id)
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

	end



	local i,j = GetNumMacros()

	if i == 0 and j == 0 or not next(spells) then return end

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
	print("Macros saved")
	saveKeyBinds(arg)
	print("Keybinds saved")
	saveActionButtons(arg)
	print("Action buttons saved")
	SaveCVars()
	print("Console Variables saved")

	if EditModeManagerFrame then
		local activeLayoutInfo = EditModeManagerFrame:GetActiveLayoutInfo()
		L1QS_Settings[class].EditModeLayout = C_EditMode.ConvertLayoutInfoToString(activeLayoutInfo)
		L1QS_Settings[class].EditModeLayoutName = activeLayoutInfo.layoutName
	end
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
	print("Edit Mode Layout saved")
	local d = date()
	L1QS_Settings.date = d
	print("Profile saved at:",d)
end

function loadAll(arg)
	C_Timer.After(0,function()
		LoadLayout()
	end)
	loadKeyBinds(arg)
	createMacros(arg)
	loadActionButtons(arg)
	LoadCVars()

end
