local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,D,W=addon.ForeverQuickAccess,addon.ForeverQuickAccessData,addon.ConfigWidgets

function M:CreateConfigPage(parent)
    local page=W.Page(parent,480);self.page=page
    local function Toggle(label,key)
        page:ToggleGrid({{label=label,get=function() return self.db[key] end,
            set=function(v) self:SetOption(key,v) end}})
    end
    local function Slider(label,key,suffix)
        local r=D.ranges[key]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(label,48),r[1],r[2],r[3],
            function() return self.db[key] end,function(v) self:SetOption(key,v) end,suffix,true)
    end
    local function Button(label,text,callback)
        local b=W.Button(page:Row(label,48),text,180,28)
        b:SetPoint("LEFT");b:SetScript("OnClick",function() callback();page:Refresh() end)
        return b
    end
    page:Section("Professions")
    Toggle("Show Profession Bar","showProfessionBar")
    local status=W.Label(page:Row("Learned Professions",72),"",nil,0,-4,280,addon.Theme.muted)
    status:SetWordWrap(true)
    Button("Update Learned List","Refresh Professions",function() self:RefreshProfessions() end)
    -- Five reusable rows allow learning/unlearning to update an already-open page.
    page.professionCells={}
    for i=1,5 do
        local cell=page:ToggleGrid({{label="Profession "..i,
            get=function() local p=self.professions[i];return p and not self.db.hidden[p.id] or false end,
            set=function(v) local p=self.professions[i];if p then self:SetHidden(p.id,not v) end end}})[1]
        page.professionCells[i]=cell
        cell.searchEntry=page.searchEntries[#page.searchEntries]
    end
    page.refreshers[#page.refreshers+1]=function()
        status:SetText(self.message or "Enable Quick Access Bars to discover learned professions.")
        for i,cell in ipairs(page.professionCells) do
            local p=self.professions[i]
            cell.label:SetText(p and p.name or "No profession")
            cell.searchEntry.label=p and p.name or "No profession"
            cell.frame:SetEnabled(p~=nil);cell.button:SetEnabled(p~=nil)
        end
    end
    page:Section("Layout")
    Slider("Bar Scale","scale","%")
    Slider("Icon Size","iconSize")
    Slider("Icons Per Row","columns")
    Slider("Icon Spacing","spacing")
    Slider("Bar Padding","padding")
    Toggle("Show Profession Names","showNames")
    Slider("Name Font Size","fontSize")
    Toggle("Show Tooltips","showTooltips")
    page:Section("Appearance")
    -- Reuse the established color widget through a narrow adapter; storage stays flat.
    local colorOwner={db={appearance=self.db}}
    function colorOwner:CanConfigure() return M:CanConfigure() end
    function colorOwner:SetAppearance(key,value) return M:SetOption(key,value) end
    function colorOwner:GetFonts() return M:GetFonts() end
    local _,refreshFont=W.FontDropdown(page:Row("Name Font"),colorOwner)
    page.refreshers[#page.refreshers+1]=refreshFont
    Toggle("Name Outline","outline")
    W.ColorRow(page,colorOwner,"Background Color","backgroundColor")
    Slider("Background Opacity","backgroundOpacity","%")
    W.ColorRow(page,colorOwner,"Border Color","borderColor")
    Slider("Border Opacity","borderOpacity","%")
    W.ColorRow(page,colorOwner,"Name Color","textColor")
    page:Section("Visibility")
    Slider("Out of Combat Opacity","outOpacity","%")
    Slider("In Combat Opacity","combatOpacity","%")
    Slider("Fade Duration","fadeDuration","s")
    Toggle("Reveal on Hover","hoverReveal")
    local note=W.Label(page:Row("Visibility Help",96),
        "0% hides the bar and passes clicks through. Hover reveal works outside combat when opacity is above 0%. Profession opening and movement require being outside combat. Unlocking or Preview/Edit reveals learned icons.",nil,0,-4,280,addon.Theme.muted)
    note:SetWordWrap(true)
    page:Section("Positioning")
    Toggle("Lock Bar","locked")
    local move=W.Label(page:Row("Move Bar",72),"Turn off Lock Bar, then drag any profession icon. Turn Lock Bar back on to open profession pages.",nil,0,-4,280,addon.Theme.muted)
    move:SetWordWrap(true)
    Slider("Horizontal Offset","x")
    Slider("Vertical Offset","y")
    Button("Screen Position","Reset Position",function()
        if self:CanConfigure() then self.db.x=0;self.db.y=-180;self:Render() end
    end)
    if addon.ForeverFoodBar then addon.ForeverFoodBar:AddConfig(page) end
    page:Finish();return page
end
