"""Cooldown Profits: profit math, ranking, shared timers, profession scans, prices, window and reminders.

Mock UI and mock C_TradeSkillUI/Auctionator only; not in-game acceptance.
"""
from smoke import load

SETUP = r'''
testServerTime=1000000
function GetServerTime() return testServerTime end
function GetProfessions() return 1,2,nil,nil,nil end
testProfessions={
  [1]={'Alchemy',136240,300,300,0,0,2937},
  [2]={'Tailoring',136249,285,300,0,0,197},
}
function GetProfessionInfo(index) return unpack(testProfessions[index]) end
testOpen=171
testLearned={[11479]=true,[11480]=true,[17187]=false,[17563]=false,[18560]=true}
testCooldowns={}
C_TradeSkillUI={
  GetBaseProfessionInfo=function() return testOpen and {professionID=testOpen} or nil end,
  GetRecipeInfo=function(spell) if testLearned[spell]==nil then return nil end return {learned=testLearned[spell]} end,
  GetRecipeCooldown=function(spell) return testCooldowns[spell],false,0,0 end,
}
testItemCount=0
C_Item=C_Item or {}
C_Item.GetItemCount=function(id) assert(id==15846);return testItemCount end
C_Container=C_Container or {}
C_Container.GetItemCooldown=function(id) assert(id==15846);return 0,0,1 end
testPrices={[12359]=11000,[12363]=65000,[12360]=125000,[12808]=15000,[7080]=42000,[7082]=46000,[7078]=30000,
  [7076]=21000,[12803]=34000,[3575]=1500,[3577]=6000,[3860]=4000,[6037]=19000,[14256]=26000,[14342]=95000,
  [8150]=800}
testAges={[7082]=6}
Auctionator={API={v1={
  GetAuctionPriceByItemID=function(caller,id) assert(caller=='PlayTheGameTools' and type(id)=='number');return testPrices[id] end,
  GetAuctionAgeByItemID=function(caller,id) assert(caller=='PlayTheGameTools');return testAges[id] or 0 end,
  RegisterForDBUpdate=function(caller,callback) assert(caller=='PlayTheGameTools');testDBUpdate=callback end,
}}}
'''

