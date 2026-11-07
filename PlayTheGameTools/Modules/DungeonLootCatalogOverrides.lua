local _,addon=...
local C=addon.DungeonLootCatalog
if not C then return end
-- Independently curated additions, 2026-11-07. Identifiers/reward relationships
-- checked against public Forever quest/item pages listed in CATALOG_SOURCES.md.
-- Short objective/location notes below are original summaries, not guide prose.
local Q=C.Data.Quests
Q[1806]={name="The Test of Righteousness",level=22,min=20,side="A",classes={"PALADIN"},src="forever",pre={1654},
    obj="Wait while Jordan finishes your weapon.",start={kind="npc",name="Jordan Stilwell"},finish={kind="npc",name="Jordan Stilwell"},
    startText="Jordan Stilwell, outside Ironforge",finishText="Jordan Stilwell, outside Ironforge",reward={6953}}
Q[95140]={name="Old Fire-Eye",level=26,min=20,side="H",classes={"PALADIN"},src="forever",
    obj="Defeat Old Fire-Eye using the Moonsilver Blade, then return to Lumina.",
    start={kind="npc",name="Lumina Windsinger"},finish={kind="npc",name="Lumina Windsinger"},
    startText="Lumina Windsinger, the Sepulcher crypt",finishText="Lumina Windsinger, the Sepulcher crypt",reward={267369}}
Q[78261]={name="The Horn of Xelthos",min=20,side="B",classes={"ROGUE"},src="forever",
    obj="Recover the horn from the stables chest inside Shadowfang Keep.",
    start={kind="object",name="Dead Drop",map=1421,x=47,y=71},finish={kind="object",name="Dead Drop",map=1421,x=47,y=71},
    startText="Dead Drop, near Pyrewood Village",finishText="Dead Drop, near Pyrewood Village",
    note="Solo class quest. The chest requires a key assembled from two pickpocketed halves."}
Q[78307]={name="The Horn of Xelthos",min=20,side="B",classes={"ROGUE"},src="forever",pre={78261},
    obj="Return to the Dead Drop to collect your payment.",
    start={kind="object",name="Dead Drop",map=1421,x=47,y=71},finish={kind="object",name="Dead Drop",map=1421,x=47,y=71},
    startText="Dead Drop, near Pyrewood Village",finishText="Dead Drop, near Pyrewood Village",reward={277210},
    note="The payment follows another letter after the horn has been returned."}
C.Data.Items[6953]=C.Data.Items[6953] or "Verigan's Fist|Two-Hand Mace|"
C.Data.Items[267369]="Wolfsbane|Two-Hand Sword|N"
C.Data.Items[277210]="Pyrewood Signet Ring|Finger|N"
local ids=C.Data.InstanceQuests.SFK
for index,id in ipairs(ids) do if id==1654 then ids[index]=1806 end end
ids[#ids+1]=95140;ids[#ids+1]=78307

-- The pilot lists these chains by their final reward step. Their actual dungeon
-- collection stage also counts as picked up, once, for that same quest card.
C.QuestLogAliases={[1806]={1654},[78307]={78261}}
