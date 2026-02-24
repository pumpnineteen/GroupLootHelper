local addonName, addonTable = ...
local GLH = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local crayon = LibStub("Crayon-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local AceEvent = LibStub("AceEvent-3.0")

GLH_Log = GLH_Log or {}
-- Initialize localization
local L = LibStub("AceLocale-3.0"):GetLocale("GroupLootHelper")

local AceGUI = LibStub("AceGUI-3.0")
local LibSpec = LibStub("LibClassicSpecs", true) or LibStub("LibSpec")

local dummyFunc = function() end
local UnitGroupRolesAssigned = UnitGroupRolesAssigned or dummyFunc
local select = select
local pairs = pairs
local ipairs = ipairs
local unpack = unpack
local table = table
local type = type
local string = string
local tonumber = tonumber
local tostring = tostring
local C_Timer = C_Timer
local print = print
local date = date
local time = time
local YOU = YOU

local UnitExists = UnitExists
local UnitName = UnitName
local _UnitFullName = UnitFullName
local UnitGUID = UnitGUID
local UnitIsFriend = UnitIsFriend
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local GetUnitName = GetUnitName

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
        roll_button_size = 24,
        item_tooltip_width = 0,  -- 0 = auto-size based on content
        player_name_width = 0,   -- auto-width for name column
        roll_value_width = 0,    -- auto-width for roll value
        grow_up = false,
        log = "",
        activeRolls  = {},      -- keyed by rollID
        historyTable = {},
        playerGCache  = {},      
        uniqueID = 0,
    },
}

local db

local DEBUG = false
local PRINTLOG = false
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
local DEFAULT_ITEM_TOOLTIP_WIDTH = 160
local MINI_TOOLTIP_SCALE
local LIST_TOOLTIP_SCALE
local PLAYER_NAME_WIDTH
local ROLL_VALUE_WIDTH
local PLAYER_NAME_FONT_SIZE
local PLAYER_NAME_FONT_SIZE_MINI

local LOOT_EXPIRATION = 4 * 60 * 60

local GROW_UP
local log
local register_mouseover

local youName
local youFullName
local youGUID
local guidCache = {}
local realmName
local loot_container_cache = {}

local miniRollWindow
local miniRollPaged
local activeMiniRolls = {}
local activeMiniRollIDs = {}
local miniRollsActiveIndex = 1

local cnameCache = {}

local qualities = {
        poor = "|cff9d9d9d",
        common = "|cffffffff",
        uncommon = "|cff1eff00", 
        rare = "|cff0070dd",
        epic = "|cffa335ee",
        legendary = "|cffff8000",
    }

local function split(inputstr, delimiter)
    if inputstr == nil or type(inputstr) ~= "string" then
        return {}
    end
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
    local logLine = join(args, " ")
    log = log .. logLine 
    table.insert(GLH_Log, {logLine})
    log = log .. "\n"
    if logEditbox then
        logEditbox:SetText(log)
    end
    if PRINTLOG then
        print(logLine)
    end
end

local function debugmsg(...)
    if DEBUG then
        local args = {...}
        print("DEBUG:", join(args, " "))
    end
end

local function errormsg(...)
    if DEBUG then
        local args = {...}
        print("ERROR:", join(args, " "))
    end
end

