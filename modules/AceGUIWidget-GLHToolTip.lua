local AceGUI = LibStub("AceGUI-3.0")
local AceEvent = LibStub("AceEvent-3.0")
local widgetType = "GLHTooltip"
local widgetVersion = 1
local LOOT_FRAME_WIDTH = 243
local LOOT_FRAME_HEIGHT = 84
local LOOT_ICON_SIZE = 34


local function AddIconCallbacks(self, element, link)
    local widget = self

    element:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(link)
    end)
    element:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    element:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(link)
            elseif IsModifiedClick("DRESSUP") then
                DressUpItemLink(link)
            else
                -- TODO: Add quest rewards/set items/etc
                widget:ToggleExpansion()
            end
        end
    end)
end

local function CreateIcon(self, link, texture)
    -----------------------------------------------------------------------------
    -- Create the item icon
    -----------------------------------------------------------------------------
    print("Creating icon:", link, texture, self.iconSet)
    if not self.iconSet then
        -- self.icon:ClearAllPoints()
        self.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 6, -6)
        self.icon:SetTexture(texture)
        self.icon:SetWidth(LOOT_ICON_SIZE)
        self.icon:SetHeight(LOOT_ICON_SIZE)
        AddIconCallbacks(self, self.frame, link)
    end
    self.iconSet = true
end

