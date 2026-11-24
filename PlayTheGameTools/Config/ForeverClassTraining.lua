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
    -- No Refresh button: SPELLS_CHANGED, LEARNED_SPELL_IN_SKILL_LINE, trainer and
    -- level events (and opening this page) re-read the spellbook outside combat.
    local general=page:Section("General")
    local function applyFeature(key,value)
        self.db[key]=value
        if key=="levelAlerts" and not value then
            self.pendingDing,self.pendingGuildDing=nil,nil
            self.guildDingDraft=nil
            self.guildDingStatus=nil
            self:ResetLevelTime()
            if self.dingWindow then self.dingWindow:Hide() end
        elseif key=="levelAlerts" then self:RequestLevelPlayed() end
        self:SyncTrainingDisplays()
    end
    -- While the module is on, its shortcut is in the Quick Actions ring.
    page:ToggleGrid({
        {label="Level Up Window",get=function() return self.db.levelAlerts~=false end,set=function(v) applyFeature("levelAlerts",v) end},
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
    page.emptyControl.row.visibleWhen = function() return page.visibleCount==0 end
    -- One scroll: Level Up Window shows while its window is on, and Shortcut
    -- Icon & Menu follows the module switch alone.
    local upcomingSection, knownSection = page.sections[4], page.sections[5]
    for _,row in ipairs(page.baseRows) do
        local index
        for i,section in ipairs(page.sections) do if row.section==section then index=i end end
        local visible=row.visibleWhen
        if index==2 then row.visibleWhen=function() return M.active and M.db.levelAlerts~=false and (not visible or visible()) end
        elseif index==3 then row.visibleWhen=function() return M.active and (not visible or visible()) end end
    end
    -- Upcoming abilities list under their heading and the rest under
    -- Available & Known; each level heading goes with its first ability.
    local function PlaceCatalog(self)
        local lists, levelSection, headed = {[upcomingSection]={}, [knownSection]={}}, {}, {}
        for i, record in ipairs(P.records) do
            local item = self.trainingRows[i]
            if item and item.visible and not levelSection[record.level] then
                levelSection[record.level] = item.upcoming and upcomingSection or knownSection
            end
        end
        for i, record in ipairs(P.records) do
            local item = self.trainingRows[i]
            local heading = self.levelHeaders[record.level]
            local section = item and item.upcoming and upcomingSection or knownSection
            if heading and not headed[record.level] then
                headed[record.level] = true
                local target = levelSection[record.level] or knownSection
                heading.row.section = target; table.insert(lists[target], heading.row)
            end
            if item then item.control.row.section = section; table.insert(lists[section], item.control.row) end
        end
        self.emptyControl.row.section = knownSection
        table.insert(lists[knownSection], self.emptyControl.row)
        self.rows = {}
        for _, row in ipairs(self.baseRows) do
            self.rows[#self.rows+1] = row
            for _, listed in ipairs(row.sectionHeader and lists[row.section] or {}) do self.rows[#self.rows+1] = listed end
        end
    end
    function page:RenderTraining()
        if self.buildingRows then return end
        self:EnsureCatalogRows()
        local lookup = {}
        for _, result in ipairs(M.rows or {}) do lookup[result.record.id] = result end
        self.visibleCount, self.levelVisible = 0, {}
        local stale = M.dirty or not M:OutsideCombat()
        self.statusLabel:SetText(not M.active and "" or ((M.message or "No spellbook data") .. (stale and " · Pending" or "")))
        self.totalLabel:SetText("Training total  " .. (M.rows and M:MoneyText(P.TrainingTotal(M.rows)) or "—"))
        self.popupPreviewButton:SetEnabled(M.active and M.db.levelAlerts~=false and M:OutsideCombat())
        self.guildMessageStatus:SetText(M.guildDingStatus or "Manual guild draft after next level-up.")
        M:UpdateDingActions()
        for _, item in ipairs(self.trainingRows) do
            local result = item.record and lookup[item.record.id]
            local upcoming=result and result.tab~="Learned" and M.snapshot and M.snapshot.level and result.record.level>M.snapshot.level
            item.result,item.visible,item.upcoming=result,result~=nil,upcoming and true or false
            if item.visible then
                self.visibleCount = self.visibleCount + 1; self.levelVisible[item.record.level] = true
                local name, icon = M:SpellPresentation(item.record)
                item.icon:SetTexture(icon)
                item.label:SetText(name)
                item.cost:SetText(result.tab=="Learned" and (result.known and "Known" or "Superseded") or M:MoneyText(item.record.cost))
            end
        end
        self.emptyLabel:SetText(not M.active and "Enable Class Training to view your abilities." or
            (M.rows and "No abilities to show." or (M.message or "No spellbook data.")))
        PlaceCatalog(self)
        self:Layout()
    end
    page.refreshers[#page.refreshers+1] = function() page:RenderTraining() end
    page:SetScript("OnShow", function() if self.active then self:RefreshTraining() end end)
    self.trainingPage = page
    page:Finish()
    return page
end

function M:UpdateTrainingPage()
    if self.trainingPage and self.trainingPage:IsShown() and self:OutsideCombat() then self.trainingPage:Refresh() end
end
