local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M = { title="Character Panel", category="reskins", defaultEnabled=false,
    configDescription="Mode styling for your native character sheet. Configure outside combat." }
addon.CharacterReskin=M
addon:RegisterModule("characterReskin",M)
-- Deliberately no runtime implementation for the two later phases.
for _, entry in ipairs({{"damageMeterReskin","Damage Meters"},{"chatReskin","Chat Window"}}) do
    addon:RegisterModule(entry[1],{title=entry[2],category="reskins",defaultEnabled=false,planned=true,
        configDescription="Planned phase. Character Panel is the current refinement target."})
end
local D=addon.ForeverRogueData -- shared guarded reads, independent of Rogue enable state/class
M.defaults={quickStats=true,enhancements=true,font="game",fontMedia="",fontSize=11,outline=false,shadow=true,
    textColor={212/255,212/255,212/255},accentColor={0,240/255,1},
    enchantColor={127/255,219/255,151/255},imbueColor={230/255,184/255,1},
    panelColor={35/255,35/255,35/255},panelOpacity=100,titleSize=15,portraitSize=28,itemBorderSize=2,
    quickStatsX=6,quickStatsY=0,quickStatsWidth=116,
    -- Retired pilot fields remain valid for old profiles; the UI exposes only
    -- settings used by the current character-panel presentation.
    backgroundColor={42/255,42/255,42/255},foregroundColor={53/255,53/255,53/255},borderColor={179/255,179/255,179/255},
    backgroundOpacity=100,foregroundOpacity=80,borderOpacity=65,texture="mode",border="thin",borderSize=1,
    padding=0,borderX=0,borderY=0,statsX=140,statsY=-4,statsWidth=116,statsAlign="LEFT",statsAnchor="TOPLEFT",
    enchantX=5,enchantY=0,enchantWidth=76,enchantAlign="AUTO"}
M.ranges={fontSize={8,22,1},backgroundOpacity={0,100,1},foregroundOpacity={0,100,1},borderOpacity={0,100,1},
    panelOpacity={0,100,1},titleSize={12,24,1},portraitSize={20,40,1},itemBorderSize={1,4,1},
    quickStatsX={0,120,1},quickStatsY={-150,100,1},quickStatsWidth={90,220,1},
    borderSize={1,12,1},padding={0,20,1},borderX={-30,30,1},borderY={-30,30,1},statsX={-150,250,1},
    statsY={-350,50,1},statsWidth={80,240,1},enchantX={-60,80,1},enchantY={-30,30,1},enchantWidth={40,160,1}}
function M.Initialize(db)
    for key,default in pairs(M.defaults) do
        if db[key]==nil then db[key]=addon.ProfileCodec.Copy(default) end
        local v=db[key];assert(D.Public(v) and type(v)==type(default),"Invalid character reskin setting: "..key)
        local r=M.ranges[key]
        if r then assert(D.Number(v,r[1],r[2]) and v==math.floor(v),"Invalid character reskin range: "..key) end
        if type(default)=="table" then for i=1,3 do assert(D.Number(v[i],0,1),"Invalid character reskin color") end end
    end
    assert(({LEFT=true,CENTER=true,RIGHT=true})[db.statsAlign],"Invalid stats alignment")
    assert(({TOPLEFT=true,TOP=true,TOPRIGHT=true})[db.statsAnchor],"Invalid stats anchor")
    assert(({AUTO=true,LEFT=true,CENTER=true,RIGHT=true})[db.enchantAlign],"Invalid enhancement alignment")
end
function M:CanConfigure() return D.OutsideCombat() end
function M:SetAppearance(key,value)
    if not self:CanConfigure() or self.defaults[key]==nil then return false end
    local copy=addon.ProfileCodec.Copy(self.db);copy[key]=value
    if not pcall(self.Initialize,copy) then return false end
    self.db[key]=addon.ProfileCodec.Copy(value);self:Refresh()
    if self.page then self.page:Refresh() end
    return true
end
function M:GetFonts() return addon.Media:GetFonts() end
function M:OnInitialize()
    self.Initialize(self.db);self.surfaces={};self.savedAlpha={};self.savedFonts={};self.labels={}
    self.savedGeometry={};self.decorations={};self.buttonSkins={};self.itemBorders={}
end
function M:HideArt(region)
    if not region or not region.GetAlpha then return end
    if self.savedAlpha[region]==nil then self.savedAlpha[region]=region:GetAlpha() end
    region:SetAlpha(0)
