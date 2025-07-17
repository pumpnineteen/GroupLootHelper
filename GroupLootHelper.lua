local addonName, addonTable = ...
local GLH = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local crayon = LibStub("Crayon-3.0")
local AceTimer = LibStub("AceTimer-3.0")

local dummyFunc = function() end
local UnitGroupRolesAssigned = UnitGroupRolesAssigned or dummyFunc

local defaults = {
    profile = {
    },
    char = {
    },
    global = {
        frame_positions = {},
        spacing = 5,
        role_icon_size = 16,
        spec_icon_size = 16,
        ROLL_BUTTON_SIZE = 24,
        item_tooltip_width = 0,  -- 0 = auto-size based on content
        player_name_width = 0,   -- auto-width for name column
        roll_value_width = 0,    -- auto-width for roll value
        grow_up = false,
        log = "",
        activeRolls  = {},      -- keyed by rollID
        historyRolls = {},
        playerCache  = {},      
        uniqueID = 0,
    },
}

local db

local DEBUG = false
local top_container = nil
local logWindow = nil
local logEditbox = nil

-----------------------------------------
-- Fixed width / spacing variables
-----------------------------------------
local DEFAULT_SPACING
local ROLE_ICON_SIZE
local SPEC_ICON_SIZE
local ROLL_BUTTON_SIZE
local ITEM_TOOLTIP_WIDTH
local PLAYER_NAME_WIDTH
local ROLL_VALUE_WIDTH

local GROW_UP
local log

local youName
local loot_container_cache = {}

local function split(inputstr, delimiter)
    if delimiter == nil then
        delimiter = "%s"  -- Default: split by whitespace.
    end
    local result = {}
    for substr in string.gmatch(inputstr, "([^" .. delimiter .. "]+)") do
        table.insert(result, substr)
    end
    return result
end

local function join(things, joiner)
    if type(joiner) ~= "string" then
        error("Joiner must be a string!", joiner)
        return nil
    end
    local result = ""
    for i, v in ipairs(things) do
        result = result .. tostring(v)
        if i < #things then
            result = result .. joiner
        end
    end
    return result
end

local function Log(...)
    local args = {...}
    local logLine = ""
    for _, v in ipairs(args) do
        logLine = logLine .. tostring(v) .. " "
    end
    -- logLine = logLine .. "\n"
    log = log .. logLine .. "\n"
    if logEditbox then
        logEditbox:SetText(log)
    end
    print(logLine)
end

local function debugmsg(...)
    if DEBUG then
        local args = {...}
        Log("DEBUG:", unpack(args))
    end
end

