local _, addon = ...
-- Independently curated, rounded planning points. See docs/DUNGEON_LOOT.md for
-- public location references/check dates. These are estimates, not native sightings.
local D = {}
addon.DungeonLootLocationData = D
local hadrec={1421,43,41,"High Executor Hadrec"}
local doan={1413,49,57,"Doan Karhan"}
local beldugur={1458,54,55,"Keeper Bel'dugur"}
local dalar={1421,44,40,"Dalar Dawnweaver"}
local jordan={1426,52,37,"Jordan Stilwell"}
local lumina={1421,43,41,"Lumina Windsinger","After her Fenris escort, look in the Sepulcher crypt. Approximate location."}
local drop={1421,47,71,"Dead Drop"}
local function Inside(name,detail) return {1421,45,68,name,"Entrance marker only. "..detail} end
local courtyard=Inside("Deathstalker Vincent (inside SFK)","Enter Shadowfang Keep and reach the courtyard after the first boss.")
local book=Inside("The Book of Ur (inside SFK)","The book is on a shelf in Fenrus's room.")
local arugal=Inside("Archmage Arugal (inside SFK)","The final encounter is inside the keep.")
local fragments=Inside("SFK fragment collection", "Only the Shadowfang Keep portion is marked; the other fragments require Blackfathom Deeps.")
local hammer=Inside("Jordan's Smithing Hammer (inside SFK)","The hammer is in the stables/courtyard area.")
local horn=Inside("The Horn of Xelthos (inside SFK)","This is a solo class-quest objective inside the keep.")
local quests={
    [1098]={pickup={hadrec},turnin={courtyard},objective={courtyard}},
    [1740]={pickup={doan},turnin={doan},objective={fragments}},
    [1013]={pickup={beldugur},turnin={beldugur},objective={book}},
    [1014]={pickup={dalar},turnin={dalar},objective={arugal}},
    [1806]={pickup={jordan},turnin={jordan},objective={jordan}}, -- Wait for forging, not the earlier collection step.
    [1654]={pickup={jordan},turnin={jordan},objective={hammer}},
    [95140]={pickup={lumina},turnin={lumina}}, -- Final outdoor kill location remains unknown here.
    [78307]={pickup={drop},turnin={drop},objective={drop}}, -- Payment step.
    [78261]={pickup={drop},turnin={drop},objective={horn}},
}
function D:Targets(id,kind)
    local list=quests[id] and quests[id][kind]
    local result={}
    for _,point in ipairs(list or {}) do
        result[#result+1]={mapID=point[1],x=point[2]/100,y=point[3]/100,label=point[4],
            points={{point[2]/100,point[3]/100}},paths={},approximate=true,
            detail=point[5] or "Approximate planning location. Confirm the NPC/object position in game.",source="Play The Game Tools location catalog"}
    end
    return result
end