-- Copies visual regions from sourceFrame to targetFrame.
local function _copyFrameRegions(self, sourceFrame, targetFrame, link, texture)
        assert(sourceFrame and targetFrame, "Source and target frames must be provided.")

        local fullWidth = self:GetUserData("tooltipWidth") or sourceFrame:GetWidth()
        print("Source frame width:", sourceFrame:GetWidth(), "Full width:", fullWidth)  
        -- clear out any old children so we don’t stack textures & strings forever
        for _, child in ipairs({ targetFrame:GetChildren() }) do
            child:Hide()
            child:SetParent(nil)
        end

        for _, child in ipairs({ targetFrame:GetRegions() }) do
            child:Hide()
            child:SetParent(nil)
        end

        local topTextOffset = -6
        local nameFontString = nil
        local fontStringsList = {}  -- Collect non-right-aligned fontstrings for deferred sizing
        -- local itemIcon = self:GetUserData("itemIcon") or targetFrame
        local icon = self:GetUserData("itemButton")
        local width = sourceFrame:GetWidth()
        -- local height = sourceFrame:GetHeight()
        -- local height = 0
        targetFrame:SetWidth(fullWidth)
        -- targetFrame:SetHeight(height)

        local lastText = self.icon
        for i, region in ipairs({ sourceFrame:GetRegions() }) do
            local regionType = region:GetObjectType()
            local point = region:GetPoint()
            if regionType == "Texture" then
                -- if region:GetTexture() then
                    -- local drawLayer = region:GetDrawLayer()
                    -- if not drawLayer or drawLayer == "0" or drawLayer == 0 then
                    --     drawLayer = "ARTWORK"
                    -- end
                    -- -- print("Adding texture", link)
                    -- local textureCopy = targetFrame:CreateTexture(nil, drawLayer)

                    -- textureCopy:SetAllPoints(region)
                    -- textureCopy:SetTexture(region:GetTexture())
                    -- textureCopy:SetVertexColor(region:GetVertexColor())
                    -- textureCopy:SetBlendMode(region:GetBlendMode())
                    -- textureCopy:SetTexCoord(region:GetTexCoord())
                -- end
            elseif regionType == "FontString" then
                if region:GetText() then
                    local str = region:GetText()
                    if str and str == RETRIEVING_ITEM_INFO then
                        -- the tooltip is still loading—delay and retry once
                        C_Timer.After(1, function()
                            -- if sourceFrame:IsShown() then
                                self:SetUserData("Hyperlink_set", false)
                                self:SetHyperlink(link, texture)
                            -- end
                        end)
                    end
                    local drawLayer = region:GetDrawLayer()
                    if not drawLayer or drawLayer == "0" or drawLayer == 0 then
                        drawLayer = "OVERLAY"
                    end
                
                    local text = targetFrame:CreateFontString(nil, drawLayer, "GameFontNormal")
                    text:ClearAllPoints()
                    text:SetFontObject(region:GetFontObject())
                    text:SetText(str)
                    -- print(str)
                    text:SetTextColor(region:GetTextColor())
                    text:SetShadowColor(region:GetShadowColor())
                    text:SetShadowOffset(region:GetShadowOffset())
                    text:SetJustifyH(region:GetJustifyH())
                    text:SetJustifyV(region:GetJustifyV())
                    
                    -- if (not fullWidth) and str and nameFontString then
                    --     print("trying to adjust tooltip width...", self:GetUserData("tooltipWidth"))
                    --     text:SetText("1000 - 1000 Damage   Speed 3.00")
                    --     tooltipWidth = text:GetWidth() + 6 + 6
                    --     print("Calculated tooltip width:", tooltipWidth)
                    --     self:SetUserData("tooltipWidth", tooltipWidth)
                    --     text:SetText(str)
                    --     targetFrame:SetWidth(tooltipWidth)

                    --     if nameFontString:GetWidth() > tooltipWidth then
                    --         nameFontString:ClearPoint("RIGHT")
                    --         nameFontString:SetPoint("RIGHT", targetFrame, "RIGHT", -6, 0)
                    --     end
                    -- end

                    if not nameFontString and str then
                        nameFontString = text
                        -- print("nameFontString", text:GetText())
                    end
                    
                    -- text:SetAllPoints(region)

                    -- print(point)
                    -- print(point, region:GetJustifyH(), sourceFrame:GetWidth(), text:GetWidth())

                    if point == "TOP" then
                        text:SetPoint("TOP", lastText, "BOTTOM", 0 , -2)
                        text:SetPoint("LEFT", lastText, "LEFT", 0, 0)
                        if text:GetWidth() > (fullWidth or sourceFrame:GetWidth()) then
                            text:SetPoint("RIGHT", targetFrame, "RIGHT", -6, 0)
                        else
                            text:SetPoint("RIGHT", lastText, "LEFT", text:GetWidth() + 6, 0)
                        end
                        -- Collect non-right-aligned fontstring for deferred height calculation
                        table.insert(fontStringsList, text)
                        topTextOffset = topTextOffset - text:GetHeight() - 1
                        -- height = height + text:GetHeight() + 1
                        lastText = text
                    elseif point == "RIGHT" then
                        text:SetJustifyH("RIGHT")
                        text:SetPoint("TOP", lastText, "TOP", 0 , 0)
                        text:SetPoint("LEFT", lastText, "RIGHT", 0, 0)
                        text:SetPoint("RIGHT", targetFrame, "RIGHT", -6, 0)
                        -- RIGHT-aligned fontstrings are not included in deferred height calculation
                        topTextOffset = topTextOffset - 1
                    else
                        print("GLHTooltip: Unhandled region point:", point)
                    end
                    -- if text:GetWidth() > (fullWidth or sourceFrame:GetWidth()) then
                    --     fullWidth = text:GetStringWidth() + 12
                    --     self:SetUserData("tooltipWidth", fullWidth)
                    --     targetFrame:SetWidth(fullWidth)
                    -- end
                end
            end
        end
        topTextOffset = topTextOffset - 6 
        self:SetUserData("nameFontString", nameFontString)
        self:SetUserData("fontStringsList", fontStringsList)
        self:SetUserData("fullWidth", fullWidth)
        
        -- Position tooltip frame off-screen initially to allow rendering
        targetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
        targetFrame:SetWidth(fullWidth)
        
        -- Defer height calculation until next frame when rendering is complete
        C_Timer.After(0, function()
            self:_CalculateAndApplySizes(targetFrame, link, texture)
        end)
    end

