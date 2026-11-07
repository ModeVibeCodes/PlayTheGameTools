local _, addon = ...
local M, P = addon.ForeverClassTraining, addon.ForeverTrainingData

function M:MoneyText(copper, full)
    local function coin(amount, name)
        return amount .. " |TInterface\\MoneyFrame\\UI-" .. name .. "Icon:12:12:0:0|t"
    end
    local gold, silver = math.floor(copper/10000), math.floor(copper/100)%100
    local text = (gold > 0 or full) and (coin(gold,"Gold") .. "  ") or ""
    if silver > 0 or gold > 0 or full then text = text .. coin(silver,"Silver") .. "  " end
    return text .. coin(copper%100,"Copper")
end

function M:OpenTraining(section)
    if not self:OutsideCombat() then return end
    if not addon.configWindow or not addon.configWindow:IsShown() then addon:ToggleConfig() end
    addon:SelectConfigPage("foreverClassTraining")
    local page=addon.configWindow and addon.configWindow.pages.foreverClassTraining
    if page and section then page:SelectSectionTab(section) end
end

local function number(value)
    local G = P.NewGuard(_G)
    return G:Public(value) and type(value)=="number" and value==value and math.abs(value)<10000
end

function M:CreateShortcut()
    if self.shortcut or not self:OutsideCombat() then return end
    local button = CreateFrame("Button", nil, UIParent)
    button:SetSize(40,40); button:SetFrameStrata("MEDIUM"); button:SetClampedToScreen(true)
    local pos = self.db.shortcutPosition
    local x,y = -180,-140
    if type(pos)=="table" and number(pos.x) and number(pos.y) then x,y=pos.x,pos.y end
    button:SetPoint("CENTER",UIParent,"CENTER",x,y)
    local icon = button:CreateTexture(nil,"ARTWORK"); icon:SetSize(32,32); icon:SetPoint("CENTER");button.icon=icon
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    icon:SetTexCoord(0.07,0.93,0.07,0.93)
    if icon.AddMaskTexture and button.CreateMaskTexture then
        local mask=button:CreateMaskTexture(); mask:SetAllPoints(icon)
        mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"); icon:AddMaskTexture(mask)
        button.mask=mask
    end
    button.openGlow=button:CreateTexture(nil,"BACKGROUND")
    button.openGlow:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    button.openGlow:SetSize(44,44);button.openGlow:SetPoint("CENTER")
    button.openGlow:SetVertexColor(0.25,0.9,0.4,0.2);button.openGlow:Hide()
    -- Native owned textures form a thin circular green ring, no bundled artwork.
    button.ring={}
    for i=1,48 do
        local angle=i*math.pi/24;local dot=button:CreateTexture(nil,"OVERLAY")
        dot:SetSize(1.5,1.5);dot:SetPoint("CENTER",button,"CENTER",18*math.cos(angle),18*math.sin(angle))
        dot:SetColorTexture(0.25,0.9,0.4,1)
        button.ring[i]=dot
    end
    button:SetMovable(true);button:RegisterForDrag("LeftButton");button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnDragStart",function()
        local G=P.NewGuard(_G);local ok,shift=G:Call(IsShiftKeyDown)
        if self:OutsideCombat() and ok and shift==true then self:CloseTrainingFlyout();button.wasDragged=true;button.moving=true;button:StartMoving() end
    end)
    button:SetScript("OnDragStop",function()
        button:StopMovingOrSizing();button.moving=false
        C_Timer.After(0,function() button.wasDragged=nil end)
        if not self:OutsideCombat() then return end
        local x,y=button:GetCenter();local px,py=UIParent:GetCenter()
        if number(x) and number(y) and number(px) and number(py) then
            self.db.shortcutPosition={x=x-px,y=y-py}
            button:ClearAllPoints();button:SetPoint("CENTER",UIParent,"CENTER",x-px,y-py)
        end
    end)
    button:SetScript("OnClick",function()
        if button.wasDragged then button.wasDragged=nil;return end
        self:ToggleTrainingFlyout()
    end)
    button:SetScript("OnEnter",function()
        if GameTooltip then
            GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:SetText("Class Training")
            GameTooltip:AddLine("Click to open · Shift-drag to move",0.8,0.8,0.8);GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnHide",function() self:CloseTrainingFlyout() end)
    self.shortcut=button
    self:ApplyShortcutSize()
end

function M:ShortcutSize()
    local value=self.db.shortcutSize
    return P.NewGuard(_G):Integer(value,24,72) and value or 40
end

function M:ApplyShortcutSize()
    if not self.shortcut or not self:OutsideCombat() then return end
    local b=self.shortcut;local size=self:ShortcutSize()
    if b.appliedSize==size then return end
    local diameter=size*0.9-2 -- inset from the ring's inner edge at every supported size
    if not b.mask then diameter=diameter/math.sqrt(2) end
    b.appliedSize=size;b:SetSize(size,size);b.icon:SetSize(diameter,diameter);b.openGlow:SetSize(size+4,size+4)
    for i,dot in ipairs(b.ring) do
        local angle=i*math.pi/24;dot:ClearAllPoints();dot:SetPoint("CENTER",b,"CENTER",size*0.45*math.cos(angle),size*0.45*math.sin(angle))
    end
end

function M:PopupValue(key)
    local ranges={popupWidth={420,600,440,20},popupScale={75,125,100,5},popupDetailSize={10,16,12,1},popupAbilitySize={10,16,12,1},popupTitleSize={22,34,28,1},popupOpacity={25,100,100,5}}
    local range=ranges[key];local value=self.db[key]
    if not range then return value~=false end
    local G=P.NewGuard(_G)
    if G:Integer(value,range[1],range[2]) and value%range[4]==0 then return value end
    return range[3]
end

function M:SetPopupOption(key,value)
    local flags={showLevelTime=true,showPlayerMoney=true,showProfessions=true,showSecondaryProfessions=true}
    local ranges={popupWidth={420,600,20},popupScale={75,125,5},popupDetailSize={10,16,1},popupAbilitySize={10,16,1},popupTitleSize={22,34,1},popupOpacity={25,100,5}}
    local G=P.NewGuard(_G);local range=ranges[key]
    if flags[key] then if not G:Public(value) or type(value)~="boolean" then return false end
    elseif not range or not G:Integer(value,range[1],range[2]) or value%range[3]~=0 then return false end
    if key=="showLevelTime" and value~=self.db[key] then self.lastLevelClock,self.lastClockLevel,self.levelDuration=nil,nil,nil end
    self.db[key]=value
    if self.dingWindow and self.dingWindow:IsShown() and self:OutsideCombat() then
        self:ShowDing(self.displayLevel,self.displayRows,self.displayPreview)
    end
    return true
end

function M:RecordLevelTime(level)
    if not self:PopupValue("showLevelTime") or self.lastClockLevel==level then return end
    local G=P.NewGuard(_G);local ok,now=G:Call(GetTime)
    self.levelDuration=nil
    if ok and G:Public(now) and type(now)=="number" and now==now and now>=0 and now<1e12 then
        if self.lastClockLevel==level-1 and self.lastLevelClock and now>=self.lastLevelClock then self.levelDuration=now-self.lastLevelClock end
        self.lastLevelClock,self.lastClockLevel=now,level
    else self.lastLevelClock,self.lastClockLevel=nil,nil end
end

function M:GuildDingText(level)
    local text="Ding "..level
    local duration=self.levelDuration;local G=P.NewGuard(_G)
    if not self:PopupValue("showLevelTime") or self.lastClockLevel~=level or not G:Public(duration) or
        type(duration)~="number" or not (duration>=0 and duration<1e12) then return text end
    duration=math.floor(duration)
    local elapsed
    if duration>=3600 then
        elapsed=string.format("%dh %02dm %02ds",math.floor(duration/3600),math.floor(duration/60)%60,duration%60)
    elseif duration>=60 then elapsed=string.format("%dm %02ds",math.floor(duration/60),duration%60)
    else elapsed=duration.."s" end
    return text..", that took me "..elapsed
end

function M:PopupDetails(preview)
    local lines={};local G=P.NewGuard(_G)
    if self:PopupValue("showLevelTime") then
        local duration=preview and 1458 or self.levelDuration
        if duration then
            duration=math.floor(duration)
            lines[#lines+1]=string.format("Time to level  %dh %02dm %02ds%s",math.floor(duration/3600),math.floor(duration/60)%60,duration%60,preview and " · Sample" or "")
        else lines[#lines+1]="Time to level  —  (needs two level-ups this session)" end
    end
    if self:PopupValue("showPlayerMoney") then
        local ok,money=G:Call(GetMoney)
        lines[#lines+1]="Money  "..(ok and G:Integer(money,0,1e12) and self:MoneyText(money,true) or "Unavailable")
    end
    if self:PopupValue("showProfessions") or self:PopupValue("showSecondaryProfessions") then
        -- Build-70790 SkillLine identities: Forever variants first, then legacy IDs.
        local groups={{2937,171},{2938,164},{2940,333},{2941,202},{2944,182},{2945,165},{2946,186},{2947,393},{2948,197}}
        if not self:PopupValue("showProfessions") then groups={} end
        if self:PopupValue("showSecondaryProfessions") then
            groups[#groups+1]={2939,185};groups[#groups+1]={2942,129};groups[#groups+1]={2943,356}
        end
        local fn=G:Get(C_SkillInfo,"GetSkillLineInfoByID");local count,unreadable=0,false
        for _,ids in ipairs(groups) do
            for _,id in ipairs(ids) do
                local ok,info=G:Call(fn,id)
                if not ok then unreadable=true
                elseif info~=nil then
                    local skill=G:Get(info,"skillID");local name=G:Get(info,"name")
                    local rank=G:Get(info,"rank");local maximum=G:Get(info,"maxRank")
                    local header=G:Get(info,"isHeader")
                    if skill==id and header==false and type(name)=="string" and G:Integer(rank,1,10000) and G:Integer(maximum,rank,10000) then
                        lines[#lines+1]=name:gsub("[\r\n|]"," "):sub(1,48).."  "..rank.." / "..maximum;count=count+1;break
                    else unreadable=true end
                end
            end
        end
        if count==0 then lines[#lines+1]=unreadable and "Professions unavailable" or "No known professions" end
    end
    return lines
end

function M:PreviewDing()
    if self.db.levelAlerts==false or not self:OutsideCombat() then return false end
    if not self:SelectPlayerCatalog() then return false end
    local G=P.NewGuard(_G);local _,_,_,race=G:Call(UnitRace,"player");local _,faction=G:Call(UnitFactionGroup,"player")
    local context={}
    if G:Integer(race,1,1000) then context.race=race end
    if faction=="Alliance" or faction=="Horde" then context.faction=faction end
    local rows={}
    for _,record in ipairs(P.records) do if record.level==14 and P.Applicable(record,context)==true then rows[#rows+1]={record=record} end end
    self:ShowDing(14,rows,true)
    return true
end

function M:ShowDing(level, rows, preview)
    if not self:OutsideCombat() then return end
    local W,T=addon.ConfigWidgets,addon.Theme
    if not self.dingWindow then
        local frame=CreateFrame("Frame",nil,UIParent);frame:SetSize(440,160)
        frame:SetPoint("CENTER",UIParent,"CENTER",-300,60)
        frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
        self.dingBackground=W.Texture(frame,"Window","BACKGROUND")
        local header=W.Texture(frame,"Header","BORDER",2,0.85)
        header:ClearAllPoints();header:SetPoint("TOPLEFT",2,-2);header:SetPoint("TOPRIGHT",-2,-2);header:SetHeight(84)
        W.Texture(frame,"BorderSilver","OVERLAY",0,0.9)
        local divider=W.Texture(frame,"AccentMint","ARTWORK",0,0.75)
        divider:ClearAllPoints();divider:SetPoint("TOPLEFT",22,-80);divider:SetPoint("TOPRIGHT",-22,-80);divider:SetHeight(1)
        self.dingTitle=W.Heading(frame,"DING",28,0,0,400,T.primary)
        self.dingTitle:ClearAllPoints();self.dingTitle:SetPoint("TOPLEFT",20,-17);self.dingTitle:SetPoint("TOPRIGHT",-20,-17)
        self.dingTitle:SetJustifyH("CENTER")
        self.dingSubtitle=W.Label(frame,"",nil,0,0,400,T.muted)
        self.dingSubtitle:ClearAllPoints();self.dingSubtitle:SetPoint("TOPLEFT",20,-53);self.dingSubtitle:SetPoint("TOPRIGHT",-20,-53)
        self.dingSubtitle:SetJustifyH("CENTER")
        self.dingRows={}
        self.dingDetails={}
        local close=W.Button(frame,"Close",104,30,"secondary");close:SetPoint("BOTTOMRIGHT",-20,14)
        W.Texture(close,"BorderSilver","OVERLAY",0,0.65)
        close:SetScript("OnClick",function() frame:Hide() end)
        local open=W.Button(frame,"Training",120,30,"button");open:SetPoint("BOTTOMLEFT",20,14)
        open:SetSelected(true)
        open:SetScript("OnClick",function() self:OpenTraining(5);frame:Hide() end)
        local guild=W.Button(frame,"Guild Message",122,30,"secondary")
        guild:SetScript("OnClick",function() self:PrepareGuildDing() end)
        self.dingClose,self.dingTraining,self.dingGuild=close,open,guild
        frame:Hide();self.dingWindow=frame
    end
    self.dingTitle:SetText("DING")
    addon.Media:BindInterfaceFont(self.dingTitle,GameFontNormalLarge,self:PopupValue("popupTitleSize"))
    self.dingBackground:SetAlpha(self:PopupValue("popupOpacity")/100)
    self.dingSubtitle:SetText("Level "..level..(preview and " · Preview" or ""))
    self.displayLevel,self.displayRows,self.displayPreview=level,rows,preview==true
    self:UpdateDingActions()
    local width=self:PopupValue("popupWidth")
    self.dingWindow:SetWidth(width);self.dingWindow:SetScale(self:PopupValue("popupScale")/100)
    for _,item in ipairs(self.dingRows) do item.frame:Hide() end
    local cursor=94
    for i,row in ipairs(rows) do
        local item=self.dingRows[i]
        if not item then
            local frame=CreateFrame("Frame",nil,self.dingWindow);frame:SetSize(400,30);frame:SetPoint("TOPLEFT",20,-94-(i-1)*34)
            W.Texture(frame,"InsetPanel","BACKGROUND",0,0.45)
            local icon=frame:CreateTexture(nil,"ARTWORK");icon:SetSize(24,24);icon:SetPoint("LEFT")
            local text=W.Label(frame,"",nil,32,-7,250,T.text)
            local cost=W.Label(frame,"",nil,0,0,120,T.text);cost:ClearAllPoints();cost:SetPoint("RIGHT");cost:SetJustifyH("RIGHT")
            text:SetWidth(230);text:SetWordWrap(true);cost:SetWordWrap(true)
            item={frame=frame,icon=icon,text=text,cost=cost};self.dingRows[i]=item
        end
        local name,icon=self:SpellPresentation(row.record)
        item.frame:ClearAllPoints();item.frame:SetPoint("TOPLEFT",20,-cursor)
        item.frame:SetWidth(width-40);item.text:SetWidth(width-210)
        addon.Media:BindInterfaceFont(item.text,GameFontHighlight,self:PopupValue("popupAbilitySize"))
        addon.Media:BindInterfaceFont(item.cost,GameFontHighlight,self:PopupValue("popupAbilitySize"))
        item.icon:SetTexture(icon);item.text:SetText(name);item.cost:SetText(self:MoneyText(row.record.cost));item.frame:Show()
        local h=math.max(30,item.text:GetStringHeight()+14,item.cost:GetStringHeight()+14)
        item.frame:SetHeight(h);cursor=cursor+h+4
    end
    for _,label in ipairs(self.dingDetails) do label:Hide() end
    local details=self:PopupDetails(preview)
    local detailSize=self:PopupValue("popupDetailSize");local lineHeight=detailSize+9
    local detailCursor=cursor+10
    for i,text in ipairs(details) do
        local label=self.dingDetails[i]
        if not label then label=W.Label(self.dingWindow,"",nil,0,0,400,T.muted);self.dingDetails[i]=label end
        label:ClearAllPoints();label:SetPoint("TOPLEFT",22,-detailCursor)
        label:SetWidth(width-44);label:SetWordWrap(true)
        addon.Media:BindInterfaceFont(label,GameFontHighlight,detailSize)
        label:SetText(text);label:Show()
        detailCursor=detailCursor+math.max(lineHeight,label:GetStringHeight()+8)
    end
    self.dingWindow:SetHeight(#details>0 and detailCursor+38 or cursor+48);self.dingWindow:Show()
end

function M:SetGuildDingStatus(text)
    self.guildDingStatus=text
    if self.trainingPage and self.trainingPage.guildMessageStatus then self.trainingPage.guildMessageStatus:SetText(text) end
end

function M:UpdateDingActions()
    local ready=self.active and self.db.levelAlerts~=false and self.db.guildDing~=false and self.guildDingDraft~=nil and self:OutsideCombat()
    if self.trainingPage and self.trainingPage.guildPrepareButton then self.trainingPage.guildPrepareButton:SetEnabled(ready==true) end
    if not self.dingWindow then return end
    local training=self.displayRows and #self.displayRows>0
    local guild=ready and not self.displayPreview and self.guildDingDraft.level==self.displayLevel
    self.dingTraining:SetShown(training==true);self.dingGuild:SetShown(guild==true)
    self.dingClose:ClearAllPoints();self.dingGuild:ClearAllPoints()
    if training then
        self.dingGuild:SetPoint("BOTTOM",0,14);self.dingClose:SetPoint("BOTTOMRIGHT",-20,14)
    elseif guild then
        self.dingGuild:SetPoint("BOTTOMLEFT",20,14);self.dingClose:SetPoint("BOTTOMRIGHT",-20,14)
    else self.dingClose:SetPoint("BOTTOM",0,14) end
end

function M:TryGuildDing()
    if not self.pendingGuildDing or not self:OutsideCombat() then return end
    local level=self.pendingGuildDing;self.pendingGuildDing=nil;self.guildDingDraft=nil
    if self.db.levelAlerts==false or self.db.guildDing==false then self:UpdateDingActions();return end
    local G=P.NewGuard(_G)
    local ok,inGuild=G:Call(IsInGuild)
    local allowed,canSpeak=G:Call(G:Get(C_GuildInfo,"CanSpeakInGuildChat"))
    if not ok or inGuild~=true or not allowed or canSpeak~=true then
        self:SetGuildDingStatus("Unavailable: guild chat permission.")
    else
        self.guildDingDraft={level=level,text=self:GuildDingText(level)}
        self:SetGuildDingStatus("Ready: click Guild Message, then press Enter.")
    end
    self:UpdateDingActions()
end

function M:PrepareGuildDing()
    if not self.active or self.db.levelAlerts==false or self.db.guildDing==false or not self.guildDingDraft or not self:OutsideCombat() then return false end
    local G=P.NewGuard(_G)
    local ok,inGuild=G:Call(IsInGuild)
    local allowed,canSpeak=G:Call(G:Get(C_GuildInfo,"CanSpeakInGuildChat"))
    if not ok or inGuild~=true or not allowed or canSpeak~=true then self:SetGuildDingStatus("Unavailable: guild chat permission.");return false end
    local readable,edit=G:Call(G:Get(ChatFrameUtil,"GetActiveWindow"))
    if not readable then self:SetGuildDingStatus("Unavailable: chat input.");return false end
    local valid,override=G:Call(G:Get(ChatFrameUtil,"GetChatFocusOverride"))
    if not valid then self:SetGuildDingStatus("Unavailable: chat input.");return false end
    for _,box in pairs({active=edit,override=override}) do
        local public,text=G:Call(G:Get(box,"GetText"),box)
        if not public or type(text)~="string" then self:SetGuildDingStatus("Unavailable: chat input.");return false end
        if text~="" then self:SetGuildDingStatus("Finish or clear your current chat draft first.");return false end
    end
    -- Only opens an editable /g draft from a button click. The player presses Enter.
    local opened=G:Call(G:Get(ChatFrameUtil,"OpenChat"),"/g "..self.guildDingDraft.text)
    self:SetGuildDingStatus(opened and "Prepared: review and press Enter to send." or "Unavailable: chat input.")
    return opened
end

function M:SyncTrainingDisplays()
    if not self.active or not self:OutsideCombat() then return end
    if self.snapshot and self.snapshot.class==P.class then
        self:CreateShortcut();self:ApplyShortcutSize();self.shortcut:SetShown(self.db.showShortcut~=false)
    elseif self.shortcut then self.shortcut:Hide() end
    if self.trainingFlyout and self.trainingFlyout:IsShown() then self:RenderTrainingFlyout() end
    -- The level event owns the celebration; readable training data only supplies optional rows.
    if self.pendingDing then
        local level=self.pendingDing;self.pendingDing=nil
        if self.db.levelAlerts~=false then
            local eligible={}
            local rows=self.snapshot and self.snapshot.level and self.snapshot.level>=level and self.rows or {}
            for _,row in ipairs(rows or {}) do
                if row.record.level==level and row.tab=="To Learn" and row.known==false and not row.uncertain then eligible[#eligible+1]=row end
            end
            self:ShowDing(level,eligible)
        end
    end
    self:TryGuildDing()
end
