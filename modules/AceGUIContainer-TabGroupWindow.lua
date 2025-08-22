--[[-----------------------------------------------------------------------------
TabGroup Container
Container that uses tabs on top to switch between groups.
-------------------------------------------------------------------------------]]
local Type, Version = "TabGroupWindow", 39
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, ipairs, assert, type, wipe = pairs, ipairs, assert, type, table.wipe

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

-- local upvalue storage used by BuildTabs
local widths = {}
local rowwidths = {}
local rowends = {}

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

local function PanelTemplates_TabResize(tab, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)
	local tabName = tab:GetName();

	local buttonMiddle = tab.Middle or tab.middleTexture or _G[tabName.."Middle"];
	local buttonMiddleDisabled = tab.MiddleDisabled or (tabName and _G[tabName.."MiddleDisabled"]);
	local left = tab.Left or tab.leftTexture or _G[tabName.."Left"];
	local sideWidths = 2 * left:GetWidth();
	local tabText = tab.Text or _G[tab:GetName().."Text"];
	local highlightTexture = tab.HighlightTexture or (tabName and _G[tabName.."HighlightTexture"]);

	local width, tabWidth;
	local textWidth;
	if ( absoluteTextSize ) then
		textWidth = absoluteTextSize;
	else
		tabText:SetWidth(0);
		textWidth = tabText:GetWidth();
	end
	-- If there's an absolute size specified then use it
	if ( absoluteSize ) then
		if ( absoluteSize < sideWidths) then
			width = 1;
			tabWidth = sideWidths
		else
			width = absoluteSize - sideWidths;
			tabWidth = absoluteSize
		end
		tabText:SetWidth(width);
	else
		-- Otherwise try to use padding
		if ( padding ) then
			width = textWidth + padding;
		else
			width = textWidth + 24;
		end
		-- If greater than the maxWidth then cap it
		if ( maxWidth and width > maxWidth ) then
			if ( padding ) then
				width = maxWidth + padding;
			else
				width = maxWidth + 24;
			end
			tabText:SetWidth(width);
		else
			tabText:SetWidth(0);
		end
		if (minWidth and width < minWidth) then
			width = minWidth;
		end
		tabWidth = width + sideWidths;
	end

	if ( buttonMiddle ) then
		buttonMiddle:SetWidth(width);
	end
	if ( buttonMiddleDisabled ) then
		buttonMiddleDisabled:SetWidth(width);
	end

	tab:SetWidth(tabWidth);

	if ( highlightTexture ) then
		highlightTexture:SetWidth(tabWidth);
	end
end

local function PanelTemplates_DeselectTab(tab)
	local name = tab:GetName();

	local left = tab.Left or _G[name.."Left"];
	local middle = tab.Middle or _G[name.."Middle"];
	local right = tab.Right or _G[name.."Right"];
	left:Show();
	middle:Show();
	right:Show();
	--tab:UnlockHighlight();
	tab:Enable();
	local text = tab.Text or _G[name.."Text"];
	text:SetPoint("CENTER", tab, "CENTER", (tab.deselectedTextX or 0), (tab.deselectedTextY or 2));

	local leftDisabled = tab.LeftDisabled or _G[name.."LeftDisabled"];
	local middleDisabled = tab.MiddleDisabled or _G[name.."MiddleDisabled"];
	local rightDisabled = tab.RightDisabled or _G[name.."RightDisabled"];
	leftDisabled:Hide();
	middleDisabled:Hide();
	rightDisabled:Hide();
end

local function PanelTemplates_SelectTab(tab)
	local name = tab:GetName();

	local left = tab.Left or _G[name.."Left"];
	local middle = tab.Middle or _G[name.."Middle"];
	local right = tab.Right or _G[name.."Right"];
	left:Hide();
	middle:Hide();
	right:Hide();
	--tab:LockHighlight();
	tab:Disable();
	tab:SetDisabledFontObject(GameFontHighlightSmall);
	local text = tab.Text or _G[name.."Text"];
	text:SetPoint("CENTER", tab, "CENTER", (tab.selectedTextX or 0), (tab.selectedTextY or -3));

	local leftDisabled = tab.LeftDisabled or _G[name.."LeftDisabled"];
	local middleDisabled = tab.MiddleDisabled or _G[name.."MiddleDisabled"];
	local rightDisabled = tab.RightDisabled or _G[name.."RightDisabled"];
	leftDisabled:Show();
	middleDisabled:Show();
	rightDisabled:Show();

	if GameTooltip:IsOwned(tab) then
		GameTooltip:Hide();
	end
