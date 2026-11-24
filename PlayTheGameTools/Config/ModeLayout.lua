local _,addon=...
local W,T=addon.ConfigWidgets,addon.InterfaceTheme
-- Placement is never a settings row: every display is positioned in Layout.

local function Measure(label)
    local width=label:GetStringWidth()
    if (issecretvalue and issecretvalue(width)) or type(width)~="number" or width~=width or width<0 or width==math.huge then width=#(label:GetText() or "")*11 end
    return math.max(1,math.ceil(width))
end

function W.ModeHeadingRule(parent,heading)
    local line=parent:CreateTexture(nil,"ARTWORK");line.modeAsset="ModeHeaderLine";W.Paint(line,T.line,0.7)
    line:SetHeight(1)
    local function Align()
        local width=math.min(heading:GetWidth(),Measure(heading))
        line:ClearAllPoints();line:SetPoint("TOPLEFT",heading,"BOTTOMLEFT",0,-4);line:SetWidth(width)
    end
    Align();return line,Align
end

local function CompactColors(page)
    for _,color in ipairs(page.settingsColors or {}) do
        color.hex:Hide();if color.apply then color.apply:Hide() end
        color.pick:SetWidth(80)
    end
end

-- Every module page is one vertical scroll of its sections (Config/Pages.lua).
-- Existing rows, controls, callbacks, search entries and visibility predicates
-- remain the owners of their behavior. This layer only compacts routed rows
-- for the shared form rhythm. Display styling is not on these pages: it lives
-- in Layout (the Style card).
function W.ApplyModeModuleLayout(page,id)
    if page.modeLayout then return end
    local plan=W.ModeLayoutPlans[id]
    if not plan then return end
    page.modeFooterLayout=true
    CompactColors(page)
    local state={plan=plan,routes={}}
    page.modeLayout=state
    for _,row in ipairs(page.rows) do
        local feature=plan.route and plan.route(row)
        if feature then
            row.modeRoute={feature=feature};state.routes[row]=row.modeRoute
            if row.divider then row.divider:Hide() end
            row.gapBefore=0;row.gapAfter=2
            if row.settingsStandaloneToggle and not row.settingsToggles then
                local host=row.settingsHost;local button=row.settingsStandaloneToggle
                row.settingsLabel:Hide();host:ClearAllPoints();host:SetAllPoints(row)
                local cell=CreateFrame("Button",nil,host);cell:EnableMouse(true);cell:RegisterForClicks("LeftButtonUp")
                local label=W.Label(cell,row.settingsTitle,nil,28,-13,136,T.secondary);label:SetWordWrap(true)
                button:SetParent(cell);button:ClearAllPoints();button:SetPoint("TOPLEFT",-7,-6)
                cell:SetScript("OnClick",function() local click=button:GetScript("OnClick");if button:IsEnabled() and click then click(button) end end)
                cell:HookScript("OnEnter",function() button.hovered=true;button:RefreshAppearance() end)
                cell:HookScript("OnLeave",function() button.hovered=false;button:RefreshAppearance() end)
                row.settingsToggles={{frame=cell,button=button,label=label}}
                function row:layoutChildren(width) self:SetHeight(42);cell:ClearAllPoints();cell:SetPoint("TOPLEFT");cell:SetSize(width,42);label:SetWidth(math.max(1,width-36)) end
            end
            if row.settingsTitle and row.settingsTitle~="" and not row.layoutChildren and row:GetHeight()<=52 then row:SetHeight(math.min(row:GetHeight(),48)) end
        end
    end
    page:Layout()
end
