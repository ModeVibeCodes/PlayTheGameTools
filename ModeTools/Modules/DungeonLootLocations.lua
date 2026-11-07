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
        return {mapID=raw.mapID,x=raw.x,y=raw.y,label=type(raw.label)=="string" and raw.label or "Quest location",points={{raw.x,raw.y}},paths={}}
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
