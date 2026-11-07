local _, addon = ...
addon.ForeverTrainingData = {}
local P = addon.ForeverTrainingData

-- All external values pass these checks before use. No native calls at file load.
function P.NewGuard(env)
    local G = {}
    function G:Public(value)
        if type(env.issecretvalue) ~= "function" then return false end
        local ok, secret = pcall(env.issecretvalue, value)
        return ok and secret == false
    end
    function G:Table(value)
        if not self:Public(value) or type(value) ~= "table" then return false end
        if env.canaccesstable ~= nil then
            if type(env.canaccesstable) ~= "function" then return false end
            local ok, accessible = pcall(env.canaccesstable, value)
            if not ok or accessible ~= true then return false end
        end
        return true
    end
    function G:Get(value, key)
        if not self:Table(value) then return nil, false end
        local ok, result = pcall(function() return value[key] end)
        if ok and self:Public(result) then return result, true end
        return nil, false
    end
    function G:Call(fn, ...)
        if type(fn) ~= "function" then return false end
        local ok, a, b, c, d = pcall(fn, ...)
        if not ok then return false end
        if not self:Public(a) or not self:Public(b) or
            not self:Public(c) or not self:Public(d) then return false end
        return true, a, b, c, d
    end
    function G:Integer(value, minimum, maximum)
        return self:Public(value) and type(value) == "number" and value == value and
            value >= minimum and value <= maximum and value % 1 == 0
    end
    function G:Array(value, maximum)
        if not self:Table(value) then return end
        local copy, count, highest = {}, 0, 0
        -- Caller contains traversal errors. Bound even malformed/sparse inputs.
        for key, id in pairs(value) do
            count = count + 1
            if count > maximum or not self:Integer(key, 1, maximum) or
                not self:Integer(id, 1, 2147483647) then return end
            if key > highest then highest = key end
            copy[key] = id
        end
        if highest ~= count then return end
        return copy
    end
    return G
end
