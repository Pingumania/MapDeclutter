local ADDON_NAME, ns = ...
local L = ns.L
local LibDD = LibStub("LibUIDropDownMenu-4.0")
local cfg, HandyNotes

local dataProviders = {
	["AreaPOI"] 				= { template = "AreaPOIPinTemplate", name = L["Points of Interest"] },
	["BattlefieldFlag"] 		= { template = "BattlefieldFlagPinTemplate", name = L["Battlefield Flag"] },
	["BonusObjective"] 			= { templates = { "ThreatObjectivePinTemplate", "BonusObjectivePinTemplate" }, name = L["Bonus Objectives"] },
	["ContentTracking"] 		= { template = "ContentTrackingPinTemplate", name = L["Content Tracking"] },
	["ContributionCollector"] 	= { template = "ContributionCollectorPinTemplate", name = L["Contribution Collector"] },
	["DeathMap"] 				= { templates = { "CorpsePinTemplate", "DeathReleasePinTemplate" }, name = L["Death"] },
	["DigSite"] 				= { template = "DigSitePinTemplate", name = L["Dig Sites"] },
	["DungeonEntrance"] 		= { template = "DungeonEntrancePinTemplate", name = L["Dungenon Entrances"] },
	["EncounterJournal"] 		= { template = "EncounterJournalPinTemplate", name = L["Encounter"] },
	["FlightPoint"] 			= { template = "FlightPointPinTemplate", name = L["Flight Points"] },
	["FogOfWar"] 				= { template = "FogOfWarPinTemplate", name = L["Fog of War"] },
	["GarrisonPlot"] 			= { template = "GarrisonPlotPinTemplate", name = L["Garrison Plot"] },
	["Gossip"] 					= { template = "GossipPinTemplate", name = L["Gossip"] },
	["GroupMembers"] 			= { template = "GroupMembersPinTemplate", name = L["Group Members"] },
	["Invasion"] 				= { template = "InvasionPinTemplate", name = L["Invasion"] },
	["MapExploration"] 			= { template = "MapExplorationPinTemplate", name = L["Map Exploration"] },
	["MapHighlight"] 			= { template = "MapHighlightPinTemplate", name = L["Map Highlights"] },
	["MapIndicatorQuest"] 		= { template = "MapIndicatorQuestPinTemplate", name = L["Map Indicators"] },
	["MapLink"] 				= { template = "MapLinkPinTemplate", name = L["Map Links"] },
	["PetTamer"] 				= { template = "PetTamerPinTemplate", name = L["Pet Tamer"] },
	["Quest"] 					= { template = "QuestPinTemplate", name = L["Quests"] },
	["QuestBlob"] 				= { template = "QuestBlobPinTemplate", name = L["Quest Blobs"] },
	["Scenario"] 				= { templates = { "ScenarioPinTemplate", "ScenarioBlobPinTemplate" }, name = L["Scenarios"] },
	["SelectableGraveyard"] 	= { template = "SelectableGraveyardPinTemplate", name = L["Graveyards"] },
	["StorylineQuest"] 			= { template = "StorylineQuestPinTemplate", name = L["Storyline"] },
	["Vehicle"] 				= { template = "VehiclePinTemplate", name = L["Vehicles"] },
	["Vignette"] 				= { template = "VignettePinTemplate", name = L["Vignettes"]},
	["WaypointLocation"] 		= { template = "WaypointLocationPinTemplate", name = L["Waypoints"] },
	["WorldMap_EventOverlay"] 	= { templates = { "WorldMapInvasionOverlayPinTemplate", "WorldMapThreatOverlayPinTemplate" }, name = L["World Events"] },
	["WorldMap_WorldQuest"] 	= { template = "WorldMap_WorldQuestPinTemplate", name = L["World Quests"] },
}

local addonProviders = {
	["BetterWorldQuests"] = { template = "BetterWorldQuestPinTemplate", name = select(2, C_AddOns.GetAddOnInfo("BetterWorldQuests")) },
	["HandyNotes"] = { name = select(2, C_AddOns.GetAddOnInfo("HandyNotes")) }
}