end
function M:HideTextures(host)
    if not host or not host.GetRegions then return end
    for _,r in ipairs({host:GetRegions()}) do if r:IsObjectType("Texture") then self:HideArt(r) end end
end
function M:Font(text,color,size)
    local db=self.db
    local path=addon.Media:GetFont(db.fontMedia) or (db.fontMedia=="" and addon.Media:GetDisplayFont(db,true))
        or addon.Media:GetFont("Expressway") or addon.Media.gameFont
    if text:SetFont(path,size or db.fontSize,db.outline and "OUTLINE" or "")==false then
        text:SetFont(addon.Media.gameFont,size or db.fontSize,db.outline and "OUTLINE" or "")
    end
    text:SetTextColor(unpack(color or db.textColor));text:SetShadowColor(0,0,0,db.shadow and .85 or 0)
    text:SetShadowOffset(db.shadow and 1 or 0,db.shadow and -1 or 0)
end
function M:Surface(host,foreground)
    if not host then return end
    local s=self.surfaces[host]
    if not s then
        s=CreateFrame("Frame",nil,host,"BackdropTemplate");s:SetFrameLevel(math.max(0,host:GetFrameLevel()-1));s:EnableMouse(false)
        s.fill=s:CreateTexture(nil,"BACKGROUND",nil,-8);s.fill:SetAllPoints()
        s.line=s:CreateTexture(nil,"BORDER");s.line:SetPoint("TOPLEFT",1,-1);s.line:SetPoint("TOPRIGHT",-1,-1);s.line:SetHeight(1)
        self.surfaces[host]=s
    end
    local db=self.db;local p=0
    -- Backdrop edges are inside this expanded rectangle: inner edge begins at the host's outer edge.
    local edge={kind="thin",edgeSize=1}
    local size=db.borderSize
    s:ClearAllPoints();s:SetPoint("TOPLEFT",host,"TOPLEFT",-p-size,p+size)
    s:SetPoint("BOTTOMRIGHT",host,"BOTTOMRIGHT",p+size,-p-size)
    local ok=pcall(s.SetBackdrop,s,{edgeFile=edge.path or "Interface\\Buttons\\WHITE8X8",edgeSize=size>0 and size or 1})
    if not ok then s:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=size>0 and size or 1}) end
    s:SetBackdropBorderColor(db.borderColor[1],db.borderColor[2],db.borderColor[3],size>0 and db.borderOpacity/100 or 0)
    if not addon.Media:ApplyTexture(s.fill,"ModeSurface") then s.fill:SetColorTexture(1,1,1,1) end
    local c=db.panelColor
    s.fill:SetVertexColor(c[1],c[2],c[3],db.panelOpacity/100)
    s.line:SetColorTexture(db.borderColor[1],db.borderColor[2],db.borderColor[3],db.borderOpacity/100)
    s:Show()
end
function M:StyleNativeFonts(host)
    if not host then return end
    for _,r in ipairs({host:GetRegions()}) do
        if r:IsObjectType("FontString") then
            if not self.savedFonts[r] then
                self.savedFonts[r]={font={r:GetFont()},color={r:GetTextColor()},shadow={r:GetShadowColor()},offset={r:GetShadowOffset()}}
            end
            self:Font(r)
        end
    end
end
function M:StyleStats(host,depth)
    if not host or depth>6 then return end
    self:StyleNativeFonts(host)
    -- Only decorative stat art, preserving scrollbar thumbs and control glyphs.
    for _,r in ipairs({host:GetRegions()}) do
        if r:IsObjectType("Texture") then
            local atlas=D.Call(r.GetAtlas,r)
            if type(atlas)=="string" and (atlas:find("UI-Character-Info-Stat",1,true) or atlas:find("UI-Character-Info-Line",1,true)) then self:HideArt(r) end
            if atlas=="UI-Character-Info-Title" then self:HideArt(r);self:Surface(host,true) end
        end
    end
    for _,child in ipairs({host:GetChildren()}) do
        if not child:IsObjectType("Button") then self:StyleStats(child,depth+1) end
    end
end
function M:Restore()
    for r,a in pairs(self.savedAlpha) do r:SetAlpha(a) end
    for r,v in pairs(self.savedFonts) do r:SetFont(unpack(v.font));r:SetTextColor(unpack(v.color));r:SetShadowColor(unpack(v.shadow));r:SetShadowOffset(unpack(v.offset)) end
    self.savedAlpha={};self.savedFonts={}
    self:RestoreChrome()
    for _,s in pairs(self.surfaces) do s:Hide() end
    for _,text in pairs(self.labels) do text:Hide() end
    if self.stats then self.stats:Hide() end