local function cleanName(name)
    local nametbl = split(name, "%:%s+")
    if name == YOU then
        name = youName
    end
    return nametbl[#nametbl]
end

GLH_Log = GLH_Log or {}
local Gargul_L

-- Initialize localization
local L = LibStub("AceLocale-3.0"):GetLocale("GroupLootHelper")

local AceGUI = LibStub("AceGUI-3.0")
local LibSpec = LibStub("LibClassicSpecs", true) or LibStub("LibSpec")

local activeRolls
local historyRolls
local playerCache
local uniqueID
local uid_to_rollid = {}
local rollid_to_uid = {}
local itemNameToRollID = {} -- Map item names to roll IDs
local itemLinkToRollID = {} -- Map item links to roll IDs
local playerCache = {} -- Cache player information
local pendingInspectRequests = {} -- Global table for caching pending inspect requests (keyed by player name)
local tooltipIndex = 1

local backdrop = { 
    bgFile="Interface\\Buttons\\WHITE8X8", 
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=false, 
    tileSize=0, 
    edgeSize=14, 
    insets = { left=3, right=3, top=3, bottom=3 } 
}

local clearBackdrop = { 
    bgFile="", 
    edgeFile="", 
    tile=false, 
    tileSize=0, 
    edgeSize=0, 
    insets = { left=0, right=0, top=0, bottom=0 } 
}

local edgelessBackdrop = { 
    bgFile="Interface\\Buttons\\WHITE8X8", 
    edgeFile="", 
    tile=false, 
    tileSize=0, 
    edgeSize=0, 
    insets = { left=0, right=0, top=0, bottom=0 } 
}

local needButtonTextures = {}
local greedButtonTextures = {}
local disenchantButtonTextures = {}
local passButtonTextures = {}

-- Need button textures
needButtonTextures['up'] = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
needButtonTextures['down'] = "Interface\\Buttons\\UI-GroupLoot-Dice-Down"
needButtonTextures['highlight'] = "Interface\\Buttons\\UI-GroupLoot-Dice-Highlight"

-- Greed button textures
greedButtonTextures['up'] = "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
greedButtonTextures['down'] = "Interface\\Buttons\\UI-GroupLoot-Coin-Down"
greedButtonTextures['highlight'] = "Interface\\Buttons\\UI-GroupLoot-Coin-Highlight"

-- Disenchant button textures
disenchantButtonTextures['up'] = "Interface\\Buttons\\UI-GroupLoot-DE-Up"
disenchantButtonTextures['down'] = "Interface\\Buttons\\UI-GroupLoot-DE-Down"
disenchantButtonTextures['highlight'] = "Interface\\Buttons\\UI-GroupLoot-DE-Highlight"

-- Pass button textures
passButtonTextures['up'] = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
passButtonTextures['down'] = "Interface\\Buttons\\UI-GroupLoot-Pass-Down"
passButtonTextures['highlight'] = "Interface\\Buttons\\UI-GroupLoot-Pass-Highlight"

local classIcon_DeathKnight = "Interface\\ICONS\\ClassIcon_DeathKnight"
local classIcon_DemonHunter = "Interface\\ICONS\\ClassIcon_DemonHunter"
local classIcon_Druid = "Interface\\ICONS\\ClassIcon_Druid"
local classIcon_Hunter = "Interface\\ICONS\\ClassIcon_Hunter"
local classIcon_Mage = "Interface\\ICONS\\ClassIcon_Mage"
local classIcon_Monk = "Interface\\ICONS\\ClassIcon_Monk"
local classIcon_Paladin = "Interface\\ICONS\\ClassIcon_Paladin"
local classIcon_Priest = "Interface\\ICONS\\ClassIcon_Priest"
local classIcon_Rogue = "Interface\\ICONS\\ClassIcon_Rogue"
local classIcon_Shaman = "Interface\\ICONS\\ClassIcon_Shaman"
local classIcon_Warlock = "Interface\\ICONS\\ClassIcon_Warlock"

local classIcons = {
    DEATHKNIGHT = classIcon_DeathKnight,
    DEMONHUNTER = classIcon_DemonHunter,
    DRUID = classIcon_Druid,
    HUNTER = classIcon_Hunter,
    MAGE = classIcon_Mage,
    MONK = classIcon_Monk,
    PALADIN = classIcon_Paladin,
    PRIEST = classIcon_Priest,
    ROGUE = classIcon_Rogue,
    SHAMAN = classIcon_Shaman,
    WARLOCK = classIcon_Warlock,
}

-- Class specialization icons

local rollpatternKeys  = {
    "PATTERN_LOOT_ITEM",
    "PATTERN_LOOT_ITEM_MULTIPLE",
    "PATTERN_LOOT_ITEM_PUSHED",
    "PATTERN_LOOT_ITEM_PUSHED_MULTIPLE",
    "PATTERN_LOOT_ITEM_PUSHED_SELF",
    "PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE",
    "PATTERN_LOOT_ITEM_SELF",
    "PATTERN_LOOT_ITEM_SELF_MULTIPLE",
    "PATTERN_LOOT_ROLL_DISENCHANT",
    "PATTERN_LOOT_ROLL_DISENCHANT_SELF",
    "PATTERN_LOOT_ROLL_GREED",
    "PATTERN_LOOT_ROLL_GREED_SELF",
    "PATTERN_LOOT_ROLL_NEED",
    "PATTERN_LOOT_ROLL_NEED_SELF",
    "PATTERN_LOOT_ROLL_PASSED",
    "PATTERN_LOOT_ROLL_PASSED_AUTO",
    "PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE",
    "PATTERN_LOOT_ROLL_PASSED_SELF",
    "PATTERN_LOOT_ROLL_PASSED_SELF_AUTO",
    "LOOT_ROLL_ALL_PASSED",
    "PATTERN_LOOT_ROLL_ROLLED_DE",
    "PATTERN_LOOT_ROLL_ROLLED_GREED",
    "PATTERN_LOOT_ROLL_ROLLED_NEED",
    "PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS",
}

local rollTypeChanged = {
    LOOT_MASTER_LOOTER,
    LOOT_GROUP_LOOT,
    LOOT_PERSONAL_LOOT,
    LOOT_FREE_FOR_ALL,
    LOOT_NEED_BEFORE_GREED,
    LOOT_ROUND_ROBIN, 
}

local function CreateLootButton(item)
    local button = AceGUI:Create("Button")
    button:SetText(item.name)
    button:SetImage(item.icon)
    button:SetWidth(32)
    button:SetHeight(32)
    -- button:SetCallback("OnClick", function() print("Item clicked: " .. item.name) end)
    
    -- Add tooltip functionality
    button:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT")
        if item.link then
            GameTooltip:SetHyperlink(item.link)
        else
            GameTooltip:SetText(item.name)
        end
        GameTooltip:Show()
    end)
    
    button:SetCallback("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return button
end

local function saveButtonPosition(frame, name)
    local point, relativeTo, relativePoint, xOffs, yOffs = frame:GetPoint()
    debugmsg("Saving position for button: ", name, point, relativeTo, relativePoint, xOffs, yOffs)
    if not db.global.frame_positions[name] then
        db.global.frame_positions[name] = {}
    end
    db.global.frame_positions[name].point = { point, relativeTo, relativePoint, xOffs, yOffs }
    db.global.frame_positions[name].width = frame:GetWidth()
    db.global.frame_positions[name].height = frame:GetHeight()
    -- print(name, point, relativeTo, relativePoint, xOffs, yOffs)
end

function GLH:FrameSetPoint(frame, name)
    if db.global.frame_positions[name] and #db.global.frame_positions[name].point > 1 then
        frame:SetPoint(unpack(db.global.frame_positions[name].point))
        frame:SetWidth(db.global.frame_positions[name].width or 600)
        frame:SetHeight(db.global.frame_positions[name].height or 400)
    else
        frame:SetPoint("CENTER")
        frame:SetWidth(600)
        frame:SetHeight(400)
    end
end

local function AddBackdropToFrame(frame, backdrop, colour)
    if not frame.SetBackdrop then
        print("Adding backdop...")
        Mixin(frame, BackdropTemplateMixin)
    end
    if backdrop then
        frame:SetBackdrop(backdrop)
        print("Setting backdrop for frame: ", frame:GetName())
        if colour then
            frame:SetBackdropColor(colour[1] or 0, colour[2] or 0, colour[3] or 0, colour[4] or 1)
        end
    end
end

local function CreateLootWindow()
    local frameWidget = AceGUI:Create("Frame")
    local frame = frameWidget.frame
    frameWidget.GLH_Name = "GLH_LootWindow"
    frameWidget:SetTitle("Loot")
    frameWidget:SetStatusText("Ready to Roll")
    frameWidget:SetLayout("List")
    
    GLH:FrameSetPoint(frameWidget.frame, frameWidget.GLH_Name)

    AddBackdropToFrame(frame, backdrop, {0, 0, 0, 0.6})

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        saveButtonPosition(frame, frameWidget.GLH_Name)
    end)
    
    local lootList = AceGUI:Create("ScrollFrame")
    lootList:SetLayout("List")
    lootList:SetFullWidth(true)
    lootList:SetFullHeight(true)
    lootList:SetAutoAdjustHeight(true)
    frameWidget:AddChild(lootList)
    frameWidget:SetUserData("lootList", lootList)

    frameWidget:Hide()
    return frameWidget
end