local function IsAtLeastOneAddonLoaded()
	local loaded
	for addon in pairs(addonProviders) do
		loaded = IsAddOnLoaded(addon)
		if loaded then
			return true
		end
	end
	return false
end

local function GetDataProviderFromTemplate(template)
	for value, data in pairs(dataProviders) do
		if data.template == template then
			return value
		end
	end
end

local hookedPins = {}
local function hookPin(pin, dataProvider)
	if hookedPins[pin] then return end

	pin:HookScript("OnShow", function(self)
		if cfg[dataProvider] then
			self:Show()
		else
			self:Hide()
		end
	end)

	hookedPins[pin] = true
end

local function hookPins(template)
	for pin in WorldMapFrame:EnumeratePinsByTemplate(template) do
		hookPin(pin, GetDataProviderFromTemplate(template))
	end
end

local function hookAllPins()
	for value, data in pairs(dataProviders) do
		if data.template then
			hookPins(data.template)
		elseif data.templates then
			for template in pairs(data.templates) do
				hookPins(template)
			end
		end
	end
end

local function hookVignettePin(template, vignetteInfo)
	for pin in WorldMapFrame:EnumeratePinsByTemplate(template) do
		if pin:GetVignetteID() == vignetteInfo.vignetteID then
			hookPin(pin, GetDataProviderFromTemplate(template))
		end
	end
end

local function toggleAllTemplatePins(template)
	if InCombatLockdown() then return end
	for pin in WorldMapFrame:EnumeratePinsByTemplate(template) do
		if cfg[GetDataProviderFromTemplate(template)] then
			pin:Show()
		else
			pin:Hide()
		end
	end
end

local function toggleAllPins()
	for value, data in pairs(dataProviders) do
		if data.template then
			toggleAllTemplatePins(data.template)
		elseif data.templates then
			for template in pairs(data.templates) do
				toggleAllTemplatePins(template)
			end
		end
	end
end

local function toggleHandyNotes(state)
	if state then
		HandyNotes:Enable()
	else
		HandyNotes:Disable()
	end
end

local function PreHook()
	for dp in pairs(WorldMapFrame.dataProviders) do
		if dp.GetPinTemplate then
			local template = dp:GetPinTemplate()
			if template == "VignettePinTemplate" then
				hooksecurefunc(dp, "GetPin", function(self, vignetteGUID, vignetteInfo)
					hookVignettePin(template, vignetteInfo)
					toggleAllTemplatePins(template)
				end)
			elseif template == "WorldMap_WorldQuestPinTemplate" then
				hooksecurefunc(dp, "RefreshAllData", function()
					hookPins(template)
					toggleAllTemplatePins(template)
				end)
			elseif template == "AreaPOIPinTemplate" then
				hooksecurefunc(dp, "RefreshAllData", function()
					hookPins(template)
					toggleAllTemplatePins(template)
				end)
			end
		elseif dp.RefreshAllData then
			hooksecurefunc(dp, "RefreshAllData", function()
				hookAllPins()
				toggleAllPins()
			end)
		end
	end
end

MapDeclutter_WorldMapButtonMixin = {}

function MapDeclutter_WorldMapButtonMixin:OnLoad()
	local function InitializeDropDown(self, level)
		self:GetParent():InitializeDropDown(self.DropDown, level)
	end
	local name = ADDON_NAME.."Button"
	self.DropDown = LibDD:Create_UIDropDownMenu(name.."DropDown", self)
	
	LibDD:UIDropDownMenu_SetInitializeFunction(self.DropDown, InitializeDropDown);
	LibDD:UIDropDownMenu_SetDisplayMode(self.DropDown, "MENU");
end

function MapDeclutter_WorldMapButtonMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(ADDON_NAME, 1, 1, 1)
	GameTooltip:AddLine(MINIMAP_TRACKING_TOOLTIP_NONE, nil, nil, nil, true)
	GameTooltip:Show()
