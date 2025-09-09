--[[-----------------------------------------------------------------------------
Paged Window Container
Container that shows one child widget at a time with navigation controls.
-------------------------------------------------------------------------------]]
local Type, Version = "PagedWindow", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, ipairs, assert, type, wipe, tremove, tinsert = pairs, ipairs, assert, type, table.wipe, table.remove, table.insert

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function Button_OnClick(frame)
    PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
    frame.obj:Hide()
end

local function Frame_OnShow(frame)
    frame.obj:Fire("OnShow")
end

local function Frame_OnClose(frame)
    frame.obj:Fire("OnClose")
end

local function Frame_OnMouseDown(frame)
    frame:StartMoving()
    AceGUI:ClearFocus()
end

local function Frame_OnMouseUp(frame)
    frame:StopMovingOrSizing()
    local self = frame.obj
    local status = self.status or self.localstatus
    status.width = frame:GetWidth()
    status.height = frame:GetHeight()
    status.top = frame:GetTop()
    status.left = frame:GetLeft()
end


local function Title_OnMouseDown(frame)
    frame:GetParent():StartMoving()
    AceGUI:ClearFocus()
end

local function MoverSizer_OnMouseUp(mover)
    local frame = mover:GetParent()
    frame:StopMovingOrSizing()
    local self = frame.obj
    local status = self.status or self.localstatus
    status.width = frame:GetWidth()
    status.height = frame:GetHeight()
    status.top = frame:GetTop()
    status.left = frame:GetLeft()
end

local function SizerSE_OnMouseDown(frame)
    frame:GetParent():StartSizing("BOTTOMRIGHT")
    AceGUI:ClearFocus()
end

local function SizerS_OnMouseDown(frame)
    frame:GetParent():StartSizing("BOTTOM")
    AceGUI:ClearFocus()
end

local function SizerE_OnMouseDown(frame)
    frame:GetParent():StartSizing("RIGHT")
    AceGUI:ClearFocus()
end

local function HideWidget(widget)
    if widget.Hide then
        widget:Hide()
    else
        widget.frame:Hide()
    end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Nav_OnClick(frame)
    PlaySound(841) -- SOUNDKIT.IG_CHARACTER_INFO_TAB
    local self = frame.obj
    local newIndex = self.currentIndex
    if frame.navType == "first" then
        newIndex = 1
    elseif frame.navType == "prev" then
        newIndex = self.currentIndex - 1
    elseif frame.navType == "next" then
        newIndex = self.currentIndex + 1
    elseif frame.navType == "last" then
        newIndex = #self.pages
    end
    self:SelectPage(newIndex)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local resizing = false