function GLH:AddTooltipContainer(itemLink, texture, timeEnd)
    if not itemLink then
        print("Error - AddTooltipContainer: itemLink is nil")
        return
    end
    if not texture then
        texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if not timeEnd then
        timeEnd = GetTime() + 120
    end

    local lootList = GLH.LootWindow:GetUserData("lootList")
    -----------------------------------------
    -- Create the main container using Table Layout
    -----------------------------------------
    local mainContainer = AceGUI:Create("SimpleGroup")
    print("Creating main container for item: " , itemLink)
    -- AddBackdropToFrame(mainContainer.frame, backdrop, {1, 1, 1, 0.4})
    mainContainer:SetUserData("itemLink", itemLink)
    mainContainer:SetUserData("rollIntentions", {})
    mainContainer:SetUserData("rolls", {})

    mainContainer:SetFullWidth(true)
    mainContainer:SetAutoAdjustHeight(true)
    -- mainContainer:SetFullHeight(true)
    -- Configure three main columns:
    -- Column 1: Item Tooltip (auto-size)
    -- Column 2: Player Info (complex table, see below)
    -- Column 3: Roll Buttons (fixed width)
    mainContainer:SetUserData("table", {
        columns = {
            ITEM_TOOLTIP_WIDTH,  -- Column 1: Tooltip
            1,                   -- Column 2: Player info container – using a flexible placeholder (weight 1)
            ROLL_BUTTON_SIZE,   -- Column 3: Roll Buttons (absolute width)
        },
        space = DEFAULT_SPACING,
        alignH = "CENTER",
        alignV = "TOP",
    })
    mainContainer:SetLayout("Table")

    -----------------------------------------
    -- Column 1: Item Tooltip
    -----------------------------------------
    local colTooltip = AceGUI:Create("SimpleGroup")
    colTooltip:SetLayout("Flow")
    colTooltip:SetAutoAdjustHeight(true)
    colTooltip:SetUserData("cell", { alignH = "LEFT", alignV = "TOP" })
    -- Create and add your tooltip widget into colTooltip
    do
        local tooltipFrame = GLH:CreateTooltipFrame()
        
        local tooltipWidget = AceGUI:Create("GLHTooltip")
        tooltipWidget:SetUserData("layoutParent", lootList)
        tooltipWidget:SetTooltipFrame(tooltipFrame)
        tooltipWidget:SetHyperlink(itemLink, texture)
        tooltipFrame:Show()
        local tooltip = tooltipWidget.frame
    
        AddBackdropToFrame(tooltip, edgelessBackdrop, {0, 0, 0, 0.6})
        print("Clearing tooltip frame backdrop for item: ", itemLink)
        
        -- Re-anchor the native tooltip frame within this column’s frame.
        -- tooltip:ClearAllPoints()
        -- tooltip:SetPoint("TOPLEFT", colTooltip.frame, "TOPLEFT", 0, 0)
        -- tooltip:SetPoint("BOTTOMRIGHT", colTooltip.frame, "BOTTOMRIGHT", 0, 0)
        -- tooltip:SetScript("OnUpdate", nil)
        -- tooltip:SetScript("OnHide", function()
        --     print("Hiding tooltip frame for item: ", itemLink)
        -- end)
        -- tooltip:SetScript("OnShow", function()
        --     print("Showing tooltip frame for item: ", itemLink)
        -- end)
        tooltip:SetClampedToScreen(false)
        tooltip:Show()
        print("Tooltip:", tooltip:GetWidth(), tooltip:GetHeight())
        print("Widget:", tooltipWidget.frame:GetWidth(), tooltipWidget.frame:GetHeight())

        colTooltip:AddChild(tooltipWidget)
    end
    mainContainer:AddChild(colTooltip)

    -----------------------------------------
    -- Column 2: Player Info Table wrapped in a vertical scroll frame
    -----------------------------------------
    local colPlayerInfoScroll = AceGUI:Create("ScrollFrame")
    -- Force a desired fixed width here so that no horizontal scroll appears.
    local PLAYER_INFO_SCROLL_WIDTH = 200  -- Adjust as needed
    colPlayerInfoScroll:SetWidth(PLAYER_INFO_SCROLL_WIDTH)
    -- colPlayerInfoScroll:SetFullHeight(true)
    colPlayerInfoScroll:SetAutoAdjustHeight(true)
    -- Note: AceGUI's ScrollFrame typically scrolls vertically. By fixing the width of the content,
    -- horizontal scrolling shouldn’t be needed.
    colPlayerInfoScroll:SetUserData("cell", { alignH = "LEFT", alignV = "CENTER" })
    mainContainer:AddChild(colPlayerInfoScroll)

    -- Configure the nested table within the scroll frame.
    -- This nested table has five sub-columns:
    --  1: Player Name (auto)
    --  2: Role Icon (fixed 16px)
    --  3: Spec Icon (fixed 16px)
    --  4: Roll Icon (auto)
    --  5: Roll Value (auto)
    colPlayerInfoScroll:SetUserData("table", {
        columns = {
            PLAYER_NAME_WIDTH,
            ROLE_ICON_SIZE,
            SPEC_ICON_SIZE,
            0,                   -- Roll Icon auto-width
            ROLL_VALUE_WIDTH,
        },
        space = DEFAULT_SPACING,
        alignH = "LEFT",
        alignV = "CENTER",
    })
    colPlayerInfoScroll:SetLayout("Table")

    -- Populate the player info table with one row as an example.
    local playerNamesTable = AceGUI:Create("SimpleGroup")
    playerNamesTable:SetAutoAdjustHeight(true)
    mainContainer:SetUserData("playerNamesTable", playerNamesTable)
    playerNamesTable:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    playerNamesTable:SetUserData("table", {
        columns = {
            PLAYER_NAME_WIDTH,
            ROLE_ICON_SIZE,
            SPEC_ICON_SIZE,
            0,
            ROLL_VALUE_WIDTH,
        },
        space = DEFAULT_SPACING,
    })
    playerNamesTable:SetLayout("Table")
    playerNamesTable:SetUserData("FirstGreedOrDisenchant", nil)
    playerNamesTable:SetUserData("FirstPass", nil)

    -- Finally, add the player row to the vertical scroll container.
    colPlayerInfoScroll:AddChild(playerNamesTable)

    -----------------------------------------
    -- Column 3: Roll Buttons (using Flow Layout)
    -----------------------------------------
    local colRoll = AceGUI:Create("SimpleGroup")
    colRoll:SetAutoAdjustHeight(true)
    colRoll:SetLayout("Flow")
    colRoll:SetUserData("cell", { alignH = "CENTER", alignV = "TOP" })
    mainContainer:AddChild(colRoll)

    -- Create roll buttons using your existing functions.
    local msNeedButton = self:CreateMSNeedButton(ROLL_BUTTON_SIZE)
    local osNeedButton = self:CreateOSNeedButton(ROLL_BUTTON_SIZE)
    -- local disenchantButton = self:CreateDisenchantButton(ROLL_BUTTON_SIZE)
    local greedButton = self:CreateGreedButton(ROLL_BUTTON_SIZE)
    local passButton = self:CreatePassButton(ROLL_BUTTON_SIZE)

    -- Add buttons to the roll column.
    colRoll:AddChild(msNeedButton)
    colRoll:AddChild(osNeedButton)
    -- colRoll:AddChild(disenchantButton)
    colRoll:AddChild(greedButton)
    colRoll:AddChild(passButton)

    -----------------------------------------
    -- Finally, add the main container to your Loot Window's scroll list.
    -----------------------------------------
    lootList:AddChild(mainContainer, top_container)
    if GROW_UP then
        top_container = mainContainer
    end
    if #lootList.children % 2 == 0 then
        
    end
    lootList:DoLayout()
    return mainContainer