lua, addon = load(before=SETUP)
lua.execute(r'''
local M,D=addon.CooldownProfits,addon.CooldownProfitsData
assert(M and addon.modules.cooldownProfits==M and M.title=='Cooldown Profits' and M.openLabel=='Open Cooldown Profits')
assert(M.enabled==false and M.db.enabled==false,'opt-in: off by default')

-- Pure math: sale less 5% cut less materials, scaled to a day.
local prices={}
for id,price in pairs(testPrices) do prices[id]={price=price,age=0} end
local u2w=D.Evaluate(D.RECIPE_BY_ID.undeathToWater,prices,{cut=true})
assert(u2w.cost==15000 and u2w.gross==42000 and u2w.cut==2100 and u2w.profit==24900 and u2w.perDay==24900)
local arc=D.Evaluate(D.RECIPE_BY_ID.arcanite,prices,{cut=true})
assert(arc.cost==76000 and arc.profit==42750 and arc.perDay==21375,'48 h halves the day rate')
local measured=D.Evaluate(D.RECIPE_BY_ID.arcanite,prices,{cut=true,seconds=47*3600})
assert(measured.perDay==math.floor(42750*24/47+0.5),'a measured length replaces the usual one')
local free=D.Evaluate(D.RECIPE_BY_ID.arcanite,{[12360]={price=125000}},{cut=false,freeMaterials=true})
assert(free.cost==0 and free.profit==125000 and #free.missing==0,'free materials need no price')
local missing=D.Evaluate(D.RECIPE_BY_ID.refinedSalt,prices,{cut=true})
assert(not D.Priced(missing) and missing.missing[1]==15409,'no guess without a price')
assert(#D.Evaluate(D.RECIPE_BY_ID.waterToAir,{[7080]={price=1,age=0},[7082]={price=2,age=6}},{}).stale==1)
assert(D.Money(25983)=='2|cffffd100g|r 59|cffc7c7cfs|r' and D.Money(4500,true)=='45s' and D.Money(-27750,true)=='-2g 77s')
assert(D.Duration(47*3600)=='47 h' and D.Duration(96*3600)=='4 d' and D.Duration(71*3600+1)=='3 d')

-- Plan: one craft per shared timer; upgrades are what learning adds a day.
local function E(id) return D.Evaluate(D.RECIPE_BY_ID[id],prices,{cut=true}) end
local m2t,i2g,moon,u,e2w,a=E('mithrilToTruesilver'),E('ironToGold'),E('mooncloth'),E('undeathToWater'),E('earthToWater'),E('arcanite')
local plan,total=D.Plan({m2t,i2g,moon},{})
assert(#plan==2 and total==m2t.perDay+moon.perDay,'Iron to Gold shares the transmute timer')
local ups=D.Upgrades({m2t,i2g,moon},{a,u,e2w},{},3)
assert(ups[1].entry==a and ups[1].gain==a.perDay and not ups[1].replaces,'Arcanite has its own timer and adds all of it')
assert(ups[2].entry==u and ups[2].replaces==m2t and ups[2].gain==u.perDay-m2t.perDay,'Undeath to Water takes the shared timer')
assert(ups[3].entry==e2w and ups[3].rival==u,'Earth to Water shares with a better one')
-- Seen in game: Arcanite on the transmute timer after all.
ups=D.Upgrades({m2t,i2g,moon},{a,u,e2w},{['arcanite|undeathToWater']=true,['arcanite|mithrilToTruesilver']=true,['arcanite|ironToGold']=true,['arcanite|earthToWater']=true},3)
assert(ups[1].entry==u and ups[2].entry==a and ups[2].rival==u and ups[2].gain==a.perDay-m2t.perDay,'observed sharing wins over the bundled guess')
local sorted=D.Sort({missing,a,u},'craft');assert(sorted[1]==a and sorted[3]==missing)
sorted=D.Sort({missing,a,u},'day');assert(sorted[1]==u and sorted[2]==a)

-- Settings validation.
local db={};M.Initialize(db)
assert(db.cut==true and db.freeMaterials==false and db.view=='mine' and db.sort=='day' and db.remind and db.remindBest)
assert(not pcall(M.Initialize,{view='everything'}) and not pcall(M.Initialize,{cut='yes'}))
assert(M:SetOption('view','bogus')==false and M:SetOption('nope',true)==false)

-- Turning it on reads professions, prices and the Salt Shaker; it adds a ring action.
addon:SetModuleEnabled('cooldownProfits',true)
assert(M.active and M.professions.alchemy.rank==300 and M.professions.tailoring.rank==285 and not M.professions.leatherworking)
assert(type(testDBUpdate)=='function' and M.watchingPrices,'Auctionator updates watched')
assert(addon.QuickActions.actions.cooldownProfits and addon.QuickActions.actions.cooldownProfits.available)
assert(M.ticker and M.ticker.period==30)

-- The Alchemy window opens: learned recipes and their timers are remembered per character.
FireEvent('TRADE_SKILL_SHOW')
local store=PTGToolsDB.cooldownProfits
local me=store.characters['Player-Collaboration-Fixture'].recipes
assert(me.mithrilToTruesilver.learned==true and me.mithrilToTruesilver.readyAt==0,'ready')
assert(me.arcanite.learned==false and me.undeathToWater.learned==false)
assert(me.mooncloth==nil,'Tailoring is read from its own window')
assert(me.earthToWater==nil,'a recipe the client says nothing about stays unknown')
assert(addon.db.cooldownProfits==nil and addon.db.modules.cooldownProfits.characters==nil,'timers are not profile settings')

-- A craft starts: both transmutes cool together (shared) and the length is recorded.
testCooldowns[11480]=47*3600-30;testCooldowns[11479]=47*3600-30
FireEvent('TRADE_SKILL_LIST_UPDATE')
assert(store.durations.mithrilToTruesilver==47*3600 and store.durations.ironToGold==47*3600,'length seen at the craft')
assert(store.shares['ironToGold|mithrilToTruesilver']==true)
assert(me.mithrilToTruesilver.readyAt==testServerTime+47*3600-30)
-- Arcanite learned and ready while the others cool: it has its own timer.
testLearned[17187]=true
FireEvent('TRADE_SKILL_LIST_UPDATE')
assert(store.shares['arcanite|mithrilToTruesilver']==false and store.shares['arcanite|ironToGold']==false)
-- Combat: nothing is read.
testLockdown=true;assert(M:ScanTradeSkill()==false);testLockdown=false
-- Another profession's window is never read as Alchemy.
testOpen=333;assert(M:ScanTradeSkill()==false);testOpen=171

-- The window: ranked rows, the summary and the controls.
assert(M:OpenWindow() and M.window:IsShown())
local w=M.window
local function Row(name) for _,row in ipairs(w.rows) do if row:IsShown() and row.entry.recipe.name==name then return row end end end
local first=w.rows[1].entry
assert(first.recipe.id=='undeathToWater','best per day first, learned or not')
assert(Row('Transmute: Arcanite').cells[1]:GetText():find('Your best',1,true),'learned and best on its own timer')
assert(Row('Transmute: Mithril to Truesilver').cells[1]:GetText():find('Your best',1,true))
assert(not Row('Transmute: Iron to Gold').cells[1]:GetText():find('Your best',1,true),'one per shared timer')
assert(Row('Transmute: Mithril to Truesilver').cells[8]:GetText()=='47 h left')
assert(Row('Transmute: Arcanite').cells[8]:GetText()=='Ready')
assert(Row('Transmute: Undeath to Water').cells[8]:GetText()=='Not learned')
assert(Row('Transmute: Earth to Water').cells[8]:GetText()=='Open Alchemy to check')
assert(Row('Mooncloth').cells[8]:GetText()=='Open Tailoring to check')
assert(Row('Transmute: Water to Air').cells[4]:GetText():find('*',1,true),'old price marked')
assert(Row('Refined Deeprock Salt')==nil,'My professions hides Leatherworking')
assert(w.status:GetText():find('Alchemy 300',1,true) and w.status:GetText():find("Auctionator's last scan",1,true))
assert(w.earn:GetText():find('a day',1,true) and w.upgradeLines[1]:GetText():find('Undeath to Water',1,true))
M:SetOption('view','all')
local salt=Row('Refined Deeprock Salt')
assert(salt and salt.cells[4]:GetText()=='No price','no listings: no guess')
assert(salt.cells[8]:GetText()=='Needs Leatherworking 250')
M:SetOption('view','learned')
for _,row in ipairs(w.rows) do if row:IsShown() then assert(row.entry.learned==true,row.entry.recipe.name) end end
M:SetOption('sort','craft');M:SetOption('view','mine')
assert(w.rows[1].entry.recipe.id=='arcanite')
M:SetOption('cut',false)
assert(Row('Transmute: Arcanite').entry.cut==0 and Row('Transmute: Arcanite').entry.profit==49000)
M:SetOption('cut',true);M:SetOption('sort','day')
-- An Auctionator scan redraws the open window.
testPrices[7080]=60000;testDBUpdate()
assert(Row('Transmute: Undeath to Water').entry.gross==60000)
-- Without Auctionator: timers only, said plainly.
local saved=Auctionator;Auctionator=nil;M:RenderWindow()
assert(w.status:GetText():find("Auctionator isn't loaded",1,true) and w.earn:GetText()=='—')
assert(Row('Transmute: Arcanite').cells[5]:GetText()=='—')
Auctionator=saved;M:RenderWindow()

-- Reminders: one chat line when a learned cooldown comes off, once.
for i=#messages,1,-1 do messages[i]=nil end
testServerTime=testServerTime+48*3600
M:CheckReady()
local said=table.concat(messages,'\n')
assert(said:find('Transmute: Mithril to Truesilver is ready',1,true),'best transmute named')
assert(not said:find('Iron to Gold',1,true),'only the most profitable one on a shared timer')
local count=#messages;M:CheckReady();assert(#messages==count,'once per cooldown')
M:SetOption('remind',false);me.mooncloth={learned=true,readyAt=testServerTime-5}
M:CheckReady();assert(#messages==count,'reminder off')
M:SetOption('remind',true)

-- The page: the reminder and a note; the second switch follows the first.
addon:ToggleConfig();addon:SelectConfigPage('cooldownProfits')
local page=addon:EnsureConfigPage('cooldownProfits')
local labels={}
for _,row in ipairs(page.rows) do for _,cell in ipairs(row.settingsToggles or {}) do labels[#labels+1]=cell.label:GetText() end end
assert(table.concat(labels,'|')=='Tell me when a cooldown is ready|Only for the most profitable one')
assert(addon.configWindow.moduleHeader.openButton:IsShown(),'Open Cooldown Profits in the page header')

-- Off: the window closes, events stop, the ring action goes.
addon:SetModuleEnabled('cooldownProfits',false)
assert(not M.active and not w:IsShown() and M.ticker==nil and not addon.QuickActions.actions.cooldownProfits.available)
assert(M:OpenWindow()==false)
''')

# Timers survive a reload; the profile round-trips without them.
encoded = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
again, _ = load(encoded, before=SETUP)
again.execute(r'''
local me=PTGToolsDB.cooldownProfits.characters['Player-Collaboration-Fixture'].recipes
assert(me.mithrilToTruesilver.learned==true and PTGToolsDB.cooldownProfits.durations.mithrilToTruesilver==47*3600)
assert(addon.modules.cooldownProfits.db.view=='mine' and addon.modules.cooldownProfits.db.cut==true)
''')
print('PASS Cooldown Profits: cut/material/day math, no-price honesty, shared-timer plan and upgrades, observed sharing, '
      'per-character timers outside profiles, measured lengths, combat/other-window guards, Auctionator prices and updates, '
      'window rows/summary/controls, reminders once and best-only, page, disable and reload (mock only)')