-- Calculate actual tooltip heights using rendered fontstring measurements and apply final sizing
local function _CalculateAndApplySizes(self, targetFrame, link, texture)
    local fontStringsList = self:GetUserData("fontStringsList") or {}
    local fullWidth = self:GetUserData("fullWidth") or ITEM_TOOLTIP_WIDTH
    local nameFontString = self:GetUserData("nameFontString")
    
    if not nameFontString then
        print("GLHTooltip._CalculateAndApplySizes: nameFontString not found, deferring...")
        C_Timer.After(0, function()
            self:_CalculateAndApplySizes(targetFrame, link, texture)
        end)
        return
    end
    
    local totalHeight = 6  -- Top padding
    local lineSpacing = 0
    
    -- Iterate through collected fontstrings and measure actual heights
    for i, fontStr in ipairs(fontStringsList) do
        if fontStr and fontStr:GetText() then
            local strHeight = fontStr:GetStringHeight()
            if strHeight > 0 then
                if i > 1 then
                    -- Add line spacing between fontstrings
                    lineSpacing = fontStr:GetLineSpacing() or 0
                    if lineSpacing == 0 then lineSpacing = 1 end
                    totalHeight = totalHeight + lineSpacing
                end
                totalHeight = totalHeight + strHeight
            end
        end
    end
    
    -- Add icon height to total
    totalHeight = totalHeight + LOOT_ICON_SIZE
    totalHeight = totalHeight + 6  -- Bottom padding
    
    print("GLHTooltip._CalculateAndApplySizes: calculated height:", totalHeight, "width:", fullWidth)
    
    targetFrame:SetWidth(fullWidth)
    targetFrame:SetHeight(totalHeight)
    
    self:SetUserData("fullHeight", totalHeight)
    
    -- Move frame back to visible area after sizing
    targetFrame:ClearAllPoints()
    targetFrame:SetPoint("TOPLEFT", self.icon, "BOTTOMLEFT", 0, -6)
    
    -- Update expandedBackground size for proper display
    self.expandedBackground:SetWidth(fullWidth)
    self.expandedBackground:SetHeight(totalHeight)
    
    -- Setup compact frame label (for collapsed view)
    if not self.compactFrame.label then
        self.compactFrame.label = self.compactFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    end
    
    self.compactFrame.label:SetPoint("TOPLEFT")
    self.compactFrame.label:SetPoint("BOTTOMRIGHT")
    self.compactFrame.label:SetJustifyH("LEFT")
    self.compactFrame.label:SetJustifyV("MIDDLE")
    self.compactFrame.label:SetText(nameFontString:GetText())
    self.compactFrame.label:SetVertexColor(nameFontString:GetTextColor())
    self.compactFrame.label:SetShadowColor(nameFontString:GetShadowColor())
    self.compactFrame.label:SetShadowOffset(nameFontString:GetShadowOffset())
    self.compactFrame.label:SetFontObject(nameFontString:GetFontObject())
    
    local compactHeight = LOOT_ICON_SIZE + 6 + 6
    self.compactFrame:SetWidth(fullWidth)
    self.compactFrame:SetHeight(self.compactFrame.label:GetHeight())
    
    self.compactBackground:SetWidth(fullWidth)
    self.compactBackground:SetHeight(compactHeight)
    
    self:SetUserData("compactWidth", fullWidth)
    
    -- Now expand and show
    self.expanded = true
    self:ExpandTooltip()
    self.frame:Show()
    self:Show()
    AceEvent:SendMessage("GLH_TOOLTIP_NEW_ITEMINFO", link)
end