local function cleanName(name)
    -- print("Cleaning name:", name)
    local nametbl = split(name, "%:%s+")
    if name == YOU then
        name = youName
    end
    return nametbl[#nametbl]
end

local function ensure(tbl, key, default)
    tbl[key] = tbl[key] or default
    return tbl[key]
end

local function inject_autovivify(tbl)
    setmetatable(tbl, {
        __index = function(t, k)
            local new = {}
            inject_autovivify(new)
            rawset(t, k, new)
            return new
        end
    })
    return tbl
end

local function IsEmptyTbl(tbl)
  for _ in pairs(tbl) do
    return false  -- Found a key!
  end
  return true     -- No keys found
end


local function PrintTable(tbl, indent, visited)
    indent  = indent or 0
    visited = visited or {}

    if visited[tbl] then
        print(string.rep("  ", indent) .. "*circular*")
        return
    end
    visited[tbl] = true

    for k, v in pairs(tbl) do
        local prefix = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            print(prefix .. "{")
            PrintTable(v, indent + 1, visited)
            print(string.rep("  ", indent) .. "}")
        else
            print(prefix .. tostring(v))
        end
    end
end

local function GetServerIDFromGUID(guid)
    -- print("GetServerIDFromGUID:", guid)
    if not guid or type(guid) ~= "string" then
        return nil
    end
    local splittbl = split(guid, "-")
    -- PrintTable(splittbl)
    local serverID = splittbl[2]

    return serverID
end

local function UnitFullName(unit)
    local fullName = _UnitFullName(unit)
    cleanName(fullName)
    if not fullName then
        return nil
    end
    if not string.find(fullName, "-") then
        fullName = fullName .. "-" .. realmName
    end
    return fullName
end

local itemLinkCache
local itemIDCache

local function GetItemID(itemLink)
    if not itemLink then
        return nil
    end
    if itemLinkCache[itemLink] then
        return itemLinkCache[itemLink]
    end
    local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
    if not itemID then
        return nil
    end
    itemLinkCache[itemLink] = itemID
    return itemID
end

local GetItemInfo = GetItemInfo
local itemDataCache

local function GetItemData(itemLink)
    local itemID = GetItemID(itemLink)

    if itemDataCache[itemID] then
        return itemDataCache[itemID]
    end

    local name, link, quality, level, minLevel, type, subType, stackCount, equipLoc,
        texture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent =
        GetItemInfo(itemLink)

    if not name or not itemID then
        return nil
    end

    itemDataCache[itemID] = {name=name, quality=quality, equipLoc=equipLoc, setID=setID, texture=texture, type=type}
    
    -- local itemTable = {
    --     name = name,
    --     link = link,
    --     quality = quality,
    --     itemLevel = level,
    --     minLevel = minLevel,
    --     type = type,
    --     subType = subType,
    --     stackCount = stackCount,
    --     equipLoc = equipLoc,
    --     texture = texture,
    --     sellPrice = sellPrice,
    --     classID = classID,
    --     subclassID = subclassID,
    --     bindType = bindType,
    --     expacID = expacID,
    --     setID = setID,
    --     isCraftingReagent = isCraftingReagent,
    -- }
    -- PrintTable(itemTable)
    return itemDataCache[itemID]
end

local GetInstanceInfo = GetInstanceInfo
local instanceCache

local function _GetInstanceInfo(mapID)
    local name, instanceType, diffID, diffName, maxPlayers, dynamicDiff,
      isDynamic, instanceID, instanceGroupSize, lfgDungeonID = GetInstanceInfo()

    print("Instance Info:", mapID, name, "Type:", instanceType, "ID:", instanceID, "LFG Dungeon ID:", lfgDungeonID)
    instanceCache[instanceID] = {mapID=mapID, name=name}
    return {
        name = name,
        instanceType = instanceType,
        difficultyID = diffID,
        difficultyName = diffName,
        maxPlayers = maxPlayers,
        instanceID = instanceID,
        lfgDungeonID = lfgDungeonID,
    }
end

local zoneID_list
local instanceID_list
local mapCache
local MAP_TYPE = Enum.UIMapType
local C_Map = C_Map
local math = math
local GetBuildInfo = GetBuildInfo

local buildID

local function GetZoneID()
    local FINAL_MAPID = 5000
    local BATCH_SIZE = 100
    local mapID

    local function _GetZoneID(start)
        local count = 0
        while mapID <= FINAL_MAPID and count < BATCH_SIZE do
            local info = C_Map.GetMapInfo(mapID)
            -- if info then 
            --     print("Checking mapID:", mapID, info.name, info.mapType, MAP_TYPE_ZONE, info.mapType == MAP_TYPE_ZONE, info.mapType == MAP_TYPE_DUNGEON)
            -- end
            if info and info.name then
                local mapType = info.mapType or 0
                if mapType == MAP_TYPE.Zone or mapType == MAP_TYPE.Dungeon then
                    zoneID_list[info.name] = {mapID=mapID, mapType=mapType}
                    print("Found zone:", info.name, "ID:", mapID, "Type:", mapType)
                end
            end
            count = count + 1
            mapID = mapID + 1
        end

        if mapID <= FINAL_MAPID then
            C_Timer.After(0, _GetZoneID)
        else
            db.global.zonesChecked = buildID
        end
    end

    mapID = 1
    _GetZoneID()
    
end

local function GetUnit(name)
    if not numGroupMembers then
        return "player"
    end

    for i = 1, numGroupMembers do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
        if UnitName(unit) == name or UnitFullName(unit) == name then
            return unit
        end
    end
end

local function GetGUID(name, unit)
    local guid = guidCache[name]
    if not guid then
        if not unit then
            unit = GetUnit(name)
        end
        guid = UnitGUID(unit)
        local fullName = UnitFullName(unit)
        guidCache[fullName] = guid
    end
    return guid
end

local function EmptyCell()
  local lbl = AceGUI:Create("Label")
  lbl:SetText("")
  return lbl
end

local activeRolls
local historyRolls
local historyTable
local playerGCache
local serverIDCache
local uid_to_rollid = {}
local rollid_to_uid = {}
local itemNameToUID = {} -- Map item names to roll IDs
local itemLinkToUID = {} -- Map item links to roll IDs
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

local LOOT_MASTER_LOOTER = LOOT_MASTER_LOOTER
local LOOT_GROUP_LOOT = LOOT_GROUP_LOOT
local LOOT_PERSONAL_LOOT = LOOT_PERSONAL_LOOT
local LOOT_FREE_FOR_ALL = LOOT_FREE_FOR_ALL
local LOOT_NEED_BEFORE_GREED = LOOT_NEED_BEFORE_GREED
local LOOT_ROUND_ROBIN = LOOT_ROUND_ROBIN

local rollTypeChanged = {
    LOOT_MASTER_LOOTER,
    LOOT_GROUP_LOOT,
    LOOT_PERSONAL_LOOT,
    LOOT_FREE_FOR_ALL,
    LOOT_NEED_BEFORE_GREED,
    LOOT_ROUND_ROBIN, 
}

local bbframes = {}

local function createbbframe()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(9999)
    f:SetClampedToScreen(true)
    f:Show()
    return f
end

local function ShowBoundingBox(targetFrame, frame, color)
    if not frame then 
        frame = createbbframe()
    end
    
    assert(targetFrame ~= nil, "Target frame must be specified")
    if targetFrame.frame then
        targetFrame = targetFrame.frame
    end
    
    -- Get target dimensions and position for comparison
    local targetWidth = targetFrame:GetWidth() or 0
    local targetHeight = targetFrame:GetHeight() or 0
    local targetLeft = targetFrame:GetLeft() or 0
    local targetBottom = targetFrame:GetBottom() or 0

    Log(targetLeft, targetBottom, targetWidth, targetHeight)
     
    -- Ensure minimum 100x100 display size
    local displayWidth = math.max(targetWidth, 100)
    local displayHeight = math.max(targetHeight, 100)
    
    -- Create or reuse debug frame
    if not frame._debugFrame then
        frame._debugFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame._debugFrame:SetFrameStrata("TOOLTIP")
        frame._debugFrame:SetFrameLevel(9999)
        frame._debugFrame:SetClampedToScreen(true)
        
        
        -- Create text display
        frame._debugText = frame._debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame._debugText:SetTextColor(1, 1, 1, 1)
        frame._debugText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    frame._debugFrame:Show()
    
    -- Position and size the debug frame
    frame._debugFrame:SetSize(displayWidth, displayHeight)

    -- Get frame dimensions and position
    local frameWidth = frame._debugFrame:GetWidth() or 0
    local frameHeight = frame._debugFrame:GetHeight() or 0
    local frameLeft = frame._debugFrame:GetLeft() or 0
    local frameBottom = frame._debugFrame:GetBottom() or 0

    -- Determine color based on match
    local borderColor
    if frameWidth ~= targetWidth or frameHeight ~= targetHeight or 
           frameLeft ~= targetLeft or frameBottom ~= targetBottom then
        borderColor = {1, 0, 0, 1} -- Red for mismatch
    else
        borderColor = {1, 1, 1, 1} -- White for match
    end
    
    if targetLeft and targetBottom then
        frame._debugFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", targetLeft, targetBottom)
    else
        -- Fallback positioning if frame has no position
        frame._debugFrame:SetPoint("CENTER", UIParent, "CENTER")
    end
    
    -- Set backdrop with colored border
    frame._debugFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame._debugFrame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    
    -- Position text at bottom right
    frame._debugText:SetPoint("BOTTOMRIGHT", frame._debugFrame, "BOTTOMRIGHT", -5, 5)
    
    -- Format bounding box info text
    local bbText = string.format("(%.0f,%.0f) %.0fx%.0f", frameLeft, frameBottom, frameWidth, frameHeight)
    frame._debugText:SetText(bbText)
    
    -- Show the debug frame
    frame._debugFrame:Show()
    
    -- Console output
    local matchStatus = (frameWidth == targetWidth and frameHeight == targetHeight and 
                        frameLeft == targetLeft and frameBottom == targetBottom) and "MATCH" or "MISMATCH"
    
    Log(string.format("BoundingBox [%s]: (%.1f,%.1f) %.1fx%.1f - %s", 
          frame:GetName() or "unnamed", frameLeft, frameBottom, frameWidth, frameHeight, matchStatus))
    
    if targetFrame ~= frame then
        Log(string.format("  Target [%s]: (%.1f,%.1f) %.1fx%.1f", 
              targetFrame:GetName() or "unnamed", targetLeft, targetBottom, targetWidth, targetHeight))
    end
end

local function HideBoundingBox(frame)
    if frame and frame._debugFrame then
        frame._debugFrame:Hide()
    end
end

-- Enhanced version that can show multiple frames at once
local function ShowMultipleBoundingBoxes(frames)
    for i, frameData in ipairs(frames) do
        local frame = frameData.frame or frameData
        local target = frameData.target
        local color = frameData.color
        
        ShowBoundingBox(frame, target, color)
    end
end

-- Utility to compare two frames visually
local function CompareBoundingBoxes(frame1, frame2, name1, name2)
    name1 = name1 or "Frame1"
    name2 = name2 or "Frame2" 
    
    print("=== Comparing " .. name1 .. " vs " .. name2 .. " ===")
    
    ShowBoundingBox(frame1, nil, {0, 1, 0, 1}) -- Green for frame1
    ShowBoundingBox(frame2, nil, {0, 0, 1, 1}) -- Blue for frame2
    
    -- Show if they match
    local f1Left, f1Bottom, f1Width, f1Height = frame1:GetLeft() or 0, frame1:GetBottom() or 0, frame1:GetWidth() or 0, frame1:GetHeight() or 0
    local f2Left, f2Bottom, f2Width, f2Height = frame2:GetLeft() or 0, frame2:GetBottom() or 0, frame2:GetWidth() or 0, frame2:GetHeight() or 0
    
    if f1Left == f2Left and f1Bottom == f2Bottom and f1Width == f2Width and f1Height == f2Height then
        print("  Frames are IDENTICAL")
    else
        print("  Frames DIFFER:")
        if f1Left ~= f2Left or f1Bottom ~= f2Bottom then
            print(string.format("    Position: %s(%.1f,%.1f) vs %s(%.1f,%.1f)", name1, f1Left, f1Bottom, name2, f2Left, f2Bottom))
        end
        if f1Width ~= f2Width or f1Height ~= f2Height then
            print(string.format("    Size: %s(%.1fx%.1f) vs %s(%.1fx%.1f)", name1, f1Width, f1Height, name2, f2Width, f2Height))
        end
    end
end

-- Usage examples:
--
-- Basic usage - white border for normal frames
-- ShowBoundingBox(myFrame)
--
-- Compare frame against target - red if different, white if same
-- ShowBoundingBox(myFrame, targetFrame) 
--
-- Force a specific color
-- ShowBoundingBox(myFrame, nil, {1, 1, 0, 1}) -- Yellow
--
-- Compare working vs broken miniroll items
-- local workingItem = YourAddon.lootRollWindow.items[1]
-- local brokenItem = YourAddon.miniRoll.pagedWidget.children[YourAddon.miniRoll.currentPage]
-- CompareBoundingBoxes(workingItem.frame, brokenItem.frame, "LootRoll", "MiniRoll")
--
-- Hide all debug visuals
-- for _, child in ipairs(YourAddon.miniRoll.pagedWidget.children) do
--     HideBoundingBox(child.frame)
-- end

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
        -- print("Adding backdop...")
        Mixin(frame, BackdropTemplateMixin)
    end
    if backdrop then
        frame:SetBackdrop(backdrop)
        -- print("Setting backdrop for frame: ", frame:GetName())
        if colour then
            frame:SetBackdropColor(colour[1] or 0, colour[2] or 0, colour[3] or 0, colour[4] or 1)
        end
    end
end

--[[
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

]]--

function GLH:CreateChildScrollList(frameWidget, parentWidget, childName, frameType)
    frameType = frameType or "ScrollFrame"
    local listFrame = AceGUI:Create(frameType)
    listFrame:SetLayout("List")
    listFrame:SetFullWidth(true)
    listFrame:SetFullHeight(true)
    listFrame:SetAutoAdjustHeight(true)
    parentWidget:AddChild(listFrame)
    frameWidget:SetUserData(childName, listFrame)

    return listFrame
end

-- Add “Roles & Specs” as the 3rd tab in CreateLootWindow
function GLH:CreateLootWindow()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Group Loot Helper")
    frame:SetLayout("Fill")

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs({
        { text = "Active Loot",    value = "active" },
        { text = "History",        value = "history" },
        { text = "Roles & Specs",  value = "roles" },
        { text = "Party History",  value = "party" },
    })
    tabGroup:SetCallback("OnGroupSelected", function(_, _, group)
        self:ShowTab(group)
    end)
    frame:AddChild(tabGroup)

    self.activeContainer = self:CreateChildScrollList(frame, tabGroup, "lootList")
    self.historyContainer = self:CreateChildScrollList(frame, tabGroup, "lootHistory", "SimpleGroup")
    self.rolesContainer = self:CreateChildScrollList(frame, tabGroup, "partyRoles")
    self.partyContainer = self:CreateChildScrollList(frame, tabGroup, "partyHistory")

    tabGroup:SelectTab("active")
    return frame
end

function GLH:ShowTab(group)
    self.activeContainer.frame:Hide()
    self.historyContainer.frame:Hide()
    self.rolesContainer.frame:Hide()
    self.partyContainer.frame:Hide()

    if group == "active" then
        self:RefreshActiveTab()
        self.activeContainer.frame:Show()

    elseif group == "history" then
        self:RefreshHistoryTab()
        self.historyContainer.frame:Show()

    elseif group == "roles" then
        self:RefreshRolesTab()
        self.rolesContainer.frame:Show()
    elseif group == "party" then
        self:RefreshPartyTab()
        self.partyContainer.frame:Show()
    else
        print("Unkown tab!", group)
    end
end

function GLH:RefreshHistoryTab()
    print("Refreshing history tab")
    
    self.historyContainer:SetLayout("List")
    self.historyContainer:SetFullWidth(true)
    self.historyContainer:SetFullHeight(true)
    
    -- Clear any existing content
    -- self.historyContainer:ReleaseChildren()
    
    -- Add a simple test label
    local testLabel = AceGUI:Create("Label")
    testLabel:SetText("History Tab Test Label")
    testLabel:SetFullWidth(true)
    testLabel.frame:Show()
    self.historyContainer:AddChild(testLabel)
    
    -- Force layout
    self.historyContainer:DoLayout()
end


function GLH:ApplyHistoryFilters()
    local scrollFrame = self.historyContainer:GetUserData("itemsScrollFrame")
    scrollFrame:ReleaseChildren()

    -- Get all history items and sort them
    local items = {}
    for dateKey, links in pairs(historyRolls) do
        for link, entry in pairs(links) do
            debugmsg(dateKey, link, entry)
            debugmsg("Processing", dateKey, link)
            if self:PassesHistoryFilters(entry, dateKey, link) then
                items[dateKey] = items[dateKey] or {}
                items[dateKey][link] = entry
                debugmsg("Accepted...")
            end
        end
    end

    -- Sort items by date first, then by secondary sort field
    for date, dateItems in pairs(items) do
        if self.historySortField then
            table.sort(dateItems, function(a, b)
                -- Secondary sort
                if self.historySortField then
                    -- Add sort logic here based on self.historySortField
                    return false
                end
                return false
            end)
        end
    end

    -- Process items in batches
    local batchSize = 10
    local currentDateIndex = 1
    local currentItemIndex = 1
    local currentDate = nil
    local currentDateItems = nil

    -- Get all history items and sort them by date
    local sortedDates = {}
    for dateKey in pairs(db.global.historyRolls) do
        table.insert(sortedDates, dateKey)
    end
    table.sort(sortedDates, function(a, b) return a > b end) -- Sort newest to oldest

    local function ProcessBatch()
        local count = 0
        
        while currentDateIndex <= #sortedDates and count < batchSize do
            local dateKey = sortedDates[currentDateIndex]
            print("Processing date:", dateKey)
            -- If we're starting a new date
            if dateKey ~= currentDate then
                currentDate = dateKey
                currentDateItems = {}
                -- Get all items for this date that pass filters
                for link, entry in pairs(historyRolls[dateKey]) do
                    if self:PassesHistoryFilters(entry, dateKey, link) then
                        entry.link = link -- Store link in entry for reference
                        table.insert(currentDateItems, entry)
                    end
                end
                -- Sort items for this date if needed
                if self.historySortField then
                    table.sort(currentDateItems, function(a, b)
                        -- Add sort logic here based on self.historySortField
                        return false
                    end)
                end
                
                -- Add date separator
                local dateSeparator = AceGUI:Create("Heading")
                dateSeparator:SetText(dateKey)
                dateSeparator:SetFullWidth(true)
                scrollFrame:AddChild(dateSeparator)
                
                currentItemIndex = 1
            end

            -- Process items for current date
            while currentItemIndex <= #currentDateItems and count < batchSize do
                local entry = currentDateItems[currentItemIndex]
                self:CreateHistoryItemRow(scrollFrame, entry)
                currentItemIndex = currentItemIndex + 1
                count = count + 1
            end

            -- Move to next date if we've processed all items for current date
            if currentItemIndex > #currentDateItems then
                currentDateIndex = currentDateIndex + 1
                currentDate = nil -- Reset current date to trigger new date processing
            end
        end

        -- If there are more items to process, schedule next batch
        if currentDateIndex <= #sortedDates or 
           (currentDate and currentItemIndex <= #currentDateItems) then
            C_Timer.After(0, ProcessBatch)
        else
            scrollFrame:DoLayout()
        end
    end

    -- Start processing the first batch
    ProcessBatch()
end

function GLH:PassesHistoryFilters(entry, dateKey, link)
    if not self.historyFilters then return true end
    local filters = self.historyFilters

    -- Player filter
    if filters.player and #filters.player >= 2 then
        if not entry.looter or not entry.looter:lower():find(filters.player:lower(), 1, true) then
            return false
        end
    end

    -- Quality filter
    if filters.qualities and next(filters.qualities) then
        local quality = entry.quality
        if not quality or not filters.qualities[quality] then
            return false
        end
    end

    -- Date range filter
    if filters.dateStart then
        if dateKey < filters.dateStart then return false end
    end
    
    if filters.dateEnd then
        if dateKey > filters.dateEnd then return false end
    end

    return true
end

function GLH:CreateHistoryItemRow(scrollFrame, entry)
    print("Creating history item row for:", entry.link)
    -- Date column (hidden but used for layout)
    local dateLabel = AceGUI:Create("Label")
    dateLabel:SetText("")
    dateLabel:SetWidth(100)
    scrollFrame:AddChild(dateLabel)

    -- Item column (icon + link)
    local itemGroup = AceGUI:Create("SimpleGroup")
    itemGroup:SetLayout("Flow")
    itemGroup:SetWidth(250)
    
    
    if entry.texture then
        local itemIcon = AceGUI:Create("Icon")
        itemIcon:SetImage(entry.texture)
        itemIcon:SetImageSize(24, 24)
        itemGroup:AddChild(itemIcon)
    else
        local placeHolder = AceGUI:Create("Label")
        placeHolder:SetText("")
        itemGroup:AddChild(placeHolder)
    end
    
    local itemLabel = AceGUI:Create("InteractiveLabel")
    itemLabel:SetText(entry.link or "Unknown Item")
    itemGroup:AddChild(itemLabel)
    scrollFrame:AddChild(itemGroup)

    -- Zone column
    local zoneLabel = AceGUI:Create("Label")
    zoneLabel:SetText(entry.zone or "Unknown")
    zoneLabel:SetWidth(150)
    scrollFrame:AddChild(zoneLabel)

    -- Looter column
    local looterLabel = AceGUI:Create("Label")
    looterLabel:SetText(entry.looter or "Unknown")
    looterLabel:SetWidth(100)
    scrollFrame:AddChild(looterLabel)

    -- Type column
    local typeLabel = AceGUI:Create("Label")
    typeLabel:SetText(entry.rollType or "")
    typeLabel:SetWidth(80)
    scrollFrame:AddChild(typeLabel)

    -- Slot column
    local slotLabel = AceGUI:Create("Label")
    slotLabel:SetText(entry.equipSlot or "")
    slotLabel:SetWidth(100)
    scrollFrame:AddChild(slotLabel)
end

-- Re-draw the Roles & Specs tab
function GLH:RefreshRolesTab()
    self.rolesContainer:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Table")
    scrollFrame:SetUserData("table", {
        columns = {
            0,    -- Name (auto)
            0,    -- Role buttons
            0,    -- Primary stat
            0,    -- Current spec / talent points
            0,    -- Assign spec dropdown
        },
        space  = DEFAULT_SPACING,
        alignH = "LEFT",
    })
    scrollFrame:SetFullWidth(true)
    scrollFrame:SetFullHeight(true)
    self.rolesContainer:AddChild(scrollFrame)

    -- Header row
    local headerTitles = { "Name", "Role", "Stat", "Current", "Assign Spec" }
    for _, title in ipairs(headerTitles) do
        local headerLabel = AceGUI:Create("Label")
        headerLabel:SetText("|cff00ffff" .. title .. "|r")
        headerLabel:SetFontObject(GameFontNormalSmall)
        headerLabel:SetUserData("cell", { alignH = "CENTER" })
        scrollFrame:AddChild(headerLabel)
    end

    -- One row per group member
    local numMembers = GetNumGroupMembers()
    for index = 1, numMembers do
        local unit = IsInRaid() and ("raid" .. index)
                     or (index == numMembers and "player" or "party" .. index)
        if UnitExists(unit) then
            self:CreateRoleSpecRow(scrollFrame, unit)
        end
    end

    scrollFrame:DoLayout()
    self.rolesContainer:DoLayout()
end

-- Factory for each player’s row
function GLH:CreateRoleSpecRow(parent, unit)
    local playerName = UnitName(unit)
    local cacheInfo  = db.global.playerGCache[playerName] or {}

    -- Column 1: Name (highlight & click-to-target)
    local nameLabel = AceGUI:Create("Label")
    nameLabel:SetText(cacheInfo.cname or playerName)
    nameLabel:SetUserData("cell", { alignH = "LEFT" })
    parent:AddChild(nameLabel)

    local nameFrame = nameLabel.frame
    nameFrame:EnableMouse(true)

    -- Highlight on hover
    nameFrame:SetScript("OnEnter", function()
        nameLabel:SetColor(1, 1, 0)  -- yellow
    end)
    nameFrame:SetScript("OnLeave", function()
        nameLabel:SetColor(1, 1, 1)  -- white
    end)

    -- Target unit on click
    nameFrame:SetScript("OnMouseUp", function()
        if UnitExists(unit) then
            TargetUnit(unit)
        end
    end)

    -- Column 2: Role buttons
    local roleGroup = AceGUI:Create("SimpleGroup")
    roleGroup:SetLayout("Flow")
    roleGroup:SetUserData("cell", { alignH = "CENTER" })
    roleGroup:SetWidth(90)
    parent:AddChild(roleGroup)

    for _, role in ipairs({ "TANK", "HEALER", "DAMAGE" }) do
        local roleButton = AceGUI:Create("Button")
        roleButton:SetText(role:sub(1,1))
        roleButton:SetWidth(25)
        roleButton:SetCallback("OnClick", function()
            cacheInfo.role = role
            db.global.playerGCache[playerName].role = role
        end)
        roleGroup:AddChild(roleButton)
    end

    -- Column 3: Highest primary stat
    local statValue = cacheInfo.bestStat or "-"
    local statLabel = AceGUI:Create("Label")
    statLabel:SetText(statValue)
    statLabel:SetUserData("cell", { alignH = "CENTER" })
    parent:AddChild(statLabel)

    -- Column 4: Current spec (Cata+) or Talent Points (pre-Mists)
    local specOrPointsFrame = AceGUI:Create("SimpleGroup")
    specOrPointsFrame:SetLayout("Flow")
    specOrPointsFrame:SetUserData("cell", { alignH = "CENTER" })
    specOrPointsFrame:SetWidth(100)
    parent:AddChild(specOrPointsFrame)

    local buildNumber = select(4, GetBuildInfo())
    if buildNumber >= 40000 then
        -- Post-Cataclysm: show live spec icon+name
        local specID = GetInspectSpecialization(unit)
        local specName, _, specIcon = GetSpecializationInfoByID(specID, UnitSex(unit))
        local specIconWidget = AceGUI:Create("Icon")
        specIconWidget:SetImage(specIcon)
        specIconWidget:SetImageSize(16, 16)
        specIconWidget:SetUserData("cell", { alignH = "CENTER" })
        specOrPointsFrame:AddChild(specIconWidget)

        local specNameLabel = AceGUI:Create("Label")
        specNameLabel:SetText(specName or "Unknown")
        specNameLabel:SetUserData("cell", { alignH = "LEFT" })
        specOrPointsFrame:AddChild(specNameLabel)

    else
        -- Pre-Mists: editable talent points
        local pointsBox = AceGUI:Create("EditBox")
        pointsBox:SetWidth(75)
        pointsBox:SetText(cacheInfo.talentPoints or "")
        pointsBox:SetUserData("cell", { alignH = "CENTER" })
        pointsBox:SetCallback("OnEnterPressed", function(_, _, text)
            cacheInfo.talentPoints = tonumber(text) or 0
            db.global.playerGCache[playerName].talentPoints = cacheInfo.talentPoints
        end)
        specOrPointsFrame:AddChild(pointsBox)
    end

    -- Column 5: Assign Spec dropdown (always editable)
    local specDropdown = AceGUI:Create("Dropdown")
    specDropdown:SetUserData("cell", { alignH = "LEFT" })
    specDropdown:SetWidth(150)

    -- Build list of all specs
    local availableSpecs = {}
    local numSpecs = GetNumSpecializations and GetNumSpecializations() or GetNumTalentTabs()
    for specIndex = 1, numSpecs do
        local specInfoName, _, specInfoIcon =
            (GetSpecializationInfo and GetSpecializationInfo(specIndex))
            or GetTalentTabInfo(specIndex)
        availableSpecs[specIndex] = ("|T%s:0|t %s"):format(specInfoIcon, specInfoName)
    end

    specDropdown:SetList(availableSpecs)
    specDropdown:SetValue(cacheInfo.specID or 1)
    specDropdown:SetCallback("OnValueChanged", function(_, _, selected)
        cacheInfo.specID = selected
        db.global.playerGCache[playerName].specID = selected
    end)

    parent:AddChild(specDropdown)
end

function GLH:RefreshActiveTab()
    -- Refresh the layout after adding all rolls
    self.activeContainer:DoLayout()
end

function GLH:AddTooltipContainer(itemLink, texture, timeEnd, rollID)
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
    local mainContainer = self:CreateItemRollContainerTable(itemLink)

    self:AddItemRollCells(mainContainer, lootList, itemLink, texture, rollID, LIST_TOOLTIP_SCALE)

    -----------------------------------------
    -- Finally, add the main container to Loot Window's scroll list.
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

function GLH:CreateItemRollContainerTable(itemLink)
    local mainContainer = AceGUI:Create("SimpleGroup")
    -- print("Creating main container for item: " , itemLink)
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
    return mainContainer
end

function GLH:AddItemRollCells(mainContainer, lootList, itemLink, texture, rollID, miniRoll, tooltip_scale)
-----------------------------------------
    -- Column 1: Item Tooltip
    -----------------------------------------
    local colTooltip = AceGUI:Create("SimpleGroup")
    colTooltip:SetLayout("Flow")
    colTooltip:SetAutoAdjustHeight(true)
    colTooltip:SetUserData("cell", { alignH = "LEFT", alignV = "TOP" })

    do
        local tooltipFrame = GLH:CreateTooltipFrame()
        print(ITEM_TOOLTIP_WIDTH, "setting tooltip width, scale", tooltip_scale)
        local tooltipWidget = AceGUI:Create("GLHTooltip")
        -- tooltipWidget.frame:SetScale(tooltip_scale or 1.0)
        tooltipWidget.tooltipWidth = ITEM_TOOLTIP_WIDTH
        if lootList then
            tooltipWidget:SetUserData("layoutParent", lootList)
        end
        tooltipWidget:SetUserData("tooltipWidth", ITEM_TOOLTIP_WIDTH)
        tooltipWidget:SetTooltipFrame(tooltipFrame)
        tooltipWidget:SetHyperlink(itemLink, texture)
        tooltipFrame:Show()
        local tooltip = tooltipWidget.frame

        -- AddBackdropToFrame(tooltipWidget.compactBackground, edgelessBackdrop, {0, 0, 0, 0.6})
        -- AddBackdropToFrame(tooltipWidget.expandedBackground, edgelessBackdrop, {0, 0, 0, 0.6})
        
        tooltip:SetClampedToScreen(false)
        tooltip:Show()

        colTooltip:AddChild(tooltipWidget)
    end
    mainContainer:AddChild(colTooltip)
    AceEvent:Embed(colTooltip)
    function colTooltip:GLH_TOOLTIP_NEW_ITEMINFO(msg, itemLink)
        local _il =  colTooltip:GetUserData("itemLink")
        if itemLink == colTooltip:GetUserData("itemLink") then
            print("MATCHING GLH_TOOLTIP_NEW_ITEMINFO received", itemLink)
            -- colTooltip.frame:SetWidth(colTooltip.)
        end
        -- print("GLH_TOOLTIP_NEW_ITEMINFO received", _il, itemLink)
    end
    colTooltip:RegisterMessage("GLH_TOOLTIP_NEW_ITEMINFO", "GLH_TOOLTIP_NEW_ITEMINFO")

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
    mainContainer:AddChild(colPlayerInfoScroll)

    -- Configure the nested table within the scroll frame.
    -- This nested table has five sub-columns:
    --  1: Player Name (auto)
    --  2: Role Icon (fixed 16px)
    --  3: Spec Icon (fixed 16px)
    --  4: Roll Icon (auto)
    --  5: Roll Value (auto)

    -- Populate the player info table with one row as an example.
    local playerNamesTable = AceGUI:Create("SimpleGroup")
    playerNamesTable:SetAutoAdjustHeight(true)
    mainContainer:SetUserData("playerNamesTable", playerNamesTable)
    playerNamesTable:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })

    local tableLayout
    if miniRoll then
        tableLayout = {
            columns = {
                0, -- player name
                ROLE_ICON_SIZE,
                SPEC_ICON_SIZE,
                ROLL_BUTTON_SIZE,               
            },
            space = DEFAULT_SPACING,
            alignH = "LEFT",
            alignV = "CENTER",
        }
    else
        tableLayout = {
            columns = {
                0, -- player name
                ROLE_ICON_SIZE,
                SPEC_ICON_SIZE,
                ROLL_BUTTON_SIZE,               
                ROLL_VALUE_WIDTH,
            },
            space = DEFAULT_SPACING,
            alignH = "LEFT",
            alignV = "CENTER",
        }
    end
    playerNamesTable:SetUserData("table", tableLayout)
    playerNamesTable:SetLayout("Table")
    playerNamesTable:SetUserData("FirstGreedOrDisenchant", nil)
    playerNamesTable:SetUserData("FirstPass", nil)
    playerNamesTable:SetUserData("miniRoll", miniRoll)
    
    function playerNamesTable:OnRollInfo(event, info)
        if info.rollID == self.rollID then
            print("RollInfo received!")
            local _miniRoll = self:GetUserData("miniRoll")
            if _miniRoll then
                Log("PagedMini: OnRollInfo - rollID:", info.rollID, "player:", info.name, "cname:", info.cname, "rollValue:", tostring(info.rollValue))
            end
            local row = {}
            
            local nameLabel = AceGUI:Create("Label")
            nameLabel:SetText(info.cname)
            table.insert(row, nameLabel)

            local roleIcon
            if info.roleIcon then
                roleIcon = AceGUI:Create("Icon")
                roleIcon:SetImage(info.roleIcon)
                roleIcon:SetWidth(ROLE_ICON_SIZE)
                roleIcon:SetHeight(ROLE_ICON_SIZE)
            else 
                roleIcon = EmptyCell()
            end
            table.insert(row, roleIcon)

            local specIcon
            if info.specIcon then
                specIcon = AceGUI:Create("Icon")
                specIcon:SetImage(info.specIcon)
                specIcon:SetWidth(SPEC_ICON_SIZE)
                specIcon:SetHeight(SPEC_ICON_SIZE)
            else
                specIcon = EmptyCell()
            end
            table.insert(row, specIcon)

            local rollIcon = AceGUI:Create("Icon")
            rollIcon:SetImage(info.rollIcon)
            rollIcon:SetWidth(ROLL_BUTTON_SIZE)
            rollIcon:SetHeight(ROLL_BUTTON_SIZE)
            table.insert(row, rollIcon)

            if not _miniRoll then
                local rollValue = AceGUI:Create("Label")
                rollValue:SetText(info.rollValue or "")
                rollValue:SetUserData("rollID", rollID)
                rollValue:SetUserData("name", info.name)
                AceEvent:Embed(rollValue)
                function rollValue:OnRollValue(event, info)
                    local _rollID = self:GetUserData("rollID")
                    local _name = self:GetUserData("name")
                    if info.rollID == _rollID and info.name == _name then
                        self:SetText(info.rollValue)
                    end
                end
                rollValue:RegisterMessage("GLH_ROLL_VALUE", "OnRollValue")
                table.insert(row, rollValue)
            end

            playerNamesTable:AddChildren(row)

        end
    end
    AceEvent:Embed(playerNamesTable)
    playerNamesTable:RegisterMessage("GLH_ROLL_INFO", "OnRollInfo")


    -- Finally, add the player row to the vertical scroll container.
    colPlayerInfoScroll:AddChild(playerNamesTable)

    mainContainer:SetUserData("playerNamesTable", playerNamesTable)

    -----------------------------------------
    -- Column 3: Roll Buttons (using Flow Layout)
    -----------------------------------------
    local colRoll = AceGUI:Create("SimpleGroup")
    colRoll:SetAutoAdjustHeight(true)
    colRoll:SetLayout("Flow")
    colRoll:SetUserData("cell", { alignH = "CENTER", alignV = "TOP" })
    mainContainer:AddChild(colRoll)

    -- Create roll buttons using your existing functions.
    local msNeedButton = self:CreateMSNeedButton(ROLL_BUTTON_SIZE, rollID)
    local osNeedButton = self:CreateOSNeedButton(ROLL_BUTTON_SIZE, rollID)
    -- local disenchantButton = self:CreateDisenchantButton(ROLL_BUTTON_SIZE)
    local greedButton = self:CreateGreedButton(ROLL_BUTTON_SIZE, rollID)
    local passButton = self:CreatePassButton(ROLL_BUTTON_SIZE, rollID)

    -- Add buttons to the roll column.
    colRoll:AddChild(msNeedButton)
    colRoll:AddChild(osNeedButton)
    -- colRoll:AddChild(disenchantButton)
    colRoll:AddChild(greedButton)
    colRoll:AddChild(passButton)
