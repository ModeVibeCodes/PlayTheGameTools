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
    page:Section("Professions")
    Toggle("Show Profession Bar","showProfessionBar")
    local status=W.Label(page:Row("Learned Professions",72),"",nil,0,-4,280,addon.Theme.muted)
    status:SetWordWrap(true)
    -- No refresh button: SKILL_LINES_CHANGED and SPELLS_CHANGED re-read professions.
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
        status:SetText(self.message or "Turn on Profession & Food Bars to discover learned professions.")
        for i,cell in ipairs(page.professionCells) do
            local p=self.professions[i]
            cell.label:SetText(p and p.name or "No profession")
            cell.searchEntry.label=p and p.name or "No profession"
            cell.frame:SetEnabled(p~=nil);cell.button:SetEnabled(p~=nil)
        end
    end
    -- Icon size, fonts and colors are styled in Layout (the Style card).
    Toggle("Show Tooltips","showTooltips")
    page:Section("Visibility")
    Slider("Out of Combat Opacity","outOpacity","%")
    Slider("In Combat Opacity","combatOpacity","%")
    Slider("Fade Duration","fadeDuration","s")
    Toggle("Reveal on Hover","hoverReveal")
    if addon.ForeverFoodBar then addon.ForeverFoodBar:AddConfig(page) end
    page:Finish();return page
end
