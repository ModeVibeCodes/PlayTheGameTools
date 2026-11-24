# Map Labels

Quality of Life -> Map Labels puts small icons, with optional names, on the
world map for trainers and town services: class and profession trainers, weapon
masters, banks, auction houses, inns, flight masters, guild masters and
transmogrifiers, and optionally stable masters, mailboxes, repair vendors and
other vendors. The module is off by default. Hovering an icon lists the NPCs
there and credits the data source; clicks pass through to the map.

## Behavior

- **Class Trainers** and **Profession Trainers** each choose **Mine**, **All** or
  **Off**; both default to **Mine**. Mine shows your class's trainers (class from
  `UnitClass`) and trainers for professions you have learned. Professions are
  read through the shared Quick Access reader (`GetProfessions` /
  `GetProfessionInfo` skill-line IDs) outside combat; the last read is kept for
  combat. If professions were never readable, every profession trainer shows.
- Labels belonging to the other faction are hidden unless **Other Faction** is on.
  When the client does not report your faction or class, both are shown rather
  than guessed.
- Each label has a standard game icon inside a one-pixel edge in the service's
  color: class icons for class trainers, your own profession's native icon when
  you know it, otherwise a fixed `Interface\Icons` icon per service. If an icon
  file is missing on the client, the next candidate or a colored dot is used.
  Class trainer edges and dots use the class color.
- Mailboxes show the icon without a name. **Show Names** turns all map text off.
- **Icon Size** (8-32, default 16) and **Name Size** (8-16) apply on the next map
  draw. Icons keep the same on-screen size at every map zoom.
- Nothing is recorded or saved besides these preferences. Settings use
  `PTGToolsDB.modules.cityLabels` and are covered by profile validation. The
  first release's `classTrainers`, `allClasses` and `professionTrainers`
  switches seed the two modes once and are otherwise kept but unread; saved
  sizes stay valid.

## Implementation and API use

`Modules/CityLabelsMap.lua` adds one standard data provider to `WorldMapFrame`
and draws through `AcquirePin` / `RemoveAllPinsByTemplate` with the
`PlayTheGameToolsCityLabelsMapPinTemplate` XML template, the same native pin
pool contract Dungeon Loot uses. These calls, `MapCanvasDataProviderMixin` and
`MapCanvasPinMixin` (`SetScalingLimits`, `SetIgnoreGlobalPinScale`,
`UseFrameLevelType`, `SetMouseClickEnabled`) were checked against the
[Forever map canvas source](https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_MapCanvas).
An unknown frame-level type falls back to the default level there.

- The world map addon is never force-loaded. If it is not loaded yet, the provider
  attaches on its `ADDON_LOADED`; attaching waits for `PLAYER_REGEN_ENABLED` when
  in combat. Pins are plain frames, so redraws while the map is open are safe.
- Disabling the module removes its pins; the provider stays registered and draws
  nothing, so the map's provider list is never changed in combat.
- A drawing error is printed once, shown as **Map Status** on the settings page,
  and leaves the rest of the map working.
- No other addon or database is read at runtime.

## Data

`tools/build_city_labels.py` writes two files from two pinned sources. Each
file's header records its source, commit, license and changes; both are in
THIRD_PARTY_NOTICES.md.

**`Modules/CityLabelsData.lua`** comes from the
[EG Link WoW: Forever dataset](https://github.com/JIVESCORP/eg-link-output-wowf)
(Data from Efficient Games, CC BY 4.0), where players record services on the
released client. The generator:

- reads only released-client builds (1.60.1.70790 onward), so coordinates match
  the live maps; the newest build that recorded an NPC wins;
- reads `npcs`, `trainers`, `vendors` and `creature_details.enUS`; roles come from
  the NPC's window types and title. Classic trainers greet with a gossip window,
  so an NPC offering "Train me." (`TrainerGossipIcon`) or titled like a trainer
  ("Expert Alchemist") counts as one even if nobody opened its training list;
  a trainer whose class or profession cannot be recognized is skipped and listed;
- reduces each NPC's recorded player positions to one point on the map where it
  was seen most, then merges same-service points within 12 yards (30 for one
  class's trainers, 50 for auction houses and banks) and lists an adjacent guild
  vault with its bank.

Positions are where players stood when they used the service, so labels sit
near the NPC, not exactly on it.

**`Modules/CityLabelsClassicData.lua`** fills the gaps from
[CMaNGOS classic-db](https://github.com/cmangos/classic-db) (GPL-3.0; the package
is already distributed under GPLv3 and ships the license). It keeps only
trainers and services Efficient Games has not placed, using the Forever title
when Efficient Games cached one and a Classic service flag only when the title
agrees. Each NPC's primary spawn (world yards) is converted to a Forever map
position with a per-map transform fitted to Efficient Games' own Forever points
(the generator keeps a fit only if it reproduces every point within 0.3% of the
map and has the axis-aligned 3:2 map shape, so redrawn maps such as Stormwind
are handled). Where map rectangles
overlap, the map players recorded nearest the spawn decides; otherwise the
smallest map whose recorded area, then whose rectangle, contains it, never a
continent and never within 3% of a map edge. A Classic label within 40 yards of
an Efficient Games label for the same service is dropped, and its side comes
from the nearest recorded label. Tooltips mark these as Classic positions.

Validation against the 957 NPCs both sources place, leaving each NPC's own
recorded points out: 933 land on the same map (24 differ, mostly NPCs near zone
borders or ones Forever moved), and on the same map positions differ by a median
0.12% and a 90th percentile 0.52% of the map.

To refresh, clone the dataset, download the classic-db dump, regenerate and
update the commits in THIRD_PARTY_NOTICES.md (both copies):

```sh
git clone https://github.com/JIVESCORP/eg-link-output-wowf eg-data
git -C eg-data checkout <eg-commit>
curl -LO https://raw.githubusercontent.com/cmangos/classic-db/<db-commit>/Full_DB/ClassicDB_1_12_1_z2815.sql.gz
python tools/build_city_labels.py eg-data <eg-commit> ClassicDB_1_12_1_z2815.sql.gz <db-commit>
python tests/city_labels.py
```

The generator is deterministic and never downloads anything itself.

## Checks

`python tests/city_labels.py` covers both data files and their attribution, the
reported Undercity gaps, the trainer modes with profession detection, icons and
their fallback, Classic tooltips, first-release settings, deferred and
combat-safe attaching, disable/redraw, failure reporting, the settings page and
persistence against a mock of the inspected map canvas. It is not native
confirmation; icon availability in particular needs the game.

Native checks L1-L8 (Navigation, Action, Required state, Confirmation) are in
[TESTING.md](../TESTING.md#city-labels). New TOC files need one client restart.
