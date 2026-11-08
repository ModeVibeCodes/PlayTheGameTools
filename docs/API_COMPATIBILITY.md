# Forever API compatibility notes

## Enhanced Experience Bar

Uses public player XP/rest state, quest log metadata and reward XP APIs behind
function/type/restriction checks. No combat target data, native quest selection
changes, stock XP hooks or protected frames. See
[the research and native validation contract](ENHANCED_EXPERIENCE_BAR.md#api-research-and-licensing).

Quest-ID rewards, atlas rendering and level-up ordering need owner-confirmed
testing. Collapsed headers or missing/restricted rewards produce a visibly
incomplete estimate; unavailable XP hides the display. Shared Position Manager
owns movement. Static mocks do not establish native Blizzard support.
