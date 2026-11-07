local _, addon = ...
local M, P, W, T = addon.ForeverClassTraining, addon.ForeverTrainingData, addon.ConfigWidgets, addon.Theme

function M:CreateConfigPage(parent)
    local page = W.Page(parent, 480)
    local summary = page:Row("", 42)
    summary.rowLabel:Hide();summary:ClearAllPoints();summary:SetPoint("TOPLEFT",10,-10);summary:SetPoint("BOTTOMRIGHT",-10,10)
    page.statusLabel = W.Label(summary, "", nil, 0, 0, 200, T.muted)
    page.totalLabel = W.Label(summary, "", nil, 0, 0, 270, T.text)
    page.totalLabel:ClearAllPoints(); page.totalLabel:SetPoint("TOPRIGHT"); page.totalLabel:SetJustifyH("RIGHT")
    summary.row:EnableMouse(true)
    summary.row:SetScript("OnEnter", function(owner)
        if GameTooltip then
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT"); GameTooltip:SetText("Estimated training cost")
            GameTooltip:AddLine("Catalog prices before trainer discounts. Includes unlearned abilities at your level with confirmed prerequisites. Uncertain entries are excluded.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end)
    summary.row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    local general=page:Section("General")
    local controls = page:Row("Spellbook", 42)
    page.refreshButton = W.Button(controls, "Refresh", 90, 24, "secondary")
    page.refreshButton:SetPoint("LEFT")
    page.refreshButton:SetScript("OnClick", function() self:RefreshTraining(); page:Refresh() end)
    local function applyFeature(key,value)
        self.db[key]=value
        if key=="levelAlerts" and not value then
            self.pendingDing,self.pendingGuildDing=nil,nil
            self.guildDingDraft=nil
            self.guildDingStatus=nil
            self.lastLevelClock,self.lastClockLevel,self.levelDuration=nil,nil,nil
            if self.dingWindow then self.dingWindow:Hide() end
        end
        self:SyncTrainingDisplays()
    end
    page:ToggleGrid({
        {label="Level Up Window",get=function() return self.db.levelAlerts~=false end,set=function(v) applyFeature("levelAlerts",v) end},
        {label="Shortcut Icon & Menu",get=function() return self.db.showShortcut~=false end,set=function(v) applyFeature("showShortcut",v) end},
    },{maxColumns=2})
    page:Section("Level Up Window")
    local previewRow=page:Row("Level Up Window",42)
    page.popupPreviewButton=W.Button(previewRow,"Preview",100,26,"secondary")
    page.popupPreviewButton:SetPoint("LEFT")
    page.popupPreviewButton:SetScript("OnClick",function() self:PreviewDing() end)
    local options={}
    for _,spec in ipairs({{"Guild Ding Message","guildDing"},{"Time to Level","showLevelTime"},{"Player Money","showPlayerMoney"},{"Professions","showProfessions"},{"Secondary Professions","showSecondaryProfessions"}}) do
        local key=spec[2]
        options[#options+1]={label=spec[1],get=function() return self.db[key]~=false end,set=function(v)
            if key=="guildDing" then
                self.db[key]=v;self.pendingGuildDing=nil;self.guildDingDraft=nil
                self:SetGuildDingStatus(v and "Manual guild draft after next level-up." or "Guild message preparation disabled.")
                self:UpdateDingActions()
            else self:SetPopupOption(key,v) end
        end}
    end
    page:ToggleGrid(options,{maxColumns=2})
    page.guildMessageStatus=W.Label(page:Row("Guild Message Status",58),"",nil,0,0,270,T.muted)
    page.guildMessageStatus:SetWordWrap(true)
    page.guildPrepareButton=W.Button(page:Row("Guild Message Draft",42),"Prepare Message",140,26,"secondary")
    page.guildPrepareButton:SetPoint("LEFT")
    page.guildPrepareButton:SetScript("OnClick",function() self:PrepareGuildDing() end)
    for _,spec in ipairs({{"Window Width","popupWidth",420,600,20},{"Window Scale","popupScale",75,125,5},{"Title Text Size","popupTitleSize",22,34,1},{"Ability Text Size","popupAbilitySize",10,16,1},{"Detail Text Size","popupDetailSize",10,16,1},{"Background Opacity","popupOpacity",25,100,5}}) do
        local key=spec[2]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(spec[1],48),spec[3],spec[4],spec[5],
            function() return self:PopupValue(key) end,function(v) self:SetPopupOption(key,v) end,
            (key=="popupScale" or key=="popupOpacity") and "%" or "")
    end
    page:Section("Shortcut Icon & Menu")
    page.refreshers[#page.refreshers+1]=W.Slider(page:Row("Shortcut Icon Size",48),24,72,2,
        function() return self:ShortcutSize() end,function(v) self.db.shortcutSize=v;self:ApplyShortcutSize() end,"")
    local menuOptions={}
    for _,spec in ipairs({{"Show Current Currency","flyoutShowMoney"},{"Show Total Cost Per Level","flyoutShowLevelCost"},{"Show Total Training Cost","flyoutShowTrainingTotal"}}) do
        local key=spec[2]
        menuOptions[#menuOptions+1]={label=spec[1],get=function() return self.db[key]~=false end,set=function(v)
            self.db[key]=v
            if self.trainingFlyout and self.trainingFlyout:IsShown() and self:OutsideCombat() then self:RenderTrainingFlyout() end
        end}
    end
    page:ToggleGrid(menuOptions,{maxColumns=2})
    for _,spec in ipairs({{"Popout Background Opacity","flyoutOpacity",10,100,5},{"Popout Text Size","flyoutTextSize",10,18,1}}) do
        local key=spec[2]
        page.refreshers[#page.refreshers+1]=W.Slider(page:Row(spec[1],48),spec[3],spec[4],spec[5],
            function() return key=="flyoutOpacity" and self:FlyoutOpacity() or self:FlyoutTextSize() end,function(v)
                self.db[key]=v
                if self.trainingFlyout and self.trainingFlyout:IsShown() and self:OutsideCombat() then self:RenderTrainingFlyout() end
            end,key=="flyoutOpacity" and "%" or "")
    end
    page:Section("Upcoming Abilities")
    page:Section("Available & Known")
    page.trainingRows,page.levelHeaders={},{}
    page.activeSection=nil
    page.baseRows={}
    for _,row in ipairs(page.rows) do page.baseRows[#page.baseRows+1]=row end
    function page:EnsureCatalogRows()
    if self.catalogVersion==P.version or self.buildingRows then return end
    self.buildingRows=true;self.catalogVersion=P.version
    for _,item in ipairs(self.trainingRows) do item.record=nil;item.visible=false;item.control.row:Hide() end
    for _,heading in pairs(self.levelHeaders) do heading.row:Hide() end
    self.rows={};for _,row in ipairs(self.baseRows) do self.rows[#self.rows+1]=row end
    local priorLevel
    for i, record in ipairs(P.records) do
        if record.level ~= priorLevel then
            if not page.levelHeaders[record.level] then
            local heading = page:Row("", 34)
            heading.rowLabel:Hide(); heading:Hide()
            local text = W.Heading(heading.row, "Level " .. record.level, 20, 10, -7, 300, T.primary)
            page.levelHeaders[record.level] = {row=heading.row, label=text}
            local level = record.level
            heading.row.visibleWhen = function() return page.levelVisible and page.levelVisible[level] == true end
            else self.rows[#self.rows+1]=page.levelHeaders[record.level].row end
            priorLevel = record.level
        end
        if not page.trainingRows[i] then
        local control = page:Row("", 32, {"class", "training"})
        control.rowLabel:Hide(); control:ClearAllPoints(); control:SetAllPoints(control.row)
        local icon = control:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26); icon:SetPoint("LEFT", 9, 0); icon:SetTexCoord(0.07,0.93,0.07,0.93)
        local label = W.Label(control, "", nil, 0, 0, 250, T.text)
        label:ClearAllPoints(); label:SetPoint("LEFT", icon, "RIGHT", 9, 0)
        label:SetPoint("RIGHT", control, "RIGHT", -166, 0); label:SetWordWrap(false)
        local cost = W.Label(control, "", nil, 0, 0, 146, T.text)
        cost:ClearAllPoints(); cost:SetPoint("RIGHT", -10, 0); cost:SetJustifyH("RIGHT")
        local item = {control=control, label=label, icon=icon, cost=cost, record=record}
        control.row.visibleWhen = function() return item.visible == true end
        control.row:EnableMouse(true)
        control.row:SetScript("OnEnter", function(owner)
            if not GameTooltip then return end
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            if not item.record then return end
            local name = M:SpellPresentation(item.record); GameTooltip:SetText(name)
            GameTooltip:AddLine("Estimated price before trainer discounts.",0.7,0.7,0.7,true); GameTooltip:Show()
        end)
        control.row:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        page.trainingRows[i] = item
        else self.rows[#self.rows+1]=page.trainingRows[i].control.row end
        page.trainingRows[i].record=record
    end
    if self.emptyControl then self.rows[#self.rows+1]=self.emptyControl.row end
    self.buildingRows=false
    end
    page.emptyControl = page:Row("", 48); page.emptyControl.rowLabel:Hide()
    page.emptyLabel = W.Label(page.emptyControl.row, "", nil, 10, -12, 440, T.muted)
    page.emptyControl.row.visibleWhen = function() return page.visibleCount==0 and page.selectedSection and
        (page.selectedSection.title=="Upcoming Abilities" or page.selectedSection.title=="Available & Known") end
    W.SectionTabs(page)
    local selectTab=page.SelectSectionTab
    function page:SelectSectionTab(section)
        local index=type(section)=="number" and section or nil
        if not index then for i,s in ipairs(self.sections) do if s==section then index=i end end end
        if index==2 and (not M.active or M.db.levelAlerts==false) or index==3 and (not M.active or M.db.showShortcut==false) then return end
        selectTab(self,section)
    end
    page.sectionTabs:SetPoint("TOPLEFT"); page.sectionTabs:SetPoint("TOPRIGHT", -24, 0)
    page.scroll:ClearAllPoints(); page.scroll:SetPoint("TOPLEFT", 0, -38); page.scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    page.scrollbar:ClearAllPoints(); page.scrollbar:SetPoint("TOPRIGHT", -4, -42); page.scrollbar:SetPoint("BOTTOMRIGHT", -4, 4)
    function page:RenderTraining()
        if self.buildingRows then return end
        self:EnsureCatalogRows()
        local lookup = {}
        for _, result in ipairs(M.rows or {}) do lookup[result.record.id] = result end
        local title = self.selectedSection and self.selectedSection.title
        for i,key in pairs({[2]="levelAlerts",[3]="showShortcut"}) do
            local enabled=M.active and M.db[key]~=false
            self.sectionTabs.buttons[i]:SetEnabled(enabled);self.sectionTabs.buttons[i]:SetAlpha(enabled and 1 or 0.4)
            if not enabled and self.selectedSection==self.sections[i] then self:SelectSectionTab(1);title="General" end
        end
        self.visibleCount, self.levelVisible = 0, {}
        local stale = M.dirty or not M:OutsideCombat()
        self.statusLabel:SetText(not M.active and "Disabled" or ((M.message or "No spellbook data") .. (stale and " · Pending" or "")))
        self.totalLabel:SetText("Training total  " .. (M.rows and M:MoneyText(P.TrainingTotal(M.rows)) or "—"))
        self.refreshButton:SetEnabled(M.active == true and M:OutsideCombat())
        self.popupPreviewButton:SetEnabled(M.active and M.db.levelAlerts~=false and M:OutsideCombat())
        self.guildMessageStatus:SetText(M.guildDingStatus or "Manual guild draft after next level-up.")
        M:UpdateDingActions()
        for _, item in ipairs(self.trainingRows) do
            local result = item.record and lookup[item.record.id]
            local upcoming=result and result.tab~="Learned" and M.snapshot and M.snapshot.level and result.record.level>M.snapshot.level
            item.result,item.visible=result,result~=nil and ((title=="Upcoming Abilities" and upcoming) or (title=="Available & Known" and not upcoming))
            if item.visible then
                self.visibleCount = self.visibleCount + 1; self.levelVisible[item.record.level] = true
                local name, icon = M:SpellPresentation(item.record)
                item.icon:SetTexture(icon)
                item.label:SetText(name)
                item.cost:SetText(result.tab=="Learned" and (result.known and "Known" or "Superseded") or M:MoneyText(item.record.cost))
            end
        end
        self.emptyLabel:SetText(not M.active and "Enable Class Training to view your abilities." or
            (M.rows and "No abilities in this tab." or (M.message or "No spellbook data.")))
        self:Layout()
    end
    page.refreshers[#page.refreshers+1] = function() page:RenderTraining() end
    page.OnSectionTabChanged = function() page:RenderTraining() end
    page:SetScript("OnShow", function() if self.active then self:RefreshTraining() end end)
    self.trainingPage = page
    page:Finish()
    return page
end

function M:UpdateTrainingPage()
    if self.trainingPage and self.trainingPage:IsShown() and self:OutsideCombat() then self.trainingPage:Refresh() end
end
