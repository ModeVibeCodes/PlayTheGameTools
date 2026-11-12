local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end

-- Normalize the bundled catalog without exposing mutable source tables.
-- No external data addon is required; see CATALOG_SOURCES.md for attribution.
local P = {}
addon.DungeonLootProvider = P
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Text(v)
    if not Public(v) or type(v) ~= "string" then return nil end
    -- Keep the independent UI free of upstream texture/atlas and color markup.
    return v:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
local function Table(v) return Public(v) and type(v) == "table" and v or {} end
local function ID(v)
    if Public(v) and type(v) == "number" and v > 0 and v < 10000000 and v == math.floor(v) then return v end
end
local function Restrictions(raw)
    raw=Table(raw)
    local q={id=ID(raw.id),faction=Text(raw.faction),classOnly=Text(raw.classOnly),classes={},logIDs={},completionIDs={}}
    for _,token in ipairs(Table(raw.classes)) do if Text(token) then q.classes[#q.classes+1]=token end end
    for _,id in ipairs(Table(raw.logIDs)) do if ID(id) then q.logIDs[#q.logIDs+1]=id end end
    for _,id in ipairs(Table(raw.completionIDs)) do if ID(id) then q.completionIDs[#q.completionIDs+1]=id end end
    return q
end
function P:Player()
    local player={}
    if type(UnitFactionGroup)=="function" then
        local ok,faction=pcall(UnitFactionGroup,"player")
        if ok and Public(faction) and (faction=="Alliance" or faction=="Horde") then player.faction=faction end
    end
    if type(UnitClass)=="function" then
        local ok,_,token=pcall(UnitClass,"player")
        if ok then player.class=Text(token) end
    end
    return player
end
-- nil means identity is unavailable: do not claim a definitive personal total.
function P:Eligible(q,player)
    local faction=Text(q.faction)
    if faction=="Alliance" or faction=="Horde" then
        if not player.faction then return nil end
        if faction~=player.faction then return false end
    end
    local classes=Table(q.classes)
    local only=Text(q.classOnly)
    if #classes>0 or only then
        if not player.class then return nil end
        if #classes==0 then return only==player.class end
        for _,token in ipairs(classes) do if Text(token)==player.class then return true end end
        return false
    end
    return true
end
local function QuestFlag(id,cache,method)
    if not id then return nil end
    if cache[id]~=nil then if cache[id]=="unknown" then return nil end;return cache[id] end
    local getter=C_QuestLog and C_QuestLog[method]
    if type(getter)=="function" then
        local ok,value=pcall(getter,id)
        if ok and Public(value) and type(value)=="boolean" then cache[id]=value;return value end
    end
    cache[id]="unknown"
end
function P:UpdateQuestState(data)
    local cache,completionCache={},{}
    local changed=false
    data.questStates={}
    for _,card in ipairs(data.cards) do
        local stats={total=0,inLog=0,classTotal=0,classInLog=0,completed=0,classCompleted=0,known=true,logKnown=true,completionKnown=true}
        local seen,states={},{}
        for _,q in ipairs(card.questHeaders or {}) do
            local eligible=self:Eligible(q,data.player)
            if eligible==nil then stats.known=false end
            local id=ID(q.id)
            if eligible and id and not seen[id] then
                seen[id]=true;stats.total=stats.total+1
                local onQuest=QuestFlag(id,cache,"IsOnQuest")
                local unknown=onQuest==nil
                for _,alias in ipairs(Table(q.logIDs)) do
                    local active=QuestFlag(ID(alias),cache,"IsOnQuest")
                    if active then onQuest=true end
                    if active==nil then unknown=true end
                end
                if not onQuest and unknown then stats.logKnown=false end
                if onQuest then stats.inLog=stats.inLog+1 end
                local completed=true
                local completionIDs=#q.completionIDs>0 and q.completionIDs or {id}
                for _,finishID in ipairs(completionIDs) do
                    local done=QuestFlag(finishID,completionCache,"IsQuestFlaggedCompleted")
                    if done==nil then stats.completionKnown=false end
                    if not done then completed=false end
                end
                if completed then stats.completed=stats.completed+1 end
                local status={inLog=onQuest==true,completed=completed,logKnown=not unknown or onQuest==true}
                local previous=card.questStates and card.questStates[id]
                if not previous or previous.inLog~=status.inLog or previous.completed~=status.completed or previous.logKnown~=status.logKnown then changed=true end
                states[id]=status
                if q.classOnly or #Table(q.classes)>0 then
                    stats.classTotal=stats.classTotal+1
                    if onQuest then stats.classInLog=stats.classInLog+1 end
                    if completed then stats.classCompleted=stats.classCompleted+1 end
                end
            end
        end
        local old=card.questState or {}
        for key,value in pairs(stats) do if old[key]~=value then changed=true end end
        card.questState=stats;card.questStates=states
        if card.name==data.name then data.questStates=states end
    end
    for _,q in ipairs(data.quests or {}) do
        local previousStage=q.currentStage and q.currentStage.id
        local state=data.questStates[q.id]
        q.currentStage=state and state.completed and q.stages and q.stages[#q.stages] or nil
        for _,stage in ipairs(not q.currentStage and self:Eligible(q,data.player) and q.stages or {}) do
            if QuestFlag(stage.id,cache,"IsOnQuest")==true then q.currentStage=stage;break end
            if not q.currentStage and QuestFlag(stage.id,completionCache,"IsQuestFlaggedCompleted")~=true then q.currentStage=stage end
        end
        if not q.currentStage and q.stages and #q.stages>0 then q.currentStage=q.stages[#q.stages] end
        if previousStage~=(q.currentStage and q.currentStage.id) then changed=true end
        -- Only a confirmed character completion flag marks a stage done.
        for _,stage in ipairs(q.stages or {}) do
            local done=QuestFlag(stage.id,completionCache,"IsQuestFlaggedCompleted")==true
            if stage.completed~=done then changed=true end
            stage.completed=done
        end
    end
    return changed
end
local function Map(v)
    v = Table(v)
    local label = Text(v.label)
    if Public(v.x) and Public(v.y) and type(v.x) == "number" and type(v.y) == "number"
        and v.x >= 0 and v.x <= 1 and v.y >= 0 and v.y <= 1 then
        return (label or "Location") .. string.format(" (%.1f, %.1f)", v.x * 100, v.y * 100)
    end
    return label
end
local function Items(source, reward)
    local items = {}
    for _, raw in ipairs(Table(source)) do
        raw = Table(raw)
        local id = ID(raw[1])
        if id then items[#items + 1] = { id = id, name = Text(raw[2]) or ("Item " .. id),
            slot = not reward and Text(raw[3]) or nil } end
    end
    return items
end
local fields = { "objective", "pickup", "turnin", "note", "warning", "description", "faction", "classOnly", "rewards", "rewardSummary" }
local function Quest(raw, ns, context, step, stepID, stepName)
    raw = Table(raw)
    local q = { id = ID(raw.id) or ID(stepID), name = Text(raw.name) or Text(stepName) or "Unnamed quest", level = ID(raw.level), requires = ID(raw.requires) }
    for _, field in ipairs(fields) do q[field] = Text(raw[field]) end
    local restrictions=Restrictions(raw)
    q.logIDs,q.classes,q.completionIDs=restrictions.logIDs,restrictions.classes,restrictions.completionIDs
    local start=raw.startMap or raw.map or Table(ns.QUEST_START_MAPS)[q.id]
    local finish=raw.turninMap
    local locations=addon.DungeonLootLocations
    start=start or locations:FindRecorded(q.pickup,context.locations) or locations:Interior(q.pickup,context.name,context.entrance)
    finish=finish or locations:FindRecorded(q.turnin,context.locations) or locations:Interior(q.turnin,context.name,context.entrance)
    q.start,q.finish=Map(start),Map(finish)
    q.pickupTargets=locations:Targets(q.id,"pickup",start)
    q.turninTargets=locations:Targets(q.id,"turnin",finish)
    q.objectiveTargets=locations:Targets(q.id,"objective")
    q.items = Items(raw.rewardItems, true)
    q.fixedItems = Items(raw.fixedRewardItems,true)
    q.rewardChoice = raw.rewardChoice == true
    q.startItem = Items(raw.startItem and {raw.startItem}, true)[1]
    q.startObject = Text(Table(raw.startObject)[1])
    q.startHint = Text(Table(raw.startItem)[4]) or Text(Table(raw.startObject)[3])
    q.chain = {}
    if not step then
        for _, entry in ipairs(Table(Table(ns.QUEST_PREREQ_CHAINS)[q.id])) do
            entry = Table(entry)
            local detail = Table(Table(ns.QUEST_PREREQ_DETAILS)[ID(entry.id)])
            local normalized = Quest(detail, ns, context, true, entry.id, entry.name)
            normalized.id, normalized.name = ID(entry.id), Text(entry.name) or normalized.name
            if P:Eligible(normalized,context.player) then q.chain[#q.chain + 1] = normalized end
        end
    end
    q.stages={}
    if not step then
        for _,stage in ipairs(Table(raw.stages)) do
            local detail=Quest(stage,ns,context,true)
            if P:Eligible(detail,context.player) then q.stages[#q.stages+1]=detail end
        end
    end
    return q
end
local TERRITORY={
    [1426]="Alliance",[1436]="Alliance",[1453]="Alliance",[1455]="Alliance",
    [1413]="Horde",[1420]="Horde",[1421]="Horde",[1454]="Horde",[1458]="Horde",
}
local function Extra(boss)
    local id=ID(boss.npcID)
    return boss.trash==true or boss.recipeTab==true or id==3864 or id==4627
end
local function Art(value)
    if ID(value) then return value end
    local path=Text(value)
    if path and path:sub(1,10)=="Interface\\" and not path:find("..",1,true) then return path end
end
local function Card(name,raw,ns)
    local low,high=(Text(raw.level) or ""):match("(%d+)%D+(%d+)")
    low,high=tonumber(low),tonumber(high)
    if name=="Shadowfang Keep" then low,high=low or 20,high or 30 end
    local entrance=Table(raw.entrance)
    local home=Art(Table(ns.DUNGEON_HOME_ART)[name]) or Art(Table(ns.DUNGEON_PAGE_ART)[name])
    if name=="Shadowfang Keep" then home="Interface\\Glues\\LoadingScreens\\LoadScreenShadowFangKeep" end
    local crop={.04,.96,.28,.78}
    local supplied=Table(Table(ns.DUNGEON_HOME_TEXCOORD)[name])
    if name~="Shadowfang Keep" and #supplied==4 then
        local valid=true
        for _,v in ipairs(supplied) do if not Public(v) or type(v)~="number" or v<0 or v>1 then valid=false end end
        if valid and supplied[1]<supplied[2] and supplied[3]<supplied[4] then crop={supplied[1],supplied[2],supplied[3],supplied[4]} end
    end
    local count,rare=0,0
    for _,boss in ipairs(Table(raw.bosses)) do
        boss=Table(boss)
        if not Extra(boss) then if boss.rare==true then rare=rare+1 else count=count+1 end end
    end
    local preview=raw.previewOnly==true
    local available=not preview and (type(raw.bosses)=="table" or type(raw.quests)=="table")
    local faction=TERRITORY[entrance.mapID] or (name=="Shadowfang Keep" and "Horde" or "Both")
    if preview and not ID(entrance.mapID) then faction=nil end
    local headers={}
    for _,q in ipairs(Table(raw.quests)) do headers[#headers+1]=Restrictions(q) end
    return {name=name,available=available,previewOnly=preview,bossCount=count,rareCount=rare,questCount=#Table(raw.quests),questCountKnown=raw.questDataIncomplete~=true,
        questHeaders=headers,
        location=Text(raw.location) or "Location unknown",levelLow=low,levelHigh=high,
        card={art=home or Art(raw.icon),iconOnly=not home,crop=crop,
            faction=faction,
            suggestedLevel=low and (low.."–"..high) or "Unknown"}}
end
function P:Read(dungeon)
    dungeon=dungeon or "Shadowfang Keep"
    local catalog=addon.DungeonLootCatalog
    local ns=Table(catalog and catalog:Read(dungeon))
    local db=Table(ns.DB)
    local result={name=dungeon,catalog={},cards={},bosses={},quests={},available=false,bossCount=0,rareCount=0,player=self:Player()}
    for name,raw in pairs(db) do
        if type(name)=="string" and type(raw)=="table" and raw.isRaid~=true and raw.type~="raid" and (raw.previewOnly==true or type(raw.bosses)=="table" or type(raw.quests)=="table") then
            result.cards[#result.cards+1]=Card(name,raw,ns)
        end
    end
    table.sort(result.cards,function(a,b)
        local al,bl=a.levelLow or 1000,b.levelLow or 1000
        if al~=bl then return al<bl end
        local ah,bh=a.levelHigh or 1000,b.levelHigh or 1000
        if ah~=bh then return ah<bh end
        return a.name<b.name
    end)
    local selected
    for _,card in ipairs(result.cards) do
        result.catalog[#result.catalog+1]=card.name
        if card.name==dungeon then selected=card end
    end
    if #result.cards==0 then
        local fallback=Card("Shadowfang Keep",{},ns)
        result.cards[1]=fallback;result.catalog[1]=fallback.name
    end
    result.card=(selected or Card(dungeon,{},ns)).card
    if not next(db) then
        result.source="The bundled dungeon catalog could not be loaded. Restart WoW after updating the addon."
        return result
    end
    result.source=addon.DungeonLootCatalog.source
    result.providerSource=result.source
    local raw=Table(db[dungeon])
    if not selected or not selected.available then
        self:UpdateQuestState(result)
        result.source=selected and selected.previewOnly and "Dungeon data is not available yet." or "No recorded data for this dungeon."
        return result
    end
    result.available=true
    result.bossCount,result.rareCount=selected.bossCount,selected.rareCount
    result.location,result.level=Text(raw.location),Text(raw.level)
    result.lootIncomplete=raw.fullItemsTBD==true
    local context={name=dungeon,player=result.player,entrance=raw.entrance,locations=addon.DungeonLootLocations:RecordedIndex(ns)}
    for _,boss in ipairs(Table(raw.bosses)) do
        boss=Table(boss)
        result.bosses[#result.bosses+1]={name=Text(boss.name) or "Unnamed encounter",items=Items(boss.loot),
            displayID=ID(boss.displayID) or ID(Table(ns.STATIC_DISPLAY_IDS)[ID(boss.npcID)]),
            rare=boss.rare==true,extra=Extra(boss)}
    end
    for _,quest in ipairs(Table(raw.quests)) do result.quests[#result.quests+1]=Quest(quest,ns,context) end
    self:UpdateQuestState(result)
    return result
end
