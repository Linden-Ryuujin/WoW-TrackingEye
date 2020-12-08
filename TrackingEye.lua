
--====================================================================================================================================================
-- TrackingEye-1.0
--
-- A simple addon to add a tracking button to the minimap.
--
-- License: MIT
--====================================================================================================================================================

local TrackingEye = LibStub("AceAddon-3.0"):NewAddon("TrackingEye", "AceConsole-3.0", "AceEvent-3.0")

-- Setup minimap button
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("TrackingEyeData",
{
	type = "group",
	text = "Tracking Eye",
	icon = "",
	OnClick = function(_, msg)
		if msg == "LeftButton" then
			TrackingEye:TrackingMenu_Open();
		elseif msg == "RightButton" then
			CancelTrackingBuff();
		end
	end,
})
local LDBIcon = LibStub("LibDBIcon-1.0")

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Initialise Tracking Eye
--
-- Setups up default profile values, and registers for all events etc.
------------------------------------------------------------------------------------------------------------------------------------------------------
function TrackingEye:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("TrackingEyeDB",
	{
		profile =
		{
			minimap =
			{
				hide = false,
				minimapPos = 142,
				lock = true,
			},
		},
	})

	MiniMapTrackingFrame:SetScale(0.001) --hide frame permanently by making it tiny

	LDBIcon:Register("TrackingEyeData", LDB, self.db.profile.minimap)
	LDBIcon:GetMinimapButton("TrackingEyeData"):SetScale(1.13)

	LDB.icon = GetTrackingTexture()

	self:RegisterChatCommand("te", "MinimapButton_ChatCommand")
	self:RegisterEvent("MINIMAP_UPDATE_TRACKING", "TrackingIcon_Updated")

	local Minimap_OnMouseUp = Minimap:GetScript("OnMouseUp");
	Minimap:SetScript("OnMouseUp", function( self, button )
		if (button == "RightButton") then
			TrackingEye:TargetMenu_Open()
		else
			Minimap_OnMouseUp(self, button)
		end
	end)
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Match the Tracking Eye button image to the current tracking target.
--
-- Event callback triggered when the Blizzard UI Tracking Icon has changed.
------------------------------------------------------------------------------------------------------------------------------------------------------
function TrackingEye.TrackingIcon_Updated()
	LDB.icon = GetTrackingTexture()
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Lock and unlock the Tracking Eye button position by Chat command.
------------------------------------------------------------------------------------------------------------------------------------------------------
function TrackingEye:MinimapButton_ChatCommand(input)
	if not input or input:trim() == "" then
		TrackingEye:MinimapButton_ToggleLock()
	else
		LibStub("AceConfigCmd-3.0").HandleCommand(TrackingEye, "te", "TrackingEye", input)
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Lock and unlock the Tracking Eye minimap button position.
------------------------------------------------------------------------------------------------------------------------------------------------------
function TrackingEye:MinimapButton_ToggleLock()
	self.db.profile.minimap.lock = not self.db.profile.minimap.lock

	if self.db.profile.minimap.lock then
		LDBIcon:Lock("TrackingEyeData")
		print("Tracking Eye minimap button locked.")
	else
		LDBIcon:Unlock("TrackingEyeData")
		print("Tracking Eye minimap button unlocked.")
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create the Tracking Eye tracking context menu.
--
-- Will check what spells are known and populate the menu with all usable tracking types.
------------------------------------------------------------------------------------------------------------------------------------------------------
function TrackingEye:TrackingMenu_Open()
	local menu =
	{
		{
			text = "Select Tracking", isTitle = true
		}
	}

	-- In level order, with racial/professions last
	local spells =
	{
		1494,	--Track Beasts
		19883,	--Track Humanoids
		19884,	--Track Undead
		19885,	--Track Hidden
		19880,	--Track Elementals
		19878,	--Track Demons
		19882,	--Track Giants
		19879,	--Track Dragonkin
		5225,	--Track Humanoids: Druid
		5500,	--Sense Demons
		5502,	--Sense Undead
		2383,	--Find Herbs
		2580,	--Find Minerals
		2481	--Find Treasure
	}

	for key,spellId in ipairs(spells) do
		spellName = GetSpellInfo(spellId)
		if IsPlayerSpell(spellId) then
			table.insert(menu,
			{
				text = spellName,
				icon = GetSpellTexture(spellId),
				func = function()
					CastSpellByID(spellId)
				end
			})
		end
	end

	local menuFrame = CreateFrame("Frame", "TrackingEyeTrackingMenu", UIParent, "UIDropDownMenuTemplate")
	EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU");
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create the Tracking Eye target context menu.
--
-- Will search for a context menu and then convert it to a targeting menu.
------------------------------------------------------------------------------------------------------------------------------------------------------
function TrackingEye:TargetMenu_Open()
	if UnitAffectingCombat('player') then
		print("|c00ff0000Tracking eye menu can't be used in combat.")
		return
	end

	local targets = GameTooltipTextLeft1:GetText();

	if (targets == nil or targets == '') then
		return
	end

	local lines = split(targets, "\n")

	local menu =
	{
		{
			text = "Select Target", isTitle = true
		}
	}

	for i, line in ipairs(lines) do
		table.insert(menu,
		{
			attributes =
			{
				type = "macro",
				macrotext = "/target " .. stripColour(line)
			},
			text = line
		})
	end

	-- I have added some custom code to LibUIDropDownMenu that handle an "attributes" entry using secure buttons for macro support.
	local menuFrame = L_Create_UIDropDownMenu("TrackingEyeTargetMenu", UIParent)
	L_EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU");
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Split the passed string into a table using the passed delimiter to mark the end of each item.
------------------------------------------------------------------------------------------------------------------------------------------------------
function split(str, delimiter)
	local result = {};
	for match in (str..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove colour markers from a string
------------------------------------------------------------------------------------------------------------------------------------------------------
function stripColour(str)
	stripped, count  = str:gsub("|c[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]", "")
	stripped, count  = stripped:gsub("|r", "")
	return stripped
end