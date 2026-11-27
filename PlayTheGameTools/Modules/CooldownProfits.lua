local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local D=addon.CooldownProfitsData

-- Ranks profession cooldown crafts (transmutes, Mooncloth, the Salt Shaker)
-- by the gold they earn a day. Read-only: it never crafts, uses items or
-- touches protected frames.
--   Recipes and timers: C_TradeSkillUI.GetRecipeInfo/GetRecipeCooldown while
--   that profession's window is open (the Forever Professions UI reads
--   GetRecipeCooldown the same way), remembered per character. The Salt
--   Shaker is an item: C_Item.GetItemCount and C_Container.GetItemCooldown.
--   Prices: Auctionator's public API (Auctionator.API.v1), an optional
--   dependency. Without it the window lists timers only.
local M={title="Cooldown Profits",category="qualityOfLife",defaultEnabled=false,openLabel="Open Cooldown Profits",
    configDescription="Ranks your profession cooldowns, like transmutes and Mooncloth, by the gold they earn a day at auction house prices."}
addon.CooldownProfits=M
addon:RegisterModule("cooldownProfits",M)

M.CALLER="PlayTheGameTools"
M.VIEWS={"learned","mine","all"}
M.SORTS={"day","craft"}
M.CHECK_INTERVAL=30
local QUICK_ACTION="cooldownProfits"
local DEFAULTS={cut=true,freeMaterials=false,view="mine",sort="day",remind=true,remindBest=true}
local BOOLEANS={"cut","freeMaterials","remind","remindBest"}

local function Public(v) return not (issecretvalue and issecretvalue(v)) end
local function Call(fn,...)
    if type(fn)~="function" then return false end
    return pcall(fn,...)
end
local function Listed(list,value) for _,item in ipairs(list) do if item==value then return true end end return false end
local function Number(v) return Public(v) and type(v)=="number" and v==v and v>-math.huge and v<math.huge end
local function OutsideCombat()
    local ok,combat=Call(InCombatLockdown)
    return ok and combat==false
end
function M.Now()
    local ok,now=Call(GetServerTime)
    if ok and Number(now) then return now end
    return time()
end

-- Pure defaults and validation; profile validation runs this on detached copies.
function M.Initialize(db)
    for key,value in pairs(DEFAULTS) do if db[key]==nil then db[key]=value end end
    for _,key in ipairs(BOOLEANS) do assert(type(db[key])=="boolean","Invalid Cooldown Profits setting: "..key) end
    assert(Listed(M.VIEWS,db.view),"Invalid Cooldown Profits view")
    assert(Listed(M.SORTS,db.sort),"Invalid Cooldown Profits sort")
end

function M:SetOption(key,value)
    if Listed(BOOLEANS,key) then
        if type(value)~="boolean" then return false end
    elseif key=="view" then
        if not Listed(M.VIEWS,value) then return false end
    elseif key=="sort" then
        if not Listed(M.SORTS,value) then return false end
    else return false end
    self.db[key]=value
    self:Changed()
    if addon.RefreshConfig then addon:RefreshConfig() end
    return true
end

---------------------------------------------------------------------------
-- Saved timers. They belong to a character and the game's rules to the
-- account, so neither lives in a profile (profiles are shared and exported):
-- PTGToolsDB.cooldownProfits = {
--   characters[key].recipes[id] = {learned=bool, readyAt=server time, announced=readyAt},
--   durations[id] = seconds seen when a craft started (account-wide),
--   shares["a|b"] = whether two recipes were seen on one timer (account-wide) }
-- Invalid entries are ignored, never repaired by deleting the table.
---------------------------------------------------------------------------
function M:Store()
    local manager=addon.ProfileManager
    local root=manager and manager.root
    if type(root)~="table" then return nil end
    if type(root.cooldownProfits)~="table" then root.cooldownProfits={} end
    local store=root.cooldownProfits
    for _,key in ipairs({"characters","durations","shares"}) do
        if type(store[key])~="table" then store[key]={} end
    end
    return store
end
function M:Character()
    local store=self:Store()
    local manager=addon.ProfileManager
    local key=store and manager.CharacterKey and manager:CharacterKey()
    if type(key)~="string" or key=="" then return nil end
    if type(store.characters[key])~="table" then store.characters[key]={} end
    local character=store.characters[key]
    if type(character.recipes)~="table" then character.recipes={} end
    return character
end
function M:Record(id,create)
    local character=self:Character()
    if not character then return nil end
    local record=character.recipes[id]
    if type(record)~="table" then
        if not create then return nil end
        record={};character.recipes[id]=record
    end
    return record
