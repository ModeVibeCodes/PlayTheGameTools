local _, addon = ...
if not addon.Edition or addon.Edition.name~="Forever" then return end
-- Adapter code is original PlayTheGameTools code. Its separately marked data inputs
-- are GPLv3. Combined distributions retain those terms; see CATALOG_SOURCES.md.
local C={Data={},source="Bundled dungeon catalog · Lootified 1.2.0"}
addon.DungeonLootCatalog=C
local function Array(v) return type(v)=="table" and v or {} end
local function Item(id,data)
    local text=data.Items[id] or ("Item "..id.."||")
    local name,slot=text:match("^([^|]*)|([^|]*)")
    return {id,name~="" and name or ("Item "..id),slot~="" and slot or nil}
end
local function Items(ids,data)
    local result={}
    for _,id in ipairs(Array(ids)) do result[#result+1]=Item(id,data) end
    return result
end
local function LocationText(loc,text)
    if text and text~="" then return text end
    loc=Array(loc)
    if loc.name then return loc.name..(loc.zone and (", "..loc.zone) or "") end
    return loc.text
end
function C:Location(loc,text,name,entrance)
    loc=Array(loc)
    local L=addon.DungeonLootLocations
    if loc.map and type(loc.x)=="number" and type(loc.y)=="number" then
        return L:Point({mapID=loc.map,x=loc.x/100,y=loc.y/100,label=loc.name or text,detail=loc.zone})
    end
    if loc.w then
        local point=L:WorldPoint(loc.w,loc.name or text)
        if point then return point end
    end
    local inside=loc.zone or text
    if inside then return L:Interior(inside,name,entrance) end
end
-- Cheap restriction metadata for every card; never resolves maps or rewards.
function C:QuestHeader(id)
    local q=self.Data.Quests[id] or {}
    local classes={}
    for _,token in ipairs(Array(q.classes)) do classes[#classes+1]=token:upper() end
    return {id=id,faction=({A="Alliance",H="Horde",B="Both"})[q.side],
        classes=classes,classOnly=#classes==1 and classes[1] or nil,logIDs=self.QuestLogAliases and self.QuestLogAliases[id]}
end
function C:Quest(id,context)
    local q=self.Data.Quests[id]
    if not q then return {id=id,name="Quest "..id,warning="Details are not recorded for this prerequisite."} end
    local start,finish=Array(q.start),Array(q.finish)
    local header=self:QuestHeader(id)
    local result={id=id,name=q.name,level=q.level,requires=q.min,objective=q.obj,classes=header.classes,logIDs=header.logIDs,
        faction=({A="Alliance",H="Horde",B="Both"})[q.side] or "Both",
        pickup=LocationText(start,q.startText),turnin=LocationText(finish,q.finishText)}
    if q.classes and #q.classes==1 then result.classOnly=q.classes[1]:upper() end
    result.startMap=self:Location(start,q.startText,context.name,context.entrance)
    result.turninMap=self:Location(finish,q.finishText,context.name,context.entrance)
    local choices=Items(q.choice,self.Data)
    result.rewardChoice=#choices>0
    result.rewardItems=#choices>0 and choices or Items(q.reward,self.Data)
    if #choices>0 then result.fixedRewardItems=Items(q.reward,self.Data) end
    local summary={}
    if q.xp and q.xp>0 then summary[#summary+1]=q.xp.." XP" end
    if q.money and q.money>0 then
        local gold=math.floor(q.money/10000);local silver=math.floor(q.money/100)%100;local copper=q.money%100
        summary[#summary+1]=string.format("%dg %ds %dc",gold,silver,copper)
    end
    for _,rep in ipairs(Array(q.rep)) do if rep[1] and rep[2] then summary[#summary+1]=rep[1].." +"..rep[2] end end
    result.rewardSummary=table.concat(summary," · ")
    if start.kind=="item" and start.id then result.startItem=Item(start.id,self.Data);result.startItem[4]=start.text or self.Data.ItemNotes[start.id] end
    if q.src=="classic" then result.warning="Classic reference data; availability may differ in Forever." end
    if q.preAny and #q.preAny>0 then result.note="Alternative prerequisite routes are included below." end
    if q.note then result.note=q.note end
    return result
end
function C:Artwork(instance)
    self.artCache=self.artCache or {}
    local saved=self.artCache[instance.key]
    if saved then return saved.path,saved.crop end
    local art=instance.art or {}
    local candidates={}
    if art.loading then candidates[#candidates+1]={"Interface\\Glues\\LoadingScreens\\"..art.loading,
        art.loading:find("camelot160",1,true) and {.04,.96,.04,.96} or {.04,.96,.28,.78}} end
    if art.ej then candidates[#candidates+1]={"Interface\\EncounterJournal\\UI-EJ-LOREBG-"..art.ej,{0,.7617187,0,.65625}} end
    if art.lfg then candidates[#candidates+1]={"Interface\\LFGFrame\\UI-LFG-BACKGROUND-"..art.lfg,{0,.66,0,.66}} end
    for _,candidate in ipairs(candidates) do
        local valid=type(GetFileIDFromPath)~="function"
        if not valid then local ok,id=pcall(GetFileIDFromPath,candidate[1]);valid=ok and type(id)=="number" and id>0 end
        if valid then
            self.artCache[instance.key]={path=candidate[1],crop=candidate[2]}
            return candidate[1],candidate[2]
        end
    end
end
-- Merge repeated titles only when mandatory prerequisite links prove a chain.
-- Independent quests with the same name and faction/class variants stay separate.
function C:Groups(key,ids)
    self.groupCache=self.groupCache or {}
    if self.groupCache[key] then return self.groupCache[key] end
    local function Path(ancestor,id,seen,depth)
        if ancestor==id then return {id} end
        if depth>32 or seen[id] then return end
        seen[id]=true
        local q=self.Data.Quests[id] or {}
        for _,parent in ipairs(Array(q.pre)) do
            if type(parent)=="number" then
                local path=Path(ancestor,parent,seen,depth+1)
                if path then path[#path+1]=id;return path end
            end
        end
    end
    local function Signature(id)
        local q=self.Data.Quests[id] or {}
        local classes={};for _,token in ipairs(Array(q.classes)) do classes[#classes+1]=token:upper() end;table.sort(classes)
        return (q.name or tostring(id)):lower().."|"..(q.side or "").."|"..table.concat(classes,",")
    end
    local groups={}
    for _,id in ipairs(Array(ids)) do
        local found
        for _,group in ipairs(groups) do
            if Signature(id)==Signature(group.ids[1]) then
                for _,other in ipairs(group.ids) do
                    local forward,reverse=Path(other,id,{},0),Path(id,other,{},0)
                    if other==id or (forward~=nil)~=(reverse~=nil) then found=group;break end
                end
            end
            if found then break end
        end
        if not found then found={ids={}};groups[#groups+1]=found end
        local exists=false;for _,other in ipairs(found.ids) do if other==id then exists=true end end
        if not exists then found.ids[#found.ids+1]=id end
    end
    for _,group in ipairs(groups) do
        local rank,original={},{}
        for index,id in ipairs(group.ids) do
            original[id]=index;rank[id]=0
            for _,other in ipairs(group.ids) do if id~=other and Path(other,id,{},0) then rank[id]=rank[id]+1 end end
        end
        table.sort(group.ids,function(a,b) return rank[a]==rank[b] and original[a]<original[b] or rank[a]<rank[b] end)
        group.stages={};group.terminal={}
        local seen={}
        local function Add(id) if not seen[id] then seen[id]=true;group.stages[#group.stages+1]=id end end
        for _,id in ipairs(group.ids) do
            local terminal=true
            for _,other in ipairs(group.ids) do
                if id~=other then
                    local path=Path(id,other,{},0)
                    if path then terminal=false;for _,step in ipairs(path) do Add(step) end end
                end
            end
            Add(id);if terminal then group.terminal[#group.terminal+1]=id end
        end
    end
    self.groupCache[key]=groups
    return groups
end
function C:Read(selected)
    local ns={DB={},QUEST_PREREQ_CHAINS={},QUEST_PREREQ_DETAILS={},DUNGEON_HOME_ART={},DUNGEON_HOME_TEXCOORD={}}
    for _,instance in ipairs(self.Data.Instances or {}) do
        if instance.kind=="dungeon" then
            local name=instance.name
            -- Retain the accepted wing labels while using stable source keys.
            if instance.key=="STRATLIVE" then name="Stratholme: Living" elseif instance.key=="STRATUD" then name="Stratholme: Undead" end
            local entry={name=name,level=instance.minLevel.."-"..instance.maxLevel,location=instance.zone,
                previewOnly=instance.status=="announced",fullItemsTBD=instance.status~="beta",icon="Interface\\EncounterJournal\\UI-EJ-BOSS-Default",bosses={},quests={}}
            local e=instance.entrance
            if e and e.map and e.x and e.y then entry.entrance={mapID=e.map,x=e.x/100,y=e.y/100,label=name.." entrance"} end
            for _,b in ipairs(instance.bosses or {}) do
                entry.bosses[#entry.bosses+1]={name=b.name,npcID=b.npc,displayID=b.display,rare=b.rare,loot=Items(b.loot,self.Data)}
            end
            if instance.trash and #instance.trash>0 then entry.bosses[#entry.bosses+1]={name="Trash drops",trash=true,loot=Items(instance.trash,self.Data)} end
            local ids=self.Data.InstanceQuests[instance.key] or {}
            entry.questDataIncomplete=instance.status=="pending" and #ids==0
            for _,id in ipairs(ids) do entry.quests[#entry.quests+1]=self:QuestHeader(id) end
            ns.DB[name]=entry
            ns.DUNGEON_HOME_ART[name],ns.DUNGEON_HOME_TEXCOORD[name]=self:Artwork(instance)
            if selected==name then
                local context={name=name,entrance=entry.entrance}
                entry.quests={}
                local normalized={}
                local function Quest(id)
                    if not normalized[id] then normalized[id]=self:Quest(id,context) end
                    return normalized[id]
                end
                for _,id in ipairs(ids) do
                    entry.quests[#entry.quests+1]=Quest(id)
                    local seen,order={[id]=true},{}
                    local alternative=false
                    local function Visit(qid,depth)
                        if type(qid)=="table" then alternative=true;for _,option in ipairs(qid) do Visit(option,depth+1) end;return end
                        if type(qid)~="number" then return end
                        if seen[qid] or depth>32 then return end
                        seen[qid]=true
                        local raw=self.Data.Quests[qid]
                        if raw then
                            for _,parent in ipairs(Array(raw.pre)) do Visit(parent,depth+1) end
                            for _,parent in ipairs(Array(raw.preAny)) do Visit(parent,depth+1) end
                        end
                        order[#order+1]=qid
                    end
                    local raw=self.Data.Quests[id]
                    if raw then
                        for _,parent in ipairs(Array(raw.pre)) do Visit(parent,1) end
                        for _,parent in ipairs(Array(raw.preAny)) do Visit(parent,1) end
                    end
                    local chain={}
                    for _,parent in ipairs(order) do
                        local detail=Quest(parent)
                        ns.QUEST_PREREQ_DETAILS[parent]=detail;chain[#chain+1]={id=parent,name=detail.name}
                    end
                    ns.QUEST_PREREQ_CHAINS[id]=chain
                    if alternative then
                        local q=Quest(id)
                        local note="Prerequisites include alternative routes; not every listed quest is required."
                        q.note=q.note and (q.note.." "..note) or note
                    end
                end
            end
            local records={};for _,q in ipairs(entry.quests) do records[q.id]=q end
            local unique={}
            for _,group in ipairs(self:Groups(instance.key,ids)) do
                local q=records[group.ids[1]]
                if q then
                    q.completionIDs=group.terminal
                    if #group.ids>1 then
                        local logIDs={};for _,id in ipairs(group.stages) do logIDs[#logIDs+1]=id end
                        for _,id in ipairs(q.logIDs or {}) do logIDs[#logIDs+1]=id end
                        q.logIDs=logIDs
                        if selected==name then
                            q.stages={}
                            for _,id in ipairs(group.stages) do q.stages[#q.stages+1]=self:Quest(id,{name=name,entrance=entry.entrance}) end
                        end
                    end
                    unique[#unique+1]=q
                end
            end
            entry.quests=unique
        end
    end
    return ns
end