end

local function PanelTemplates_SetDisabledTabState(tab)
	local name = tab:GetName();
	local left = tab.Left or _G[name.."Left"];
	local middle = tab.Middle or _G[name.."Middle"];
	local right = tab.Right or _G[name.."Right"];
	left:Show();
	middle:Show();
	right:Show();
	--tab:UnlockHighlight();
	tab:Disable();
	tab.text = tab:GetText();
	-- Gray out text
	tab:SetDisabledFontObject(GameFontDisableSmall);
	local leftDisabled = tab.LeftDisabled or _G[name.."LeftDisabled"];
	local middleDisabled = tab.MiddleDisabled or _G[name.."MiddleDisabled"];
	local rightDisabled = tab.RightDisabled or _G[name.."RightDisabled"];
	leftDisabled:Hide();
	middleDisabled:Hide();
	rightDisabled:Hide();
end

local function UpdateTabLook(frame)
	if frame.disabled then
		PanelTemplates_SetDisabledTabState(frame)
	elseif frame.selected then
		PanelTemplates_SelectTab(frame)
	else
		PanelTemplates_DeselectTab(frame)
	end
end

local function Tab_SetText(frame, text)
	frame:_SetText(text)
	local width = frame.obj.frame.width or frame.obj.frame:GetWidth() or 0
	PanelTemplates_TabResize(frame, 0, nil, nil, width, frame:GetFontString():GetStringWidth())
end

local function Tab_SetSelected(frame, selected)
	frame.selected = selected
	UpdateTabLook(frame)
end

local function Tab_SetDisabled(frame, disabled)
	frame.disabled = disabled
	UpdateTabLook(frame)
end

local function BuildTabsOnUpdate(frame)
	local self = frame.obj
	self:BuildTabs()
	frame:SetScript("OnUpdate", nil)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Tab_OnClick(frame)
	if not (frame.selected or frame.disabled) then
		PlaySound(841) -- SOUNDKIT.IG_CHARACTER_INFO_TAB
		frame.obj:SelectTab(frame.value)
	end
end

local function Tab_OnEnter(frame)
	local self = frame.obj
	self:Fire("OnTabEnter", self.tabs[frame.id].value, frame)
end

local function Tab_OnLeave(frame)
	local self = frame.obj
	self:Fire("OnTabLeave", self.tabs[frame.id].value, frame)
end

