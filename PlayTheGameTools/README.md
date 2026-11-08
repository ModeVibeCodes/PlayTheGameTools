# Play The Game Tools

**By Mode** · WoW Forever · Public beta candidate 0.2.0-beta.1

Play The Game Tools brings useful everyday tools into one modular addon with a unified dark
configuration interface. Enable the features you want, adjust their appearance,
and keep your settings between sessions. Open configuration with `/ptg`.

This distribution is for **WoW Forever only**. It does not include Retail gameplay
modules. The project display name is Play The Game Tools; the addon is named Play The Game Tools.

## Included features

- **Combat Timer:** player combat elapsed time, configurable appearance and
  positioning, with preview and editing controls.
- **Automation:** optional native Auto Loot setting, quest acceptance/turn-in and
  merchant junk selling/personal-funds repair, with conservative eligibility
  checks and a selectable modifier to keep quest interactions manual.
- **Class Training:** automatically selects your current class from all nine
  Forever classes. Browse To Learn, Upcoming, Learned and Directory; refresh from
  your spellbook and trainer interactions; see reference training costs; use a
  movable shortcut and scrollable training popout. Level-up alerts have a preview
  and optional time-to-level, money and profession summaries.
- **Quick Access and Food Bar:** configurable profession/utility access, food
  selection and optional bandages with existing native click/combat guards.
- **Threat Meter:** opt-in threat list for your current target with class-colored
  bars and percentages; pets are optional and off by default.
- **Guild Recruitment:** opt-in Who sweeps by level range and class (capped
  ranges are split and searched again), a Recruiter window (`/ptgr`) with a
  copy-name box for Guild > Add Member, optional whisper after a confirmed invite,
  a re-invite window, a never-invite list and invite/join/decline statistics.
- **Loot Sparkles:** opt-in Gameplay Enhancements under Questing & Leveling; clearer quest objects, herbs, ore and lootable corpses with optional names and range text. Custom indicators pause in combat.
- **Campfire Monitor:** Gameplay Enhancements tab with an optional native nearby-fire icon/text display, compact earned bonuses in a joined or separately movable window, appearance/position controls and a profession reference guide. Campfire monitoring starts off. Includes a movable Camp Contributions popup for ready carried profession kits, with native click-to-place actions, detected-kit summary, safe sample preview and shared Edit Mode positioning. Text colors use the native picker; gradients are optional. Contributions has independent window, icon, row and text styling; quick jumps link the three campfire elements.
- **Shared configuration:** independent module switches, saved settings, appearance
  controls and positioning/preview tools where supported by the module.

## Collaborate

This is the standalone public **Forever-only** source repository for the Play The
Game guild. Clone or fork [ModeVibeCodes/PlayTheGameTools](https://github.com/ModeVibeCodes/PlayTheGameTools).
See [CONTRIBUTING.md](CONTRIBUTING.md) for branches and pull requests and
[the development guide](docs/DEVELOPMENT.md) for tests, packaging and installation.
All addon code is editable under `PlayTheGameTools/`; this checkout needs no other repository.
There is no automatic synchronization with another checkout or live installation.

## Install

Once a release has been published, download the `PlayTheGameTools-<version>-forever.zip`
asset from this repository's Releases page. Close WoW and extract it into your
Forever client's `Interface/AddOns` directory. The result must be
`Interface/AddOns/PlayTheGameTools/PlayTheGameTools.toc`. Start WoW and enable Play The Game Tools in AddOns.
Upgrading from a build installed as `Interface/AddOns/ModeTools`: with WoW closed, delete that folder and install this one, then rename `WTF/Account/<ACCOUNT>/SavedVariables/ModeTools.lua` to `PlayTheGameTools.lua`. If a `PlayTheGameTools.lua` already exists there, it belongs to the retired standalone recruiter of the same folder name; back it up first. Your settings are adopted on the next login and nothing is reset.

For client-managed installation after publication, choose Forever in WowUp, open
Get Addons → Install from URL, and use this repository's URL. Select the appropriate
testing channel if needed and confirm the offered version. A direct ZIP URL is a
one-time installation; use the repository source for recurring updates. See
[WowUp's installation guide](https://wowup.io/guide/get-addons/overview).

Installable files are attached release assets. GitHub's automatic source-code ZIP
is not the installable package. Use one addon manager/source for this folder.

## First use and beta limits

Class Training defaults on for new preferences and preserves an existing explicit
off setting. Combat Timer and Automation default off; enable them individually
in configuration. Automation can accept/complete quests, sell eligible junk and
spend personal funds when enabled. Review its switches before use. Gray equipment
selling requires a separate opt-in. Auto Loot changes Blizzard's setting; disabling
the option does not restore the previous client setting.

Training costs are catalog estimates before discounts, not guaranteed trainer
offers. Eligibility can be uncertain; pet training, tomes, quest acquisition and
all special training cases are not comprehensively covered. No cross-class browser
is provided. Auto Gossip is unavailable and remains manual. Development prototypes
and Retail-only features are excluded.

This is a beta candidate. Static checks do not establish in-game behavior; the
candidate testing checklist is in [TESTING.md](TESTING.md). Recent popout/all-class
behavior and native Automation acceptance still need the results recorded there.
Screenshots will be added later.

## Updates and feedback

Public updates are released when Mode approves a new version; development changes
do not automatically publish. Close WoW when updating and retain your own settings.
Do not delete SavedVariables as a routine update step.

Contact **Mode on Discord: NoJumperMike** as the primary support method, also shown
on the in-game dashboard. Include addon version, Forever build, class/level, exact
steps, expected/observed behavior and Lua error text if present. Remove personal
information from attachments. This repository's Issues tab, when enabled, is an
additional reporting option.

## License and credits

Play The Game Tools original code is open source under [MIT](LICENSE). See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for training-catalog attribution
and artwork ownership. WoW and Blizzard assets remain the property of Blizzard
Entertainment. Play The Game Tools is an independent community addon.