end
M.slots={{"Head",1,"left"},{"Neck",2,"left"},{"Shoulder",3,"left"},{"Back",15,"left"},
    {"Chest",5,"left"},{"Shirt",4,"left"},{"Tabard",19,"left"},{"Wrist",9,"left"},
    {"Hands",10,"right"},{"Waist",6,"right"},{"Legs",7,"right"},{"Feet",8,"right"},
    {"Finger0",11,"right"},{"Finger1",12,"right"},{"Trinket0",13,"right"},{"Trinket1",14,"right"},
    {"MainHand",16,"bottom"},{"SecondaryHand",17,"bottom"},{"Ranged",18,"bottom"}}
function M:Refresh()
    if not D.OutsideCombat() then self.pending=true;return end
    self.pending=nil
    if not self.active then self:Restore();if self.events then self.events:UnregisterAllEvents() end;return end
    local root,paper=_G.CharacterFrame,_G.PaperDollFrame
    if not root or not paper then self.status="Waiting for the native character panel.";return end
    if not self.hooked then
        paper:HookScript("OnShow",function() if self.active then self:Refresh() end end)
        root:HookScript("OnShow",function() if self.active then self:Refresh() end end)
        root:HookScript("OnHide",function() if self.active then self:Refresh() end end)
        paper:HookScript("OnHide",function() if self.active then self:Refresh() end end)
        self.hooked=true
    end
    if not root:IsShown() or not paper:IsShown() then self:Restore();return end
    self:HideTextures(root);self:HideTextures(root.NineSlice);self:Surface(root)
    for _,host in pairs({root.LeftPaneHost,root.RightPaneHost,paper.TopBackgroundStripHost}) do
        self:HideTextures(host);self:Surface(host,true);self:StyleNativeFonts(host)
    end
    self:StyleNativeFonts(root.TitleContainer)
    self:StyleNativeFonts(_G.PaperDollLevelInfo)
    local stats=D.Call(function() return root:GetStatsPane() end)
    if stats then
        self:HideTextures(stats);self:Surface(stats)
        self:StyleStats(stats,0)
        if not self.statsHooked and type(stats.ScrollBoxOnUpdate)=="function" and type(hooksecurefunc)=="function" then
            hooksecurefunc(stats,"ScrollBoxOnUpdate",function()
                if self.active and D.OutsideCombat() and root:IsShown() and paper:IsShown() then self:StyleStats(stats,0) end
            end)
            self.statsHooked=true
        end
    end
    local model=paper.CharacterModelScene or _G.CharacterModelScene
    if model then self:HideTextures(model) end
    for _,entry in ipairs(self.slots) do
        local slot=_G["Character"..entry[1].."Slot"]
        if slot then self:HideTextures(slot.BorderFrame);self:StyleItem(slot,entry[2]) end
    end
    self:StyleChrome(root,paper,model)
    self:UpdateStats(model or paper);self:UpdateEnhancements()
    self.status="Active. Native equipment buttons and model controls retained."
end
function M:OnEnable()
    self.active=true;self.events=self.events or CreateFrame("Frame")
    self.events:UnregisterAllEvents()
    for _,e in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_EQUIPMENT_CHANGED",
        "UNIT_STATS","UNIT_AURA","COMBAT_RATING_UPDATE","UNIT_ATTACK_POWER","UNIT_DAMAGE","GET_ITEM_INFO_RECEIVED","WEAPON_ENCHANT_CHANGED"}) do self.events:RegisterEvent(e) end
    self.events:SetScript("OnEvent",function(_,event,unit)
        if event:sub(1,5)=="UNIT_" and unit~="player" then return end
        if event=="PLAYER_REGEN_ENABLED" or event=="ADDON_LOADED" or not self.hooked or (_G.CharacterFrame and CharacterFrame:IsShown() and _G.PaperDollFrame and PaperDollFrame:IsShown()) then self:Refresh() end
    end)
    self:Refresh()
end
function M:OnDisable()
    self.active=false
    if D.OutsideCombat() then self:Restore();self.events:UnregisterAllEvents()
    else self.pending=true;self.events:UnregisterAllEvents();self.events:RegisterEvent("PLAYER_REGEN_ENABLED") end
end