end

function MapDeclutter_WorldMapButtonMixin:OnMouseDown()
	self.Icon:SetPoint("TOPLEFT", 8, -8)
	self.IconOverlay:Show()
end

function MapDeclutter_WorldMapButtonMixin:OnMouseUp()
	self.Icon:SetPoint("TOPLEFT", 6, -6)
	self.IconOverlay:Hide()
end

function MapDeclutter_WorldMapButtonMixin:OnClick()
	LibDD:ToggleDropDownMenu(1, nil, self.DropDown, self, 0, -5)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

function MapDeclutter_WorldMapButtonMixin:OnLeave()
	GameTooltip:Hide()
end

function MapDeclutter_WorldMapButtonMixin:InitializeDropDown(frame, level)
	local function OnSelection(button, data)
		self:OnSelection(button.value, button.checked, data)
	end
	
	local function AddSeparator()
		LibDD:UIDropDownMenu_AddSeparator(1)
	end

	if not level then level = 1 end
	local info = LibDD:UIDropDownMenu_CreateInfo()

	if (level == 1) then
		info.isTitle = true
		info.disabled = nil
		info.notCheckable = true
		info.isNotRadio = true
		info.text = L["Blizzard Pins"]
		LibDD:UIDropDownMenu_AddButton(info)

		for value, data in pairs(dataProviders) do
			info.isTitle = nil
			info.disabled = nil
			info.notCheckable = nil
			info.isNotRadio = true
			info.keepShownOnClick = true
			info.text = data.name
			info.value = value
			info.checked = cfg[value]
			info.func = function(button) OnSelection(button, data) end
			LibDD:UIDropDownMenu_AddButton(info)
		end

		if IsAtLeastOneAddonLoaded() then
			AddSeparator()
			info.isTitle = true
			info.disabled = nil
			info.notCheckable = true
			info.isNotRadio = true
			info.text = L["AddOn Pins"]
			LibDD:UIDropDownMenu_AddButton(info)
		
			for addon, data in pairs(addonProviders) do
				if IsAddOnLoaded(addon) then
					info.isTitle = nil
					info.disabled = nil
					info.notCheckable = nil
					info.isNotRadio = true
					info.keepShownOnClick = true
					info.text = data.name
					info.value = addon
					info.checked = cfg[addon]
					info.func = function(button) OnSelection(button, data) end
					LibDD:UIDropDownMenu_AddButton(info)
				end
			end
		end
	end
end

function MapDeclutter_WorldMapButtonMixin:OnSelection(value, checked, data)
	if (checked) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	else
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	end
	cfg[value] = checked

	if data.template then
		toggleAllTemplatePins(data.template)
	elseif data.templates then
		for template in pairs(data.templates) do
			toggleAllTemplatePins(template)
		end
	elseif value == "HandyNotes" then
		toggleHandyNotes(checked)
	end
end

function MapDeclutter_WorldMapButtonMixin:Refresh()
end

local function cleanSavedVariables(table1, table2)
	for key, _ in pairs(table1) do
		if not table2[key] then
			table1[key] = nil
		end
	end
end

EventUtil.ContinueOnAddOnLoaded("HandyNotes", function()
	HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
end)

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
	local WorldMapButtons = LibStub("Krowi_WorldMapButtons-1.4"):Add("MapDeclutter_WorldMapButton_Template", "DROPDOWNTOGGLEBUTTON")

	if not MapDeclutterDB then
		MapDeclutterDB = {}
	end

	local defaults = {}
	for addon in pairs(addonProviders) do
		defaults[addon] = true
	end

	for value in pairs(dataProviders) do
		defaults[value] = true
	end

	cleanSavedVariables(MapDeclutterDB, defaults)

	cfg = setmetatable(MapDeclutterDB, { __index = defaults })
	ns.cfg = cfg

	PreHook()
end)