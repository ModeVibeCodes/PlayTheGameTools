local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- Profession cooldown crafts and the arithmetic that ranks them. Pure data
-- and functions, no game calls, so tests run them directly.
-- Recipe (spell) and item IDs are WoW Classic IDs, checked against Wowhead
-- Classic. Cooldown lengths are the Classic ones; the module replaces a
-- length with the one it sees when a craft starts, since Forever may differ.
local D={}
addon.CooldownProfitsData=D

D.HOUR=3600
D.DAY=86400
D.AH_CUT=0.05
-- An Auctionator price older than this many days is marked old.
D.STALE_DAYS=3
D.SALT_SHAKER=15846

-- Forever skill line first, then the legacy one (as Class Training reads them).
D.PROFESSIONS={
    {key="alchemy",name="Alchemy",skillLines={2937,171}},
    {key="tailoring",name="Tailoring",skillLines={2948,197}},
    {key="leatherworking",name="Leatherworking",skillLines={2945,165}},
}
D.PROFESSION_BY_KEY={}
for _,profession in ipairs(D.PROFESSIONS) do D.PROFESSION_BY_KEY[profession.key]=profession end
function D.ProfessionForSkillLine(id)
    for _,profession in ipairs(D.PROFESSIONS) do
        for _,line in ipairs(profession.skillLines) do if line==id then return profession end end
    end
end

D.ITEMS={
    [12359]="Thorium Bar",[12363]="Arcane Crystal",[12360]="Arcanite Bar",
    [12808]="Essence of Undeath",[7080]="Essence of Water",[7082]="Essence of Air",
    [7078]="Essence of Fire",[7076]="Essence of Earth",[12803]="Living Essence",
    [3575]="Iron Bar",[3577]="Gold Bar",[3860]="Mithril Bar",[6037]="Truesilver Bar",
    [14256]="Felcloth",[14342]="Mooncloth",[8150]="Deeprock Salt",[15409]="Refined Deeprock Salt",
}

-- share: recipes with the same value are assumed to use one timer until the
-- module sees otherwise. Most transmutes share one; Arcanite is listed apart.
local function Transmute(id,spell,name,from,to,hours,share)
    return {id=id,spell=spell,name="Transmute: "..name,profession="alchemy",hours=hours or 24,
        share=share==nil and "transmute" or share or nil,reagents={{from,1}},output={to,1}}
end
D.RECIPES={
    {id="arcanite",spell=17187,name="Transmute: Arcanite",profession="alchemy",hours=48,
        reagents={{12359,1},{12363,1}},output={12360,1}},
    Transmute("undeathToWater",17563,"Undeath to Water",12808,7080),
    Transmute("waterToUndeath",17564,"Water to Undeath",7080,12808),
    Transmute("earthToWater",17561,"Earth to Water",7076,7080),
    Transmute("waterToAir",17562,"Water to Air",7080,7082),
    Transmute("airToFire",17559,"Air to Fire",7082,7078),
    Transmute("fireToEarth",17560,"Fire to Earth",7078,7076),
    Transmute("earthToLife",17566,"Earth to Life",7076,12803),
    Transmute("lifeToEarth",17565,"Life to Earth",12803,7076),
    Transmute("ironToGold",11479,"Iron to Gold",3575,3577),
    Transmute("mithrilToTruesilver",11480,"Mithril to Truesilver",3860,6037,48),
    {id="mooncloth",spell=18560,name="Mooncloth",profession="tailoring",hours=96,note="At a moonwell",
        reagents={{14256,2}},output={14342,1}},
    -- The Salt Shaker is an item: its timer is the item's cooldown, and it
    -- needs Leatherworking 250. The salt goes into Cured Rugged Hide.
    {id="refinedSalt",item=D.SALT_SHAKER,name="Refined Deeprock Salt",profession="leatherworking",minSkill=250,
        hours=72,note="Salt Shaker",reagents={{8150,1}},output={15409,1}},
}
D.RECIPE_BY_ID={}
for _,recipe in ipairs(D.RECIPES) do D.RECIPE_BY_ID[recipe.id]=recipe end

function D.PairKey(a,b) if a<b then return a.."|"..b end return b.."|"..a end

-- observed: { ["a|b"]=true/false } seen in game; it wins over the bundled guess.
function D.Shares(a,b,observed)
    if a.id==b.id then return true end
    local seen=observed and observed[D.PairKey(a.id,b.id)]
    if seen~=nil then return seen end
    return a.share~=nil and a.share==b.share
end

