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
- The live actions hide during combat, monitor Preview, Edit Mode and Move Windows. Contribution Preview and Edit Mode show an inert sample instead. Existing
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
   Contribution Window → Open Contributions / Preview Contributions; Detected Kits → Refresh; Contribution Position → Edit Contributions / Reset Position.
   **Action:** drag the header, Dismiss, reopen, leave/reenter camp, and reload;
   refresh after changing carried kits. **Required state:** OOC, ready kit.
   **Confirmation:** position persists; dismissal lasts this visit, reopening
   works while eligible, and a confirmed new visit can show ready items again.
4. **Navigation:** /ptg → header → Edit Mode → Exit / Save; Camp Contributions.
   **Action:** enter/exit Edit Mode, then enter/leave combat safely.
   **Required state:** a ready kit near a real fire; no placement while testing.
   **Confirmation:** only an inert sample appears in Edit Mode; all content hides in combat. Live actions resume only when
   eligible outside combat; no automatic item use occurs.
5. **Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
   Monitor → Camp Buffs → Show Your Camp Benefits / Separate Buff Window.
   **Action:** inspect earned buffs in joined and separate modes.
   **Required state:** readable native Camp Benefits timing, Preview off.
   **Confirmation:** only the native duration footer remains; no addon countdown subheading exists,
   and periodic stat text is retained.

## Preview and detected-kit controls

Open Contributions opens the eligible live window at a fire. **Preview Contributions**
is a distinct toggle: it shows one explicitly labeled sample row anywhere, even
with no carried kit or learned profession. It creates no action button, fabricates
no detected item and clears any cached native action attributes outside combat.
**Edit Contributions** enters the existing workspace and selects the registered
campfireContributions element (label Camp Contributions), using the same inert
sample. Its handles, X/Y and header drag share one saved managed position; older
contributionX/Y offsets migrate when the managed position is first created.
Aura refreshes preserve a current drag. Combat/tab/page/disable transitions stop
explicit samples; edit samples end with Exit / Save. Existing template-rejection
state does not prevent a harmless non-action preview.

**Detected Kits** lists names/counts from the latest ready-inventory scan, capped
at three names plus a remaining count. Refresh explicitly scans
outside combat even away from a fire; no placement window opens without confirmed
proximity. The concise Contributions TLDR combines the former availability/help
explanations. No kit is presented as already installed at the camp.

- **Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
  Monitor → Camp Contributions → Contribution Window → Preview Contributions.
  **Action:** enable the parent, monitor and Show Contribution Popup, start preview
  away from a fire, drag the header, then choose Stop Preview.
  **Required state:** OOC; no carried item/profession/fire required.
  **Confirmation:** labeled sample appears, moves and disappears; no item is used.
- **Navigation:** same tab → Camp Contributions → Contribution Position → Edit
  Contributions; Edit Mode → X Position / Y Position → Exit / Save.
  **Action:** select/move Camp Contributions, adjust coordinates, save and reload.
  **Required state:** OOC, monitor and popup enabled.
  **Confirmation:** existing handles edit the inert sample; saved position applies
  to preview and live windows. The sample never has a Place action.
- **Navigation:** same tab → Camp Contributions → Contribution Tools → Refresh
  Contributions; Detected Kits.
  **Action:** refresh while carrying a ready learned-profession kit, then remove
  it and refresh again. **Required state:** OOC, monitor/popup enabled.
  **Confirmation:** the detected name/count reflects each scan, including away
  from camp; sample text does not appear as a detected kit.

tests/campfire_controls.py exercises the actual settings buttons, color-wheel
apply/cancel, compact grid membership, inert sample and handle/header dragging,
saved positions, tab/combat teardown and disabled edit membership (mock only).

## Visibility correction and per-window styling

Owner confirms detection is correct but reports invisible live/preview content.
Root cause found: the initial frame had size but no screen anchor when registered
with Position Manager. Native GetCenter may be nil there, so geometry validation
rejects construction. The broad mock supplied a center even when unanchored.
Construction now sets a CENTER screen anchor before registration and uses the
existing addon preview layer (DIALOG level 90) above the settings window; a scoped
native-like geometry fixture guards this path. The sample includes an explicit
icon, title, dark row and panel, independently of item dispatch support.

Camp Contributions has separate Contribution Scale / Contribution Opacity /
Contribution Background controls. Contribution Position → Reset Position restores
the managed screen position to 0,120 without resetting other settings. Header
drag/shared Edit Mode remain supported. No tether or shared anchoring change was
needed; the existing independent position is preserved.

**Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
Monitor → Camp Contributions → Contribution Window → Preview Contributions;
Contribution Position → Reset Position / Edit Contributions.
**Action:** /reload, start preview, reset/move it, adjust Contribution Scale /
Contribution Opacity / Contribution Background, stop preview, then open the live
window at a fire with a ready kit. **Required state:** OOC, parent/monitor/popup
enabled; preview needs no item/fire. **Confirmation:** visible panel, title and
sample icon; live ready kit has its native icon and Place action. Click once and
complete native targeting to confirm placement. Native visual/use acceptance and
screenshots remain pending; detection is owner-confirmed.
