local AceGUI = LibStub("AceGUI-3.0")
local widgetType = "GLHTooltip"
local widgetVersion = 1
local LOOT_FRAME_WIDTH = 243
local LOOT_FRAME_HEIGHT = 84
local LOOT_ICON_SIZE = 34

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
        self:SetHyperlink(nil)
        self:SetUserData("layoutParent", nil)
        self:SetUserData("Hyperlink_set", nil)
        self:SetUserData("fullWidth", nil)
        self:SetUserData("fullHeight", nil)
        self:SetUserData("expanded" , nil)

        self.frame:Hide()
    end,

    ["_DoLayout"] = function(self)
        local lootList = self:GetUserData("layoutParent")
        if lootList then
          lootList:DoLayout()
          if lootList.UpdateScrollChildRect then
            lootList:UpdateScrollChildRect()
          end
        else
          print("No layoutParent set!")
        end
      end,     

    ["ToggleExpansion"] = function(self)
        local expanded = self:GetUserData("expanded")
        print("expanded", expanded)
        if expanded then
            self:CollapseTooltip()
        else
            self:ExpandTooltip()
        end
    end,
    
    ["CollapseTooltip"] = function(self)
        -- Contracted view: fixed width, one row with icon on the left and coloured item name on the right.
        local fixedWidth = self:GetUserData("condensedWidth") or  200     -- adjust as needed
        local fixedHeight = 40     -- adjust as needed
    
        self:SetWidth(fixedWidth)
        self:SetHeight(fixedHeight)
    
        -- Hide the full tooltip copied content (if any)
        if self.tooltipTextFrame then
            self.tooltipTextFrame:Hide()
        end

        local icon = self:GetUserData("itemButton")
        icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
    
        -- Create (or show) a condensed container if not already there.
        if not self.condensedFrame then
            self.condensedFrame = CreateFrame("Frame", nil, self.frame)
            -- self.condensedFrame:SetFrameLevel(icon:GetFrameLevel() - 1)
            self.condensedFrame:SetAllPoints(self.frame)
            -- Create a label for the item name (with colour coding).
            local nameFontString = self:GetUserData("nameFontString")
            local drawLayer = nameFontString:GetDrawLayer()
                if not drawLayer or drawLayer == "0" or drawLayer == 0 then
                    drawLayer = "OVERLAY"
                end
            self.condensedFrame.label = self.condensedFrame:CreateFontString(nil, drawLayer, "GameFontHighlight")

            self.condensedFrame.label:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            self.condensedFrame.label:SetJustifyH("LEFT")
            -- self.condensedFrame.label:SetJustifyV("CENTER")
            self.condensedFrame.label:SetText(nameFontString:GetText())
            self.condensedFrame.label:SetTextColor(nameFontString:GetTextColor())
            self.condensedFrame.label:SetShadowColor(nameFontString:GetShadowColor())
            self.condensedFrame.label:SetShadowOffset(nameFontString:GetShadowOffset())
            self.condensedFrame.label:SetFontObject(nameFontString:GetFontObject())
            
            C_Timer.After(0, function ()
                local width = self.condensedFrame.label:GetWidth() 
                width = width + icon:GetWidth() + 10

                if width > self.frame.width then
                    self:SetWidth(width)
                else 
                    width = self.frame.width
                end
                print("condensed width", width)

                self:SetUserData("condensedWidth", width)
            end)
        end

        C_Timer.After(0, function ()
            self.condensedFrame:Show()

            self:SetUserData("expanded", false)
        end)

        C_Timer.After(0.1, function () self:_DoLayout() end)
        
    end,
    
    ["ExpandTooltip"] = function(self)
        local fullWidth = self:GetUserData("fullWidth") or 300
        local fullHeight = self:GetUserData("fullHeight") or 100
        self:SetWidth(fullWidth)
        self:SetHeight(fullHeight)

        if self.condensedFrame then
            self.condensedFrame:Hide()
        end
    
        self.tooltipTextFrame:Show()
        local icon = self:GetUserData("itemButton")
        icon:Show()
    
        self:SetUserData("expanded", true)
        self:_DoLayout()
    end,

    ["SetHyperlink"] = function(self, link, texture)
        if self:GetUserData("Hyperlink_set") then
            return
        end

        self.itemlink = link
        self:SetUserData("itemTexture", texture)
        local tpframe = self:GetUserData("tooltipFrame")
        local frame = self.frame
        local widget = self
        if tpframe then
            tpframe:SetOwner(UIParent, "ANCHOR_NONE")
            tpframe:SetHyperlink(link)
            tpframe:Show()
            -----------------------------------------------------------------------------
            -- Create the item icon
            -----------------------------------------------------------------------------
            local icon = self:GetUserData("itemButton") or CreateFrame("Button", nil, frame)
            print("Setting item icon texture:", texture)
            icon:SetNormalTexture(texture)
            icon:SetSize(LOOT_ICON_SIZE, LOOT_ICON_SIZE)
            icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(link)
            end)
            icon:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            icon:SetScript("OnClick", function(self, button)
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
            icon:EnableMouse(true)
            self:SetUserData("itemButton", icon)

            print("icon", icon, self:GetUserData("itemButton"), self)

            if not self.tooltipTextFrame then

                self.tooltipTextFrame = CreateFrame("Frame", nil, frame)

                self:_copyFrameRegions(tpframe, self.tooltipTextFrame)

                self:SetUserData("expanded" , true)
                self.tooltipTextFrame:SetAllPoints(self.frame)
                self.tooltipTextFrame:Show()
                -- tpframe:Hide()
                frame:Show()
                self:SetUserData("Hyperlink_set", true)
            end
        else
            frame:Hide()
        end
    end,

    ["SetTooltipFrame"] = function(self, tooltipFrame)
        assert(tooltipFrame and tooltipFrame.SetOwner, "You must provide a valid tooltip frame.")
        self:SetUserData("tooltipFrame", tooltipFrame)
    end,

    -- Copies visual regions from sourceFrame to targetFrame.
    ["_copyFrameRegions"] = function(self, sourceFrame, targetFrame)
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

        local topTextOffset = -5
        local nameFontString = nil
        -- local itemIcon = self:GetUserData("itemIcon") or targetFrame
        local icon = self:GetUserData("itemButton")

        for i, region in ipairs({ sourceFrame:GetRegions() }) do
            local regionType = region:GetObjectType()
            local point = region:GetPoint()
            if regionType == "Texture" then
                -- if region:GetTexture() then
                    local drawLayer = region:GetDrawLayer()
                    if not drawLayer or drawLayer == "0" or drawLayer == 0 then
                        drawLayer = "ARTWORK"
                    end

                    local textureCopy = targetFrame:CreateTexture(nil, drawLayer)

                    textureCopy:SetAllPoints(region)
                    textureCopy:SetTexture(region:GetTexture())
                    textureCopy:SetVertexColor(region:GetVertexColor())
                    textureCopy:SetBlendMode(region:GetBlendMode())
                    textureCopy:SetTexCoord(region:GetTexCoord())
                -- end
            elseif regionType == "FontString" then
                if region:GetText() then
                    local str = region:GetText()
                    if str and str == RETRIEVING_ITEM_INFO then
                        -- the tooltip is still loading—delay and retry once
                        C_Timer.After(1, function()
                            if sourceFrame:IsShown() then
                                self:_copyFrameRegions(sourceFrame, targetFrame)
                            end
                        end)
                    end
                    local drawLayer = region:GetDrawLayer()
                    if not drawLayer or drawLayer == "0" or drawLayer == 0 then
                        drawLayer = "OVERLAY"
                    end
                
                    local text = targetFrame:CreateFontString(nil, drawLayer, "GameFontNormal")
                    text:SetFontObject(region:GetFontObject())
                    text:SetText(str)
                    text:SetTextColor(region:GetTextColor())
                    text:SetShadowColor(region:GetShadowColor())
                    text:SetShadowOffset(region:GetShadowOffset())
                    text:SetJustifyH(region:GetJustifyH())
                    text:SetJustifyV(region:GetJustifyV())
                    if not nameFontString and text:GetText() then
                        nameFontString = text
                        print("nameFontString", text:GetText())
                    end
                    
                    text:SetAllPoints(region)

                    if point == "TOP" then
                        text:SetPoint("TOP", icon, "BOTTOM", 5 , topTextOffset)
                        text:SetPoint("LEFT", targetFrame, "LEFT", 5, 0)
                        text:SetPoint("RIGHT", targetFrame, "RIGHT", -5, 0)
                        topTextOffset = topTextOffset - region:GetHeight() - 1
                    end

                end
            end
        end
        topTextOffset = topTextOffset - 5 
        self:SetUserData("nameFontString", nameFontString)

        
        if icon then
            local fullHeight = (-1 * topTextOffset) + icon:GetHeight() + 5
            local fullWidth = sourceFrame:GetWidth()
            print("Height:", sourceFrame:GetHeight(), "Full Height:", fullHeight)
            self:SetWidth(fullWidth)
            self:SetHeight(fullHeight)

            self:SetUserData("fullWidth", fullWidth)
            self:SetUserData("fullHeight", fullHeight)
        else
            print("Missing icon", icon)
        end
    end,

    ["OnShow"] = function(self)
        print("OnShow")
        self.frame:Show()
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
	frame:SetFrameStrata("FULLSCREEN_DIALOG")

    -- local content = CreateFrame("Frame", nil, frame)
	-- content:SetPoint("TOPLEFT")
	-- content:SetPoint("BOTTOMRIGHT")

    local widget = {
        frame     = frame,
        -- content   = content,
        itemlink  = nil,
        type      = widgetType,
    }

    for method, func in pairs(methods) do
		widget[method] = func
	end

    return AceGUI:RegisterAsWidget(widget)

end

AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)