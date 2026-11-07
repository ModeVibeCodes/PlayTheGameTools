local _, addon = ...
local P = addon.ForeverTrainingData

function P.NewReader(env, catalog)
    local G = P.NewGuard(env)
    local R = {}
    local function api(container, key)
        local fn = G:Get(container, key)
        return fn
    end
    local function activeConfig()
        local spec = env.C_SpecializationInfo
        local ok, group = G:Call(api(spec, "GetActiveSpecGroup"))
        if not ok or not G:Integer(group, 1, 8) then return end
        local valid, config = G:Call(api(spec, "GetCombatConfigIDForSpecGroup"), group)
        if valid and G:Integer(config, 1, 2147483647) then return group, config end
    end
    local function noStaged(config)
        local ok, purchases, refunds, swaps = G:Call(api(env.C_Traits, "GetStagedChanges"), config)
        if not ok then return false end
        if purchases == nil and refunds == nil and swaps == nil then return true end
        local a, b, c = G:Array(purchases, 512), G:Array(refunds, 512), G:Array(swaps, 512)
        return a ~= nil and b ~= nil and c ~= nil and #a == 0 and #b == 0 and #c == 0
    end
    local function talents()
        local group, config = activeConfig()
        if not config then return nil, "active-config-unavailable" end
        if not noStaged(config) then return nil, "pending-or-unreadable-talents" end
        local T = env.C_Traits
        local ok, info = G:Call(api(T, "GetConfigInfo"), config)
        local trees = ok and G:Array(G:Get(info, "treeIDs"), 4)
        if not trees or #trees == 0 then return nil, "trees-unavailable" end
        local result, targets, budget, entryBudget = {}, {}, 0, 0
        for _, id in ipairs(catalog.talentIDs) do targets[id] = true end
        for _, tree in ipairs(trees) do
            local valid, nodes = G:Call(api(T, "GetTreeNodes"), tree)
            nodes = valid and G:Array(nodes, 512)
            if not nodes then return nil, "nodes-unavailable" end
            for _, nodeID in ipairs(nodes) do
                budget = budget + 1
                if budget > 512 then return nil, "node-budget" end
                local readable, node = G:Call(api(T, "GetNodeInfo"), config, nodeID)
                local entries = readable and G:Array(G:Get(node, "entryIDs"), 16)
                local committed = readable and G:Array(G:Get(node, "entryIDsWithCommittedRanks"), 16)
                if not entries or not committed then return nil, "node-unavailable" end
                local selected, present = {}, {}
                for _, entry in ipairs(entries) do present[entry] = true end
                for _, entry in ipairs(committed) do
                    if not present[entry] then return nil, "inconsistent-committed-entry" end
                    selected[entry] = true
                end
                for _, entry in ipairs(entries) do
                    entryBudget = entryBudget + 1
                    if entryBudget > 512 then return nil, "entry-budget" end
                    local success, details = G:Call(api(T, "GetEntryInfo"), config, entry)
                    if not success or not G:Table(details) then return nil, "entry-unavailable" end
                    local definition = G:Get(details, "definitionID")
                    if not G:Integer(definition, 1, 2147483647) then
                        return nil, "unsupported-entry-definition"
                    end
                    local found, detail = G:Call(api(T, "GetDefinitionInfo"), definition)
                    if not found or not G:Table(detail) then return nil, "definition-unavailable" end
                    local spell, spellReadable = G:Get(detail, "spellID")
                    if not spellReadable or (spell ~= nil and not G:Integer(spell, 1, 2147483647)) then
                        return nil, "spell-definition-unavailable"
                    end
                    if spell and targets[spell] then
                        result[spell] = result[spell] == true or selected[entry] == true
                    end
                end
            end
        end
        local finalGroup, finalConfig = activeConfig()
        if group ~= finalGroup or config ~= finalConfig or not noStaged(config) then
            return nil, "talents-changed-during-read"
        end
        return result, "committed-entry-presence"
    end
    local function ooc()
        local ok, lock = G:Call(env.InCombatLockdown)
        local valid, combat = G:Call(env.UnitAffectingCombat, "player")
        return ok and valid and lock == false and combat == false
    end
    function R:Capture()
        local ok, snapshot = pcall(function()
            if not G:Public(env.WOW_PROJECT_ID) or not G:Public(env.WOW_PROJECT_CAMELOT) or
                type(env.WOW_PROJECT_CAMELOT) ~= "number" or
                env.WOW_PROJECT_ID ~= env.WOW_PROJECT_CAMELOT then return nil end
            if not ooc() then return nil end
            local S = {known={}, membership={}, knownStatus={}, membershipStatus={},
                skills={}, talents={}, talentStatus="unavailable"}
            local readable, _, class = G:Call(env.UnitClass, "player")
            if readable and type(class) == "string" then S.class = class end
            if S.class~=catalog.definition.class then return nil end
            local raceOK,_,_,raceID=G:Call(env.UnitRace,"player")
            if raceOK and G:Integer(raceID,1,1000) then S.race=raceID end
            local factionOK,faction=G:Call(env.UnitFactionGroup,"player")
            if factionOK and (faction=="Alliance" or faction=="Horde") then S.faction=faction end
            local valid, level = G:Call(env.UnitLevel, "player")
            if valid and G:Integer(level, 1, 1000) then S.level = level end
            local bank = G:Get(G:Get(env.Enum, "SpellBookSpellBank"), "Player")
            if G:Integer(bank, 0, 16) then
                for _, id in ipairs(catalog.ids) do
                    local knownFn = api(env.C_SpellBook, "IsSpellKnown")
                    local success, known = G:Call(knownFn, id, bank)
                    if success and type(known) == "boolean" then S.known[id] = known end
                    S.knownStatus[id] = type(knownFn) ~= "function" and "api-unavailable" or
                        not success and "error-or-restricted" or
                        type(known) ~= "boolean" and "nonboolean-result" or "readable"
                    -- Diagnostic comparison only; NEVER used to infer known or prerequisites.
                    local memberFn = api(env.C_SpellBook, "IsSpellInSpellBook")
                    local found, member = G:Call(memberFn, id, bank, false)
                    if found and type(member) == "boolean" then S.membership[id] = member end
                    S.membershipStatus[id] = type(memberFn) ~= "function" and "api-unavailable" or
                        not found and "error-or-restricted" or
                        type(member) ~= "boolean" and "nonboolean-result" or "readable"
                end
            end
            local talentOK, values, reason = pcall(talents)
            if talentOK and values then S.talents = values end
            S.talentStatus = talentOK and reason or "talent-read-error"
            local buildOK, version, build, _, interface = G:Call(env.GetBuildInfo)
            if buildOK and type(version) == "string" and type(build) == "string" and
                G:Integer(interface, 1, 1000000) then
                S.version, S.build, S.interface = version, build, interface
            end
            local _, _, finalClass = G:Call(env.UnitClass, "player")
            local _, finalLevel = G:Call(env.UnitLevel, "player")
            if not ooc() or S.class ~= finalClass or S.level ~= finalLevel then return nil end
            return S
        end)
        if ok and snapshot then return snapshot end
        return nil, "capture-unavailable-or-context-changed"
    end
    return R
end
