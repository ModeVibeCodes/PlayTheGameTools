local _, addon = ...
if not addon.Edition or addon.Edition.name ~= "Forever" then return end
local D = {}
addon.ForeverQuickAccessData = D

function D.Public(value)
    if type(issecretvalue) ~= "function" then return false end
    local ok, secret = pcall(issecretvalue, value)
    return ok and secret == false
end
function D.Number(value, low, high)
    return D.Public(value) and type(value)=="number" and value==value and value>=low and value<=high
end
function D.OutsideCombat()
    if type(InCombatLockdown)~="function" or type(UnitAffectingCombat)~="function" then return false end
    local ok, locked=pcall(InCombatLockdown)
    local valid, combat=pcall(UnitAffectingCombat,"player")
    return ok and valid and D.Public(locked) and D.Public(combat) and locked==false and combat==false
end

D.ranges={scale={50,200,5},iconSize={16,80,1},columns={1,5,1},spacing={0,24,1},padding={0,32,1},
    outOpacity={0,100,5},combatOpacity={0,100,5},fadeDuration={0,2,0.1},
    backgroundOpacity={0,100,5},borderOpacity={0,100,5},fontSize={8,20,1},x={-10000,10000,1},y={-10000,10000,1}}
local defaults={scale=100,iconSize=36,columns=5,spacing=6,padding=8,outOpacity=100,combatOpacity=0,
    fadeDuration=0.2,backgroundOpacity=65,borderOpacity=80,fontSize=11,x=0,y=-180,
    locked=true,showNames=false,showTooltips=true,hoverReveal=true,font="game",fontMedia="",outline=false,showProfessionBar=true,
    backgroundColor={0.035,0.045,0.06},borderColor={0.32,0.40,0.48},textColor={0.9,0.93,0.97}}
function D.Initialize(db,styleOnly)
    for key,value in pairs(defaults) do
        if db[key]==nil then
            db[key]=type(value)=="table" and {unpack(value)} or value
        end
        if D.ranges[key] then
            local r=D.ranges[key]
            assert(D.Number(db[key],r[1],r[2]),"Invalid Quick Access Bars setting: "..key)
            if r[3]==1 then assert(db[key]%1==0,"Invalid Quick Access Bars integer: "..key) end
        elseif type(value)=="table" then
            assert(type(db[key])=="table","Invalid Quick Access Bars color: "..key)
            for i=1,3 do assert(D.Number(db[key][i],0,1),"Invalid Quick Access Bars color: "..key) end
        else assert(type(db[key])==type(value),"Invalid Quick Access Bars setting: "..key) end
    end
    assert(db.font=="game" or db.font=="chat","Invalid Quick Access Bars font")
    assert(#db.fontMedia<=128,"Invalid Quick Access Bars media font")
    if db.hidden==nil then db.hidden={} end
    assert(type(db.hidden)=="table","Invalid Quick Access Bars profession preferences")
    for id,hidden in pairs(db.hidden) do
        assert(D.Number(id,1,2147483647) and id%1==0 and type(hidden)=="boolean","Invalid profession preference")
    end
    if not styleOnly and addon.ForeverFoodBar then addon.ForeverFoodBar.Initialize(db) end
end

-- Five explicit slots: a nil first profession must not truncate secondary skills.
-- Native Camelot slots are primary1, primary2, First Aid, Fishing, Cooking.
function D.ReadProfessions()
    if not D.OutsideCombat() then return nil,"Profession data is available outside combat." end
    if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then
        return nil,"The native profession reader is unavailable."
    end
    local ok,a,b,c,d,e=pcall(GetProfessions)
    if not ok then return nil,"The native profession reader failed." end
    local slots={a,b,c,d,e}
    local result,seen={},{}
    for i=1,5 do
        local index=slots[i]
        if not D.Public(index) then return nil,"Profession data is restricted." end
        if index~=nil then
            if not D.Number(index,1,4096) or index%1~=0 then return nil,"Profession data is unavailable." end
            local valid,name,icon,rank,maxRank,count,offset,id=pcall(GetProfessionInfo,index)
            if not valid or not D.Public(name) or not D.Public(icon) or not D.Public(rank) or
                not D.Public(maxRank) or not D.Number(id,1,2147483647) or id%1~=0 or
                type(name)~="string" or name=="" or
                not ((type(icon)=="number" and D.Number(icon,1,2147483647)) or (type(icon)=="string" and icon~="")) then
                return nil,"Profession details are unavailable. Try Refresh Professions outside combat."
            end
            if not seen[id] then
                seen[id]=true
                result[#result+1]={id=id,name=name,icon=icon,
                    rank=D.Number(rank,0,10000) and rank or nil,maxRank=D.Number(maxRank,0,10000) and maxRank or nil}
            end
        end
    end
    return result,#result==0 and "No learned professions found." or "Learned professions are up to date."
end

function D.Geometry(count,db)
    local columns=math.min(math.max(1,count),db.columns)
    local rows=math.max(1,math.ceil(count/columns))
    local cellHeight=db.iconSize+(db.showNames and db.fontSize+4 or 0)
    return 2*db.padding+columns*db.iconSize+(columns-1)*db.spacing,
        2*db.padding+rows*cellHeight+(rows-1)*db.spacing,columns,cellHeight
end
