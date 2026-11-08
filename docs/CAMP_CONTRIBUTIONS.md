# Camp contributions (Forever)

Campfire Monitor now offers a movable **Camp Contributions** popup at a native
nearby fire. It lists ready carried contribution kits for professions the player
knows, with native names/icons, profession, stack count and a **Place** action.
The popup switch defaults on inside the existing opt-in Campfire Monitor. No
separate registered module or changes to Retail/shared core are involved.

## Availability and interaction

- The identity lookup covers 36 kits across twelve professions. Fire-building
  kits are excluded: the popup contributes to an existing fire. No crafting,
  bank search, contribution automation or guessed camp object positions.
- Native profession skill-line identity, carried bag contents, public unlocked
  stack data, C_Item.IsUsableItem and GetContainerItemCooldown gate each row.
  Missing/secret data fails closed. Item names/icons must be natively cached;
  missing metadata is requested once and the load-result event refreshes it.
- Readiness is an inventory/usability/cooldown check, not proof that a particular
  fire accepts placement. Native range, tier/skill, camp slots, one-contribution
  and shared-cooldown rules still apply on use. The nearby aura provides no
  exact placement distance; the player may need to move closer.
- Each row uses Blizzard's unprotected InsecureActionButtonTemplate, retaining
  its native OnClick. A user hardware click dispatches the whitelisted item's
  native /use macro outside combat. No synthetic clicks, direct use API, OnClick
  replacement, automatic ground targeting or placement bypass. Finish any native
  ground reticle/cast required by the item. Unsupported dispatch hides actions.
- The popup hides during combat, Preview, Edit Mode and Move Windows. Existing
  attributes are not mutated in combat; native template/macro combat guards also
  block use. Drag the popup header outside combat to save its separate position.
- Dismiss suppresses the popup for the current camp visit. Confirmed absence of
  the nearby aura rearms it; an unreadable aura does not. Open Contributions can
  reopen it manually while eligible. Disabled/away states perform no bag scans.
- Bag/lock/cooldown/profession/item-cache events invalidate a cached scan. A
  generation-checked one-shot wake handles a known cooldown expiry. No inventory
  polling or duplicate player-aura listener; the monitor supplies proximity.

## Research and licensing

Native API and action behavior were checked against Blizzard's classic UI source:
[container documentation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua),
[item documentation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua),
[native action template](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml)
and [dispatch implementation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
The addon already uses this out-of-combat template in ForeverFoodBar. The actual
Forever client's template dispatch and item placement still require player testing.

[Blizzard's camp overview](https://news.blizzard.com/en-us/article/24301516/gather-around-the-campfire-in-world-of-warcraft-forever)
describes profession contributions and native camp limits. Item identities were
checked in MIT-licensed [Forever Forge CampfireAlert](https://github.com/crumpshot-forever/ForeverForge/blob/94b37bfe89832050a45641786f74d38fd024fca4/Modules/CampfireAlert.lua).
The lookup is independently grouped by native profession IDs; dispatch/UI code
and artwork are original/native. Its MIT notice is retained in both third-party
notice copies. Installed NaowhForever profession recipe data was inspected only
to corroborate factual item identities; its all-rights-reserved source/catalog
was not copied. No reference addon was changed.

## Validation and exact native checks

tests/camp_contributions.py covers filtering/deduplication, unknown data, native
template intent, combat guards, dismissal/rearm, cooldown/cache events, saved
movement, settings and Preview/Edit Mode suppression. Mock checks establish
neither native hardware dispatch nor successful placement. Screenshots and all
new native interactions remain pending user confirmation.

1. **Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
   Monitor → Enable Campfire Monitor; Camp Contributions → Show Contribution Popup.
   **Action:** /reload, enable the parent header and monitor, enable the popup,
   approach a real fire with a ready carried contribution kit for a learned
   profession. **Required state:** OOC, Preview off, Edit Mode closed.
   **Confirmation:** Camp Contributions appears with native item/profession/count;
   unrelated items, fire kits and unusable/cooling kits do not appear.
2. **Navigation:** Camp Contributions → Place (on the desired item row).
   **Action:** click once and finish any native ground placement. **Required
   state:** OOC, native range/skill/camp capacity permit use.
   **Confirmation:** native placement/use follows the user click; bag/cooldown
   events remove unavailable rows. Native rejection remains authoritative.
3. **Navigation:** Camp Contributions → header / Dismiss; /ptg → Questing &
   Leveling → Gameplay Enhancements → Campfire Monitor → Camp Contributions →
   Contribution Window → Open Contributions; Carried Camp Kits → Refresh Contributions.
   **Action:** drag the header, Dismiss, reopen, leave/reenter camp, and reload;
   refresh after changing carried kits. **Required state:** OOC, ready kit.
   **Confirmation:** position persists; dismissal lasts this visit, reopening
   works while eligible, and a confirmed new visit can show ready items again.
4. **Navigation:** /ptg → header → Edit Mode → Exit / Save; Camp Contributions.
   **Action:** enter/exit Edit Mode, then enter/leave combat safely.
   **Required state:** a ready kit near a real fire; no placement while testing.
   **Confirmation:** actions hide in Edit Mode/combat and resume only when
   eligible outside combat; no automatic item use occurs.
5. **Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
   Monitor → Display → Show Your Camp Benefits / Separate Buff Window.
   **Action:** inspect earned buffs in joined and separate modes.
   **Required state:** readable native Camp Benefits timing, Preview off.
   **Confirmation:** the sole remaining-time display is the Camp Buffs subheading;
   native duration-only footer rows are absent and periodic stat text is retained.
