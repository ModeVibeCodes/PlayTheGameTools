local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- One standard map data provider on WorldMapFrame. Whenever the map shows or
-- changes zone, Blizzard calls RefreshAllData and we place one pin per label
-- for that map. Pins are plain (non-secure) frames; only attaching the
-- provider waits for the end of combat. The map addon is never force-loaded.
local Map={}
addon.CityLabelsMap=Map
local TEMPLATE="PlayTheGameToolsCityLabelsMapPinTemplate"
local FLAT="Interface\\Buttons\\WHITE8X8"
local CREDIT="Locations: Efficient Games (CC BY 4.0)"
local CLASSIC_CREDIT="Location: CMaNGOS classic-db (GPL-3.0)"
local COLORS={
    classTrainer={1,.82,0}, professionTrainer={.45,.75,1}, weaponMaster={.86,.6,.35},
    bank={1,.86,.3}, auctionHouse={1,.55,.2}, inn={.45,.85,.45}, flightMaster={.3,.9,.9},
    otherService={.78,.55,1}, stableMaster={.8,.66,.46}, mailbox={.88,.88,.88},
    repair={.72,.74,.8}, vendor={.62,.62,.62},
}
Map.COLORS=COLORS

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function InCombat()
    for _,fn in ipairs({InCombatLockdown,UnitAffectingCombat}) do
        if type(fn)=="function" then
            local ok,value=pcall(fn,"player")
            if not ok or not Public(value) or value~=false then return true end
        end
    end
    return false
end

local Pin={}
_G.PlayTheGameToolsCityLabelsMapPinMixin=Pin
function Pin:OnLoad()
    -- Icon inside a one-pixel edge in the service color; a colored dot instead
    -- when none of the entry's icons exists on this client.
    self.edge=self:CreateTexture(nil,"BORDER")
    self.edge:SetAllPoints(self);self.edge:SetTexture(FLAT)
    self.icon=self:CreateTexture(nil,"ARTWORK")
    self.icon:SetPoint("TOPLEFT",1,-1);self.icon:SetPoint("BOTTOMRIGHT",-1,1)
    self.icon:SetTexCoord(.08,.92,.08,.92)
    self.dot=self:CreateTexture(nil,"ARTWORK")
    self.dot:SetAllPoints(self)
    local path=addon.Media:GetTexture("RoundMarker")
    if not path or self.dot:SetTexture(path)==false then self.dot:SetTexture(FLAT) end
    self.text=self:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    self.text:SetPoint("LEFT",self,"RIGHT",3,0)
    self.text:SetJustifyH("LEFT");self.text:SetWordWrap(false)
    -- Hover shows details; clicks fall through so the map still zooms.
    if type(self.SetMouseClickEnabled)=="function" then self:SetMouseClickEnabled(false) end
end
function Pin:OnAcquired(entry,style)
    self.entry=entry
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    -- Constant on-screen size at every zoom level, like the Dungeon Loot marker.
    self:SetIgnoreGlobalPinScale(true)
    self:SetScalingLimits(1,1,1)
    self:SetSize(style.iconSize,style.iconSize)
    local color=COLORS[entry.kind] or COLORS.vendor
    if entry.kind=="classTrainer" and type(RAID_CLASS_COLORS)=="table" and RAID_CLASS_COLORS[entry.class] then
        local c=RAID_CLASS_COLORS[entry.class];color={c.r,c.g,c.b}
    end
    self.dot:SetVertexColor(color[1],color[2],color[3],1)
    self.edge:SetVertexColor(color[1],color[2],color[3],1)
    local hasIcon=false
    for _,icon in ipairs(entry.icons or {}) do
        if self.icon:SetTexture(icon)~=false then hasIcon=true;break end
    end
    -- Trim the icons' built-in border; reapplied after each texture change.
    self.icon:SetTexCoord(.08,.92,.08,.92)
    self.icon:SetShown(hasIcon);self.edge:SetShown(hasIcon);self.dot:SetShown(not hasIcon)
    local base=GameFontHighlightSmall or GameFontHighlight
    local font,_,flags
    if base then font,_,flags=base:GetFont() end
    if font then self.text:SetFont(font,style.fontSize,flags and flags~="" and flags or "OUTLINE") end
    self.text:SetText(entry.label)
    self.text:SetShown(entry.showName==true)
    self:SetPosition(entry.x,entry.y)
    self:ApplyCurrentScale()
