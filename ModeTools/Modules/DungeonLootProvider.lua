local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end

-- Read-only interoperability with the user's separately installed DungeonJournal.
-- No upstream records, wording, code or assets are distributed in this addon.
local P = {}
addon.DungeonLootProvider = P
local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Text(v)
    if not Public(v) or type(v) ~= "string" then return nil end
    -- Keep the independent UI free of upstream texture/atlas and color markup.
    return v:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
local function Table(v) return Public(v) and type(v) == "table" and v or {} end
local function ID(v)
    if Public(v) and type(v) == "number" and v > 0 and v < 10000000 and v == math.floor(v) then return v end
end
local function Map(v)
    v = Table(v)
    local label = Text(v.label)
    if Public(v.x) and Public(v.y) and type(v.x) == "number" and type(v.y) == "number"
        and v.x >= 0 and v.x <= 1 and v.y >= 0 and v.y <= 1 then
        return (label or "Location") .. string.format(" (%.1f, %.1f)", v.x * 100, v.y * 100)
    end
    return label
end
local function Items(source, reward)
    local items = {}
    for _, raw in ipairs(Table(source)) do
        raw = Table(raw)
        local id = ID(raw[1])
        if id then items[#items + 1] = { id = id, name = Text(raw[2]) or ("Item " .. id),
            slot = not reward and Text(raw[3]) or nil } end
    end
    return items
end
local fields = { "objective", "pickup", "turnin", "note", "warning", "description", "faction", "classOnly", "rewards", "rewardSummary" }
local function Quest(raw, ns, step, stepID, stepName)
    raw = Table(raw)
    local q = { id = ID(raw.id) or ID(stepID), name = Text(raw.name) or Text(stepName) or "Unnamed quest", level = ID(raw.level), requires = ID(raw.requires) }
    for _, field in ipairs(fields) do q[field] = Text(raw[field]) end
    q.start = Map(raw.startMap or raw.map or Table(ns.QUEST_START_MAPS)[q.id])
    q.finish = Map(raw.turninMap)
    q.items = Items(raw.rewardItems, true)
    q.startItem = Items(raw.startItem and {raw.startItem}, true)[1]
    q.startObject = Text(Table(raw.startObject)[1])
    q.startHint = Text(Table(raw.startItem)[4]) or Text(Table(raw.startObject)[3])
    q.chain = {}
    if not step then
        for _, entry in ipairs(Table(Table(ns.QUEST_PREREQ_CHAINS)[q.id])) do
            entry = Table(entry)
            local detail = Table(Table(ns.QUEST_PREREQ_DETAILS)[ID(entry.id)])
            local normalized = Quest(detail, ns, true, entry.id, entry.name)
            normalized.id, normalized.name = ID(entry.id), Text(entry.name) or normalized.name
            q.chain[#q.chain + 1] = normalized
        end
    end
    return q
end
function P:Read()
    local ns = Table(_G.ForeverDungeonJournal_NS)
    local db = Table(ns.DB)
    local result = { catalog = {}, bosses = {}, quests = {}, available = false }
    for name, dungeon in pairs(db) do
        if Text(name) and type(dungeon) == "table" then result.catalog[#result.catalog + 1] = Text(name) end
    end
    local found
    for _, name in ipairs(result.catalog) do if name == "Shadowfang Keep" then found = true end end
    if not found then result.catalog[#result.catalog + 1] = "Shadowfang Keep" end
    table.sort(result.catalog)
    local raw = db["Shadowfang Keep"]
    if type(raw) ~= "table" then
        result.source = "DungeonJournal data unavailable. Enable ForeverDungeonJournal in the AddOns list, then /reload."
        return result
    end
    local version = "unknown version"
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        local ok, value = pcall(C_AddOns.GetAddOnMetadata, "ForeverDungeonJournal", "Version")
        if ok then version = Text(value) or version end
    end
    result.available = true
    result.source = "Source: installed DungeonJournal " .. version .. ". Community tables; current drops and quest availability are not independently confirmed."
    result.location, result.level = Text(raw.location), Text(raw.level)
    for _, boss in ipairs(Table(raw.bosses)) do
        boss = Table(boss)
        result.bosses[#result.bosses + 1] = { name = Text(boss.name) or "Unnamed encounter", items = Items(boss.loot) }
    end
    for _, quest in ipairs(Table(raw.quests)) do
        result.quests[#result.quests + 1] = Quest(quest, ns)
    end
    return result
end
