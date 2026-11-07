# Bundled Dungeon Loot catalog

The runtime catalog is independent of DungeonJournal, Lootified, AtlasLoot,
Questie and QuestieDB installations. Those addons need not be installed. Optional
Questie APIs may add recorded patrols, but baseline records ship in this package.

## Reused data and distribution terms

The three Modules/DungeonLootCatalog{Items,Instances,Quests}.lua files derive
from the data tables in **Lootified 1.2.0**, by **Alen**, published by
**TepsiPepsi**, licensed GPLv3. Namespace bindings were changed on 2026-11-07;
original data/provenance comments are preserved. No Lootified UI, fonts, emblems,
fan maps, bundled textures or simulator code is included.

- Original release: https://www.curseforge.com/wow/addons/lootified/files/9112707
- Pinned source archive: https://edge.forgecdn.net/files/9112/707/Lootified-1.2.0.zip
- SHA-256: 6446886ad6fd9a58b5edbf4661aef3fe05970e9f131408c485d320ebf375777c
- Full license: LICENSES/GPL-3.0.txt (copied unchanged from that release).
- Upstream author/credits: release README.md and THIRD_PARTY_NOTICES.md.

Lootified attributes its quest/loot/creature/spawn data in part to
[CMaNGOS classic-db](https://github.com/cmangos/classic-db), GPLv3. Its documented
Forever facts come from the game client and public beta databases/guides. These
attributions remain applicable. Blizzard retains its game names, quest text,
identifiers and native artwork. Referencing native client textures conveys no
ownership of Blizzard assets.

Distributions containing this GPLv3-derived catalog are provided under GPLv3.
Mode's original code retains its MIT copyright/permission notices in LICENSE;
that original MIT grant does not relicense the imported data. The source Lua
files are included in editable form with the package and repository. There is no
warranty; no source data is claimed to guarantee current server availability.

## Original additions and uncertainty

DungeonLootCatalogOverrides.lua contains short, independently authored summaries
for the SFK completion/class quests that the licensed snapshot lacks. Checked:
2026-11-07. Game facts/reward relationships:

- https://www.wowhead.com/forever/quest=1806/the-test-of-righteousness
- https://www.wowhead.com/forever/quest=95140/old-fire-eye
- https://www.wowhead.com/forever/item=267369/wolfsbane
- https://www.wowhead.com/forever/quest=78261/the-horn-of-xelthos
- https://www.wowhead.com/forever/quest=78307/the-horn-of-xelthos
- https://www.wowhead.com/forever/item=277210/pyrewood-signet-ring

The small owned SFK planning-point catalog remains separately attributed in
docs/DUNGEON_LOOT.md. No DungeonJournal records or assets were copied into this
bundle. Questie/QuestieDB databases and Completao's excluded generated quest data
were not imported; their dataset licensing was not treated as blanket permission.
AtlasLoot's GPLv2 data was inspected but not combined with this GPLv3 catalog.

The pinned data snapshot predates some newest Forever additions. Classic fallback
quests/loot are identified as reference data, pending/announced records stay
explicitly incomplete, and unknown loot, quests or positions are never invented.
Native item tooltips can supply current item details for recorded item IDs.

## Reproducing the import

Run `python tools/update_dungeon_catalog.py <local Lootified-1.2.0.zip>` to verify
all imported data and the license against the pinned SHA-256. The optional
`--write` replaces only those four files. It does not download, import assets,
install addons or update our independent overrides. Review newer snapshots and
their terms before changing the pin; never silently follow a latest release.
