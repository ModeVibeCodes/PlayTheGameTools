local _, addon = ...
-- Read-only optional QuestieDB/Questie APIs; never copy or modify their records.
local L = {}
addon.DungeonLootLocations = L
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Table(v) return Public(v) and type(v)=="table" and v or {} end
local function Number(v, low, high) return Public(v) and type(v)=="number" and v>=low and v<=high end
local function Read(db, key, id)
    local fn=Table(db)[key]
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,id)
    if ok and Public(value) then return value end
end
function L:Point(raw)
    raw=Table(raw)
    if Number(raw.mapID,1,1000000) and Number(raw.x,0,1) and Number(raw.y,0,1) then
        return {mapID=raw.mapID,x=raw.x,y=raw.y,label=type(raw.label)=="string" and raw.label or "Quest location",detail=Public(raw.detail) and type(raw.detail)=="string" and raw.detail or nil,points={{raw.x,raw.y}},paths={}}
    end
end
-- Convert static catalog spawn coordinates through the current client, never
-- through another addon. This touches no player position or quest-log state.
function L:WorldPoint(world,label)
    if type(world)~="table" or not Number(world[1],0,1) or not Number(world[2],-100000,100000) or not Number(world[3],-100000,100000) then return nil end
    if not C_Map or type(C_Map.GetMapPosFromWorldPos)~="function" or type(C_Map.GetMapInfoAtPosition)~="function" or type(CreateVector2D)~="function" then return nil end
    self.worldCache=self.worldCache or {}
    local key=string.format("%d,%.6f,%.6f",world[1],world[2],world[3])
    local saved=self.worldCache[key]
    if saved then return self:Point({mapID=saved.mapID,x=saved.x,y=saved.y,label=label}) end
    local ok,point=pcall(function()
        local mapID=world[1]==0 and 1415 or 1414
        local vector=CreateVector2D(world[2],world[3])
        local _,position=C_Map.GetMapPosFromWorldPos(world[1],vector,mapID)
        if not Public(position) or not position then return nil end
        local limit=Enum and Enum.UIMapType and Enum.UIMapType.Zone
        if not limit then return nil end
        for _=1,4 do
            if not Number(position.x,0,1) or not Number(position.y,0,1) then return nil end
            local info=C_Map.GetMapInfoAtPosition(mapID,position.x,position.y)
            if not Public(info) or type(info)~="table" or not Number(info.mapID,1,1000000) or info.mapID==mapID or not Number(info.mapType,0,limit) then break end
            local nextID,nextPosition=C_Map.GetMapPosFromWorldPos(world[1],vector,info.mapID)
            if not Public(nextPosition) or not nextPosition or not Public(nextID) or nextID~=info.mapID then break end
            mapID,position=info.mapID,nextPosition
        end
        if mapID==1414 or mapID==1415 then return nil end
        return self:Point({mapID=mapID,x=position.x,y=position.y,label=label})
    end)
    if ok and point then self.worldCache[key]={mapID=point.mapID,x=point.x,y=point.y};return point end
end
-- Exact giver-name joins only; ambiguous map records remain unresolved.
local function Name(text)
    if not Public(text) or type(text)~="string" then return nil end
    local name=text:match("^([^,;\n]+)") or text
    for _,separator in ipairs({" — "," - "," ("}) do
        local at=name:find(separator,1,true);if at then name=name:sub(1,at-1) end
    end
    return name:match("^%s*(.-)%s*$"):lower()
end
function L:RecordedIndex(ns)
    local index={}
    local function Add(raw,name)
        local point=self:Point(raw)
        name=Name(name)
        if not point or not name or name=="" then return end
        local old=index[name]
        if old==false then return end
        if old and (old.mapID~=point.mapID or math.abs(old.x-point.x)>.005 or math.abs(old.y-point.y)>.005) then index[name]=false
        elseif not old then index[name]=point end
    end
    for _,raw in pairs(Table(ns.QUEST_START_MAPS)) do
        raw=Table(raw);Add(raw,raw.targetName or raw.label)
    end
    for _,raw in ipairs(Table(ns.TURNIN_SPOTS)) do raw=Table(raw);Add(raw,raw.targetName or raw.label) end
    for _,dungeon in pairs(Table(ns.DB)) do
        for _,q in ipairs(Table(Table(dungeon).quests)) do
            q=Table(q);Add(q.startMap or q.map,q.pickup);Add(q.turninMap,q.turnin)
        end
    end
    return index
