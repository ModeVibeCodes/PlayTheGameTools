local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local M, SOFT = addon.LootSparkles, "softinteract"

-- Cursor paths/atlases and numeric file IDs are all used by Forever builds.
-- Do not inspect hidden tooltip data or guess quest status from object names.
function M:CursorCategory(unit)
    if not self.probe then self.probe=UIParent:CreateTexture(nil,"BACKGROUND"); self.probe:Hide() end
    if self.Read(SetUnitCursorTexture,self.probe,unit,nil,true) ~= true then return end
    if not self.cursorIDs then
        self.cursorIDs={}
        for _,entry in ipairs({{"Mine","ore"},{"GatherHerbs","herbs"},{"Quest","questObjects"},
            {"QuestRepeatable","questObjects"},{"QuestTurnIn","questObjects"}}) do
            for _,prefix in ipairs({"","Unable"}) do
                local path="Interface\\Cursor\\"..prefix..entry[1]
                local id=self.Read(GetFileIDFromPath,path) or self.Read(GetFileIDFromPath,path..".blp")
                if type(id)=="number" then self.cursorIDs[id]={entry[2],prefix~=""} end
            end
        end
    end
    local texture=self.Read(self.probe.GetTexture,self.probe)
    if type(texture)=="number" and self.cursorIDs[texture] then
        return unpack(self.cursorIDs[texture])
    end
    for _,value in ipairs({texture or false,self.Read(self.probe.GetAtlas,self.probe) or false}) do
        if type(value)=="string" then
            value=value:lower()
            local blocked=value:find("unable",1,true)~=nil
            if value:find("mine",1,true) then return "ore",blocked end
            if value:find("gather",1,true) then return "herbs",blocked end
            if value:find("quest",1,true) then return "questObjects",blocked end
        end
    end
end
function M:Classify(unit)
    if self.Read(UnitIsGameObject,unit)==true then
        local category, blocked=self:CursorCategory(unit)
        if not category and self.Read(C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest,unit)==true then
            category="questObjects"
        end
        return category,blocked
    end
    if not self.db.corpses or self.Read(UnitIsDead,unit)~=true or type(CanLootUnit)~="function" then return end
    local guid=self.Read(UnitGUID,unit)
    if type(guid)~="string" then return end
    local ok,hasLoot,canLoot=pcall(CanLootUnit,guid)
    if ok and self.Public(hasLoot) and self.Public(canLoot) and hasLoot==true and canLoot==true then return "corpses",false end
end
function M:Resolve()
    local plate=self.Read(C_NamePlate and C_NamePlate.GetNamePlateForUnit,SOFT)
    if plate then return SOFT,plate end
    -- Never attach to an arbitrary object nameplate. A fallback must be the
    -- same native interaction target, even when multiple nodes are visible.
    for unit in pairs(self.units) do
        if self.Read(UnitIsUnit,unit,SOFT)==true then
            plate=self.Read(C_NamePlate and C_NamePlate.GetNamePlateForUnit,unit)
            if plate then return unit,plate end
        end
    end
    return SOFT,nil
end
function M:Evaluate()
    if not self.nodes or not self:OutsideCombat() then self:Release(); return end
    if self:GetCVar("SoftTargetInteract")=="0" or self:GetCVar("SoftTargetIconGameObject")~="1" then
        self:Release(); return
    end
    local unit,plate=self:Resolve()
    local category,blocked=self:Classify(unit)
    if not category or not self.db[category] then self:Gate(false); self:Release(); return end
    if not self:Gate(true) then self:Release(); return end
    if not plate then self:Release(); return end
    if self.Read(plate.IsForbidden,plate)==true or self.Read(plate.CanBeAccessedInContext,plate)==false then
        self:Release(); return
    end
    local range=self.Read(UnitIsInInteractRange,unit)
    local state=blocked and "Unavailable" or (range==true and "In reach" or (range==false and "Out of reach" or "Range unknown"))
    local name=self.Read(UnitName,unit)
    self:ShowTarget(plate,type(name)=="string" and name or "",state)
end
