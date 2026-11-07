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
            q.chain[#q.chain + 1] = normalized
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
    return {name=name,available=available,previewOnly=preview,bossCount=count,rareCount=rare,questCount=#Table(raw.quests),questCountKnown=raw.questDataIncomplete~=true,
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
    local result={name=dungeon,catalog={},cards={},bosses={},quests={},available=false,bossCount=0,rareCount=0}
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
        result.source=selected and selected.previewOnly and "Dungeon data is not available yet." or "No recorded data for this dungeon."
        return result
    end
    result.available=true
    result.bossCount,result.rareCount=selected.bossCount,selected.rareCount
    result.location,result.level=Text(raw.location),Text(raw.level)
    result.lootIncomplete=raw.fullItemsTBD==true
    local context={name=dungeon,entrance=raw.entrance,locations=addon.DungeonLootLocations:RecordedIndex(ns)}
    for _,boss in ipairs(Table(raw.bosses)) do
        boss=Table(boss)
        result.bosses[#result.bosses+1]={name=Text(boss.name) or "Unnamed encounter",items=Items(boss.loot),
            displayID=ID(boss.displayID) or ID(Table(ns.STATIC_DISPLAY_IDS)[ID(boss.npcID)]),
            rare=boss.rare==true,extra=Extra(boss)}
    end
    for _,quest in ipairs(Table(raw.quests)) do result.quests[#result.quests+1]=Quest(quest,ns,context) end
    return result
end