end


function GLH:AddRollInfo(rollID, playerInfoData)
    Log("Adding roll info for rollID:", rollID, "player:", playerInfoData.name, "cname:", playerInfoData.cname, "rollValue:", tostring(playerInfoData.rollValue))
    local uid = rollid_to_uid[rollID]
    if not uid then 
        print("WARNING: couldn't find uniqueID for rollID", rollID)
        Log("WARNING: couldn't find uniqueID for rollID", rollID)
        return 
    end

    -- Store roll data in activeRolls for later sorting
    if not activeRolls[uid].rollsData then
        activeRolls[uid].rollsData = {}
    end
    
    -- Get class info and colorize name
    local class = playerInfoData.class
    local name = playerInfoData.name
    if class then
        local classColour = self:GetClassColour(class)
        playerInfoData.cname = crayon:ColorizeRGB(classColour.r, classColour.g, classColour.b, name)
    end
    
    -- Store the player's roll data
    activeRolls[uid].rollsData[name] = playerInfoData
    
    -- Refresh the entire display with sorted data
    self:RefreshRollDisplay(rollID)
    self:RefreshMiniRollDisplay(rollID)

    -- local playerNamesTable = loot_container_cache[uid].loot_container:GetUserData("playerNamesTable")
    -- if not playerNamesTable then return end
    -- local firstGreedOrDisenchant = playerNamesTable:GetUserData("FirstGreedOrDisenchant")
    -- local firstPass = playerNamesTable:GetUserData("FirstPass")
    -- local rollType = playerInfoData.rollType
    -- if not rollType then
    --     errormsg("playerInfoData.rollType is nil for rollID: " .. tostring(uid))
    --     rollType = "PASSED"
    -- end

    -- local function AddName(before)
    --     local playerName = AceGUI:Create("Label")
    --     playerName:SetText(playerInfoData.name or "Unknown")
    --     playerName:SetUserData("cell", { alignH = "LEFT", alignV = "CENTER" })
    --     playerNamesTable:AddChild(playerName, before)
    --     return playerName
    -- end
    
    -- local function AddRole(before)
    --     local roleIcon = AceGUI:Create("Icon")
    --     roleIcon:SetImage(playerInfoData.roleIcon or "Interface\\Icons\\INV_Shield_04")
    --     roleIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    --     playerNamesTable:AddChild(roleIcon, before)
    --     return roleIcon
    -- end

    -- local function AddSpec(before)
    --     local specIcon = AceGUI:Create("Icon")
    --     specIcon:SetImage(playerInfoData.specIcon or "Interface\\Icons\\INV_Sword_04")
    --     specIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    --     playerNamesTable:AddChild(specIcon, before)
    --     return specIcon
    -- end
    
    -- local function AddRollIcon(before)
    --     local rollIcon = AceGUI:Create("Icon")
    --     rollIcon:SetImage(playerInfoData.rollIcon or "Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    --     rollIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    --     playerNamesTable:AddChild(rollIcon, before)
    --     return rollIcon
    -- end
    
    -- local function AddRollValue(before)
    --     local rollValue = AceGUI:Create("Label")
    --     rollValue:SetText(playerInfoData.rollValue or "")
    --     rollValue:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    --     playerNamesTable:AddChild(rollValue, before)
    --     return rollValue
    -- end

    -- local function AddForward()
    --     local nameLabel = AddName()
    --     AddRole()
    --     AddSpec()
    --     AddRollIcon()
    --     AddRollValue()
    --     return nameLabel
    -- end

    -- local function AddBackward(before)
    --     local before = AddRollValue(before)
    --     before = AddRollIcon(before)
    --     before = AddSpec(before)
    --     before = AddRole(before)
    --     local nameLabel = AddName(before)
    --     return nameLabel
    -- end

    -- local function InsertInfo()
    --     if rollType == "NEED"  and firstGreedOrDisenchant then
    --         AddBackward(firstGreedOrDisenchant)
        
    --     elseif (rollType == "NEED" or rollType == "GREED" or rollType == "DISENCHANT") and firstPass then
    --         local insert = AddBackward(firstPass)
    --         -- Store firstGreedOrDisenchant if it doesn't exist
    --         if rollType == "GREED" or rollType == "DISENCHANT" then
    --             if not firstGreedOrDisenchant then
    --                 playerNamesTable:SetUserData("FirstGreedOrDisenchant", insert)
    --             end
    --         end
    --     else
    --         local insert = AddForward()
    --         -- Store firstPass if it doesn't exist
    --         if rollType == "PASSED" then
    --             if not firstPass then
    --                 playerNamesTable:SetUserData("FirstPass", insert)
    --             end
    --         end
    --     end
    -- end

    -- playerNamesTable:DoLayout()
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
    local widget = AceGUI:Create("InteractiveLabel")
    widget:SetWidth(size)
    widget:SetHeight(size)
    widget:SetText("")
    
    local button = widget.frame
    widget.vertexColor = vertexColor
    widget.normalTexture = textures['up']
    widget.pushedTexture = textures['down']

    widget:SetImage(widget.normalTexture)

    local highlightTexture = button:CreateTexture(nil, "ARTWORK")
    highlightTexture:SetTexture(textures['highlight'])    
    highlightTexture:SetAllPoints(widget.image)
    highlightTexture:SetBlendMode("ADD")
    if vertexColor then
        highlightTexture:SetVertexColor(unpack(vertexColor))
    end
    highlightTexture:SetAlpha(0.7)
    highlightTexture:Hide()
    widget.highlightTexture = highlightTexture
    
    function widget:MaybeVertexColor()
        if self.image then
            if self.vertexColor then
                self.image:SetVertexColor(unpack(self.vertexColor))
            else
                self.image:SetVertexColor(1, 1, 1, 1)
            end
        end
    end
    widget:MaybeVertexColor()
    widget:SetImageSize(size, size)

    widget:SetCallback("OnEnter", function()
        widget.highlightTexture:Show()
    end)

    widget:SetCallback("OnLeave", function()
        widget.highlightTexture:Hide()
    end)

    widget:SetCallback("OnMouseDown", function()
        widget:SetImage(widget.pushedTexture)
        widget:MaybeVertexColor()
        widget:SetImageSize(size, size)
        -- print("pushed")
    end)
    
    
    return widget
end

local function IsGargulRoll(rollID)
    -- Check if the rollID is a Gargul roll
    if type(rollID) == "number" then
        return false
    end
    return rollID and rollID:match("^GargulRoll_")
end

local function disableButton(button, time)
    if not button then return end
    if not button.GetParent then return end
    
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
        GLH:SendMessage("GLH_ROLLED", {rollID = rollID})
        if IsGargulRoll(rollID) then
            print("MS Need clicked")
            RandomRoll(1, 100)
            disableButton(widget, 3)

        elseif rollID and type(rollID) == "number" then
            print("MS Need clicked", rollID, rollid_to_uid[rollID])
            RollOnLoot(rollID, 1)
            disableButton(widget)
            -- GLH:RemoveRollID(rollID)
        else 
            print("RollID missing...")
        end
    end)
    return button
