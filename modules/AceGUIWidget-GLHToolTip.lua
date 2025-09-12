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
        local tooltipWidth = self.tooltipWidth
        -- local itemIcon = self:GetUserData("itemIcon") or targetFrame
        local icon = self:GetUserData("itemButton")
        local width = sourceFrame:GetWidth()
        local height = sourceFrame:GetHeight()
        targetFrame:SetWidth(width)
        targetFrame:SetHeight(height)

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
                    
                    -- if (not tooltipWidth) and str and nameFontString then
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
                        if text:GetWidth() > (tooltipWidth or sourceFrame:GetWidth()) then
                            text:SetPoint("RIGHT", targetFrame, "RIGHT", -6, 0)
                        else
                            text:SetPoint("RIGHT", lastText, "LEFT", text:GetWidth() + 6, 0)
                        end
                        topTextOffset = topTextOffset - region:GetHeight() - 1
                        lastText = text
                    elseif point == "RIGHT" then
                        text:SetJustifyH("RIGHT")
                        text:SetPoint("TOP", lastText, "TOP", 0 , 0)
                        text:SetPoint("LEFT", lastText, "RIGHT", 0, 0)
                        text:SetPoint("RIGHT", targetFrame, "RIGHT", -6, 0)
                        topTextOffset = topTextOffset - 1
                    end    
                end
            end
        end
        topTextOffset = topTextOffset - 6 
        self:SetUserData("nameFontString", nameFontString)

        
        local fullHeight = (-1 * topTextOffset)
        local fullWidth = self:GetUserData("tooltipWidth") or sourceFrame:GetWidth()
        -- print("Height:", sourceFrame:GetHeight(), "Full Height:", fullHeight)
        targetFrame:SetWidth(fullWidth)
        targetFrame:SetHeight(fullHeight)

        self:SetUserData("fullWidth", fullWidth)
        self:SetUserData("fullHeight", fullHeight)
        print("W H:", fullWidth, fullHeight, nameFontString:GetWidth())
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

            do
                self:SetUserData("Hyperlink_set", true)
                _copyFrameRegions(self, tpframe, self.expandedFrame, link, texture)
                self.expanded = true

                self.expandedFrame:Show()
                
                local width = self.expandedFrame:GetWidth() 
                width = width + LOOT_ICON_SIZE + 6 + 6 + 6
                local height = self.expandedFrame:GetHeight() 
                height = height + LOOT_ICON_SIZE + 6 + 6

                self.expandedBackground:SetWidth(width)
                self.expandedBackground:SetHeight(height)
                self.expandedBackground:Show()
            end

            do
                local nameFontString = self:GetUserData("nameFontString")
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
                self.compactFrame:Show()
                self.compactFrame.label:Show()
                self.compactFrame:SetWidth(self.compactFrame.label:GetWidth())
                self.compactFrame:SetHeight(self.compactFrame.label:GetHeight())

                local width = self.compactFrame.label:GetWidth() 
                width = width + LOOT_ICON_SIZE + 6 + 6 + 6
                local height = LOOT_ICON_SIZE + 6 + 6

                width = math.max(self.expandedBackground:GetWidth(), width)

                self.compactBackground:SetWidth(width)
                self.compactBackground:SetHeight(height)
                self.compactBackground:Hide()

                self:SetUserData("compactWidth", width)
            end
            CreateIcon(self, link, texture)
        else
            frame:Hide()
        end
        self:ExpandTooltip()
        frame:Show()
        self:Show()
        AceEvent:SendMessage("GLH_TOOLTIP_NEW_ITEMINFO", link)
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