end


function GLH:AddRollInfo(rollID, playerInfoData)
    local uid = rollid_to_uid[rollID]
    if not uid then 
        print("WARNING: couldn't find uniqueID for rollID", rollID)
        return 
    end

    local playerNamesTable = loot_container_cache[uid].loot_container:GetUserData("playerNamesTable")
    if not playerNamesTable then return end
    local firstGreedOrDisenchant = playerNamesTable:GetUserData("FirstGreedOrDisenchant")
    local firstPass = playerNamesTable:GetUserData("FirstPass")
    local rollType = playerInfoData.rollType
    if not rollType then
        print("Error: playerInfoData.rollType is nil for rollID: " .. tostring(uid))
        rollType = "PASSED"
    end

    local function AddName(before)
        local playerName = AceGUI:Create("Label")
        playerName:SetText(playerInfoData.name or "Unknown")
        playerName:SetUserData("cell", { alignH = "LEFT", alignV = "CENTER" })
        playerNamesTable:AddChild(playerName, before)
        return playerName
    end
    
    local function AddRole(before)
        local roleIcon = AceGUI:Create("Icon")
        roleIcon:SetImage(playerInfoData.roleIcon or "Interface\\Icons\\INV_Shield_04")
        roleIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
        playerNamesTable:AddChild(roleIcon, before)
        return roleIcon
    end

    local function AddSpec(before)
        local specIcon = AceGUI:Create("Icon")
        specIcon:SetImage(playerInfoData.specIcon or "Interface\\Icons\\INV_Sword_04")
        specIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
        playerNamesTable:AddChild(specIcon, before)
        return specIcon
    end
    
    local function AddRollIcon(before)
        local rollIcon = AceGUI:Create("Icon")
        rollIcon:SetImage(playerInfoData.rollIcon or "Interface\\Buttons\\UI-GroupLoot-Dice-Up")
        rollIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
        playerNamesTable:AddChild(rollIcon, before)
        return rollIcon
    end
    
    local function AddRollValue(before)
        local rollValue = AceGUI:Create("Label")
        rollValue:SetText(playerInfoData.rollValue or "")
        rollValue:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
        playerNamesTable:AddChild(rollValue, before)
        return rollValue
    end

    local function AddForward()
        local nameLabel = AddName()
        AddRole()
        AddSpec()
        AddRollIcon()
        AddRollValue()
        return nameLabel
    end

    local function AddBackward(before)
        local before = AddRollValue(before)
        before = AddRollIcon(before)
        before = AddSpec(before)
        before = AddRole(before)
        local nameLabel = AddName(before)
        return nameLabel
    end

    local function InsertInfo()
        if rollType == "NEED"  and firstGreedOrDisenchant then
            AddBackward(firstGreedOrDisenchant)
        
        elseif (rollType == "NEED" or rollType == "GREED" or rollType == "DISENCHANT") and firstPass then
            local insert = AddBackward(firstPass)
            -- Store firstGreedOrDisenchant if it doesn't exist
            if rollType == "GREED" or rollType == "DISENCHANT" then
                if not firstGreedOrDisenchant then
                    playerNamesTable:SetUserData("FirstGreedOrDisenchant", insert)
                end
            end
        else
            local insert = AddForward()
            -- Store firstPass if it doesn't exist
            if rollType == "PASSED" then
                if not firstPass then
                    playerNamesTable:SetUserData("FirstPass", insert)
                end
            end
        end
    end

    playerNamesTable:DoLayout()
end

-- Function to get player's spec
local function GetPlayerSpec(unit)
    if not LibSpec then return "Unknown" end
    
    local specId = LibSpec:GetSpecialization(unit)
    if not specId then return "Unknown" end
    
    local _, specName = LibSpec:GetSpecializationInfo(specId)
    return specName or "Unknown"
end

local classDisplayName, class = UnitClass("player") 
local activeTalentGroup = GetActiveTalentGroup()
local id, name, description, icon, pointsSpent, background, previewPointsSpent, isUnlocked = GetTalentTabInfo(1)

local function fixClassColour(colour)
    if colour then
        colour.a = 1
    end
    return colour
end

function GLH:GetClassColour(class)
    if CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] then
        return fixClassColour(CUSTOM_CLASS_COLORS[class])
    elseif RAID_CLASS_COLORS[class] then
        return fixClassColour(RAID_CLASS_COLORS[class])
    end
    return {r = 0.7, g = 0.7, b = 0.7, a = 1} -- Default to gray if class not found
end

local function CreateButtonWithTextures(size, textures, vertexColor)
    size = math.floor(tonumber(size or 16))
    
    -- Create an AceGUI Button widget instead of a raw frame.
    local widget = AceGUI:Create("Button")
    widget:SetWidth(size)
    widget:SetHeight(size)
    widget:SetText("")
    
    local button = widget.frame
    
    -- Create and set the normal texture.
    local normal = button:CreateTexture(textures.up, "ARTWORK")
    normal:SetAllPoints()
    normal:SetTexture(textures['up'])
    if vertexColor then
        normal:SetVertexColor(unpack(vertexColor))
    end
    button:SetNormalTexture(normal)
    
    -- Create and set the pushed texture.
    local pushed = button:CreateTexture(textures.down, "ARTWORK")
    pushed:SetAllPoints()
    pushed:SetTexture(textures['down'])
    if vertexColor then
        pushed:SetVertexColor(unpack(vertexColor))
    end
    button:SetPushedTexture(pushed)
    
    -- Create and set the highlight texture.
    local highlight = button:CreateTexture(textures.highlight, "ARTWORK")
    highlight:SetAllPoints()
    highlight:SetTexture(textures['highlight'])
    if vertexColor then
        highlight:SetVertexColor(unpack(vertexColor))
    end
    button:SetHighlightTexture(highlight)
    
    return widget
end

local function IsGargulRoll(rollID)
    -- Check if the rollID is a Gargul roll
    return rollID and rollID:match("^GargulRoll_")
