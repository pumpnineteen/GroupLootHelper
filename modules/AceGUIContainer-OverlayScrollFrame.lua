local AceGUI = LibStub("AceGUI-3.0")

local Type    = "OverlayScrollFrame"
local Version = 1

local BAR_WIDTH   = 8
local BAR_INSET   = 2
local THUMB_MIN_H = 20
local HIDE_DELAY  = 0.4


local function Frame_OnMouseWheel(self, delta)
    self.obj:MoveScroll(delta)
end

-- Fires when the ScrollFrame's intrinsic scroll range changes (content resized).
local function ScrollFrame_OnScrollRangeChanged(self)
    self.obj:FixScroll()
end

-- Guard: Slider_OnValueChanged must not recurse into FixScroll.
local function Slider_OnValueChanged(self, value)
    if not self.obj.updateLock then
        self.obj:SetScroll(value)
    end
end

local function Any_OnEnter(self)
    local w = self.obj
    if w.hideTimer then
        w.hideTimer:Cancel()
        w.hideTimer = nil
    end
    if w.hasOverflow then
        w.slider:Show()
    end
end

local function Any_OnLeave(self)
    local w = self.obj

    -- Early-out: OnLeave fires when the cursor enters an *overlapping child*
    if w.scrollframe:IsMouseOver() or w.slider:IsMouseOver() then
        return
    end

    if w.hideTimer then
        w.hideTimer:Cancel()
    end
    w.hideTimer = C_Timer.NewTimer(HIDE_DELAY, function()
        w.hideTimer = nil
        -- Re-check: cursor may have re-entered during the delay.
        if not w.scrollframe:IsMouseOver() and not w.slider:IsMouseOver() then
            w.slider:Hide()
        end
    end)
end

local function SetScroll(self, value)
    local status   = self.status or self.localstatus
    local viewH    = self.scrollframe:GetHeight()
    local contentH = self.content:GetHeight()
    local offset

    if viewH >= contentH then
        offset = 0
    else
        offset = floor((contentH - viewH) / 1000 * value)
    end

    self.content:ClearAllPoints()
    self.content:SetPoint("TOPLEFT",  0,  offset)
    self.content:SetPoint("TOPRIGHT", 0,  offset)
    status.offset      = offset
    status.scrollvalue = value
end

local function MoveScroll(self, delta)
    local status   = self.status or self.localstatus
    local viewH    = self.scrollframe:GetHeight()
    local contentH = self.content:GetHeight()
    if contentH <= viewH then return end

    local step   = 1000 * (viewH * 0.20) / contentH
    local newval = Clamp((status.scrollvalue or 0) - delta * step, 0, 1000)
    self.slider:SetValue(newval)
end

local function UpdateThumb(self)
    local viewH    = self.scrollframe:GetHeight()
    local contentH = self.content:GetHeight()
    if contentH <= 0 then return end
    local trackH  = self.slider:GetHeight()
    local thumbH  = max(THUMB_MIN_H, floor((viewH / contentH) * trackH))
    self.thumbTex:SetHeight(thumbH)
end

local function FixScroll(self)
    if self.updateLock then return end
    self.updateLock = true

    local status   = self.status or self.localstatus
    local viewH    = self.scrollframe:GetHeight()
    local contentH = self.content:GetHeight()

    if viewH <= 0 then
        self.updateLock = nil
        return
    end

    if contentH <= viewH then
        self.hasOverflow = false
        self.slider:Hide()
        self.content:ClearAllPoints()
        self.content:SetPoint("TOPLEFT",  0, 0)
        self.content:SetPoint("TOPRIGHT", 0, 0)
        status.offset      = 0
        status.scrollvalue = 0
        self.slider:SetValue(0)
    else
        self.hasOverflow = true
        UpdateThumb(self)

        local offset = status.offset or 0
        local value  = Clamp(offset / (contentH - viewH) * 1000, 0, 1000)
        status.scrollvalue = value
        self.slider:SetValue(value)
        SetScroll(self, value)

        if self.scrollframe:IsMouseOver() or self.slider:IsMouseOver() then
            self.slider:Show()
        end
    end

    self.updateLock = nil