-- prices: itemID -> {price=copper|nil, age=days|nil}.
-- options: cut (bool), freeMaterials (bool), seconds (cooldown length).
function D.Evaluate(recipe,prices,options)
    local result={recipe=recipe,missing={},stale={},seconds=options.seconds or recipe.hours*D.HOUR}
    local function Price(id)
        local entry=prices[id]
        local price=entry and entry.price
        if type(price)~="number" or price<0 then result.missing[#result.missing+1]=id;return 0 end
        if type(entry.age)=="number" and entry.age>D.STALE_DAYS then result.stale[#result.stale+1]=id end
        return price
    end
    -- Materials counted as free need no price.
    local cost=0
    if not options.freeMaterials then
        for _,reagent in ipairs(recipe.reagents) do cost=cost+Price(reagent[1])*reagent[2] end
    end
    local gross=Price(recipe.output[1])*recipe.output[2]
    if #result.missing>0 then return result end
    local cut=options.cut and math.floor(gross*D.AH_CUT+0.5) or 0
    result.cost,result.gross,result.cut=cost,gross,cut
    result.profit=gross-cut-cost
    result.perDay=math.floor(result.profit*D.DAY/result.seconds+0.5)
    return result
end
function D.Priced(entry) return entry.profit~=nil end

-- The best learned crafts you can run together: highest per day first,
-- skipping any that shares a timer with one already chosen.
function D.Plan(entries,observed)
    local sorted={}
    for _,entry in ipairs(entries) do
        if D.Priced(entry) and entry.perDay>0 then sorted[#sorted+1]=entry end
    end
    table.sort(sorted,function(a,b) if a.perDay~=b.perDay then return a.perDay>b.perDay end return a.recipe.id<b.recipe.id end)
    local chosen,total={},0
    for _,entry in ipairs(sorted) do
        local free=true
        for _,picked in ipairs(chosen) do
            if D.Shares(entry.recipe,picked.recipe,observed) then free=false;break end
        end
        if free then chosen[#chosen+1]=entry;total=total+entry.perDay end
    end
    return chosen,total
end

-- learned: list of entries you know; candidates: entries you could learn.
-- Each upgrade is how much a day the plan gains if you learned it.
function D.Upgrades(learned,candidates,observed,limit)
    local plan,total=D.Plan(learned,observed)
    local out={}
    for _,candidate in ipairs(candidates) do
        if D.Priced(candidate) and candidate.perDay>0 then
            local trial={candidate}
            for _,entry in ipairs(learned) do trial[#trial+1]=entry end
            local _,withIt=D.Plan(trial,observed)
            local gain=withIt-total
            if gain>0 then
                local replaces,rival
                for _,picked in ipairs(plan) do
                    if D.Shares(candidate.recipe,picked.recipe,observed) then replaces=picked;break end
                end
                for _,other in ipairs(candidates) do
                    if other~=candidate and D.Priced(other) and other.perDay>candidate.perDay and
                        D.Shares(candidate.recipe,other.recipe,observed) then rival=other;break end
                end
                out[#out+1]={entry=candidate,gain=gain,replaces=replaces,rival=rival}
            end
        end
    end
    table.sort(out,function(a,b) if a.gain~=b.gain then return a.gain>b.gain end return a.entry.recipe.id<b.entry.recipe.id end)
    while limit and #out>limit do out[#out]=nil end
    return out
end

-- sort: "day" or "craft". Rows without a price go last, by name.
function D.Sort(entries,sort)
    local key=sort=="craft" and "profit" or "perDay"
    table.sort(entries,function(a,b)
        local pa,pb=D.Priced(a),D.Priced(b)
        if pa~=pb then return pa end
        if pa and a[key]~=b[key] then return a[key]>b[key] end
        return a.recipe.name<b.recipe.name
    end)
    return entries
end

-- Gold and silver text with the game's coin colors; copper only under 1s.
-- plain: no color codes (for chat lines, which escape them).
function D.Money(copper,plain)
    if type(copper)~="number" then return "—" end
    local negative=copper<0
    local amount=math.floor(math.abs(copper)+0.5)
    local gold,silver,rest=math.floor(amount/10000),math.floor(amount/100)%100,amount%100
    local g,s,c="|cffffd100g|r","|cffc7c7cfs|r","|cffeda55fc|r"
    if plain then g,s,c="g","s","c" end
    local text
    if gold>0 then text=gold..g.." "..silver..s
    elseif silver>0 then text=silver..s
    else text=rest..c end
    if not negative then return text end
    return (plain and "-" or "|cffff8a8a-|r")..text
end

-- "47 h", or "2 d 1 h" past two days; whole hours, rounded up.
function D.Duration(seconds)
    if type(seconds)~="number" or seconds<=0 then return "—" end
    local hours=math.ceil(seconds/D.HOUR)
    if hours<48 then return hours.." h" end
    local days=math.floor(hours/24)
    local rest=hours-days*24
    return rest>0 and (days.." d "..rest.." h") or (days.." d")
end
