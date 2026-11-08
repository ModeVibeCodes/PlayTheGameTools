"""Focused Lua 5.1 fixtures; not native rendering/security acceptance."""
import json
from smoke import load

FIXTURE = r'''
M=addon.LootSparkles
cvars={outlineModeShowLootEffectWhenDisabled='0',SoftTargetInteract='0',
 SoftTargetIconGameObject='0',SoftTargetInteractRange='10',SoftTargetInteractArc='0',
 SoftTargetInteractOnlyInRange='1',SoftTargetNameplateInteract='0'}
local createTexture=UIParent.CreateTexture
function UIParent:CreateTexture(...)
 local t=createTexture(self,...)
 function t:GetTexture() return self.texture end
 function t:GetAtlas() return target and target.atlas end
 return t
end
writes={}; rejected=nil
C_CVar={GetCVar=function(k) return cvars[k] end,SetCVar=function(k,v)
 assert(not testCombat and not testLockdown,'no combat CVar writes')
 writes[#writes+1]={k,v}
 if k==rejected then error('native denial') end
 cvars[k]=v;FireEvent('CVAR_UPDATE',k);return true
end}
loaded={}
C_AddOns.IsAddOnLoaded=function(k) return loaded[k]==true end
plate=CreateFrame('Frame',nil,UIParent)
target={object=true,name='Copper Vein',cursor='Interface\\Cursor\\Mine',range=false}
direct=true
C_NamePlate={GetNamePlateForUnit=function(u)
 if target and ((u=='softinteract' and direct) or u=='nameplate1') then return plate end
end}
function UnitIsGameObject() return target and target.object or false end
function UnitIsDead() return target and target.dead or false end
function UnitName() return target and target.name end
function UnitIsInInteractRange() return target and target.range end
function UnitIsUnit(a,b) return target~=nil and a=='nameplate1' and b=='softinteract' end
function SetUnitCursorTexture(texture)
 if not target then return false end
 texture:SetTexture(target.cursor);return true
end
function GetFileIDFromPath(path)
 if path=='Interface\\Cursor\\Mine' then return 101 end
 if path=='Interface\\Cursor\\UnableMine' then return 102 end
end
function CanLootUnit() return target and target.hasLoot,target and target.canLoot end
-- Add omitted rendering methods only to this owned overlay, keeping native
-- unit/CVar fixtures strict.
local show=M.ShowTarget
function M:ShowTarget(...)
 if not self.overlay then
  local create=CreateFrame
  CreateFrame=function(...)
   local f=create(...)
   function f:SetIgnoreParentAlpha(v) self.ignoreAlpha=v end
   local texture=f.CreateTexture
   function f:CreateTexture(...)
    local t=texture(self,...)
    function t:SetRotation(v) self.rotation=v end
    return t
   end
   return f
  end
  local ok,err=pcall(show,self,...);CreateFrame=create;assert(ok,err)
 else show(self,...) end
end
'''

