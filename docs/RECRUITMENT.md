# Recruitment: native invitation handoff

The Forever client rejected the pilot's C_GuildInfo.Invite call with
ADDON_ACTION_FORBIDDEN and operation UNKNOWN(). A click and guildmaster rank do
not authorize addon execution. The former handler matched Invite in the operation
name and missed UNKNOWN(). The direct Invite method/button is now removed.

Candidate rows have Draft Whisper, Player Menu Link, Mark Contacted and Skip Player.
Player Menu Link prints a local native player hyperlink; the player right-clicks
that name and uses Blizzard's guild invitation option if available. It does not
invoke an invitation, simulate a native click or claim delivery. Draft Whisper
still requires player Enter. Settings and existing contact history are retained.

Pending searches fail closed on ModeTools-owned UNKNOWN() or unreadable rejection
operations, as well as named SendWho blocks. They stop for the session with no
automatic retry. Manual native Who imports remain available. Other addons' errors
are ignored. No new protected APIs, secure execution tricks or input hooks.

## Validation

Run python tests/smoke.py, python tests/recruitment.py and python tools/build_release.py.
Mock checks do not establish native player-menu availability or receipt.
Screenshots: pending. Real Forever screenshots must crop chat and other players'
names; no mockup or rendered screenshot substitutes are used.

1. **Navigation:** Play The Game Tools > Guild Tools > Recruitment > Pilot > Enable Recruitment.
   **Action:** enable it. **Required state:** OOC. **Confirmation:** ready status.
2. **Navigation:** Play The Game Tools > Guild Tools > Recruitment > Search > New Level Sweep > Start Scan.
   **Action:** scan a populated level (Minimum Level/Maximum Level inputs, Enter to save).
   **Required state:** OOC, no competing Who scan. **Confirmation:** guildless candidate
   rows with four actions, with no direct Invite button. If search is blocked,
   use native Who, then Native Who Fallback > Read Who Results.
3. **Navigation:** Play The Game Tools > Guild Tools > Recruitment > Candidates > occupied Candidate row > Player Menu Link.
   **Action:** click, right-click the printed name, inspect the native menu.
   **Required state:** OOC, guild invite permission, consenting guildless recipient.
   **Confirmation:** report whether a guild invite option exists, its actual label,
   and recipient-confirmed receipt if used. The native option has not been verified;
   do not assume a specific label or substitute a protected addon call.
4. **Navigation:** Play The Game Tools > Guild Tools > Recruitment > Candidates > occupied Candidate row > Draft Whisper.
   **Action:** review the draft, Enter only if desired.
   **Required state:** OOC, empty chat input. **Confirmation:** no automatic sending.
5. **Navigation:** Play The Game Tools > Guild Tools > Recruitment > Candidates > occupied Candidate row > Mark Contacted or Skip Player.
   **Action:** mark a test entry, reload and rescan. **Required state:** OOC.
   **Confirmation:** identity remains hidden until Forget Contacted / Skipped > Clear History.

Native checks and screenshots pending; no live sync or release is implied by this PR.