end
function Pin:OnReleased()
    MapCanvasPinMixin.OnReleased(self)
    self.entry=nil
end
function Pin:OnMouseEnter()
    local entry=self.entry
    if not entry or not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(entry.label)
    for name in tostring(entry.names or ""):gmatch("[^\n]+") do GameTooltip:AddLine(name,1,1,1) end
    if entry.classic then
        GameTooltip:AddLine("Classic position: may differ where Forever moved an NPC.",.6,.6,.6,true)
        GameTooltip:AddLine(CLASSIC_CREDIT,.5,.5,.5)
    else
        GameTooltip:AddLine("Approximate: where players stood to use it.",.6,.6,.6,true)
        GameTooltip:AddLine(CREDIT,.5,.5,.5)
    end
    GameTooltip:Show()
end
function Pin:OnMouseLeave() if GameTooltip then GameTooltip:Hide() end end

-- Blizzard's map pieces must exist before we can compose the pin and provider.
function Map:Supported(map)
    return map and type(map.AddDataProvider)=="function" and type(map.AcquirePin)=="function"
        and type(map.RemoveAllPinsByTemplate)=="function" and type(map.GetMapID)=="function"
        and MapCanvasPinMixin and MapCanvasDataProviderMixin and type(CreateFromMixins)=="function"
end

function Map:Render()
    local map=self.map
    if not map then return end
    map:RemoveAllPinsByTemplate(TEMPLATE)
    local M=addon.CityLabels
    if not M.active or not map:IsShown() then return end
    local style={iconSize=M.db.iconSize,fontSize=M.db.fontSize}
    for _,entry in ipairs(M:Entries(map:GetMapID())) do map:AcquirePin(TEMPLATE,entry,style) end
end

-- Drawing failures are reported once and leave the rest of the map working.
function Map:RefreshAllData()
    local ok,reason=pcall(self.Render,self)
    if ok then self.lastError=nil;return true end
    if self.map then pcall(self.map.RemoveAllPinsByTemplate,self.map,TEMPLATE) end
    local message="Map Labels could not draw on this map: "..(Public(reason) and tostring(reason):sub(1,200) or "unknown error")
    if self.lastError~=message then print("Play The Game Tools: "..message) end
    self.lastError=message
    return false
end

function Map:Attach()
    if self.provider or not addon.CityLabels.active then return true end
    local map=WorldMapFrame
    if not map then self:Watch("ADDON_LOADED");return false end
    if InCombat() then self:Watch("PLAYER_REGEN_ENABLED");return false end
    if not self:Supported(map) then
        self.lastError="The world map on this client does not accept add-on labels."
        return false
    end
    if C_XMLUtil and type(C_XMLUtil.GetTemplateInfo)=="function" and not C_XMLUtil.GetTemplateInfo(TEMPLATE) then
        self.lastError="Map label template is missing. Restart WoW to load the updated addon files."
        return false
    end
    for key,value in pairs(MapCanvasPinMixin) do if Pin[key]==nil then Pin[key]=value end end
    local provider=CreateFromMixins(MapCanvasDataProviderMixin)
    provider.RefreshAllData=function() self:RefreshAllData() end
    provider.RemoveAllData=function() if self.map then self.map:RemoveAllPinsByTemplate(TEMPLATE) end end
    self.map,self.provider=map,provider
    if self.events then self.events:UnregisterAllEvents() end
    map:AddDataProvider(provider)
    return true
end

-- Wait for the map addon to load, or for combat to end, then attach once.
function Map:Watch(event)
    if not self.events then
        self.events=CreateFrame("Frame")
        self.events:SetScript("OnEvent",function(_,name,loaded)
            if name=="ADDON_LOADED" and loaded~="Blizzard_WorldMap" then return end
            self.events:UnregisterAllEvents()
            if self:Attach() then self:Refresh() end
        end)
    end
    self.events:UnregisterAllEvents()
    self.events:RegisterEvent(event)
end

function Map:Refresh()
    if self.provider and self.map and self.map:IsShown() then self:RefreshAllData() end
end

function Map:Clear()
    if self.events then self.events:UnregisterAllEvents() end
    local owner=GameTooltip and type(GameTooltip.GetOwner)=="function" and GameTooltip:GetOwner()
    if owner and owner.pinTemplate==TEMPLATE then GameTooltip:Hide() end
    if self.map then pcall(self.map.RemoveAllPinsByTemplate,self.map,TEMPLATE) end
end