end

function GLH:CreateOSNeedButton(size, rollID)
    local button = CreateButtonWithTextures(size, needButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "OSNeed")
    button:SetCallback("OnClick", function(widget, event, ...)
        GLH:SendMessage("GLH_ROLLED", {rollID = rollID})
        if IsGargulRoll(rollID) then
            Log("OS Need clicked")
            RandomRoll(1, 99)
            disableButton(widget, 3)
        elseif rollID and type(rollID) == "number" then
            Log("OS Need clicked", rollID, rollid_to_uid[rollID])
            RollOnLoot(rollID, 1)
            disableButton(widget, 3)
            -- GLH:RemoveRollID(rollID)
        else 
            print("RollID missing...")
        end
    end)
    return button
end

function GLH:CreateGreedButton(size, rollID)
    local button = CreateButtonWithTextures(size, greedButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "Greed")
    button:SetCallback("OnClick", function(widget, event, ...)
        GLH:SendMessage("GLH_ROLLED", {rollID = rollID})
        print("Greed clicked", rollID)
        if IsGargulRoll(rollID) then
            RandomRoll(1, 100)
            disableButton(widget)
        elseif rollID and type(rollID) == "number" then
            print("Attempting to roll on loot", rollID, rollid_to_uid[rollID])
            RollOnLoot(rollID, 2)
            disableButton(widget, 3)
            -- GLH:RemoveRollID(rollID)
        else 
            print("RollID missing...")
        end
    end)
    return button