end

local function disableButton(button, time)
    local parent = button:GetParent()
    for _, child in ipairs(parent.children) do
        if child.SetDisabled then
            child:SetDisabled(true)
            if time then
                -- Re-enable the button after the specified time
                C_Timer.After(time, function()
                    child:SetDisabled(false)
                end)
            end
        end
    end
end

function GLH:CreateMSNeedButton(size, rollID)
    local vertexColor = {1, 0.84, 0}
    local button = CreateButtonWithTextures(size, needButtonTextures, vertexColor)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "MSNeed")
    button:SetCallback("OnClick", function(widget, event, ...)
        if IsGargulRoll(rollID) then
            print("MS Need clicked")
            RandomRoll(1, 100)
            disableButton(self, 3)

        else
            print("MS Need clicked (non-Gargul)")
            RollOnLoot(rollID, 1)
            disableButton(self)
        end
    end)
    return button
end

function GLH:CreateOSNeedButton(size, rollID)
    local button = CreateButtonWithTextures(size, needButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "OSNeed")
    button:SetCallback("OnClick", function(widget, event, ...)
        if IsGargulRoll(rollID) then
            print("OS Need clicked")
            RandomRoll(1, 99)
            disableButton(self, 3)
        else
            print("OS Need clicked (non-Gargul)")
            RollOnLoot(rollID, 1)
            disableButton(self, 3)
        end
    end)
    return button
end
function GLH:CreateGreedButton(size, rollID)
    local button = CreateButtonWithTextures(size, greedButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "Greed")
    button:SetCallback("OnClick", function(widget, event, ...)
        print("Greed clicked")
        if IsGargulRoll(rollID) then
            RandomRoll(1, 100)
            disableButton(self)
        else
            RollOnLoot(rollID, 2)
            disableButton(self, 3)
        end
    end)
    return button
end
function GLH:CreateDisenchantButton(size, rollID)
    local button = CreateButtonWithTextures(size, disenchantButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "Disenchant")
    button:SetCallback("OnClick", function(widget, event, ...)
        print("Disenchant clicked")
        RollOnLoot(rollID, 3)
        disableButton(self, 3)
    end)
    return button
end
function GLH:CreatePassButton(size, rollID)
    local button = CreateButtonWithTextures(size, passButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "Pass")
    button:SetCallback("OnClick", function(widget, event, ...)
        print("Pass clicked")
        RollOnLoot(rollID, 0)
        disableButton(self, 3)
    end)
    return button
end

local lfgRolesMain = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"
local roleTANK = "TANK"
local roleHEALER = "HEALER"
local roleDAMAGE = "DAMAGE"
local roleUNKNOWN = "UNKNOWN"

local lfgRolesCoords = {
    roleTANK = {0, 0.25, 0, 0.25},
    roleHEALER = {0.25, 0.5, 0, 0.25},
    roleDAMAGE = {0.5, 0.75, 0, 0.25},
    roleUNKNOWN = {0.75, 1, 0, 0.25}
}

local function CreateRoleIcon(parent, role)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(lfgRolesMain)
    local coords = lfgRolesCoords[role]
    if coords then
        icon:SetTexCoord(unpack(coords))
    end
    icon:SetSize(16, 16) -- Typical size for role icons, adjust as needed
    return icon
end

local testLinks = {
    ["Sulfuras"] = {"\124cffff8000\124Hitem:17182:0:0:0:0:0:0:0:0\124h[Sulfuras, Hand of Ragnaros]\124h\124r", 133066},
    ["Sul'thraze"] = {"\124cffa335ee\124Hitem:9372:0:0:0:0:0:0:0:0\124h[Sul'thraze the Lasher]\124h\124r", 135350},
    ["T2 Helm"] = {"\124cffa335ee\124Hitem:16921:0:0:0:0:0:0:0:0\124h[Halo of Transcendence]\124h\124r", 133126},
    ["Blue Weapon"] = {"\124cff0070dd\124Hitem:944:0:0:0:0:0:0:0:0\124h[Elemental Mage Staff]\124h\124r", 135144},
    ["Blue Shield"] = {"\124cff0070dd\124Hitem:7726:0:0:0:0:0:0:0:0\124h[Aegis of the Scarlet Commander]\124h\124r",134951},
    ["Green Boots"] = {"\124cff1eff00\124Hitem:7524:0:0:0:0:0:0:0:0\124h[Gossamer Boots]\124h\124r", 133766}
}

local function CreateLootWidget(parent, item)
    local widget = CreateFrame("Frame", nil, parent)
    widget:SetSize(400, 40)
    
    local lootIcon = CreateLootButton(item)
    lootIcon:SetPoint("LEFT", widget, "LEFT", 4, 4)

    
    local intended_MS = CreateMSNeedButton(widget)
    intended_MS:SetPoint("TOPLEFT", lootIcon, "TOPRIGHT", 4, 0)

    local intended_OS = CreateOSNeedButton(widget)
    intended_OS:SetPoint("LEFT", intended_MS, "RIGHT", 4, 0)

    local intended_Disenchant = CreateDisenchantButton(widget)
    intended_Disenchant:SetPoint("TOP", intended_MS, "BOTTOM", 0, -4)

    local intended_Greed = CreateGreedButton(widget)
    intended_Greed:SetPoint("TOP", intended_OS, "BOTTOM", 0, -4)
    
    local highestRollIcon = widget:CreateTexture(nil, "ARTWORK")
    highestRollIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    highestRollIcon:SetSize(32, 32)
    highestRollIcon:SetPoint("LEFT", intended_OS, "RIGHT", 0, 0)
    
    local needButton = CreateOSNeedButton(widget)
    needButton:SetPoint("LEFT", highestRollIcon, "RIGHT", 0, 0)
    
    local greedButton = CreateGreedButton(widget)
    greedButton:SetPoint("LEFT", needButton, "RIGHT", 0, 0)
    
    local disenchantButton = CreateDisenchantButton(widget)
    disenchantButton:SetPoint("LEFT", greedButton, "RIGHT", 0, 0)
    
    local passButton = CreatePassButton(widget)
    passButton:SetPoint("LEFT", disenchantButton, "RIGHT", 0, 0)
    
    local playerName = widget:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    playerName:SetText("Player Name")
    playerName:SetPoint("LEFT", passButton, "RIGHT", 0, 0)
    
    local rollType = widget:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rollType:SetText("Roll Type")
    rollType:SetPoint("LEFT", playerName, "RIGHT", 0, 0)
    
    local rollValue = widget:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rollValue:SetText("Roll Value")
    rollValue:SetPoint("LEFT", rollType, "RIGHT", 0, 0)
    
    return widget
