local ADDON_NAME, ns = ...
local L = ns.L
local LibDD = LibStub("LibUIDropDownMenu-4.0")
local HN = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local cfg

local dataProviders = {
	["AreaPOIPins"] = { template = "AreaPOIPinTemplate", name = L["Area Points of Interest"] },
	["WorldMap_WorldQuestPins"] = { template = "WorldMap_WorldQuestPinTemplate", name = L["World Quests"] },
	["MapLinkPins"] = { template = "MapLinkPinTemplate", name = L["Map Links"] },
	["FlightPointPins"] = { template = "FlightPointPinTemplate", name = L["Flight Points"] },
	["PetTamerPins"] = { template = "PetTamerPinTemplate", name = L["Pet Tamer"] },
	["EncounterJournalPins"] = { template = "EncounterJournalPinTemplate", name = L["Boss Icons"] },
	["VignettePins"] = { template = "VignettePinTemplate", name = L["Vignettes"] }
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

local function hookPin(pin)
	if pin.hooked then return end

	pin:HookScript("OnShow", function(self)
		if self.state then
			self:Show()
		else
			self:Hide()
		end
	end)

	pin.hooked = true
end

local function togglePinTemplate(template, state)
	for pin in WorldMapFrame:EnumeratePinsByTemplate(template) do
		pin.state = state
		hookPin(pin)
		pin:SetShown(state)
	end
end

local function toggleAllPinTemplates()
	for value, data in pairs(dataProviders) do
		togglePinTemplate(data.template, cfg[value])
	end
end

local function toggleHandyNotes(state)
	if state then
		HN:Enable()
	else
		HN:Disable()
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
		togglePinTemplate(data.template, checked)
	elseif value == "HandyNotes" then
		toggleHandyNotes(checked)
	end
end

function MapDeclutter_WorldMapButtonMixin:Refresh()
	toggleAllPinTemplates()
	toggleHandyNotes(cfg["HandyNotes"])
end

local function cleanSavedVariables(table1, table2)
	for key, _ in pairs(table1) do
		if not table2[key] then
			table1[key] = nil
		end
	end
end

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
end)