end

function GLH:CreateDisenchantButton(size, rollID)
    local button = CreateButtonWithTextures(size, disenchantButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "Disenchant")
    button:SetCallback("OnClick", function(widget, event, ...)
        print("Disenchant clicked", rollID)
        if rollID and type(rollID) == "number" then
            RollOnLoot(rollID, 3)
            disableButton(widget, 3)
        end
        -- GLH:RemoveRollID(rollID)
    end)
    return button
end

function GLH:CreatePassButton(size, rollID)
    local button = CreateButtonWithTextures(size, passButtonTextures)
    button:SetUserData("rollID", rollID)
    button:SetUserData("rollType", "Pass")
    button:SetCallback("OnClick", function(widget, event, ...)
        GLH:SendMessage("GLH_ROLLED", {rollID = rollID})
        print("Pass clicked", rollID)
        if rollID and type(rollID) == "number" then
            RollOnLoot(rollID, 0)
            disableButton(widget, 3)
        end
        -- GLH:RemoveRollID(rollID)
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

-- Roll type priority for sorting (lower number = higher priority)
local ROLL_TYPE_PRIORITY = {
    NEED = 1,
    GREED = 2,
    DISENCHANT = 3,
    PASSED = 4,
    UNKNOWN = 5
}

-- Sort rolls by type priority, then alphabetically by name
local function SortRolls(rolls)
    local sortedPlayers = {}
    
    -- Convert hash table to array for sorting
    for playerName, rollData in pairs(rolls) do
        table.insert(sortedPlayers, {
            name = playerName,
            rollType = rollData.rollType,
            rollValue = rollData.rollValue,
            class = rollData.class,
            roleIcon = rollData.roleIcon,
            specIcon = rollData.specIcon,
            rollIcon = rollData.rollIcon,
            cname = rollData.cname
        })
    end
    
    -- Sort by roll type priority first, then alphabetically
    table.sort(sortedPlayers, function(a, b)
        local priorityA = ROLL_TYPE_PRIORITY[a.rollType] or 999
        local priorityB = ROLL_TYPE_PRIORITY[b.rollType] or 999
        
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
        
        -- Same roll type, sort alphabetically by name
        return a.name < b.name
    end)
    
    return sortedPlayers
end

-- Add a single player row to the table
function GLH:AddPlayerRow(playerNamesTable, playerData, rollID, fontsize)
    local miniRoll = playerNamesTable:GetUserData("miniRoll")
    
    -- Player name (colorized by class)
    local nameLabel = AceGUI:Create("Label")
    if not playerData.cname then
        local class = playerData.class
        local name = playerData.name
        if not class and name then
            local guid = guidCache[name]
            if not guid then
                Log("WARNING: no GUID found for player", name)
            else
                playerData.cname = cnameCache[guid]
            end
        end
        if not playerData.cname then
             Log("WARNING: no cname found for player", name)
        end
        playerData.cname = playerData.cname or name or "Unknown"
    end
    nameLabel:SetText(playerData.cname or playerData.name)
    nameLabel:SetFont(GameFontNormal:GetFont(), fontsize or 12, "OUTLINE")
    nameLabel:SetUserData("cell", { alignH = "LEFT", alignV = "CENTER" })
    playerNamesTable:AddChild(nameLabel)
    
    -- Role icon
    local roleIcon
    if playerData.roleIcon then
        roleIcon = AceGUI:Create("Icon")
        roleIcon:SetImage(playerData.roleIcon)
        roleIcon:SetWidth(ROLE_ICON_SIZE)
        roleIcon:SetHeight(ROLE_ICON_SIZE)
        roleIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    else 
        roleIcon = EmptyCell()
    end
    playerNamesTable:AddChild(roleIcon)
    
    -- Spec icon
    local specIcon
    if playerData.specIcon then
        specIcon = AceGUI:Create("Icon")
        specIcon:SetImage(playerData.specIcon)
        specIcon:SetWidth(SPEC_ICON_SIZE)
        specIcon:SetHeight(SPEC_ICON_SIZE)
        specIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    else
        specIcon = EmptyCell()
    end
    playerNamesTable:AddChild(specIcon)
    
    -- Roll icon
    local rollIcon = AceGUI:Create("Icon")
    rollIcon:SetImage(playerData.rollIcon or "Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    rollIcon:SetWidth(ROLL_BUTTON_SIZE)
    rollIcon:SetHeight(ROLL_BUTTON_SIZE)
    rollIcon:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
    playerNamesTable:AddChild(rollIcon)
    
    -- Roll value (only for non-mini display)
    if not miniRoll and playerData.rollValue then
        local rollValue = AceGUI:Create("Label")
        rollValue:SetText(tostring(playerData.rollValue))
        rollValue:SetUserData("cell", { alignH = "CENTER", alignV = "CENTER" })
        playerNamesTable:AddChild(rollValue)
    end
end

-- Refresh the roll display for a specific rollID
function GLH:RefreshRollDisplay(rollID)
    local uid = rollid_to_uid[rollID]
    if not uid then 
        print("WARNING: couldn't find uniqueID for rollID", rollID)
        return 
    end
    
    local container = loot_container_cache[uid]
    if not container or not container.loot_container then
        print("WARNING: couldn't find container for rollID", rollID)
        return
    end
    
    local playerNamesTable = container.loot_container:GetUserData("playerNamesTable")
    if not playerNamesTable then
        print("WARNING: couldn't find playerNamesTable for rollID", rollID)
        return
    end
    
    -- Clear existing children
    playerNamesTable:ReleaseChildren()
    
    -- Get rolls data for this rollID
    local rollsData = activeRolls[uid] and activeRolls[uid].rollsData or {}
    local sortedRolls = SortRolls(rollsData)
    
    -- Re-add all players in sorted order
    for _, playerData in ipairs(sortedRolls) do
        self:AddPlayerRow(playerNamesTable, playerData, rollID, PLAYER_NAME_FONT_SIZE)
    end
    
    playerNamesTable:DoLayout()
end

-- Refresh mini roll display
function GLH:RefreshMiniRollDisplay(rollID)
    Log("RefreshMiniRollDisplay: called for rollID", rollID, "activeMiniRolls:", activeMiniRolls[rollID])
    if not activeMiniRolls[rollID] then return end
    
    local miniContainer = activeMiniRolls[rollID]
    local playerNamesTable = miniContainer:GetUserData("playerNamesTable")
    if not playerNamesTable then
        Log("RefreshMiniRollDisplay: no playerNamesTable for rollID", rollID)
        return
    end
    
    -- Clear existing children
    playerNamesTable:ReleaseChildren()
    
    -- Get rolls data
    local uid = rollid_to_uid[rollID]
    if not uid or not activeRolls[uid] then
        Log("RefreshMiniRollDisplay: no activeRolls entry for uid/rollID", uid, rollID)
        return
    end
    
    local rollsData = activeRolls[uid].rollsData or {}
    local sortedRolls = SortRolls(rollsData)
    Log("RefreshMiniRollDisplay: rollID", rollID, "players to display:", #sortedRolls)
    
    -- Re-add all players in sorted order
    for _, playerData in ipairs(sortedRolls) do
        self:AddPlayerRow(playerNamesTable, playerData, rollID, PLAYER_NAME_FONT_SIZE_MINI)
    end
    
    playerNamesTable:DoLayout()
end

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
local function HandleSlashCommand(_msg)
    local args = split(_msg)
    local msg = args[1]
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
    elseif msg == "zones" then
        zoneID_list = {}
        GetZoneID()    
        db.global.zoneID_list = zoneID_list
    elseif msg == "history" then    
        PrintTable(historyRolls)
    elseif msg == "conv" then
        GLH:ConvertHistoryRollsFormat()
    elseif msg == "mini" then
        GLH:ActiveMiniRollsPages()
    elseif msg == "prlog" then
        PRINTLOG = not PRINTLOG
        print("Print log enabled:", PRINTLOG)
    elseif msg == "pmini" then
        PRINTLOG = true
        Log("Tooltip width:", ITEM_TOOLTIP_WIDTH)
        GLH:ActiveMiniRollsPages()
        local index = 0
        for k, link in pairs(testLinks) do
            C_Timer.After(1*index, function()
                -- Log("Adding mini:", unpack(link))
                local itemLink, texture = unpack(link)
                GLH:CreateMiniRollPages(k, itemLink, texture)
            end)
            index = index + 1
        end
    elseif msg == "roll" then
       GLH:TestRolls() 
    elseif msg == "mscale" then
        GLH:SetMiniScale(args[2] or 1.0)
    elseif msg == "mtwidth" then
        GLH:SetMiniTooltipWidth(args[2] or DEFAULT_ITEM_TOOLTIP_WIDTH)
    elseif msg == "pbb" then
        PRINTLOG = true
        if not miniRollPaged then
            return
        end
        Log("MiniRoll Page BB...")
        if not miniRollPaged.currentIndex then
            Log("No current page...")
            return
        end
        Log("Current page:", miniRollPaged.currentIndex)
        if not GLH.testBB then
            GLH.testBB = createbbframe()
        end
        local targetFrame = miniRollPaged.pages[miniRollPaged.currentIndex]
        ShowBoundingBox(targetFrame, GLH.testBB)


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
    UPDATE_MOUSEOVER_UNIT = "UPDATE_MOUSEOVER_UNIT"
}

function GLH:SetMiniScale(scale)
    scale = scale or 1.0
    scale = tonumber(scale)

    if scale < 0.1 then
        scale = 1.0
    end
    MINI_TOOLTIP_SCALE = scale
    db.global.mini_tooltip_scale = MINI_TOOLTIP_SCALE
    if miniRollPaged then
        miniRollPaged:SetScale(MINI_TOOLTIP_SCALE)
    end
end

function GLH:SetMiniTooltipWidth(width)
    ITEM_TOOLTIP_WIDTH = width or DEFAULT_ITEM_TOOLTIP_WIDTH
    ITEM_TOOLTIP_WIDTH = tonumber(ITEM_TOOLTIP_WIDTH)
    db.global.item_tooltip_width = ITEM_TOOLTIP_WIDTH
end

function GLH:GetDateKey(currDate)
    if not currDate then
        currDate = date("*t")
    end
    return string.format("%d-%02d-%02d", 
        currDate.year,
        currDate.month, 
        currDate.day)
end

function GLH:QueueTooltip(uid, entry)
    tinsert(self._tooltipQueue, { id = uid, data = entry })
end

function GLH:UPDATE_MOUSEOVER_UNIT()
    if not playerGCache then
        return
    end
    if not UnitExists("mouseover") then
        return
    end

    if not UnitIsPlayer("mouseover") or not UnitIsFriend("player", "mouseover") then
        return
    end

    local guid = UnitGUID("mouseover")
    
    if playerGCache[guid] then
        return
    end
    local fullName = UnitFullName("mouseover")
    local class = UnitClass("mouseover")
    print("Mouseover unit:", fullName, "GUID:", guid, "Class:", class)
    playerGCache[guid] = playerGCache[guid] or {}
    playerGCache[guid].name = fullName
    playerGCache[guid].class = class
    guidCache[fullName] = guid

end

function GLH:_ProcessTooltipQueue(now)
    if not now then
        now = time()
    end
    local batchSize = 5
    for i=1, batchSize do
        local item = table.remove(self._tooltipQueue, 1)
        if not item then break end
    
        local uid = item.id
        local entry  = item.data
        local timeStart = entry.timeStart
        local timeEnd = entry.timeEnd
        if timeEnd - timeStart > 120 then timeEnd = timeStart + 120 end
        local delta = now - timeEnd
        print(now, timeEnd, delta)
        if delta > LOOT_EXPIRATION then
            print("Moving", entry.link, "to history...")
            self:AddEntryToHistoryTbl(historyTable, entry)
            activeRolls[uid] = nil
        else
            local loot_container = self:AddTooltipContainer(
            entry.link,
            entry.texture,
            entry.timeEnd,
            entry.rollID
            )
            loot_container_cache[uid] = {loot_container = loot_container}
        end
        
        
    end
  
    if #self._tooltipQueue > 0 then
        C_Timer.After(0, function() self:_ProcessTooltipQueue() end)
    else
        self._tooltipRunning = false
    end
end

function GLH:SpawnAllTooltipContainers()
    local now = time()
    if self._tooltipRunning then return end
    wipe(self._tooltipQueue)
  
    -- enqueue everything from activeRolls
    for uid, entry in pairs(db.global.activeRolls) do
        -- print("processing:",uid)
        if not  entry["date"] then
            entry["date"] = date("*t")
        end
        self:QueueTooltip(uid, entry)
    end
  
    self._tooltipRunning = true
    self:_ProcessTooltipQueue(now)
end

function GLH:GetAmount(link)
    local captures = { string.match(link, "|rx(%d+)") }
    local link_amount = captures[1] or nil
    if link_amount then
        -- print("Found link amount:", link_amount, "for link:", link)
        link = string.gsub(link, "|rx%d+$", "|r")
        -- print("Updated link:", link)
    end
    return link, tonumber(link_amount) or 1
end

function GLH:AddEntryToHistory(history, entry, dateKey, link, winner, location)
    dateKey = dateKey or (entry.date and GLH:GetDateKey(entry.date)) or (entry.timeEnd and GLH:GetDateKey(date("*t", entry.timeEnd))) or GLH:GetDateKey()
    location = location or entry.location or self:GetLocation() or {}
    
    if type(dateKey) == "table" then
        dateKey = GLH:GetDateKey(dateKey)
    end

    link = link or entry.link
    local link_amount
    link, link_amount = GLH:GetAmount(link)

    winner = winner or entry.winner or youName

    local dateTbl = ensure(history, dateKey, {})
    local linkTbl = ensure(dateTbl, link, {})
    local winnersTbl = ensure(linkTbl, "winners", {})
    local locations = ensure(linkTbl, "locations", {})
    
    if location.mapID then
        local mapIDs = ensure(locations, "mapIDs", {})
        mapIDs[location.mapID] = true
    elseif location.instanceID then
        local instances = ensure(locations, "instanceIDs", {})
        instances[location.instanceID] = true
    else
        print("Warning: No mapID or instanceID found in location for link:", link)
    end

    local amount = winnersTbl and winnersTbl[winner] and winnersTbl[winner].amount or 0
    amount = amount + link_amount

    local winnerTbl = ensure(winnersTbl, winner, {})
    winnerTbl.amount = amount
    winnerTbl.player = entry.player or winner

    print("Storing:", link, winner, historyRolls[dateKey][link].winners[winner].amount)
end

function GLH:AddEntryToHistoryTbl(history, entry, dateKey, link, winner, location)
    -- print("Adding entry to history:", entry.link, link, "Winner:", winner, winner)
    local newEntry = {}
    dateKey = dateKey or (entry.date and GLH:GetDateKey(entry.date)) or (entry.timeEnd and GLH:GetDateKey(date("*t", entry.timeEnd))) or GLH:GetDateKey()
    location = location or entry.location or self:GetLocation() or {}
    
    if type(dateKey) == "table" then
        dateKey = GLH:GetDateKey(dateKey)
    end

    link = link or entry.link
    local link_amount
    link, link_amount = GLH:GetAmount(link)
    local itemID = GetItemID(link)

    winner = (playerGCache[winner] and winner) or guidCache[winner] or (entry.winner and playerGCache[entry.winner] and entry.winner) or (entry.winner and guidCache[entry.winner]) or youGUID
    local player = (entry.player and playerGCache[entry.player] and entry.player) or (entry.player and guidCache[entry.player]) or youGUID

    local amount = link_amount
    location = location or entry.location
    newEntry = {
        dateKey = dateKey,
        itemID = itemID,
        amount = amount or 1,
        player = player,
        winner = winner,
        mapID = location.mapID,
        instanceID = location.instanceID
    }
    table.insert(history, newEntry)
    Log("Storing:", link, playerGCache[winner], amount)
end



function GLH:ConvertHistoryRollsFormat()
    -- Create temporary table for new format
    local newFormat = {}
    local instanceCount = 0
    local mapCount = 0
    for uid, entry in pairs(historyRolls) do
        if type(uid) == "number" then
            
        
        end
        if type(uid) ~= "number" then
            -- entry should be the new forat table here, uid is actually dateKey
            local dateKey = uid
            if entry and type(entry) == "table" then
                if not newFormat[dateKey] then
                    newFormat[dateKey] = {}
                end
                for link, entry in pairs(historyRolls[uid]) do
                    local captures = { string.match(link, "|rx(%d+)") }
                    local link_amount = captures[1] or nil
                    if link_amount then
                        -- print("Found link amount:", link_amount, "for link:", link)
                        link = string.gsub(link, "|rx%d+$", "|r")
                        -- print("Updated link:", link)
                    end
                    if not entry.winners then
                        entry.winners = {}
                        local winner = entry.winner or youName
                        if not string.find(winner, "-", 1, true) then
                            winner = winner .. "-" .. realmName
                        end
                        entry.winners[winner] = entry.winners[winner] or {}
                        entry.winners[winner].amount = link_amount or entry.amount or 1
                    else
                        if link_amount then
                            for winner, winnerData in pairs(entry.winners) do
                                winnerData.amount = link_amount
                                break
                            end
                            for winner, winnerData in pairs(entry.winners) do
                                winnerData.player = winnerData.player or winner
                            end
                        end
                    end
                    if entry.locations and #entry.locations > 0 then
                        local newLocations = {}
                        local mapIDs = {}
                        local instanceIDs = {}
                        for key, location in pairs(entry.locations) do
                            print(key, location.mapID, location.instanceID, location.instanceInfo and location.instanceInfo.instanceID)
                            if key == "mapID" then
                                mapIDs[location] = true
                            elseif key == "instanceID" then
                                instanceIDs[location] = true
                            elseif location.mapID then
                                mapIDs[location.mapID] = true
                                mapCount = mapCount + 1
                            elseif location.instanceID then
                                instanceIDs[location.instanceID] = true
                                instanceCount = instanceCount + 1
                            elseif location.instanceInfo then
                                instanceIDs[location.instanceInfo.instanceID] = true
                                instanceCount = instanceCount + 1
                                -- print("Found instanceInfo in location:", location.instanceInfo.instanceID, instanceIDs[location.instanceInfo.instanceID])
                            end
                        end
                        -- print("InstanceIDs:")
                        -- PrintTable(instanceIDs)
                        -- print("Found locations for link:", link, "Map IDs:", #mapIDs, "Instance IDs:", #instanceIDs, "Locations:", #entry.locations)
                        if not IsEmptyTbl(instanceIDs) then
                            newLocations["instanceIDs"] = instanceIDs
                            -- print("Added instanceIDs for link:", link, "Count:", #instanceIDs)
                        end
                        if not IsEmptyTbl(mapIDs) then
                            newLocations["mapIDs"] = mapIDs
                            -- print("Added mapIDs for link:", link, "Count:", #mapIDs)
                        end
                        if IsEmptyTbl(instanceIDs) and IsEmptyTbl(mapIDs) then
                            print("Warning: No mapID or instanceID found in locations for link:", link)
                        else
                            entry.locations = newLocations
                        end
                        

                    end

                    entry.link = nil
                    entry.active = nil
                    entry.name = nil
                    entry.rollID = nil
                    entry.timeStart = nil
                    entry.winner = nil
                    entry.amount = nil
                    entry.player = nil
                    entry.maps = nil
                    entry.instances = nil
                    entry.locations.maps = nil
                    entry.locations.instances = nil

                    newFormat[dateKey][link] = entry
                end       
            end
        end
        if type(uid) == "number" then 
            -- print("Converting:", entry.link)
            GLH:AddEntryToHistory(newFormat, entry)
        end
    end

    -- Replace old format with new
    db.global.historyRolls = newFormat
    
    -- Debug output
    for dateKey, items in pairs(newFormat) do
        for link, entry in pairs(items) do
            -- Log(string.format("Converted history entry: %s >%s< x%d", dateKey, link, entry.amount))
            GetItemData(link)
        end
    end
    print("Converted historyRolls format. Instance count:", instanceCount, "Map count:", mapCount)
end

function GLH:ConsolidateItemIDCache()
    local newCache = {}
    for itemID, itemData in pairs(itemDataCache) do
        itemData.itemLink = itemIDCache[itemID]
        if not itemData.itemLink then
            errormsg("itemLink is nil for itemID:", itemID, itemData.name)
        end
        newCache[itemID] = itemData
    end
    itemDataCache = newCache
end

function GLH:AddInstanceIDtoCache()
    for name, id in pairs(instanceID_list) do
        instanceCache[id] = instanceCache[id] or {}
        instanceCache[id].name = name
    end
end

function GLH:HistoryRollsTableFormat()
    local playerNames = {
        ["Maratha-Spineshatter"] = true,
        ["Brinna-Spineshatter"] = true,
        ["Maratha"] = true,
        ["Brinna"] = true,
    } 
    local playerFullNames = {
        ["Maratha-Spineshatter"] = "Maratha-Spineshatter",
        ["Brinna-Spineshatter"] = "Brinna-Spineshatter",
        ["Maratha"] = "Maratha-Spineshatter",
        ["Brinna"] = "Brinna-Spineshatter",
    } 
    local defaultPlayer = "Maratha-Spineshatter"
    local newHistory = {}

    local function IsValidPlayerName(name)
        return name and type(name) == "string" and name ~= "" and playerNames[name]
    end

    for dateKey, items in pairs(historyRolls) do
        for link, entry in pairs(items) do
            local itemID = GetItemID(link)
            if itemID then
                local mapIDs = {}
                local instanceIDs = {}
                local playerName
                if entry.locations then
                    for key, location in pairs(entry.locations) do
                        if key == "mapID" then
                            mapIDs[location] = true
                        elseif key == "instanceID" then
                            instanceIDs[location] = true
                        elseif location.mapID then
                            mapIDs[location.mapID] = true
                        elseif location.instanceID then
                            instanceIDs[location.instanceID] = true
                        elseif location.instanceInfo and location.instanceInfo.instanceID then
                            instanceIDs[location.instanceInfo.instanceID] = true
                        end
                    end
                end
                local mapID
                local instanceID
                if mapIDs then
                    for _, id in pairs(mapIDs) do
                        mapID = id
                        break
                    end
                end
                if instanceIDs then
                    for _, id in pairs(instanceIDs) do
                        instanceID = id
                        break
                    end
                end

                if not IsValidPlayerName(entry.player) then
                    entry.player = youFullName
                else
                    entry.player = playerFullNames[entry.player]
                end
                if entry.winners then
                    for winner, winnerData in pairs(entry.winners) do
                        local newEntry = {
                            dateKey = dateKey,
                            itemID = itemID,
                            amount = winnerData.amount or 1,
                            player = entry.player,
                            winner = guidCache[winner],
                            winnerName = not guidCache[winner] and winner or nil,
                            mapID = mapID,
                            instanceID = instanceID
                        }
                        table.insert(newHistory, newEntry)
                    end
                end
            end

            -- Ensure itemLink is set correctly
            if not entry.itemLink then
                entry.itemLink = itemLinkCache[link] or link
            end

        end
        historyRolls[dateKey] = nil -- Clear old format
    end
    db.global.historyTable = newHistory
    historyTable = db.global.historyTable
end

function GLH:WinnerNameHistoryTable()
    for _, entry in ipairs(historyTable) do
        if entry.winnerName and guidCache[entry.winnerName] then
            entry.winner = guidCache[entry.winnerName]
            entry.winnerName = nil -- Remove winnerName after updating winner
        end
        if entry.player and guidCache[entry.player] then
            entry.player = guidCache[entry.player]
        end
    end
    print("Updated historyTable with winner names.")
end

function GLH:FullNameGCache()
    for guid, playerData in pairs(playerGCache) do
        local serverID = GetServerIDFromGUID(guid)
        local serverName = serverIDCache[serverID] or realmName
        if playerData.name and not string.find(playerData.name, "-", 1, true) then
            playerData.name = playerData.name .. "-" .. serverName
        end
        if not playerData.name then
            playerGCache[guid] = nil
        end
        playerData.cname = nil
    end
end

function GLH:CreateMiniRollPages(rollID, itemLink, texture)
    local mainContainer = self:CreateItemRollContainerTable(itemLink)
    mainContainer.rollID = rollID
    Log("mainContainer", mainContainer)
    local miniRoll = true
    self:AddItemRollCells(mainContainer, miniRollPaged, itemLink, texture, rollID, miniRoll, MINI_TOOLTIP_SCALE)
    activeMiniRolls[rollID] = mainContainer
    table.insert(activeMiniRollIDs, rollID)
    miniRollPaged:AddPage(mainContainer)
    Log("CreateMiniRollPages: added rollID", rollID, "itemLink:", itemLink, "totalPages:", (#miniRollPaged.pages or 0))

end

function GLH:RemoveRollID(rollID)
    for i, id in ipairs(activeMiniRollIDs) do
        if id == rollID then
            local widget = table.remove(activeMiniRollIDs, i)
            if widget then
                widget:ReleaseChildren()
                widget:Hide()
                widget = nil
                activeMiniRolls[rollID] = nil
                break
            end
        end
    end
    if #activeMiniRollIDs == 0 then
        miniRollWindow:Hide()
    else
        miniRollWindow:SelectTab("current")
    end
end

function GLH:ActiveMiniRollsPages()
    if not miniRollPaged then
        local paged = AceGUI:Create("PagedWindow")
        paged:SetLayout("Fill")
        paged:SetWidth(400)
        paged:SetHeight(200)
        paged:SetAutoAdjustHeight(false)
        AceEvent:Embed(paged)
        function paged:GLH_ROLLED(msg, info)
            Log("GLH_ROLLED received:", info.rollID)
            paged:RemovePageRollID(info.rollID)
        end
        paged:RegisterMessage("GLH_ROLLED", "GLH_ROLLED")
        
        miniRollPaged = paged

        miniRollPaged:SetScale(MINI_TOOLTIP_SCALE)
        Log("ActiveMiniRollsPages: created miniRollPaged (scale=" .. tostring(MINI_TOOLTIP_SCALE) .. ")")

    end
    miniRollPaged:Show()
    miniRollPaged:RefreshPages()
end

function GLH:TestRolls()

end

-- function GLH:AddMiniRollInfo(rollID, playerInfoData)
--     local class = playerInfoData.class
--     local name = playerInfoData.name
--     local classColour = self:GetClassColour(class)
--     local cname = crayon:ColorizeRGB(classColour.r, classColour.g, classColour.b, name)
--     playerInfoData.cname = cname
--     -- playerInfoData.rollID = rollID
--     GLH:SendMessage("GLH_ROLL_INFO", playerInfoData)
 
-- end

function GLH:AddMiniRollInfo(rollID, playerInfoData)
    -- This is now handled by RefreshMiniRollDisplay via AddRollInfo
    -- Keep for backwards compatibility but make it call the new method
    self:RefreshMiniRollDisplay(rollID)
end

function GLH:GetTooltipMaxWidth()
    local label = AceGUI:Create("Label")
    label:SetText("2000-2000 damage    3.00 speed")
    ITEM_TOOLTIP_WIDTH = label.frame:GetWidth() + 6 + 6
    print("Calculated tooltip width:", ITEM_TOOLTIP_WIDTH)
end

function GLH:OnEnable()
    db = LibStub("AceDB-3.0"):New("GroupLootHelperDB", defaults, true)
    realmName = GetRealmName()

    GLH._tooltipQueue   = {}
    GLH._tooltipRunning = false

    zoneID_list = db.global.zoneID_list or {}
    instanceID_list = db.global.instanceID_list or {}
    instanceCache = db.global.instanceCache or {}
    mapCache = db.global.mapCache or {}
    register_mouseover = db.global.register_mouseover or false

    GLH:AddInstanceIDtoCache()

    buildID = select(4, GetBuildInfo())
    if db.global.zonesChecked and db.global.zonesChecked ~= buildID or not db.global.zonesChecked then
        zoneID_list = {}
        GetZoneID()
    end

    db.global.zoneID_list = zoneID_list
    db.global.instanceID_list = instanceID_list

    GLH.LootWindow = GLH:CreateLootWindow()
    for event, func in pairs(eventHandlers) do
        -- self:RegisterEvent(event, func) -- not using direct binding to keep the logging inject
        self:RegisterEvent(event)
    end

    if not register_mouseover then
        self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
    end

    youName = GetUnitName("player")
    youFullName = UnitFullName("player")
    youGUID = UnitGUID("player")
    local _, youClass = UnitClass("player")
    print(youName)
    youName = youName .. "-" .. realmName
    guidCache[youName] = youGUID


    DEFAULT_SPACING    = db.global.spacing or 5
    ROLE_ICON_SIZE     = db.global.role_icon_size or 16
    SPEC_ICON_SIZE     = db.global.spec_icon_size or 16
    ROLL_BUTTON_SIZE   = db.global.roll_button_size or 24
    ITEM_TOOLTIP_WIDTH = db.global.item_tooltip_width or 130
    MINI_TOOLTIP_SCALE = db.global.mini_tooltip_scale or 0.8
    LIST_TOOLTIP_SCALE = db.global.list_tooltip_scale or 1.0
    PLAYER_NAME_WIDTH  = db.global.player_name_width or 0      -- auto-width for name column
    ROLL_VALUE_WIDTH   = db.global.roll_value_width or 0      -- auto-width for roll value
    PLAYER_NAME_FONT_SIZE = db.global.player_name_font_size or 12
    PLAYER_NAME_FONT_SIZE_MINI = db.global.player_name_font_size_mini or 16

    GROW_UP = db.global.grow_up or false

    log = db.global.log

    activeRolls = db.global.activeRolls or {} -- Store active roll information
    historyRolls = db.global.historyRolls or {}-- Store history of rolls
    historyTable = db.global.historyTable or {} -- Store history of rolls in a table format
    playerGCache = db.global.playerGCache or {}
    itemDataCache = db.global.itemDataCache or {} -- Cache for item data
    itemLinkCache = db.global.itemLinkCache or {} -- Cache for item links
    itemIDCache = db.global.itemIDCache or {} -- Cache for item IDs
    serverIDCache = db.global.serverIDCache or {} -- Cache for server IDs

    self:FillPlayerInfo(youName, "player")
    
    self:ConsolidateItemIDCache()

    -- Make sure DB tables exist
    db.global.activeRolls  = activeRolls
    db.global.historyRolls = historyRolls
    db.global.historyTable = historyTable
    db.global.playerCache  = nil
    db.global.playerGCache  = playerGCache
    db.global.itemDataCache = itemDataCache
    db.global.itemLinkCache = itemLinkCache
    db.global.itemIDCache = nil
    db.global.instanceCache = instanceCache
    db.global.mapCache = mapCache
    db.global.serverIDCache = serverIDCache
    db.global.item_tooltip_width = ITEM_TOOLTIP_WIDTH
    db.global.mini_tooltip_scale = MINI_TOOLTIP_SCALE 
    db.global.list_tooltip_scale = LIST_TOOLTIP_SCALE
    db.global.player_name_font_size = PLAYER_NAME_FONT_SIZE
    db.global.player_name_font_size_mini = PLAYER_NAME_FONT_SIZE_MINI

    playerGCache[youGUID] = playerGCache[youGUID] or { name = youFullName, class = youClass }

    GLH:FullNameGCache()

    local realmGUID = GetServerIDFromGUID(youGUID)
    print("Realm GUID:", realmGUID, "Realm Name:", realmName)
    serverIDCache[realmGUID] = realmName
    serverIDCache[realmName] = realmGUID

    for guid, playerData in pairs(playerGCache) do
        guidCache[playerData.name] = guid
    end

    self:ConvertHistoryRollsFormat()
    self:HistoryRollsTableFormat()
    self:WinnerNameHistoryTable()

    for uID, activeRoll in pairs(activeRolls) do
        if activeRoll.rollID then
            uid_to_rollid[uID] = activeRoll.rollID
            rollid_to_uid[activeRoll.rollID] = uID
        end
        if activeRoll.itemLink then
            itemLinkToUID[activeRoll.itemLink] = uID
        end
        if activeRoll.itemName then
            itemNameToUID[activeRoll.itemName] = uID
        end
    end

    -- GLH:GetTooltipMaxWidth()

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


function GLH:UpdatePlayerCacheGroup()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then 
        -- Do not cache or process player info in battlegrounds arenas.
        return
    end

    local numGroupMembers = GetNumGroupMembers()  -- Works with raids and parties.
    for i = 1, numGroupMembers do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
        local name = UnitFullName(unit)
        if name and not guidCache[name] then
            self:FillPlayerInfo(name, unit)
            -- We can get class info via UnitClass.
            local _, class = UnitClass(unit)
            Log("Updating player cache for:", name, "Class:", class)

            -- local classIcon = classIcons[class] or "Interface\\Icons\\INV_Misc_QuestionMark"
            -- local specIcon = "Interface\\Icons\\INV_Misc_QuestionMark"
            
            -- Update or create an entry in the cache.
            local guid = guidCache[name]
            local classColour = self:GetClassColour(class)
            cnameCache[guid] = crayon:ColorizeRGB(classColour.r, classColour.g, classColour.b, name)
            Log("Player:", name,"is", class, "GUID:", guid, "cname:", cnameCache[guid])
            playerGCache[guid].class = class or "Unknown"
            -- playerCache[name].classIcon = classIcon
            -- playerCache[name].roleIcon = "Interface\\Icons\\INV_Misc_QuestionMark"  -- You may later update this when you learn a player’s actual role.
            -- Keep existing spec info if available; otherwise set defaults.
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
    local guid = UnitGUID(unit)
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

    if not playerGCache[guid] then
        self:FillPlayerInfo(name, unit)
    end

    playerGCache[guid].spec = specName
    playerGCache[guid].class = class or "Unknown"

    Log("Player:", name,"is", playerGCache[guid].class)

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
                pendingInspectRequests[playerName] = unit
            end
            -- Debug output:
            Log("Inspecting", playerName, " couldn't be done immediately.")
            return
        end
    end
    if #pendingInspectRequests > 0 then
        self.inspectTicker = AceTimer:NewTicker(0.1, self.OnInspectTick, false)
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
    print("Inspect ticker:", #pendingInspectRequests)
    for playerName, unit in pairs(pendingInspectRequests) do
        if UnitName(unit) == playerName then
            if CanInspect(unit, true) then
                print("Inspecting", playerName, unit)
                NotifyInspect(unit)
            end
        end
    end
end

function GLH:PLAYER_REGEN_ENABLED()
    for playerName, _ in pairs(pendingInspectRequests) do
        self:RequestPlayerInspect(playerName)
        pendingInspectRequests[playerName] = nil
    end
end

-- Retrieve info for a player; if not known, request an inspect and use default values.
function GLH:FillPlayerInfo(playerName, unit)
    local guid = GetGUID(playerName, unit)
    print("Filling player info for:", playerName, "GUID:", guid)
    local info = playerGCache[guid]

    if not info or not playerGCache[guid] then
        local name = UnitFullName(unit)
        local class = UnitClass(unit)
        -- local classColour = self:GetClassColour(class)

        self:RequestPlayerInspect(playerName)
        info = {
        class = UnitClass(unit) or "Unknown",
        spec = "Unknown",
        specTree = "Unknown",
        -- cname = crayon:ColorizeRGB(classColour.r, classColour.g, classColour.b, name),
        name = name,
        }
        playerGCache[guid] = info
        guidCache[name] = guid
    end
    return info
end

function GLH:GetUID()
    local uid = db.global.uniqueID
    db.global.uniqueID = db.global.uniqueID + 1
    return uid
end

function GLH:_ChatMsgLoot(event, msg, ...)
    Log("ChatMsgLoot:", event, msg)
    -- Don’t do anything in battlegrounds/arenas
    -- local _, instanceType = IsInInstance()
    -- if instanceType == "pvp" or instanceType == "arena" then
    --     return
    -- end
    local instance, instanceType = IsInInstance()
    -- print("Instance:", instance, "Type:", instanceType)

    for _, key in ipairs(rollTypeChanged) do
        if msg == key then
            Log("Roll type changed: ", key)
            return
        end
    end

    Log("CHAT_MSG:",event, msg)
    
    for _, key in ipairs(rollpatternKeys) do
        local patternDef = L[key]
        local captures = { string.match(msg, patternDef.pattern) }
        -- Log("Trying pattern:", key, patternDef.pattern, "Captures:", unpack(captures))
        if #captures > 0 then
            local payloadData = {}
            for i, field in ipairs(patternDef.payload) do
                payloadData[field] = captures[i]
            end
            
            local uid = itemNameToUID[payloadData.loot] or itemLinkToUID[payloadData.loot]
            local rollID = uid_to_rollid[uid]
            Log("Pattern matched:", key, "Payload:", payloadData.loot, "RollID:", rollID, "UID:", uid, "ActiveRolls:", activeRolls[uid])
            -- print(key, rollID, uid)
            if rollID and activeRolls[uid] then
                self:ProcessLootRollMessage(rollID, key, payloadData)
            else
                debugmsg(payloadData.loot, " -  couldn't find rollID")
                self:ProcessLootMessage(key, payloadData)
            end
            return
        end
    end
    
end

function GLH:CHAT_MSG_LOOT(event, msg, ...)
    Log(event, msg)
    C_Timer.After(0.5, function()
        self:_ChatMsgLoot(event, msg)
    end)
end

function GLH:GetLocation()
    local instance, instanceType = IsInInstance()
    local realZone = GetRealZoneText()
    local zone = GetZoneText()
    local instanceInfo = nil
    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = nil
    if mapID then
        mapInfo = C_Map.GetMapInfo(mapID)
        mapCache[mapID] = mapInfo
        return {mapID = mapID}
    end
    if instance then
        instanceInfo = _GetInstanceInfo(mapID)
        -- print("Instance Info:", instanceInfo.name, "Type:", instanceInfo.instanceType, "ID:", instanceInfo.instanceID)
        instanceID_list[instanceInfo.name] = instanceInfo.instanceID -- Not sure we need this anymore
        return {instanceID = instanceInfo.instanceID}
    end
    print("Maybe invalid location?")
end

function GLH:ProcessLootMessage(patternkey, payloadData)
    -- Log("Processing loot message:", patternkey, payloadData.looter, payloadData.loot)
    local location = self:GetLocation()
    local looter = payloadData.looter or youName
    local loot   = payloadData.loot

    GetItemData(loot)

    looter = cleanName(looter)
    local looterGUID = guidCache[looter]
    -- print("Looter GUID:", looterGUID, "Name:", looter)

    if patternkey == "PATTERN_LOOT_ITEM" or 
       patternkey == "PATTERN_LOOT_ITEM_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_SELF" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_SELF" or 
       patternkey == "PATTERN_LOOT_ITEM_SELF_MULTIPLE" then
        -- print("Item looted: ", looter, loot)

        
        GLH:AddEntryToHistoryTbl(historyTable, {}, nil, loot, looterGUID, location)
        db.global.historyTable = historyTable
    else
        Log("Not storing loot:", loot, looter, patternkey)
    end
        

end

function GLH:ProcessLootRollMessage(rollID, patternkey, payloadData)
    Log("Processing loot roll message:", patternkey, payloadData.looter, payloadData.loot, "Roll:", payloadData.roll)
    local looter = payloadData.looter
    local loot   = payloadData.loot
    local roll   = payloadData.roll

    looter = looter or UnitName("player")  -- Default to player if looter is not specified.
    local loot_winner = nil
  
    if patternkey == "PATTERN_LOOT_ITEM" or 
       patternkey == "PATTERN_LOOT_ITEM_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_SELF" or 
       patternkey == "PATTERN_LOOT_ITEM_PUSHED_SELF_MULTIPLE" or 
       patternkey == "PATTERN_LOOT_ITEM_SELF" or 
       patternkey == "PATTERN_LOOT_ITEM_SELF_MULTIPLE" then
        -- Log("Item looted: ", looter, loot)
        loot_winner = looter  -- The looter is the one who won the item.

    
    elseif patternkey == "PATTERN_LOOT_ROLL_NEED" or 
           patternkey == "PATTERN_LOOT_ROLL_NEED_SELF" then
        Log(looter, "ROLLED NEED on", loot)
    
    elseif patternkey == "PATTERN_LOOT_ROLL_GREED" or 
           patternkey == "PATTERN_LOOT_ROLL_GREED_SELF" then
        Log(looter, "ROLLED GREED on", loot)

    elseif patternkey == "PATTERN_LOOT_ROLL_DISENCHANT" or 
           patternkey == "PATTERN_LOOT_ROLL_DISENCHANT_SELF" then
        Log(looter, "ROLLED DISENCHANT on", loot)

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
        rollID   = rollID,
        name     = looter,
        class    = info.class,
        roleIcon = info.roleIcon,
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
        rollValue = roll or "",  -- Set default; you can update this as roll values become known.
        }
    
    -- Update the UI row for this player’s roll.
    self:AddRollInfo(rollID, playerInfoData)
    -- self:AddMiniRollInfo(rollID, playerInfoData)
    if loot_winner then
        local uid = rollid_to_uid[rollID]
        if uid and activeRolls[uid] then
            activeRolls[uid].winner = loot_winner
            -- TODO: add loot trading handling
        end
    end
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
    GetItemData(itemlink)
    local timeEnd = time() + rollTime
    local uid = self:GetUID()
    activeRolls[uid] = {
        rollID = rollID,
        name = name,
        texture = texture,
        quality = quality,
        link = itemlink,
        rolls = {},
        timeStart = time(),
        timeEnd = timeEnd,
        date = date("*t"),
        active = true,
        player = youName,
        location = self:GetLocation(),
        rollsData = {}, 
    }
    uid_to_rollid[uid] = rollID
    rollid_to_uid[rollID] = uid
    itemNameToUID[name] = uid
    itemLinkToUID[itemlink] = uid
    loot_container_cache[uid] = { loot_container =self:AddTooltipContainer(itemlink, texture, timeEnd)}
    self:ActiveMiniRollsPages()
    self:CreateMiniRollPages(rollID, itemlink, texture)
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