end

function GLH:ShowLog()
    if logWindow == nil then
        logWindow = AceGUI:Create("Window")
        logWindow:SetLayout("Fill")
        logEditbox = AceGUI:Create("MultiLineEditBox")
        logWindow:AddChild(logEditbox)
    end
    logEditbox:SetText(log)
    logWindow:Show()
end


-- Function to handle slash commands
local function HandleSlashCommand(msg)
    if msg == "test" then
        GLH.LootWindow:Show()
        for _, link in pairs(testLinks) do
            print(unpack(link))
            GLH:AddTooltipContainer(unpack(link))
        end
    elseif msg == "log" then
        GLH:ShowLog()

    elseif msg == "show" or msg == "" then
        GLH.LootWindow:Show()
    else
        print("Unknown command. Use /glh to open the loot window.")
    end
end

-- Register the slash command
SLASH_GROUPLOOTHELPER1 = "/glh"
SlashCmdList["GROUPLOOTHELPER"] = HandleSlashCommand



local eventHandlers = {
    START_LOOT_ROLL = "START_LOOT_ROLL",
    LOOT_HISTORY_ROLL_COMPLETE = "LOOT_HISTORY_ROLL_COMPLETE",
    CANCEL_LOOT_ROLL = "CANCEL_LOOT_ROLL",
    LOOT_HISTORY_ROLL_CHANGED = "LOOT_HISTORY_ROLL_CHANGED",
    CHAT_MSG_LOOT = "CHAT_MSG_LOOT",
    INSPECT_READY = "INSPECT_READY",
    PLAYER_REGEN_ENABLED = "PLAYER_REGEN_ENABLED",
    GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",
    RAID_ROSTER_UPDATE = "RAID_ROSTER_UPDATE",
    PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",
    PLAYER_ROLES_ASSIGNED = "PLAYER_ROLES_ASSIGNED",
}

function GLH:QueueTooltip(rollID, entry)
    tinsert(self._tooltipQueue, { id = rollID, data = entry })
end

function GLH:_ProcessTooltipQueue()
    local batchSize = 5
    for i=1, batchSize do
        local item = tremove(self._tooltipQueue, 1)
        if not item then break end
    
        local rollID = item.id
        local entry  = item.data
  
        if not entry.loot_container then
            entry.loot_container = self:AddTooltipContainer(
            entry.link,
            entry.texture,
            entry.timeEnd
            )
        end
    end
  
    if #self._tooltipQueue > 0 then
        C_Timer.After(0, function() self:_ProcessTooltipQueue() end)
    else
        self._tooltipRunning = false
    end
end

function GLH:SpawnAllTooltipContainers()
    if self._tooltipRunning then return end
    wipe(self._tooltipQueue)
  
    -- enqueue everything from activeRolls
    for rollID, entry in pairs(db.global.activeRolls) do
        self:QueueTooltip(rollID, entry)
    end
  
    self._tooltipRunning = true
    self:_ProcessTooltipQueue()
end

function GLH:OnEnable()
    db = LibStub("AceDB-3.0"):New("GroupLootHelperDB", defaults, true)

    GLH._tooltipQueue   = {}
    GLH._tooltipRunning = false

    GLH.LootWindow = CreateLootWindow()
    for k,v in pairs(eventHandlers) do
        self:RegisterEvent(v)
    end

    youName = GetUnitName("player")
    print(youName)

    uniqueID = db.global.uniqueID or 0

    DEFAULT_SPACING    = db.global.spacing or 5
    ROLE_ICON_SIZE     = db.global.role_icon_size or 16
    SPEC_ICON_SIZE     = db.global.spec_icon_size or 16
    ROLL_BUTTON_SIZE   = db.global.roll_button_size or 24
    ITEM_TOOLTIP_WIDTH = db.global.item_tooltip_width or 0      -- 0 = auto-size based on content
    PLAYER_NAME_WIDTH  = db.global.player_name_width or 0      -- auto-width for name column
    ROLL_VALUE_WIDTH   = db.global.roll_value_width or 0      -- auto-width for roll value

    GROW_UP = db.global.grow_up or false

    log = db.global.log

    activeRolls = db.global.activeRolls or {} -- Store active roll information
    historyRolls = db.global.historyRolls or {}-- Store history of rolls
    playerCache = db.global.playerCache or {}

    -- Make sure DB tables exist
    db.global.activeRolls  = activeRolls
    db.global.historyRolls = historyRolls
    db.global.playerCache  = playerCache
    db.global.uniqueID = uniqueID


    for uID, activeRoll in pairs(activeRolls) do
        if activeRoll.rollID then
            uid_to_rollid[uID] = activeRoll.rollID
            rollid_to_uid[activeRoll.rollID] = uID
        end
        if activeRoll.itemLink then
            itemLinkToRollID[activeRoll.itemLink] = uID
        end
        if activeRoll.itemName then
            itemNameToRollID[activeRoll.itemName] = uID
        end
    end

    for playerName, tbl in pairs(playerCache) do
        name = cleanName(playerName)
        if name ~= playerName then
            print(name, "<<<", playerName)
            if name then
                playerCache[playerName] = nil
                playerCache[name] = tbl
            end
        end
    end 



    self:SpawnAllTooltipContainers()
end

function GLH:CreateTooltipFrame()
    local name = "GLH_Tooltip" .. tooltipIndex
    tooltipIndex = tooltipIndex + 1
    local tooltip = CreateFrame("GameTooltip", name, UIParent, "GameTooltipTemplate")
    debugmsg("Creating tooltip: " , name , tooltip, tooltip:GetName())
    -- self:AddTooltipHooks(tooltip)
    return tooltip
end

function GLH:OnEvent(event, ...)
    table.insert(GLH_Log, {event, unpack(...)})
    local handler = eventHandlers[event]
    if handler and self[handler] then
        self[handler](self, event, ...)
    end
end

