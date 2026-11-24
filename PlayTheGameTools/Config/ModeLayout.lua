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

local function PairColors(page)
    local candidates={
        textColor={"Font Size","Name Font Size","Food Font Size","Bar Text Size"},
        sessionTextColor={"Session Text Size"},
        backgroundColor={"Background opacity","Background Opacity","Food Background Opacity"},
        borderColor={"Border Opacity","Food Border Opacity"},
    }
    for _,color in ipairs(page.settingsColors or {}) do
        local original=color.host.row;local route=original.modeRoute
        if route and original.settingsHost==color.host then
            for _,title in ipairs(candidates[color.key] or {}) do
                local paired
                for _,row in ipairs(page.rows) do
                    local target=row.modeRoute
                    if row.settingsTitle==title and target and target.feature==route.feature and target.panel==route.panel and row.settingsHost.slider and not row.layoutChildren then
                        paired=row;break
                    end
                end
                if paired then
                    original.modePaired=true;color.host:SetParent(paired);color.host.row=paired;color.host.rowLabel=paired.settingsLabel
                    paired.modePairedColor=color
                    local host=paired.settingsHost
                    function paired:layoutChildren(width)
                        local wide=width>=420;self:SetHeight(wide and 46 or 82)
                        self.settingsLabel:SetWidth(152)
                        host:ClearAllPoints();host:SetPoint("TOPLEFT",self,"TOPLEFT",164,-10);host:SetSize(math.max(1,width-(wide and 264 or 176)),26)
                        color.host:ClearAllPoints();color.host:SetSize(80,30)
                        if wide then color.host:SetPoint("TOPRIGHT",self,"TOPRIGHT",-12,-8)
                        else color.host:SetPoint("TOPLEFT",self,"TOPLEFT",164,-46) end
                    end
                    for _,entry in ipairs(page.searchEntries) do if entry.row==original then entry.row=paired end end
                    break
                end
            end
        end
    end
end

-- Every module page is one vertical scroll of its sections (Config/Pages.lua).
-- Existing rows, controls, callbacks, search entries and visibility predicates
-- remain the owners of their behavior. This layer only routes rows so display
-- styling stays in Layout, and compacts rows for the shared form rhythm.
function W.ApplyModeModuleLayout(page,id)
    if page.modeLayout then return end
    local plan=W.ModeLayoutPlans[id]
    if not plan then return end
    page.modeFooterLayout=true
    CompactColors(page)
    local state={plan=plan,routes={}}
    page.modeLayout=state
    -- Styling of a placeable display lives in Layout, not on this page.
    local owned=W.EditOwnedFeatures(id)
    state.editOwned=owned
    for _,row in ipairs(page.rows) do
        local feature,panel
        if plan.route then feature,panel=plan.route(row) end
        if feature then
            row.modeRoute={feature=feature,panel=panel or "options"};state.routes[row]=row.modeRoute
            -- Headings are never styling: they show while a row under them does.
            local heading=row.sectionHeader or row.subsectionHeading
            if not heading and owned[feature] and W.EditAppearancePanels[row.modeRoute.panel] then row.editAppearance=row.modeRoute end
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
    PairColors(page)
    if id=="foreverRogue" then
        -- Customize opens the display itself in Layout, where its styling lives.
        for i,button in ipairs(page.displayButtons) do
            local element=i==1 and "roguePoisonReminder" or "rogueQuickPoisons"
            button:HookScript("OnClick",function() if button:IsEnabled() then addon:EditElementAppearance(element) end end)
        end
    end
    local originalVisible=page.ModeRowVisible
    function page:ModeRowVisible(row,original)
        if row.editAppearance or row.modeReplacedNavigation or row.modePaired then return false end
        if originalVisible then return originalVisible(self,row,original) end
        return original
    end
    page:Layout()
end