end
function L:FindRecorded(text,index)
    local name=Name(text)
    local point=name and index[name]
    if point then return self:Point(point) end
end
function L:Interior(text,dungeon,entrance)
    if type(text)~="string" or not text:lower():find("inside",1,true) then return nil end
    local lower=text:lower()
    local place=(dungeon:match("^([^:]+)") or dungeon):lower()
    if not lower:find(place,1,true) and not lower:find("inside the dungeon",1,true) and not lower:find("inside the instance",1,true) then return nil end
    local point=self:Point(entrance)
    if point then
        point.label="Dungeon entrance — "..dungeon
        point.detail="Entrance marker only. "..text
        return point
    end
end
function L:Targets(id,kind,fallback)
    local targets={}
    local database=Table(_G.LibQuestieDB)
    local quests=Table(database.Quest)
    local groups=Table(Read(quests,kind=="pickup" and "startedBy" or kind=="turnin" and "finishedBy" or "objectives",id))
    local zoneDB
    if QuestieLoader and type(QuestieLoader.ImportModule)=="function" then
        local ok,value=pcall(QuestieLoader.ImportModule,QuestieLoader,"ZoneDB")
        if ok then zoneDB=value end
    end
    if zoneDB and type(zoneDB.GetUiMapIdByAreaId)=="function" then
        for category=1,2 do
            local db=Table(database[category==1 and "Npc" or "Object"])
            for _,record in ipairs(Table(groups[category])) do
                local entity=kind=="objective" and Table(record)[1] or record
                if Number(entity,1,10000000) then
                    local name=Read(db,"name",entity)
                    local spawns=Table(Read(db,"spawns",entity))
                    local paths=Table(Read(db,"waypoints",entity))
                    local zones={}
                    for zone in pairs(spawns) do zones[zone]=true end
                    for zone in pairs(paths) do zones[zone]=true end
                    local ordered={};for zone in pairs(zones) do if Number(zone,1,1000000) then ordered[#ordered+1]=zone end end;table.sort(ordered)
                    for _,zone in ipairs(ordered) do
                        local ok,mapID=pcall(zoneDB.GetUiMapIdByAreaId,zoneDB,zone)
                        if ok and Number(mapID,1,1000000) then
                            local target={mapID=mapID,label=type(name)=="string" and name or "Quest location",points={},paths={},source="QuestieDB"}
                            for _,point in ipairs(Table(spawns[zone])) do
                                point=Table(point)
                                if Number(point[1],0,100) and Number(point[2],0,100) then target.points[#target.points+1]={point[1]/100,point[2]/100} end
                            end
                            for _,path in ipairs(Table(paths[zone])) do
                                local route={}
                                for _,point in ipairs(Table(path)) do
                                    point=Table(point)
                                    if Number(point[1],0,100) and Number(point[2],0,100) then route[#route+1]={point[1]/100,point[2]/100}
                                    else route={};break end -- Never bridge across an unknown point.
                                end
                                if #route>1 then target.paths[#target.paths+1]=route end
                            end
                            local first=target.points[1] or (target.paths[1] and target.paths[1][1])
                            if first then target.x,target.y=first[1],first[2];targets[#targets+1]=target end
                        end
                    end
                end
            end
        end
    end
    local owned=addon.DungeonLootLocationData:Targets(id,kind)
    if #owned>0 then
        -- Keep owned planning pins stable. Optional sources may add a recorded
        -- patrol only for the same named entity on the same UI map.
        for _,point in ipairs(owned) do
            for _,extra in ipairs(targets) do
                if point.mapID==extra.mapID and point.label==extra.label and #extra.paths>0 then point.paths=extra.paths;break end
            end
        end
        return owned
    end
    if #targets==0 then local point=self:Point(fallback);if point then targets[1]=point end end
    return targets
end