end
function M:Duration(id)
    local store=self:Store()
    local seconds=store and store.durations[id]
    if Number(seconds) and seconds>=60 and seconds<=30*D.DAY then return seconds end
end
function M:ObservedShares()
    local store=self:Store()
    return store and store.shares or {}
end

---------------------------------------------------------------------------
-- Professions: GetProfessions slots, matched by skill line.
---------------------------------------------------------------------------
function M:ReadProfessions()
    if not OutsideCombat() then return self.professions end
    local ok,a,b,c,d,e=Call(GetProfessions)
    if not ok then return self.professions end
    local slots,found={a,b,c,d,e},{}
    for i=1,5 do
        local index=slots[i]
        if Number(index) then
            local valid,name,_,rank,_,_,_,line=Call(GetProfessionInfo,index)
            if valid and Number(line) then
                local profession=D.ProfessionForSkillLine(line)
                if profession then
                    found[profession.key]={rank=Number(rank) and rank or 0,
                        name=Public(name) and type(name)=="string" and name~="" and name or profession.name}
                end
            end
        end
    end
    self.professions=found
    return found
end

---------------------------------------------------------------------------
-- The open profession window: learned recipes, time left, cooldown lengths
-- and which recipes share a timer.
---------------------------------------------------------------------------
function M:OpenProfession()
    local api=C_TradeSkillUI
    if type(api)~="table" then return nil end
    local ok,info=Call(api.GetBaseProfessionInfo)
    if not ok or type(info)~="table" then return nil end
    for _,field in ipairs({"professionID","parentProfessionID"}) do
        local id=info[field]
        if Number(id) then
            local profession=D.ProfessionForSkillLine(id)
            if profession then return profession end
        end
    end
end

-- true or false from the recipe; nil when the client doesn't say.
function M:RecipeLearned(recipe)
    local api=C_TradeSkillUI
    local ok,info=Call(api and api.GetRecipeInfo,recipe.spell)
    if ok and type(info)=="table" and Public(info.learned) and type(info.learned)=="boolean" then return info.learned end
    -- A known spell is learned; anything else stays unknown rather than "not learned".
    local known
    ok,known=Call(IsPlayerSpell,recipe.spell)
    if ok and Public(known) and known==true then return true end
    return nil
end

-- seen: {recipe, remaining} for learned recipes read together. One on its
-- timer while the other is ready means they don't share; the same time left
-- to the second means they do. Different times left prove nothing.
function M.ObserveShares(seen,shares)
    for i=1,#seen do
        for j=i+1,#seen do
            local a,b=seen[i],seen[j]
            local key=D.PairKey(a.recipe.id,b.recipe.id)
            if (a.remaining>0)~=(b.remaining>0) then shares[key]=false
            elseif a.remaining>0 and math.abs(a.remaining-b.remaining)<=2 then shares[key]=true end
        end
    end
end

