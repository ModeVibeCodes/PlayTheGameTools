local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local M,W=addon.ForeverRecruitment,addon.ConfigWidgets
function M:CreateConfigPage(parent)
    local page=W.Page(parent,620);self.page=page
    local function Button(label,text,fn)
        local b=W.Button(page:Row(label,48),text,180,28);b:SetPoint("LEFT")
        b:SetScript("OnClick",function() fn();page:Refresh() end);return b
    end
    local function Input(label,key,limit)
        local e=CreateFrame("EditBox",nil,page:Row(label,48));e:SetSize(340,28);e:SetPoint("LEFT")
        e:SetFontObject(GameFontHighlight);e:SetAutoFocus(false);e:SetMaxLetters(limit);e:SetTextInsets(6,6,0,0)
        W.Texture(e,"InputField")
        local function reset() e:SetText(self.db[key]);e:ClearFocus() end
        e:SetScript("OnEnterPressed",function() self:SetOption(key,e:GetText());reset() end)
        e:SetScript("OnEscapePressed",reset)
        page.refreshers[#page.refreshers+1]=function() if not e:HasFocus() then e:SetText(self.db[key]) end end
    end
    page:Section("Pilot")
    page:ToggleGrid({{label="Enable Recruitment",get=function() return self.enabled end,
        set=function(value) if self:OutsideCombat() then addon:SetModuleEnabled(self.id,value) end end}})
    page:Section("Search")
    local status=W.Label(page:Row("Recruitment Status",100),"",nil,0,-4,390,addon.Theme.muted);status:SetWordWrap(true)
    page.refreshers[#page.refreshers+1]=function() status:SetText(self.status) end
    for _,entry in ipairs({{"Minimum Level","minLevel"},{"Maximum Level","maxLevel"}}) do
        local key=entry[2]
        local input=W.NumericInput(page:Row(entry[1],48),function() return self.db[key] end,function(v) self:SetOption(key,v) end,1,60,70)
        input:SetPoint("LEFT");page.refreshers[#page.refreshers+1]=function() input:Refresh() end
    end
    Input("Zone (exact name)","zone",80)
    Button("New Level Sweep","Start Scan",function() self:StartScan() end)
    Button("Continue Level Sweep","Next Search",function() self:NextSearch() end)
    Button("Cancel Level Sweep","Stop Scan",function() self:StopScan() end)
    Button("Native Who Fallback","Read Who Results",function() self:ReadWhoResults(true) end)
    page:Section("Contact")
    Input("Whisper Text (Enter saves)","message",200)
    local note=W.Label(page:Row("Pilot Limits",110),"Each search and invite needs a click. Draft Whisper opens editable chat; Enter sends. Invite only requests delivery. If blocked, use Player Menu Link. Contacted and skipped players stay hidden until Clear History.",nil,0,-4,390,addon.Theme.muted);note:SetWordWrap(true)
    page:Section("Candidates")
    self.cells={}
    for i=1,8 do
        local row=page:Row("Candidate "..i,118)
        row.rowLabel:SetWidth(160)
        local cell={row=row};self.cells[i]=cell
        for j,spec in ipairs({{"Draft Whisper",function(name) self:Draft(name) end},{"Invite",function(name) self:Invite(name) end},
            {"Player Menu Link",function(name) self:NativeLink(name) end},{"Mark Contacted",function(name) self:Remember(name,"contacted") end},
            {"Skip Player",function(name) self:Remember(name,"skip") end}}) do
            local action=spec[2];local b=W.Button(row,spec[1],145,26)
            b:SetPoint("TOPLEFT",((j-1)%2)*153,-math.floor((j-1)/2)*31)
            b:SetScript("OnClick",function() if cell.name then action(cell.name);page:Refresh() end end)
            cell[j]=b
        end
    end
    page.refreshers[#page.refreshers+1]=function()
        local visible={}
        for _,name in ipairs(self.order) do if self.candidates[name] and not self.db.history[name] then visible[#visible+1]=name end end
        self.offset=math.min(self.offset,math.max(0,math.floor((#visible-1)/8)*8))
        for i,cell in ipairs(self.cells) do
            cell.name=visible[self.offset+i];local c=cell.name and self.candidates[cell.name]
            cell.row.rowLabel:SetText(c and (c.name.."\n"..c.level.." "..c.class.."\n"..c.zone) or "No candidate")
            for j=1,5 do cell[j]:SetEnabled(c~=nil and self:Ready() and (j~=2 or not self.inviteBlocked)) end
        end
    end
    Button("Earlier Candidates","Previous Page",function() self.offset=math.max(0,self.offset-8) end)
    Button("More Candidates","Next Page",function() self.offset=self.offset+8 end)
    Button("Forget Contacted / Skipped","Clear History",function() if self:Ready() then self.db.history={};self:Refresh("Contact history cleared.") end end)
    page:Finish();return page
end
