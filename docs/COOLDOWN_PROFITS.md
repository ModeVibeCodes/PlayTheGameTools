# Cooldown Profits

Opt-in module (`cooldownProfits`, Quality of Life). It ranks profession
cooldown crafts by the gold they earn a day, so you can see which transmute or
other cooldown is worth learning and running. Designed in the PTG v2 design
artifact (Exploring: Cooldown Profits).

## What it covers

| Craft | Profession | Recipe / item | Usual cooldown | Bundled timer group |
| --- | --- | --- | --- | --- |
| Transmute: Arcanite | Alchemy | spell 17187 | 2 days | its own |
| Undeath to Water, Water to Undeath, Earth to Water, Water to Air, Air to Fire, Fire to Earth, Earth to Life, Life to Earth | Alchemy | spells 17563, 17564, 17561, 17562, 17559, 17560, 17566, 17565 | 1 day | shared transmute |
| Transmute: Iron to Gold | Alchemy | spell 11479 | 1 day | shared transmute |
| Transmute: Mithril to Truesilver | Alchemy | spell 11480 | 2 days | shared transmute |
| Mooncloth (at a moonwell) | Tailoring | spell 18560 | 4 days | its own |
| Refined Deeprock Salt (Salt Shaker) | Leatherworking 250 | item 15846 | 3 days | its own |

Spell names, cooldowns and item IDs were checked on Wowhead Classic. The salt
goes into Cured Rugged Hide, which has no cooldown of its own.
Transmute: Elemental Fire (10 minutes) is not a long cooldown and is left out.

Bundled guesses that the module corrects from what it sees in game:

- **Cooldown length.** The usual Classic length is shown with `~` until a
  craft starts while that profession's window is open. The time left at that
  moment becomes the length (account-wide, rounded up to the minute). The Salt
  Shaker reports its exact length as an item cooldown.
- **Shared timers.** Most transmutes are assumed to share one timer and
  Arcanite to have its own. When two learned recipes are read together and one
  is on its timer while the other is ready, they don't share. When both show
  the same time left (within 2 s), they do. Different times left prove nothing.

Reagent counts are the Classic ones (1 to 1 for transmutes, 2 Felcloth for
Mooncloth, Thorium Bar + Arcane Crystal for Arcanite). They aren't read from
the client.

## How profit is worked out

`profit = sale price − 5% auction house cut − materials at market price`, and
`per day = profit × 24 h ÷ cooldown length`. The window can drop the cut
(**Take off the 5% auction house cut** off) and count materials you farmed as
free (**Count my own materials as free**). A craft whose item had no listing
in the last scan shows **No price**, never a guess. A price older than 3 days is
marked `*`; the row's tooltip says how old.

**Your learned cooldowns earn** adds the best learned craft on each timer.
**Worth learning** shows, for each recipe you could learn in your
professions, how much more a day that plan would earn with it, and why: it
has its own timer, it takes a shared timer from a learned one, or it shares a
timer with a better one.

## Game and add-on APIs

All calls are guarded (`pcall`, type and secret-value checks). Nothing is
crafted, used or clicked; no protected frames are touched.

- **Professions:** `GetProfessions` / `GetProfessionInfo`, matched by skill
  line (Forever 2937/2948/2945, legacy 171/197/165), as Class Training reads
  them.
- **Recipes and timers:** the Forever client uses the Retail-style Professions
  UI (`C_TradeSkillUI`; its RecipeSchematicForm reads
  `C_TradeSkillUI.GetRecipeCooldown(recipeID)` as seconds left). On
  `TRADE_SKILL_SHOW` / `TRADE_SKILL_LIST_UPDATE`, outside combat, the module
  takes the open profession from `C_TradeSkillUI.GetBaseProfessionInfo()`
  (`professionID` or `parentProfessionID`) and reads only that profession's
  recipes: `GetRecipeInfo(spell).learned` (or `IsPlayerSpell` when it says
  true) and `GetRecipeCooldown(spell)`. A recipe the client says nothing about
  stays unknown ("Open Alchemy to check"), never "Not learned".
- **Salt Shaker:** `C_Item.GetItemCount(15846)` and
  `C_Container.GetItemCooldown(15846)` (start, duration against `GetTime`).
- **Prices:** Auctionator's public API, read from the installed Forever copy
  (`Source/API/v1`): `Auctionator.API.v1.GetAuctionPriceByItemID(callerID,
  itemID)` returns copper or nil; `GetAuctionAgeByItemID` returns days since
  seen, nil past 21 days; `RegisterForDBUpdate(callerID, callback)` fires
  after a scan. Both raise errors on bad arguments, so every call is wrapped.
  The caller ID is `PlayTheGameTools`. Auctionator is an optional dependency
  (TOC `OptionalDeps`); without it the window says so and shows timers only.

## Saved data

Settings in the profile (`modules.cooldownProfits`): `cut`, `freeMaterials`,
`view` (`learned`/`mine`/`all`), `sort` (`day`/`craft`), `remind`,
`remindBest`. Timers are per character and the game's rules account-wide, so
they live outside every profile in `PTGToolsDB.cooldownProfits`
(`characters[guid].recipes[id] = {learned, readyAt, announced}`,
`durations[id]`, `shares["a|b"]`). Profile export and import never carry
them. Nothing existing is changed or removed.

## Limitations

- Learned recipes and timers update only when that profession's window opens.
  The window then shows what it last saw.
- A shared timer whose category recovery is shorter than one recipe's own
  cooldown could be read as "not shared" once its category time runs out.
- Profit uses Auctionator's last scanned minimum buyout. It says nothing about
  how many sell.

## Manual checks (native confirmation pending)

1. **Turn it on.** Navigation: `/ptg` → sidebar **Cooldown Profits**. Action:
   turn on the page header switch. Required state: out of combat.
   Confirmation: the page shows **Reminders** and **Prices**, the header shows
   **Open Cooldown Profits**, and the Quick Actions ring gains a coin icon.
2. **Prices.** Navigation: auction house → Auctionator → full scan, then the
   page header's **Open Cooldown Profits**. Required state: Auctionator
   enabled. Confirmation: the status line ends "Prices from Auctionator's last
   scan" and transmute rows show Materials, Sells for, Profit and Per day.
3. **Recipes.** Navigation: open your Alchemy (then Tailoring) profession
   window, then **Open Cooldown Profits**. Required state: out of combat.
   Confirmation: learned transmutes show **Ready** or "N h left", unlearned
   ones **Not learned**, and none still say "Open Alchemy to check".
4. **Length and sharing.** Navigation: Alchemy window. Action: craft a ready
   transmute with the window open, then hover its row in Cooldown Profits.
   Confirmation: its Cooldown loses the `~`, and the tooltip names the recipes
   it shares a timer with (and leaves out Arcanite if Arcanite stayed Ready).
5. **Controls.** In the window, choose **Show: Learned / My professions /
   All** and **Sort: Per day / Per craft**, and tick the two checkboxes.
   Confirmation: rows filter and reorder, and Profit changes by the 5% cut or
   the material cost.
6. **Reminder.** Settings: **Tell me when a cooldown is ready** on. Required
   state: a learned cooldown that finishes while you are logged in.
   Confirmation: one chat line "Cooldown Profits: <craft> is ready, worth … a
   day." and no repeat.
