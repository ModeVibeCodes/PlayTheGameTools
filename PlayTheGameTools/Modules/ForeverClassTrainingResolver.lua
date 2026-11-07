local _, addon = ...
local P = addon.ForeverTrainingData

function P.Known(snapshot, id)
    if snapshot.known[id] == true or (snapshot.book and snapshot.book[id] == true) then return true end
    return snapshot.known[id]
end

function P.TrainingTotal(rows)
    local total, count = 0, 0
    for _, row in ipairs(rows) do
        if row.tab == "To Learn" and row.known == false and not row.uncertain then
            total = total + row.record.cost; count = count + 1
        end
    end
    return total, count
end

function P.Applicable(record,snapshot)
    local unknown=false
    if record.faction then
        if not snapshot.faction then unknown=true elseif record.faction~=snapshot.faction then return false end
    end
    if record.race or record.races then
        if not snapshot.race then unknown=true
        else
            local match=record.race==snapshot.race
            for _,race in ipairs(record.races or {}) do if race==snapshot.race then match=true end end
            if not match then return false end
        end
    end
    if unknown then return nil end
    return true
end

-- Direct known evidence is never rewritten by the reference replacement chains.
function P.HigherKnown(id, snapshot)
    for _, chain in pairs(P.chains) do
        local found = false
        for _, other in ipairs(chain) do
            if found and P.Known(snapshot, other) == true then return other end
            if other == id then found = true end
        end
    end
end

function P.ResolveTraining(snapshot)
    local rows = {}
    if snapshot.class~=P.class then return rows end
    for _, record in ipairs(P.records) do
        local applicable=P.Applicable(record,snapshot)
        if applicable~=false then
        local known = P.Known(snapshot, record.id)
        local higher = P.HigherKnown(record.id, snapshot)
        local row = {record=record, known=known, higher=higher, reasons={}}
        if applicable==nil then row.uncertain=true;row.reasons[#row.reasons+1]="Race or faction unconfirmed" end
        if known == true then row.state = "Known now"
        elseif higher then row.state = "Superseded (catalog)"
        elseif known == nil then row.state = "Known state unknown"
        else row.state = "Not known" end
        if record.previous and P.Known(snapshot, record.previous) ~= true then
            if P.HigherKnown(record.previous, snapshot) then
                row.reasons[#row.reasons+1] = "Earlier prerequisite superseded in catalog chain"
            else
                row.reasons[#row.reasons+1] = "Previous rank not confirmed: " .. record.previous
                row.uncertain = true
            end
        end
        for _,id in ipairs(record.required or {}) do
            if P.Known(snapshot,id)~=true and not P.HigherKnown(id,snapshot) then row.uncertain=true;row.reasons[#row.reasons+1]="Required ability unconfirmed" end
        end
        if record.talent and snapshot.talents[record.talent] ~= true then
            row.reasons[#row.reasons+1] = snapshot.talents[record.talent] == false and
                "Required talent not selected" or "Required talent unknown"
            row.uncertain = true
        end
        if record.skill then
            row.reasons[#row.reasons+1] = "Skill " .. record.skill.id .. " requires " .. record.skill.rank .. "; current rank unknown"
            row.uncertain = true
        end
        for _,skill in ipairs(record.skills or {}) do row.uncertain=true;row.reasons[#row.reasons+1]="Skill prerequisite unconfirmed" end
        if known == true or higher then row.tab = "Learned"
        elseif type(snapshot.level) ~= "number" or known == nil then row.tab = "To Learn"; row.uncertain = true
        elseif record.level > snapshot.level then row.tab = "Upcoming"
        else row.tab = "To Learn" end
        if row.tab == "To Learn" then
            row.state = row.uncertain and "Requirements unknown or unmet" or "Training candidate"
            if known == nil then row.state = "Known state unknown" end
        elseif row.tab == "Upcoming" then row.state = "Upcoming by level" end
        rows[#rows+1] = row
        end
    end
    table.sort(rows, function(a,b)
        if a.record.level ~= b.record.level then return a.record.level < b.record.level end
        return a.record.id < b.record.id
    end)
    return rows
end