-- This function updates the class data (and placeholder spec) for every member in your group.
function GLH:UpdatePlayerCacheGroup()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then 
        -- Do not cache or process player info in battlegrounds arenas.
        return
    end

    local numGroupMembers = GetNumGroupMembers()  -- Works with raids and parties.
    for i = 1, numGroupMembers do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
        local name = UnitName(unit)
        if name and not playerCache[name] then
            self:FillPlayerInfo(name)
            -- We can get class info via UnitClass.
            local _, class = UnitClass(unit)
            Log("Updating player cache for:", name, "Class:", class)

            local classIcon = classIcons[class] or "Interface\\Icons\\INV_Misc_QuestionMark"
            local specIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
            
            -- Update or create an entry in the cache.
            if not playerCache[name] then
                playerCache[name] = {}
            end
            local classColour = self:GetClassColour(class)
            playerCache[name].cname = crayon:ColorizeRGB(classColour.r, classColour.g, classColour.b, name)
            playerCache[name].class = class or "Unknown"
            playerCache[name].classIcon = classIcon
            playerCache[name].roleIcon = "Interface\\Icons\\INV_Misc_QuestionMark"  -- You may later update this when you learn a player’s actual role.
            -- Keep existing spec info if available; otherwise set defaults.
            if not playerCache[name].spec then
                playerCache[name].spec = "Unknown"
                playerCache[name].specIcon = specIcon
            end
        end
    end
end

local function _groupUpdate()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        -- In battlegrounds/arenas, we do not cache or update info.
        return
    end
    GLH:UpdatePlayerCacheGroup()
end

function GLH:GROUP_ROSTER_UPDATE()
    _groupUpdate()
end

function GLH:RAID_ROSTER_UPDATE()
    _groupUpdate()
end

function GLH:PLAYER_ENTERING_WORLD()
    _groupUpdate()
end

function GLH:PLAYER_ROLES_ASSIGNED()
    self:UpdatePlayerCacheGroup()
end

--------------------------------------------------------------------------------
-- Example INSPECT_READY handler (for party members)
--------------------------------------------------------------------------------
function GLH:INSPECT_READY(unit)
    local name = UnitName(unit)
    if not name then return end

    local specID = GetInspectSpecialization(unit)
    local specName, specIcon = "Unknown", "Interface\\Icons\\INV_Misc_QuestionMark"
    if specID and specID > 0 then
        -- Depending on your WoW version, you might use:
        specName, _, specIcon = GetSpecializationInfoByID(specID, UnitSex(unit))  -- adjust as needed
    end

    -- Get class info as fallback; UnitClass is reliable.
    local _, class = UnitClass(unit)
    local classIcon = classIcons[class] or "Interface\\Icons\\INV_Misc_QuestionMark"

    if not playerCache[name] then
        self:FillPlayerInfo(name)
    end

    playerCache[name].spec = specName
    playerCache[name].specIcon = specIcon
    playerCache[name].class = class or "Unknown"
    playerCache[name].classIcon = classIcon

    Log("Player:", name,"is", playerCache[name].class)

end

-- Request an inspection for a given player if they’re in your group.
-- If you are in combat, cache the player’s name to inspect later.
function GLH:RequestPlayerInspect(playerName)
    local _, instanceType = IsInInstance()
    -- Skip inspections in battlegrounds or arenas (if desired)
    if instanceType == "pvp" or instanceType == "arena" then 
        return
    end

    -- If we're in combat, simply cache the player name.
    if InCombatLockdown() then
        if not pendingInspectRequests[playerName] then
            pendingInspectRequests[playerName] = true
            -- Debugging output:
            Log("Queued inspect for", playerName, "until out of combat.")
        end
        return
    end

    -- Not in combat – attempt to inspect immediately
    local numGroupMembers = GetNumGroupMembers()  -- Works with raids and parties.
    for i = 1, numGroupMembers do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
        if UnitName(unit) == playerName then
            if ( CanInspect(unit, true) ) then
                NotifyInspect(unit)
                Log("Inspecting", playerName, "immediately.")
            else
                pendingInspectRequests[playerName] = true
            end
            -- Debug output:
            Log("Inspecting", playerName, " couldn't be done immediately.")
            return
        end
    end
    if #pendingInspectRequests > 0 then
        self.inspectTicker = AceTimer:NewTicker(0.5, self.OnInspectTick, false)
    else
        self:CancelInspectTicker()
    end
end

function GLH:CancelInspectTicker()
    if #pendingInspectRequests == 0 then
        if self.inspectTicker then
            self.inspectTicker:Cancel()
            self.inspectTicker = nil
        end
    end
end

function GLH:OnInspectTick()

end

function GLH:PLAYER_REGEN_ENABLED()
    for playerName, _ in pairs(pendingInspectRequests) do
        self:RequestPlayerInspect(playerName)
        pendingInspectRequests[playerName] = nil
    end
end

-- Retrieve info for a player; if not known, request an inspect and use default values.
function GLH:FillPlayerInfo(playerName)
  local info = playerCache[playerName]
  if not info then
    self:RequestPlayerInspect(playerName)
    info = {
      class = "Unknown",
      spec = "Unknown",
      classIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
      specIcon = "Interface\\Icons\\INV_Misc_QuestionMark",
      roleIcon = "",
    }
    playerCache[playerName] = info
  end
  return info
end

function GLH:CHAT_MSG_LOOT(event, msg, ...)
    -- Don’t do anything in battlegrounds/arenas
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return
    end

    for _, key in ipairs(rollTypeChanged) do
        if msg == key then
            Log("Roll type changed: ", key)
            return
        end
    end
    
    for _, key in ipairs(rollpatternKeys) do
        local patternDef = L[key]
        local captures = { string.match(msg, patternDef.pattern) }
        if #captures > 0 then
            local payloadData = {}
            for i, field in ipairs(patternDef.payload) do
                payloadData[field] = captures[i]
            end
            
            local rollID = itemNameToRollID[payloadData.loot] or itemLinkToRollID[payloadData.loot]
            local uid = rollid_to_uid[rollID]
            if rollID and activeRolls[uid] then
                self:ProcessLootRollMessage(rollID, key, payloadData)
            else
                -- TODO add to loot history
                debugmsg(payloadData.loot, " -  couldn't find rollID")
            end

            return

        end
    end
end