local function Tab_OnShow(frame)
	_G[frame:GetName().."HighlightTexture"]:SetWidth(frame:GetTextWidth() + 30)
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
		self.tablist = nil
		for _, tab in pairs(self.tabs) do
			tab:Hide()
		end
	end,

	["CreateTab"] = function(self, id)
		local tabname = ("AceGUITabGroup%dTab%d"):format(self.num, id)
		local tab = CreateFrame("Button", tabname, self.border)
		tab:SetSize(115, 24)
		tab.deselectedTextY = -3
		tab.selectedTextY = -2

		tab.LeftDisabled = tab:CreateTexture(tabname .. "LeftDisabled", "BORDER")
		tab.LeftDisabled:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
		tab.LeftDisabled:SetSize(20, 24)
		tab.LeftDisabled:SetPoint("BOTTOMLEFT", 0, -3)
		tab.LeftDisabled:SetTexCoord(0, 0.15625, 0, 1.0)

		tab.MiddleDisabled = tab:CreateTexture(tabname .. "MiddleDisabled", "BORDER")
		tab.MiddleDisabled:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
		tab.MiddleDisabled:SetSize(88, 24)
		tab.MiddleDisabled:SetPoint("LEFT", tab.LeftDisabled, "RIGHT")
		tab.MiddleDisabled:SetTexCoord(0.15625, 0.84375, 0, 1.0)

		tab.RightDisabled = tab:CreateTexture(tabname .. "RightDisabled", "BORDER")
		tab.RightDisabled:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
		tab.RightDisabled:SetSize(20, 24)
		tab.RightDisabled:SetPoint("LEFT", tab.MiddleDisabled, "RIGHT")
		tab.RightDisabled:SetTexCoord(0.84375, 1.0, 0, 1.0)

		tab.Left = tab:CreateTexture(tabname .. "Left", "BORDER")
		tab.Left:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InActiveTab")
		tab.Left:SetSize(20, 24)
		tab.Left:SetPoint("TOPLEFT")
		tab.Left:SetTexCoord(0, 0.15625, 0, 1.0)

		tab.Middle = tab:CreateTexture(tabname .. "Middle", "BORDER")
		tab.Middle:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InActiveTab")
		tab.Middle:SetSize(88, 24)
		tab.Middle:SetPoint("LEFT", tab.Left, "RIGHT")
		tab.Middle:SetTexCoord(0.15625, 0.84375, 0, 1.0)

		tab.Right = tab:CreateTexture(tabname .. "Right", "BORDER")
		tab.Right:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InActiveTab")
		tab.Right:SetSize(20, 24)
		tab.Right:SetPoint("LEFT", tab.Middle, "RIGHT")
		tab.Right:SetTexCoord(0.84375, 1.0, 0, 1.0)

		tab.Text = tab:CreateFontString(tabname .. "Text")
		tab:SetFontString(tab.Text)

		tab:SetNormalFontObject(GameFontNormalSmall)
		tab:SetHighlightFontObject(GameFontHighlightSmall)
		tab:SetDisabledFontObject(GameFontHighlightSmall)
		tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", "ADD")
		tab.HighlightTexture = tab:GetHighlightTexture()
		tab.HighlightTexture:ClearAllPoints()
		tab.HighlightTexture:SetPoint("LEFT", tab, "LEFT", 10, -4)
		tab.HighlightTexture:SetPoint("RIGHT", tab, "RIGHT", -10, -4)
		_G[tabname .. "HighlightTexture"] = tab.HighlightTexture

		tab.obj = self
		tab.id = id

		tab.text = tab.Text -- compat
		tab.text:ClearAllPoints()
		tab.text:SetPoint("LEFT", 14, -3)
		tab.text:SetPoint("RIGHT", -12, -3)

		tab:SetScript("OnClick", Tab_OnClick)
		tab:SetScript("OnEnter", Tab_OnEnter)
		tab:SetScript("OnLeave", Tab_OnLeave)
		tab:SetScript("OnShow", Tab_OnShow)

		tab._SetText = tab.SetText
		tab.SetText = Tab_SetText
		tab.SetSelected = Tab_SetSelected
		tab.SetDisabled = Tab_SetDisabled

		return tab
	end,

	["SetTitle"] = function(self, text)
		self.titletext:SetText(text or "")
		if text and text ~= "" then
			self.alignoffset = 25
		else
			self.alignoffset = 18
		end
		self:BuildTabs()
	end,

	["SelectTab"] = function(self, value)
		local status = self.status or self.localstatus
		local found
		for i, v in ipairs(self.tabs) do
			if v.value == value then
				v:SetSelected(true)
				found = true
			else
				v:SetSelected(false)
			end
		end
		status.selected = value
		if found then
			self:Fire("OnGroupSelected",value)
		end
	end,

	["SetTabs"] = function(self, tabs)
		self.tablist = tabs
		self:BuildTabs()
	end,


	["BuildTabs"] = function(self)
		local hastitle = (self.titletext:GetText() and self.titletext:GetText() ~= "")
		local tablist = self.tablist
		local tabs = self.tabs

		if not tablist then return end

		local width = self.frame.width or self.frame:GetWidth() or 0

		wipe(widths)
		wipe(rowwidths)
		wipe(rowends)

		--Place Text into tabs and get thier initial width
		for i, v in ipairs(tablist) do
			local tab = tabs[i]
			if not tab then
				tab = self:CreateTab(i)
				tabs[i] = tab
			end

			tab:Show()
			tab:SetText(v.text)
			tab:SetDisabled(v.disabled)
			tab.value = v.value

			widths[i] = tab:GetWidth() - 6 --tabs are anchored 10 pixels from the right side of the previous one to reduce spacing, but add a fixed 4px padding for the text
		end

		for i = (#tablist)+1, #tabs, 1 do
			tabs[i]:Hide()
		end

		--First pass, find the minimum number of rows needed to hold all tabs and the initial tab layout
		local numtabs = #tablist
		local numrows = 1
		local usedwidth = 0

		for i = 1, #tablist do
			--If this is not the first tab of a row and there isn't room for it
			if usedwidth ~= 0 and (width - usedwidth - widths[i]) < 0 then
				rowwidths[numrows] = usedwidth + 10 --first tab in each row takes up an extra 10px
				rowends[numrows] = i - 1
				numrows = numrows + 1
				usedwidth = 0
			end
			usedwidth = usedwidth + widths[i]
		end
		rowwidths[numrows] = usedwidth + 10 --first tab in each row takes up an extra 10px
		rowends[numrows] = #tablist

		--Fix for single tabs being left on the last row, move a tab from the row above if applicable
		if numrows > 1 then
			--if the last row has only one tab
			if rowends[numrows-1] == numtabs-1 then
				--if there are more than 2 tabs in the 2nd last row
				if (numrows == 2 and rowends[numrows-1] > 2) or (rowends[numrows] - rowends[numrows-1] > 2) then
					--move 1 tab from the second last row to the last, if there is enough space
					if (rowwidths[numrows] + widths[numtabs-1]) <= width then
						rowends[numrows-1] = rowends[numrows-1] - 1
						rowwidths[numrows] = rowwidths[numrows] + widths[numtabs-1]
						rowwidths[numrows-1] = rowwidths[numrows-1] - widths[numtabs-1]
					end
				end
			end
		end

		--anchor the rows as defined and resize tabs to fill thier row
		local starttab = 1
		for row, endtab in ipairs(rowends) do
			local first = true
			for tabno = starttab, endtab do
				local tab = tabs[tabno]
				tab:ClearAllPoints()
				if first then
					tab:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -(hastitle and 14 or 7)-(row-1)*20 )
					first = false
				else
					tab:SetPoint("LEFT", tabs[tabno-1], "RIGHT", -10, 0)
				end
			end

			-- equal padding for each tab to fill the available width,
			-- if the used space is above 75% already
			-- the 18 pixel is the typical width of a scrollbar, so we can have a tab group inside a scrolling frame,
			-- and not have the tabs jump around funny when switching between tabs that need scrolling and those that don't
			local padding = 0
			if not (numrows == 1 and rowwidths[1] < width*0.75 - 18) then
				padding = (width - rowwidths[row]) / (endtab - starttab+1)
			end

			for i = starttab, endtab do
				PanelTemplates_TabResize(tabs[i], padding + 4, nil, nil, width, tabs[i]:GetFontString():GetStringWidth())
			end
			starttab = endtab + 1
		end

		self.borderoffset = (hastitle and 17 or 10)+((numrows)*20)
		self.border:SetPoint("TOPLEFT", 1, -self.borderoffset)
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
        local border = self.border
		local contentwidth = width - 60
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
        border:SetWidth(width - 2)
		self:BuildTabs(self)
		self.frame:SetScript("OnUpdate", BuildTabsOnUpdate)
	end,

	["OnHeightSet"] = function(self, height)
        if resizing then return end -- Prevent recursive calls
            resizing = true
        -- print("OnHeightSet called with height:", height)
		local content = self.content
        local border = self.border
		local contentheight = height - (self.borderoffset + 23)
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
        -- print(content.height)
        border:SetHeight(height - 4)
        resizing = false
	end,

	["LayoutFinished"] = function(self, width, height)
		if self.noAutoHeight then return end
		self:SetHeight((height or 0) + (self.borderoffset + 23))
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