lua, _ = load()
lua.execute(FIXTURE)
lua.execute(r'''
assert(not M.enabled and not M.driver.scripts.OnUpdate and #writes==0)
addon:SetModuleEnabled('lootSparkles',true)
assert(cvars.outlineModeShowLootEffectWhenDisabled=='1' and cvars.SoftTargetInteract=='3')
assert(cvars.SoftTargetNameplateInteract=='1' and M.overlay:IsShown())
assert(M.overlay.label:GetText()=='Copper Vein\nOut of reach')
assert(M.state=='Out of reach' and M.overlay.ignoreAlpha)
target.cursor=101;M:Evaluate();assert(M.overlay:IsShown(),'numeric cursor file ID')
target.cursor=102;M:Evaluate();assert(M.state=='Unavailable')
target.cursor=999;target.atlas='Cursor_GatherHerbs_64';M:Evaluate();assert(M.overlay:IsShown(),'atlas fallback')
target.atlas=nil;target.cursor={secret=true};M:Evaluate();assert(not M.overlay:IsShown(),'secret cursor')
target.cursor='Mine';M:Evaluate()
M.overlay.scripts.OnUpdate(M.overlay,0.05)
assert(M.overlay.glints[1].rotation~=nil)
target.range=true;M:Evaluate();assert(M.state=='In reach')
target.range={secret=true};M:Evaluate();assert(M.state=='Range unknown')
target.cursor='Cursor_Crosshair_UnableMine_64';M:Evaluate()
assert(M.state=='Unavailable' and M.tint[1]==0.6)
target.cursor='Interface\\Cursor\\GatherHerbs';target.range=true;target.name='Peacebloom'
M:Evaluate();assert(M.overlay.label:GetText()=='Peacebloom\nIn reach')
assert(M:SetOption('herbs',false));assert(not M.overlay:IsShown())
assert(M:SetOption('herbs',true));assert(M.overlay:IsShown())
target.cursor='Interface\\Cursor\\Quest';M:Evaluate();assert(M.overlay:IsShown())
assert(M:SetOption('questObjects',false) and not M.overlay:IsShown())
assert(M:SetOption('questObjects',true))
target.cursor='Interface\\Cursor\\Interact';M:Evaluate();assert(not M.overlay:IsShown())
C_QuestLog={UnitIsRelatedToActiveQuest=function() return true end}
M:Evaluate();assert(M.overlay:IsShown());C_QuestLog=nil
target.object=false;target.dead=true;target.hasLoot=true;target.canLoot=true
M:Evaluate();assert(M.overlay:IsShown())
target.canLoot=false;M:Evaluate();assert(not M.overlay:IsShown())
target.canLoot={secret=true};M:Evaluate();assert(not M.overlay:IsShown())
target.canLoot=nil;M:Evaluate();assert(not M.overlay:IsShown(),'unknown loot access stays hidden')
target={object=true,name='Copper Vein',cursor='Mine',range=true}
direct=false;M:Evaluate();assert(not M.overlay:IsShown(),'no arbitrary plate fallback')
FireEvent('NAME_PLATE_UNIT_ADDED','nameplate1');assert(M.overlay:IsShown())
local same=UnitIsUnit;UnitIsUnit=function() return false end
M:Evaluate();assert(not M.overlay:IsShown());UnitIsUnit=same;M:Evaluate()
plate.forbidden=true;M:Evaluate();assert(not M.overlay:IsShown());plate.forbidden=nil
target.name={secret=true};M:Evaluate();assert(M.overlay.label:GetText()=='In reach')
target.name='Copper Vein';M:Evaluate()
assert(M:SetOption('showNames',false) and not M.overlay.label:IsShown())
assert(M:SetOption('size',50) and M:SetOption('opacity',50) and M.overlay:GetAlpha()==0.5)
assert(not M:SetOption('size',0) and not M:SetOption('size',0/0))
assert(not M:SetOption('fontSize',25) and not M:SetOption('ore',1) and not M:SetOption('invented',true))
local count=#writes
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not M.overlay:IsShown() and not M.driver.scripts.OnUpdate)
assert(not M:SetOption('ore',false))
addon:SetModuleEnabled('lootSparkles',false)
assert(#writes==count and M.pending)
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(cvars.SoftTargetInteract=='0' and cvars.SoftTargetNameplateInteract=='0')
assert(cvars.outlineModeShowLootEffectWhenDisabled=='0' and next(PTGToolsDB.lootSparkleCVars)==nil)
assert(not M.driver.scripts.OnUpdate and not M.overlay:IsShown())
addon:SetModuleEnabled('lootSparkles',true)
cvars.SoftTargetInteract='1'
addon:SetModuleEnabled('lootSparkles',false)
assert(cvars.SoftTargetInteract=='1','player override preserved')
addon:SetModuleEnabled('lootSparkles',true)
cvars.SoftTargetIconGameObject='0';M:Evaluate();assert(not M.overlay:IsShown())
FireEvent('PLAYER_ENTERING_WORLD');assert(cvars.SoftTargetIconGameObject=='0','respect player override')
assert(M:SetOption('showNames',true));assert(cvars.SoftTargetIconGameObject=='0','appearance toggle must not force native settings')
assert(M:SetOption('ore',true));assert(cvars.SoftTargetIconGameObject=='1')
loaded.ForeverLootSparkles=true;FireEvent('ADDON_LOADED','ForeverLootSparkles')
assert(not M.nodes and not M.overlay:IsShown() and not M.driver.scripts.OnUpdate)
assert(M.status:find('ForeverLootSparkles',1,true))
loaded.ForeverLootSparkles=nil;M:Configure(false);assert(M.nodes)
cvars.outlineModeShowLootEffectWhenDisabled='0';FireEvent('CVAR_UPDATE','graphicsQuality')
Advance(1.1);assert(cvars.outlineModeShowLootEffectWhenDisabled=='1')
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
assert(M.page==addon.configWindow.pages.lootSparkles and M.page.sparkleControls.ore and M.page.sparkleStatus)
assert(addon.modules.lootSparkles.category=='questingLeveling')
local exported=addon.ProfileManager:Export(addon.ProfileManager.root.defaultProfile)
assert(exported and not addon.ProfileCodec.Decode(exported).lootSparkleCVars)
local candidate=addon.ProfileCodec.Copy(addon.db);candidate.modules.lootSparkles.size=500
assert(not addon.ProfileValidation:Validate(candidate))
''')

state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
native = lua.eval('addon.ProfileCodec.Encode(cvars)')
reloaded, _ = load(state, before=FIXTURE + '\ncvars=addon.ProfileCodec.Decode(' + json.dumps(native) + ')')
reloaded.execute('''
assert(M.enabled and M.nodes and M.overlay:IsShown())
addon:SetModuleEnabled('lootSparkles',false)
assert(cvars.SoftTargetInteract=='1','original value survives reload')
assert(cvars.SoftTargetIconGameObject=='0' and cvars.SoftTargetInteractRange=='10')
''')

failure, _ = load()
failure.execute(FIXTURE)
failure.execute('''
rejected='SoftTargetNameplateInteract'
addon:SetModuleEnabled('lootSparkles',true)
assert(not M.overlay or not M.overlay:IsShown())
local count=#writes
for i=1,10 do M:Evaluate() end
assert(#writes==count,'do not repeatedly write rejected native settings')
addon:SetModuleEnabled('lootSparkles',false)
C_CVar=nil
addon:SetModuleEnabled('lootSparkles',true)
assert(not M.overlay or not M.overlay:IsShown())
''')
# Enabling during combat waits; leaving combat uses the latest preference.
combat, _ = load()
combat.execute(FIXTURE)
combat.execute('''
testCombat=true;testLockdown=true
addon:SetModuleEnabled('lootSparkles',true)
assert(#writes==0 and M.pending and not M.driver.scripts.OnUpdate)
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(M.overlay:IsShown() and M.nodes)
for _,key in ipairs({'ore','herbs','questObjects','corpses'}) do assert(M:SetOption(key,false)) end
assert(not M.driver.scripts.OnUpdate and cvars.SoftTargetInteract=='0')
assert(cvars.outlineModeShowLootEffectWhenDisabled=='1','native quest effect independent')
''')
print('PASS Loot Sparkles categories, range/secrets, plate identity, animation, settings, combat, conflicts, restoration/reload, profile isolation and native rejection fixtures')
