# Feature registry

| Feature | Configuration | Scope | Native status |
| --- | --- | --- | --- |
| Loot Sparkles | Questing & Leveling -> Gameplay Enhancements -> Loot Sparkles | Default-off native quest effect plus one-target herb/ore/quest/corpse glints and names; appearance controls; owned CVar restoration | Static fixtures only; native validation and screenshots pending; [details](LOOT_SPARKLES.md) |
| Dungeon Loot | Questing & Leveling → Dungeon Loot | All recorded Forever dungeon/wing cards, boss/quest details, automatic faction/class filtering and quest-log/completion card status, deduplicated chain tasks and bracket jumps, native map/copy controls; bundled GPLv3 catalog; no DungeonJournal dependency | SFK and PR #8 player-progress/completion/layout revision accepted in-game by owner; screenshots pending |

See [Dungeon Loot](DUNGEON_LOOT.md) for source provenance, dependencies, API
assumptions, limitations and exact manual checks. Existing modules are documented
in the README and their owning source/config files; this registry begins with the
Dungeon Loot pilot and does not replace their documentation.