local function Constructor()
	local num = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", nil ,UIParent, "BackdropTemplate")
    frame:Hide()
	frame:SetHeight(200)
	frame:SetWidth(200)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100) -- Lots of room to draw under it
	-- frame:SetBackdrop(PaneBackdrop)
	-- frame:SetBackdropColor(0, 0, 0, 1)

    frame:EnableMouse(true)
    frame:SetResizeBounds(240, 120)
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
	border:SetPoint("TOPLEFT", 1, -27)
	border:SetPoint("BOTTOMRIGHT", -1, 3)
	border:SetBackdrop(PaneBackdrop)
	border:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
	border:SetBackdropBorderColor(0.4, 0.4, 0.4)

    local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	closebutton:SetScript("OnClick", Button_OnClick)
	closebutton:SetPoint("TOPRIGHT", -5, 0)
	closebutton:SetHeight(20)
	closebutton:SetWidth(100)
	closebutton:SetText(CLOSE)

	local content = CreateFrame("Frame", nil, border)
	content:SetPoint("TOPLEFT", 10, -7)
	content:SetPoint("BOTTOMRIGHT", -10, 7)

	local widget = {
		num          = num,
		frame        = frame,
		localstatus  = {},
		alignoffset  = 18,
		titletext    = titletext,
		border       = border,
		borderoffset = 27,
		tabs         = {},
        sizer_se     = sizer_se,
		sizer_s      = sizer_s,
		sizer_e      = sizer_e,
		content      = content,
		type         = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
    closebutton.obj = widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