function GLH:ProcessLootRollMessage(rollID, patternkey, payloadData)
    local looter = payloadData.looter
    local loot   = payloadData.loot

    looter = looter or UnitName("player")  -- Default to player if looter is not specified.
  
    if patternkey == "PATTERN_LOOT_ITEM" or 
       patternkey == "PATTERN_LOOT_ITEM_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_SELF" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_SELF" or 
       patternkey == "PATTERN_LOOT_ITEM_SELF_MULTIPLE" then
        Log("Item looted: ", looter, loot)
        -- (Additional handling for received loot can be placed here.)
    
    elseif patternkey == "PATTERN_LOOT_ROLL_NEED" or 
           patternkey == "PATTERN_LOOT_ROLL_NEED_SELF" then
        Log(looter, "rolled NEED on", loot)
    
    elseif patternkey == "PATTERN_LOOT_ROLL_GREED" or 
           patternkey == "PATTERN_LOOT_ROLL_GREED_SELF" then
        Log(looter, "rolled GREED on", loot)

    elseif patternkey == "PATTERN_LOOT_ROLL_DISENCHANT" or 
           patternkey == "PATTERN_LOOT_ROLL_DISENCHANT_SELF" then
        Log(looter, "rolled DISENCHANT on", loot)

    elseif patternkey == "PATTERN_LOOT_ROLL_PASSED" or 
           patternkey == "PATTERN_LOOT_ROLL_PASSED_AUTO" or 
           patternkey == "PATTERN_LOOT_ROLL_PASSED_AUTO_FEMALE" or 
           patternkey == "PATTERN_LOOT_ROLL_PASSED_SELF" or 
           patternkey == "PATTERN_LOOT_ROLL_PASSED_SELF_AUTO" then
        Log(looter, "passed on", loot)
        
    elseif patternkey == "PATTERN_LOOT_ROLL_ROLLED_DE" then
        Log(looter, "disenchanted ", loot)
        
    elseif patternkey == "PATTERN_LOOT_ROLL_ROLLED_NEED" or 
           patternkey == "PATTERN_LOOT_ROLL_ROLLED_NEED_ROLE_BONUS" then
        Log(looter, "won NEED roll on", loot)
        
    elseif patternkey == "PATTERN_LOOT_ROLL_ROLLED_GREED" then
        Log(looter, "won GREED roll on", loot)
        
    else
        Log("Unhandled loot pattern.")
    end
    
    -- Retrieve or update player info from the cache.
    looter = cleanName(looter)
    local info = self:FillPlayerInfo(looter)
    
    -- Build a player info table for UI purposes.
    local playerInfoData = {
      name     = looter,
      roleIcon = info.roleIcon,  -- You might update this based on class or spec via additional logic.
      specIcon = info.specIcon,
      rollType = (patternkey:find("NEED") and "NEED") or 
                 (patternkey:find("GREED") and "GREED") or
                 (patternkey:find("DISENCHANT") and "DISENCHANT") or 
                 (patternkey:find("PASSED") and "PASSED") or 
                 "UNKNOWN",
      rollIcon = (patternkey:find("NEED") and "Interface\\Buttons\\UI-GroupLoot-Dice-Up") or 
                 (patternkey:find("GREED") and "Interface\\Buttons\\UI-GroupLoot-Coin-Up") or 
                 (patternkey:find("DISENCHANT") and "Interface\\Buttons\\UI-GroupLoot-Disenchant-Up") or
                 (patternkey:find("PASSED") and "Interface\\Buttons\\UI-GroupLoot-Pass-Up") or 
                 "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
      rollValue = "",  -- Set default; you can update this as roll values become known.
    }
    
    -- Update the UI row for this player’s roll.
    self:AddRollInfo(rollID, playerInfoData)
  end


function GLH:START_LOOT_ROLL(event, rollID, rollTime)
    -- Don’t do anything in battlegrounds/arenas
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return
    end
    -- can we be sure if this fires before the chat event?

    local texture, name, count, quality, bindOnPickUp = GetLootRollItemInfo(rollID)
    local itemlink = GetLootRollItemLink(rollID)
    local timeEnd = GetTime() + rollTime
    local uid = uniqueID
    uniqueID = uniqueID + 1
    activeRolls[uid] = {
        rollID = rollID,
        name = name,
        texture = texture,
        quality = quality,
        link = itemlink,
        rolls = {},
        timeStart = GetTime(),
        timeEnd = timeEnd,
        active = true,
    }
    uid_to_rollid[uid] = rollID
    rollid_to_uid[rollID] = uid
    itemNameToRollID[name] = uid
    itemLinkToRollID[itemlink] = uid
    loot_container_cache[uid] = GLH:AddTooltipContainer(itemlink, texture, timeEnd),
    Log("New roll started for: " , name, rollID, uid, itemlink)
end

function GLH:LOOT_HISTORY_ROLL_COMPLETE(event, rollID, playerName, rollType, rollNumber, ...)
    local uid = rollid_to_uid[rollID]
    if not uid then return end
    if not activeRolls[uid] then return end
    
    local rollTypeText
    if rollType == 1 then
        rollTypeText = "Need"
    elseif rollType == 2 then
        rollTypeText = "Greed"
    elseif rollType == 3 then
        rollTypeText = "Disenchant"
    else
        rollTypeText = "Pass"
    end
    
    activeRolls[uid].rolls[playerName] = {
        type = rollTypeText,
        number = rollNumber
    }
    
    Log(playerName,
        "rolled",
        rollTypeText,
        "(", 
        rollNumber,
        ") for",
        activeRolls[uid].name)
end

function GLH:LOOT_HISTORY_ROLL_CHANGED(event, index, rollID, playerName, rollType, rollResult, ...)
    local uid = rollid_to_uid[rollID]
    if not uid then return end
    if not activeRolls[uid] then return end
    
    Log("Roll history changed for rollID: " .. rollID, playerName, rollType, rollResult, activeRolls[uid])

    local rollTypeText
    if rollType == 1 then
        rollTypeText = "Need"
    elseif rollType == 2 then
        rollTypeText = "Greed"
    elseif rollType == 3 then
        rollTypeText = "Disenchant"
    else
        rollTypeText = "Pass"
    end
    
    -- If the playerName is nil, it could be a roll ending
    if playerName then
        activeRolls[uid].rolls[playerName] = {
            type = rollTypeText,
            number = rollResult
        }
    end
    
    Log(playerName,
        "rolled",
        rollTypeText,
        "(", 
        rollResult,
        ") for", 
        activeRolls[uid].name)
end

function GLH:CANCEL_LOOT_ROLL(event, rollID)
    local uid = rollid_to_uid[rollID]
    if not uid then return end
    if not activeRolls[uid] then return end

    if activeRolls[uid] then
        Log("Roll cancelled for: ", rollID , activeRolls[uid].name)
        activeRolls[uid].active = false

    end
end






