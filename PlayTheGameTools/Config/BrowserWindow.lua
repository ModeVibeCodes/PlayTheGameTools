local _,addon=...
local W,T=addon.ConfigWidgets,addon.InterfaceTheme

-- Data browsers (Dungeon Loot, Class Training) are tools, not settings: each
-- opens in its own movable window from its page header, ring icon or binding.
-- They are ordinary unprotected frames, so they open, move and close in
-- combat; their content defers any restricted reads itself.
-- The surface is the theme's Window texture, as the Recruiter uses, so mode,
-- Modern and Blizzard each draw it their own way.
local HEADER_HEIGHT=44
-- Session-only positions (centre offsets), keyed by window name. A new
-- session opens each window in its default place.
local positions={}
addon.BrowserWindowPositions=positions

local function Place(f,name,default)
    local position=positions[name] or default
    f:ClearAllPoints()
    f:SetPoint("CENTER",UIParent,"CENTER",position.x/f:GetScale(),position.y/f:GetScale())
end

-- Shrinks a window that would not fit the screen, like the settings window.
local function Fit(f,width,height)
    local screenW,screenH=UIParent:GetWidth(),UIParent:GetHeight()
    local scale=math.min(1,math.max(1,screenW-32)/width,math.max(1,screenH-32)/height)
    if f:GetScale()~=scale then f:SetScale(scale) end
end

-- spec: name, title, width, height, module (owner, for Settings and fonts),
-- optional x/y default centre offset, onShow and onHide.
function W.BrowserWindow(spec)
    local name=spec.name
    local default={x=spec.x or 0,y=spec.y or 0}
    local f=CreateFrame("Frame",name,UIParent)
    f:Hide()
    f.ptgMediaScope=spec.module.id
    f:SetSize(spec.width,spec.height);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true)
    if f.SetToplevel then f:SetToplevel(true) end
    f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() f.moving=true;f:StartMoving() end)
    f:SetScript("OnDragStop",function()
        f:StopMovingOrSizing();f.moving=false
        local x,y=f:GetCenter();local px,py=UIParent:GetCenter()
        local ratio=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
        if x and y and px and py then positions[name]={x=x*ratio-px,y=y*ratio-py} end
        Place(f,name,default)
    end)
    W.Texture(f,"Window")
    -- The stock dialog border is about 12px deep; keep content clear of it.
    local edge=f.blizzardBackdrop and 8 or 0
    f.title=W.Heading(f,spec.title,T.fontSize.section,16+edge,-14-edge,spec.width-200,T.text)
    local close=W.Button(f,"Close",64,24,"secondary");close:SetPoint("TOPRIGHT",-12-edge,-10-edge)
    close:SetScript("OnClick",function() f:Hide() end)
    local settings=W.Button(f,"Settings",76,24,"secondary");settings:SetPoint("RIGHT",close,"LEFT",-6,0)
    settings:SetScript("OnClick",function()
        if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
        if addon.configWindow and addon.configWindow:IsShown() then addon:SelectConfigPage(spec.module.id) end
    end)
    f.closeButton,f.settingsButton=close,settings
    local body=CreateFrame("Frame",nil,f)
    body:SetPoint("TOPLEFT",16+edge,-HEADER_HEIGHT-4-edge)
    body:SetPoint("BOTTOMRIGHT",-16-edge,16+edge)
    body.ptgMediaScope=spec.module.id
    f.body=body
    f:SetScript("OnShow",function()
        Fit(f,spec.width,spec.height);Place(f,name,default)
        f:Raise()
        if spec.onShow then spec.onShow(f) end
    end)
    f:SetScript("OnHide",function()
        if f.moving then f:StopMovingOrSizing();f.moving=false end
        if spec.onHide then spec.onHide(f) end
    end)
    -- Own group: opening it closes the addon's other windows (settings
    -- included); Escape closes it. Registered after OnShow, which it hooks.
    addon.Dialogs:Register(f,{group=spec.group or spec.module.id})
    return f
end