end

local function LayoutFinished(self, width, height)
    self.content:SetHeight(height or 0)
    self:FixScroll()
end

local function OnWidthSet(self, width)
    self.content:SetWidth(width)
    self.content.width = width 
end

local function OnHeightSet(self, height)
    self.content:SetHeight(height)
    self.content.height = height
    self:FixScroll()
end

local function OnAcquire(self)
    self.hasOverflow = false
    self.localstatus = { scrollvalue = 0, offset = 0 }
    self.scrollframe:SetScrollChild(self.content)
    self.slider:SetValue(0)
    self.slider:Hide()
end

local function OnRelease(self)
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end
    self.status      = nil
    self.hasOverflow = false
    for k in pairs(self.localstatus) do
        self.localstatus[k] = nil
    end
    self.slider:SetValue(0)
    self.slider:Hide()
end

local function SetStatusTable(self, status)
    assert(type(status) == "table")
    self.status = status
    status.scrollvalue = status.scrollvalue or 0
    status.offset      = status.offset      or 0
end

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(100, 100)
    frame:Hide()

    local scrollframe = CreateFrame("ScrollFrame", nil, frame)
    scrollframe:SetAllPoints(frame)
    scrollframe:EnableMouseWheel(true)
    scrollframe:SetScript("OnMouseWheel",         Frame_OnMouseWheel)
    scrollframe:SetScript("OnScrollRangeChanged", ScrollFrame_OnScrollRangeChanged)
    scrollframe:SetScript("OnEnter",              Any_OnEnter)
    scrollframe:SetScript("OnLeave",              Any_OnLeave)

    local content = CreateFrame("Frame", nil, scrollframe)
    content:SetPoint("TOPLEFT")
    content:SetPoint("TOPRIGHT")
    content:SetHeight(400)  -- placeholder; LayoutFinished will correct it
    scrollframe:SetScrollChild(content)

    local slider = CreateFrame("Slider", nil, frame)
    slider:SetWidth(BAR_WIDTH)
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 1000)
    slider:SetValue(0)
    slider:SetValueStep(1)
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    slider:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    -BAR_INSET, -BAR_INSET)
    slider:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -BAR_INSET,  BAR_INSET)
    slider:Hide()

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.4)

    local thumbTex = slider:CreateTexture(nil, "ARTWORK")
    thumbTex:SetColorTexture(0.75, 0.75, 0.75, 0.70)
    thumbTex:SetSize(BAR_WIDTH, THUMB_MIN_H)
    slider:SetThumbTexture(thumbTex)

    slider:SetScript("OnValueChanged", Slider_OnValueChanged)
    slider:SetScript("OnMouseWheel",   Frame_OnMouseWheel)
    slider:SetScript("OnEnter",        Any_OnEnter)
    slider:SetScript("OnLeave",        Any_OnLeave)

    local widget = {
        -- Frames
        frame       = frame,
        scrollframe = scrollframe,
        content     = content,    
        slider      = slider,
        thumbTex    = thumbTex,

        localstatus = { scrollvalue = 0, offset = 0 },
        hasOverflow = false,

        OnAcquire      = OnAcquire,
        OnRelease      = OnRelease,
        SetScroll      = SetScroll,
        MoveScroll     = MoveScroll,
        FixScroll      = FixScroll,
        OnWidthSet     = OnWidthSet,
        OnHeightSet    = OnHeightSet,
        LayoutFinished = LayoutFinished,
        SetStatusTable = SetStatusTable,

        type = Type,
    }

    -- RegisterAsContainer:
    --   • Adds standard container methods (AddChild, ReleaseChildren, SetLayout…)
    --   • Sets frame.obj   = widget
    --   • Sets content.obj = widget  ← used by child widget callbacks
    --   • Calls widget:SetLayout("List") as the default
    AceGUI:RegisterAsContainer(widget)

    scrollframe.obj = widget
    slider.obj      = widget

    return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)