local methods = {
    ["OnAcquire"] = function(self)
        self.frame:SetParent(UIParent)
        self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
        self.frame:SetFrameLevel(100) -- Lots of room to draw under it
        self:ApplyStatus()
        self:SetTitle()
        self:Show()
        self:EnableResize(true)
    end,

    ["OnRelease"] = function(self)
        self.status = nil
        for k in pairs(self.localstatus) do
            self.localstatus[k] = nil
        end
        self:RemoveAllChildren()
    end,

    ["SetTitle"] = function(self, text)
        self.titletext:SetText(text or "")
        if text and text ~= "" then
            self.alignoffset = 35
        else
            self.alignoffset = 28
        end
        self.border:SetPoint("TOPLEFT", 1, -(self.alignoffset + 20))
    end,

    ["UpdateNavControls"] = function(self)
        local numPages = #self.pages
        local currentIndex = self.currentIndex

        self.pageDisplay:SetText(("%d / %d"):format(currentIndex, numPages))

        self.firstButton:SetEnabled(currentIndex > 1)
        self.prevButton:SetEnabled(currentIndex > 1)
        self.nextButton:SetEnabled(currentIndex < numPages)
        self.lastButton:SetEnabled(currentIndex < numPages)

        self.firstButton:Show()
        self.prevButton:Show()
        self.pageDisplay:Show()
        self.nextButton:Show()
        self.lastButton:Show()

        if numPages == 0 then
            self.pageDisplay:SetText("0 / 0")
            self.firstButton:SetEnabled(false)
            self.prevButton:SetEnabled(false)
            self.nextButton:SetEnabled(false)
            self.lastButton:SetEnabled(false)
        end
    end,

    ["SelectPage"] = function(self, index)
        local status = self.status or self.localstatus
        local numPages = #self.pages
        if numPages == 0 then
            self.currentIndex = 0
            status.currentIndex = 0
            wipe(self.children)
            self:UpdateNavControls()
            return
        end

        index = math.max(1, math.min(index, numPages))

        for _, page in ipairs(self.pages) do
            page.frame:Hide()
        end

        self.currentIndex = index
        status.currentIndex = index

        wipe(self.children)
        
        if self.pages[self.currentIndex] then
            local page = self.pages[self.currentIndex]
            self:AddChild(page)
            page.frame:Show()
            if page.LayoutFinished then
                page:LayoutFinished(self.content.width, self.content.height)
            end
            self:Fire("OnPageChanged", self.currentIndex, page)
        end

        self:UpdateNavControls()
        self:DoLayout()
    end,

    ["AddPage"] = function(self, widget, index)
        widget.frame:Hide()

        if index and index >= 1 and index <= #self.pages then
            tinsert(self.pages, index, widget)
            if self.currentIndex >= index then
                self.currentIndex = self.currentIndex + 1
            end
        else
            tinsert(self.pages, widget)
            -- print("Added children", widget, #self.children)
        end

        if #self.pages == 1 then
            self:SelectPage(1)
        else
            self:UpdateNavControls()
        end
    end,

    ["RemovePage"] = function(self, widget)
        self:Release(widget)
        for i = #self.pages, 1, -1 do
            if self.pages[i] == widget then
                HideWidget(widget)
                tremove(self.pages, i)
                if self.currentIndex > i then
                    self.currentIndex = self.currentIndex - 1
                elseif self.currentIndex == i then
                    self:SelectPage(i) -- This will select the new widget at this index, or the last one
                end
                break
            end
        end
        self:UpdateNavControls()
    end,

    ["RemovePageRollID"] = function(self, rollID)
        local removedIndex = nil
        local numPages = #self.pages
        
        -- Find and remove the page with matching rollID
        for i = numPages, 1, -1 do
            local widget = self.pages[i]
            if widget.rollID and widget.rollID == rollID then
                removedIndex = i
                
                print("Removing page with rollID:", rollID, "at index:", i)
                
                -- Hide the widget first
                HideWidget(widget)
                
                -- Remove from children if it's currently displayed
                for j = #self.children, 1, -1 do
                    if self.children[j] == widget then
                        tremove(self.children, j)
                        break
                    end
                end
                
                -- Release the widget properly
                self:Release(widget)
                
                -- Remove from pages array
                tremove(self.pages, i)
                break
            end
        end
        
        if not removedIndex then
            print("No page found with rollID:", rollID)
            return
        end
        
        local newNumPages = #self.pages
        print("Pages remaining:", newNumPages)
        
        if newNumPages == 0 then
            self.currentIndex = 0
            wipe(self.children)
            self:UpdateNavControls()
            return
        end
        
        -- Adjust current index if necessary
        if self.currentIndex > removedIndex then
            -- We removed a page before current, shift index down
            self.currentIndex = self.currentIndex - 1
        elseif self.currentIndex == removedIndex then
            -- We removed the current page
            if removedIndex > newNumPages then
                -- The removed page was the last one, go to new last page
                self.currentIndex = newNumPages
            else
                -- Stay at same index (which now shows the next page)
                -- But make sure we don't go beyond available pages
                self.currentIndex = math.min(removedIndex, newNumPages)
            end
        end
        
        -- Ensure currentIndex is within valid bounds
        self.currentIndex = math.max(1, math.min(self.currentIndex, newNumPages))
        
        -- Update status
        local status = self.status or self.localstatus
        status.currentIndex = self.currentIndex
        
        print("New current index:", self.currentIndex, "of", newNumPages)
        
        -- Refresh the current page display
        self:SelectPage(self.currentIndex)
    end,

    -- Also add this helper method to rebuild/refresh the entire widget
    ["RefreshPages"] = function(self)
        local numPages = #self.pages
        
        if numPages == 0 then
            self.currentIndex = 0
            wipe(self.children)
            self:UpdateNavControls()
            return
        end
        
        -- Ensure current index is valid
        if self.currentIndex > numPages then
            self.currentIndex = numPages
        elseif self.currentIndex < 1 then
            self.currentIndex = 1
        end
        
        -- Update status
        local status = self.status or self.localstatus
        status.currentIndex = self.currentIndex
        
        -- Force refresh current page
        self:SelectPage(self.currentIndex)
    end,

    ["RemoveAllChildren"] = function(self)
        -- Release all pages properly
        for _, widget in ipairs(self.pages) do
            HideWidget(widget)
            self:Release(widget)
        end
        
        -- Clear the pages array
        wipe(self.pages)
        
        -- Clear children array
        wipe(self.children)
        
        -- Reset current index
        self.currentIndex = 0
        
        -- Update status
        local status = self.status or self.localstatus
        status.currentIndex = 0
        
        -- Update navigation controls
        self:UpdateNavControls()
    end,

    ["OnWidthSet"] = function(self, width)
        local content = self.content
        local border = self.border
        local contentwidth = width - 22 -- 2 for border, 20 for content padding
        if contentwidth < 0 then
            contentwidth = 0
        end
        content:SetWidth(contentwidth)
        content.width = contentwidth
        border:SetWidth(width - 2)
    end,

    ["OnHeightSet"] = function(self, height)
        if resizing then return end -- Prevent recursive calls
        resizing = true

        local content = self.content
        local border = self.border
        local contentheight = height - (self.alignoffset + 20 + 23)
        if contentheight < 0 then
            contentheight = 0
        end
        content:SetHeight(contentheight)
        content.height = contentheight
        border:SetHeight(height - 4)
        resizing = false
    end,

    ["LayoutFinished"] = function(self, width, height)
        if self.noAutoHeight then return end
        self:SetHeight((height or 0) + self.alignoffset + 20 + 23)
    end,

    ["Hide"] = function(self)
        self.frame:Hide()
    end,

    ["Show"] = function(self)
        self.frame:Show()
    end,

    ["EnableResize"] = function(self, state)
        local func = state and "Show" or "Hide"
        self.sizer_se[func](self.sizer_se)
        self.sizer_s[func](self.sizer_s)
        self.sizer_e[func](self.sizer_e)
    end,

    -- called to set an external table to store status in
    ["SetStatusTable"] = function(self, status)
        assert(type(status) == "table")
        self.status = status
        self:ApplyStatus()
    end,

    ["ApplyStatus"] = function(self)
        local status = self.status or self.localstatus
        local frame = self.frame
        self:SetWidth(status.width or 700)
        self:SetHeight(status.height or 500)
        frame:ClearAllPoints()
        if status.top and status.left then
            frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
            frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
        else
            frame:SetPoint("CENTER")
        end
        self:SelectPage(status.currentIndex or 1)
    end,

    ["ToggleClipping"] = function(self)
        -- TODO: maybe set up a clipper frame, and attach children to that for better clipping... 
        self.clipping = not self.clipping
        self.content:SetClipsChildren(self.clipping)
    end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local PaneBackdrop  = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local function CreateNavButton(parent, name, text, navType)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetText(text)
    btn:SetScript("OnClick", Nav_OnClick)
    btn.navType = navType
    return btn
end

local function Constructor()
    local num = AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Frame", nil ,UIParent, "BackdropTemplate")
    frame:Hide()
    frame:SetHeight(200)
    frame:SetWidth(400)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100) -- Lots of room to draw under it

    frame:EnableMouse(true)
    frame:SetResizeBounds(340, 120)
    frame:SetMovable(true)
    frame:SetResizable(true)

    frame:SetToplevel(true)
    frame:SetScript("OnShow", Frame_OnShow)
    frame:SetScript("OnHide", Frame_OnClose)
    frame:SetScript("OnMouseDown", Frame_OnMouseDown)
    frame:SetScript("OnMouseUp", Frame_OnMouseUp)

    local sizer_se = CreateFrame("Frame", nil, frame)
    sizer_se:SetPoint("BOTTOMRIGHT")
    sizer_se:SetWidth(25)
    sizer_se:SetHeight(25)
    sizer_se:EnableMouse()
    sizer_se:SetScript("OnMouseDown", SizerSE_OnMouseDown)
    sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

    local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
    line1:SetWidth(14)
    line1:SetHeight(14)
    line1:SetPoint("BOTTOMRIGHT", -8, 8)
    line1:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
    local x = 0.1 * 14/17
    line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

    local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
    line2:SetWidth(8)
    line2:SetHeight(8)
    line2:SetPoint("BOTTOMRIGHT", -8, 8)
    line2:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
    x = 0.1 * 8/17
    line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

    local sizer_s = CreateFrame("Frame", nil, frame)
    sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
    sizer_s:SetPoint("BOTTOMLEFT")
    sizer_s:SetHeight(25)
    sizer_s:EnableMouse(true)
    sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
    sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

    local sizer_e = CreateFrame("Frame", nil, frame)
    sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
    sizer_e:SetPoint("TOPRIGHT")
    sizer_e:SetWidth(25)
    sizer_e:EnableMouse(true)
    sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
    sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)


    local titletext = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    titletext:SetPoint("TOPLEFT", 14, 0)
    titletext:SetPoint("TOPRIGHT", -14, 0)
    titletext:SetJustifyH("LEFT")
    titletext:SetHeight(18)
    titletext:SetText("")

    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetPoint("BOTTOMRIGHT", -1, 3)
    border:SetBackdrop(PaneBackdrop)
    border:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    border:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closebutton:SetScript("OnClick", Button_OnClick)
    closebutton:SetPoint("TOPRIGHT", -5, -10)
    closebutton:SetHeight(20)
    closebutton:SetWidth(28)
    closebutton:SetText("X")

    local content = CreateFrame("Frame", nil, border)
    content:SetPoint("TOPLEFT", 10, -7)
    content:SetPoint("BOTTOMRIGHT", -10, 7)
    content:SetClipsChildren(true)

    -- Navigation Controls
    local navContainer = CreateFrame("Frame", nil, frame)
    navContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -25)
    navContainer:SetPoint("TOPRIGHT", closebutton, "TOPLEFT", -10, 0)
    navContainer:SetHeight(22)

    local firstButton = CreateNavButton(navContainer, "GLH_PagedNavFirst"..num, "<<", "first")
    firstButton:SetPoint("LEFT", 0, 0)
    firstButton:SetWidth(40)

    local prevButton = CreateNavButton(navContainer, "GLH_PagedNavPrev"..num, "<", "prev")
    prevButton:SetPoint("LEFT", firstButton, "RIGHT", 5, 0)
    prevButton:SetWidth(30)

    local pageDisplay = navContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pageDisplay:SetPoint("LEFT", prevButton, "RIGHT", 5, 0)
    pageDisplay:SetPoint("RIGHT", navContainer, "RIGHT", -85, 0)
    pageDisplay:SetJustifyH("CENTER")

    local nextButton = CreateNavButton(navContainer, "GLH_PagedNavNext"..num, ">", "next")
    nextButton:SetPoint("RIGHT", navContainer, "RIGHT", -45, 0)
    nextButton:SetWidth(30)

    local lastButton = CreateNavButton(navContainer, "GLH_PagedNavLast"..num, ">>", "last")
    lastButton:SetPoint("RIGHT", navContainer, "RIGHT", 0, 0)
    lastButton:SetWidth(40)

    local widget = {
        num          = num,
        frame        = frame,
        localstatus  = {},
        alignoffset  = 18,
        titletext    = titletext,
        border       = border,
        pages        = {},
        currentIndex = 0,
        sizer_se     = sizer_se,
        sizer_s      = sizer_s,
        sizer_e      = sizer_e,
        content      = content,
        firstButton  = firstButton,
        prevButton   = prevButton,
        pageDisplay  = pageDisplay,
        nextButton   = nextButton,
        lastButton   = lastButton,
        clipping     = true,
        type         = Type
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    closebutton.obj = widget
    firstButton.obj = widget
    prevButton.obj = widget
    nextButton.obj = widget
    lastButton.obj = widget
    frame.obj = widget

    -- widget:SetTitle(frame:GetName())
    widget:UpdateNavControls()
    -- widget:ApplyStatus()

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)