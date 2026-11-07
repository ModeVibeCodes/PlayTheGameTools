local _, addon = ...
local P = addon.ForeverTrainingData
P.factories = {}
P.records, P.chains = {}, {}
P.catalog = {definition={},ids={},talentIDs={}}

-- Only instantiate the detected player's class. There is no other-class browser.
function P.SelectClass(token)
    if token==P.class then return P.class~=nil,false end
    P.class,P.version,P.records,P.chains=nil,nil,{},{}
    P.catalog={definition={},ids={},talentIDs={}}
    local factory=type(token)=="string" and P.factories[token]
    if not factory then return false,true end
    local definition=factory()
    assert(definition.class==token and #definition.records>0 and #definition.records<=256)
    local seen,ids,talents={},{},{}
    for _,row in ipairs(definition.records) do
        assert(not seen[row.id],"Duplicate class training ID");seen[row.id]=true;ids[row.id]=true
        if row.previous then ids[row.previous]=true end
        for _,id in ipairs(row.required or {}) do ids[id]=true end
        if row.talent then ids[row.talent]=true;talents[row.talent]=true end
    end
    local catalog={definition={class=token},ids={},talentIDs={}}
    for id in pairs(ids) do catalog.ids[#catalog.ids+1]=id end
    for id in pairs(talents) do catalog.talentIDs[#catalog.talentIDs+1]=id end
    table.sort(catalog.ids);table.sort(catalog.talentIDs)
    P.class,P.version,P.records,P.chains,P.catalog=token,definition.version,definition.records,definition.chains,catalog
    return true,true
end