local methods = {
	["OnAcquire"] = function(self)
        
	end,

	-- ["OnRelease"] = nil,

	["LayoutFinished"] = function(self, width, height)
		if self.noAutoHeight then return end
		self:SetHeight(height or 0)
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.frame
		content:SetWidth(width)
		content.width = width
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.frame
		content:SetHeight(height)
		content.height = height
	end,

    ["OnRelease"] = function(self)
        print("OnRelease...")
        self:SetUserData("layoutParent", nil)
        self:SetUserData("Hyperlink_set", nil)
        self:SetUserData("fullWidth", nil)
        self:SetUserData("fullHeight", nil)
        self.expanded = nil
        self.itemLink = nil
        if self._rollListener then
            AceGUI:UnregisterCallback(self.rollMessage, self)
        end
        self._rollListener = false

        self.frame:Hide()
    end,

    ["DoLayout"] = function(self)
    end,

    ["_DoLayout"] = function(self, layoutParent)
        if layoutParent then
            layoutParent:DoLayout()
            if layoutParent.UpdateScrollChildRect then
                layoutParent:UpdateScrollChildRect()
            end
        else
            print("No layoutParent set!")
        end
    end,

    ["ToggleExpansion"] = function(self)
        -- print("expanded", expanded)
        if self.expanded then
            self:CollapseTooltip()
        else
            self:ExpandTooltip()
        end
    end,
    
    ["CollapseTooltip"] = function(self)
        -- Contracted view: fixed width, one row with icon on the left and coloured item name on the right.
        self.compactBackground:Show()
        self.expandedBackground:Hide()
        self.frame:SetWidth(self.compactBackground:GetWidth())
        self.frame:SetHeight(self.compactBackground:GetHeight())
        self.expanded = false
        self.frame:Show()
    end,
    
    ["ExpandTooltip"] = function(self)
        self.compactBackground:Hide()
        self.expandedBackground:Show()
        self.frame:SetWidth(self.expandedBackground:GetWidth())
        self.frame:SetHeight(self.expandedBackground:GetHeight())
        self.expanded = true
        self.frame:Show()
    end,

    ["SetHyperlink"] = function(self, link, texture)
        if self:GetUserData("Hyperlink_set") then
            return
        end

        self.itemLink = link
        -- print("SetHyperlink:", link, texture)
        self:SetUserData("itemTexture", texture)
        local tpframe = self:GetUserData("tooltipFrame")
        -- print("TPFRAME:", tpframe)
        local frame = self.frame
        frame:Show()

        if tpframe then
            tpframe:SetOwner(UIParent, "ANCHOR_NONE")
            tpframe:SetHyperlink(link)
            tpframe:Show()

            self:SetUserData("Hyperlink_set", true)
            -- Copy regions and defer sizing calculation via C_Timer
            _copyFrameRegions(self, tpframe, self.expandedFrame, link, texture)
            
            -- Create the icon immediately
            CreateIcon(self, link, texture)
            
            -- Setup will be completed by _CalculateAndApplySizes after rendering
        else
            frame:Hide()
        end
    end,

    ["SetTooltipFrame"] = function(self, tooltipFrame)
        assert(tooltipFrame and tooltipFrame.SetOwner, "You must provide a valid tooltip frame.")
        self:SetUserData("tooltipFrame", tooltipFrame)
    end,

    ["OnShow"] = function(self)
        -- print("Showing", self.itemLink)
        self.frame:Show()
        if self.expanded then
            self:ExpandTooltip()
        else 
            self:CollapseTooltip()
        end
    end,

    ["Show"] = function(self)
        -- print("Showing", self.itemLink)
        self.frame:Show()
        if self.expanded then
            self:ExpandTooltip()
        else 
            self:CollapseTooltip()
        end
    end,

    ["OnHide"] = function(self)
        self.frame:Hide()
    end,

    ["Hide"] = function(self)
        self.frame:Hide()
    end,

    ["_splitCSV"] = function (self, input)
        local result = {}
        for word in string.gmatch(input, '([^,]+)') do
            table.insert(result, word:match("^%s*(.-)%s*$")) -- trim surrounding spaces
        end
        return result
    end
    

}

local function Constructor()

    local frame = CreateFrame("Frame", nil, UIParent)
    -- frame:Hide()
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
    local iconFrame = CreateFrame("Frame", nil, frame )
    iconFrame:SetFrameLevel(frame:GetFrameLevel() + 10)

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")

    local expandedBackground = CreateFrame("Frame", nil, frame )
    expandedBackground:SetPoint("TOPLEFT",  icon, "TOPLEFT",  -6, 6)
    expandedBackground:Hide()

    local compactBackground = CreateFrame("Frame", nil, frame)
    compactBackground:SetPoint("TOPLEFT",  icon, "TOPLEFT",  -6, 6)
    compactBackground:Hide()
	
    local expandedFrame = CreateFrame("Frame", nil, expandedBackground)
	expandedFrame:SetPoint("TOPLEFT",  icon, "BOTTOMLEFT",  0, -6)
	expandedFrame:SetPoint("BOTTOMRIGHT")

    local compactFrame = CreateFrame("Frame", nil, compactBackground)
	compactFrame:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6 , 0)
	compactFrame:SetPoint("BOTTOMRIGHT")

    

    local widget = {
        frame = frame,
        icon = icon, 
        expandedBackground = expandedBackground,
        compactBackground = compactBackground,
        expandedFrame = expandedFrame,
        compactFrame = compactFrame,
        itemlink = nil,
        expanded = true,
        type = widgetType,
    }

    for method, func in pairs(methods) do
		widget[method] = func
	end

    return AceGUI:RegisterAsWidget(widget)

end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)