function M:ScanTradeSkill()
    if not self.active or not OutsideCombat() then return false end
    local profession=self:OpenProfession()
    local store=self:Store()
    if not profession or not store then return false end
    local api,now,seen=C_TradeSkillUI,M.Now(),{}
    self.seenReady=self.seenReady or {}
    for _,recipe in ipairs(D.RECIPES) do
        if recipe.profession==profession.key and recipe.spell then
            local learned=self:RecipeLearned(recipe)
            local record=self:Record(recipe.id,learned~=nil)
            if record and learned~=nil then record.learned=learned end
            if record and record.learned==true then
                local ok,cooldown,isDay=Call(api.GetRecipeCooldown,recipe.spell)
                if ok and (cooldown==nil or Number(cooldown)) then
                    local remaining=cooldown and cooldown>0 and cooldown or 0
                    -- Ready earlier this session and cooling now: a craft just
                    -- started, so the time left is the cooldown's full length.
                    if remaining>0 and self.seenReady[recipe.id] and not (Public(isDay) and isDay==true) then
                        store.durations[recipe.id]=math.ceil(remaining/60)*60
                    end
                    self.seenReady[recipe.id]=remaining==0 or nil
                    record.readyAt=remaining>0 and math.floor(now+remaining+0.5) or 0
                    seen[#seen+1]={recipe=recipe,remaining=remaining}
                end
            end
        end
    end
    M.ObserveShares(seen,store.shares)
    self:Changed()
    return true
end

-- The Salt Shaker counts as learned while it is in your bags and you have
-- Leatherworking 250. Its item cooldown gives both time left and length.
function M:ScanSaltShaker()
    if not self.active then return false end
    local recipe=D.RECIPE_BY_ID.refinedSalt
    local store=self:Store()
    if not store then return false end
    local countFn=C_Item and C_Item.GetItemCount or GetItemCount
    local okCount,count=Call(countFn,recipe.item)
    local leather=self.professions and self.professions.leatherworking
    local record=self:Record(recipe.id,true)
    if not record then return false end
    if okCount and Number(count) and self.professions then
        record.learned=count>0 and leather~=nil and leather.rank>=recipe.minSkill
    end
    local ok,start,duration=Call(C_Container and C_Container.GetItemCooldown,recipe.item)
    local okTime,clock=Call(GetTime)
    if ok and okTime and Number(start) and Number(duration) and Number(clock) then
        local cooling=start>0 and duration>60
        if cooling then store.durations[recipe.id]=math.floor(duration+0.5) end
        local remaining=cooling and math.max(0,start+duration-clock) or 0
        record.readyAt=remaining>0 and math.floor(M.Now()+remaining+0.5) or 0
    end
    return true
end

---------------------------------------------------------------------------
-- Prices from Auctionator: copper, and days since the item was last seen.
---------------------------------------------------------------------------
function M:Auctionator()
    local root=rawget(_G,"Auctionator")
    local api=type(root)=="table" and type(root.API)=="table" and root.API.v1
    if type(api)=="table" and type(api.GetAuctionPriceByItemID)=="function" then return api end
end
function M:Prices()
    local api,prices=self:Auctionator(),{}
    if not api then return prices,false end
    for id in pairs(D.ITEMS) do
        local ok,price=pcall(api.GetAuctionPriceByItemID,M.CALLER,id)
        price=ok and Number(price) and price>=0 and price or nil
        local age
        if price and type(api.GetAuctionAgeByItemID)=="function" then
            local okAge,days=pcall(api.GetAuctionAgeByItemID,M.CALLER,id)
            -- Auctionator gives no age past 21 days; such a price is old.
            if okAge then age=Number(days) and days or 22 end
        end
        prices[id]={price=price,age=age}
    end
    return prices,true
end
function M:WatchPrices()
    if self.watchingPrices then return end
    local api=self:Auctionator()
    if not api or type(api.RegisterForDBUpdate)~="function" then return end
    -- Auctionator has no way to unregister; the callback checks the switch.
    if pcall(api.RegisterForDBUpdate,M.CALLER,function() if M.active then M:Changed() end end) then
        self.watchingPrices=true
    end
end

---------------------------------------------------------------------------
-- What the window shows: every recipe evaluated for this character.
---------------------------------------------------------------------------
function M:Entries()
    local prices,priced=self:Prices()
    self.lastPrices=prices
    local character=self:Character()
    local professions=self.professions or {}
    local entries={}
    for _,recipe in ipairs(D.RECIPES) do
        local seconds=self:Duration(recipe.id)
        local entry=D.Evaluate(recipe,prices,{cut=self.db.cut,freeMaterials=self.db.freeMaterials,seconds=seconds})
        local record=character and character.recipes[recipe.id]
        if type(record)=="table" then
            if type(record.learned)=="boolean" then entry.learned=record.learned end
            entry.readyAt=Number(record.readyAt) and record.readyAt or nil
        end
        entry.measured=seconds~=nil
        entry.profession=professions[recipe.profession]
        entries[#entries+1]=entry
    end
    return entries,priced
end
function M.Learned(entry) return entry.profession~=nil and entry.learned==true end
function M.Learnable(entry) return entry.profession~=nil and entry.learned~=true end

function M:Summary(entries)
    local learned,candidates={},{}
    for _,entry in ipairs(entries) do
        if M.Learned(entry) then learned[#learned+1]=entry elseif M.Learnable(entry) then candidates[#candidates+1]=entry end
    end
    local shares=self:ObservedShares()
    local plan,total=D.Plan(learned,shares)
    return plan,total,D.Upgrades(learned,candidates,shares,3)
end

-- Rows for the current view and sort.
function M:Rows(entries)
    local view,rows=self.db.view,{}
    for _,entry in ipairs(entries) do
        if view=="all" or (view=="mine" and entry.profession) or (view=="learned" and M.Learned(entry)) then rows[#rows+1]=entry end
    end
    return D.Sort(rows,self.db.sort)
end

function M:Status(entry,now)
    local recipe=entry.recipe
    local profession=D.PROFESSION_BY_KEY[recipe.profession].name
    if not entry.profession then
        return recipe.minSkill and ("Needs "..profession.." "..recipe.minSkill) or ("Needs "..profession),"muted"
    end
    if recipe.item then
        if entry.learned~=true then
            if entry.profession.rank<recipe.minSkill then return "Needs "..profession.." "..recipe.minSkill,"muted" end
            return "No Salt Shaker in bags","muted"
        end
    elseif entry.learned==nil then return "Open "..profession.." to check","muted"
    elseif entry.learned==false then return "Not learned","muted" end
    if not entry.readyAt then return "Open "..profession.." to check","muted" end
    if entry.readyAt>now then return D.Duration(entry.readyAt-now).." left","text" end
    return "Ready","primary"
end

---------------------------------------------------------------------------
-- Ready reminders: one chat line when a learned cooldown comes off.
---------------------------------------------------------------------------
function M:CheckReady()
    if not self.active or not self.db.remind then return end
    local character=self:Character()
    if not character then return end
    local now=M.Now()
    local entries=self:Entries()
    local best
    if self.db.remindBest then
        local plan=self:Summary(entries)
        -- Without prices there is no best one: every ready craft is named.
        if #plan>0 then best={};for _,entry in ipairs(plan) do best[entry.recipe.id]=true end end
    end
    for _,entry in ipairs(entries) do
        local record=character.recipes[entry.recipe.id]
        if M.Learned(entry) and type(record)=="table" and Number(record.readyAt) and record.readyAt>0 and
            record.readyAt<=now and record.announced~=record.readyAt then
            if best and not best[entry.recipe.id] then record.announced=record.readyAt
            else
                local worth=D.Priced(entry) and entry.perDay>0 and (", worth "..D.Money(entry.perDay,true).." a day") or ""
                if addon:PrintAction("Cooldown Profits: "..entry.recipe.name.." is ready"..worth..".","cooldownProfits:"..entry.recipe.id) then
                    record.announced=record.readyAt
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Lifecycle and events
---------------------------------------------------------------------------
function M:Changed()
    if self.RenderWindow and self.window and self.window:IsShown() then self:RenderWindow() end
end

function M:QueueScan()
    if self.scanQueued then return end
    self.scanQueued=true
    C_Timer.After(0.2,function()
        self.scanQueued=false
        if self.active then self:ScanTradeSkill() end
    end)
end

function M:SyncQuickAction()
    local Q=addon.QuickActions
    if not Q then return end
    if self.active and not self.shortcut and OutsideCombat() then
        self.shortcut=Q:AddAction(QUICK_ACTION,{order=40,texture="Interface\\Icons\\INV_Misc_Coin_02",color={.9,.74,.26},
            title="Cooldown Profits",hint="Click to open.",onClick=function() if M.active then M:OpenWindow() end end})
    end
    Q:SetAvailable(QUICK_ACTION,self.active==true)
end

local EVENTS={"PLAYER_ENTERING_WORLD","SKILL_LINES_CHANGED","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE",
    "BAG_UPDATE_COOLDOWN","BAG_UPDATE_DELAYED","PLAYER_REGEN_ENABLED"}
function M:OnEvent(event)
    if not self.active then return end
    if event=="TRADE_SKILL_SHOW" or event=="TRADE_SKILL_LIST_UPDATE" then self:QueueScan();return end
    if event=="PLAYER_REGEN_ENABLED" then self:SyncQuickAction() end
    if event~="BAG_UPDATE_COOLDOWN" then self:ReadProfessions() end
    self:ScanSaltShaker()
    self:Changed()
end

function M:OnInitialize()
    self.Initialize(self.db)
    self.seenReady={}
end

function M:OnEnable()
    if self.active then return end
    self.active=true
    if not self.events then
        self.events=CreateFrame("Frame")
        self.events:SetScript("OnEvent",function(_,event) M:OnEvent(event) end)
    end
    for _,event in ipairs(EVENTS) do pcall(self.events.RegisterEvent,self.events,event) end
    self:ReadProfessions()
    self:ScanSaltShaker()
    self:WatchPrices()
    self:SyncQuickAction()
    self.ticker=C_Timer.NewTicker(M.CHECK_INTERVAL,function() M:CheckReady() end)
    self:CheckReady()
end

function M:OnDisable()
    self.active=false
    if self.events then self.events:UnregisterAllEvents() end
    if self.ticker then self.ticker:Cancel();self.ticker=nil end
    self:SyncQuickAction()
    if self.window then self.window:Hide() end
end
