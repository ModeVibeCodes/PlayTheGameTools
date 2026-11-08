from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

NATIVE_GEOMETRY=r'''
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=create(kind,name,parent,template)
 if kind=='Frame' and parent==UIParent and template=='BackdropTemplate' then
  local center=f.GetCenter
  function f:GetCenter() if not self.anchor then return nil,nil end;return center(self) end
 end
 return f
end
'''
lua,_=load(before=FIXTURE+EXTRA+NATIVE_GEOMETRY)
lua.execute(r'''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local page=M.page
page.sectionTabs.buttons[2].scripts.OnClick()
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
assert(not C.snapshot.nearby and #A.items==0)
-- Exercise the actual settings buttons, without a fire or carried ready kit.
bag={};page.contributionPreview.scripts.OnClick()
assert(A.previewing and A.window:IsShown() and A.window.sample:IsShown())
assert(#macroCalls==0 and #A.buttons==0,'sample uses no native item action button')
assert(A.window.anchor and A.window.sample.icon.texture==135805,'anchored preview with visible icon')
assert(A.window:GetFrameLevel()==90,'same visible layer as existing addon previews')
assert(A.window.title:GetText() and A.window:GetWidth()>0 and A.window:GetHeight()>0)
assert(C:SetOption('contributionOpacity',70) and A.window:GetAlpha()==0.7)
assert(C:SetOption('contributionScale',80) and A.window:GetScale()==0.8)
C:SetOption('contributionOpacity',100);C:SetOption('contributionScale',100)
local pm=addon.PositionManager
assert(pm.elements.campfireContributions.label=='Camp Contributions')
assert(page.contributionPreview.label:GetText()=='Stop Preview')
A.window.centerX=540;A.window.centerY=470
A.window.header.scripts.OnDragStart();FireEvent('UNIT_AURA','player')
assert(A.window.dragging,'aura refresh must not interrupt sample drag')
A.window.header.scripts.OnDragStop()
assert(C.db.contributionX==40 and C.db.contributionY==70)
page.contributionPreview.scripts.OnClick();assert(not A.previewing and not A.window:IsShown())
page.contributionEdit.scripts.OnClick()
assert(C.editing and A.window:IsShown() and A.window.sample:IsShown())
assert(pm.selected=='campfireContributions' and pm.elements.campfireContributions.decoration.handle:IsShown())
assert(addon.EditMode:SetCoordinate('x',125) and C.db.contributionX==125)
assert(pm:StartDragging('campfireContributions'))
local anchor=A.window.anchor;FireEvent('UNIT_AURA','player')
assert(pm.elements.campfireContributions.dragging and A.window.anchor==anchor)
A.window.centerX=625;A.window.centerY=490;pm:StopDragging('campfireContributions')
assert(C.db.contributionX==125 and C.db.contributionY==90)
addon:SetEditMode(false);assert(not A.window:IsShown() and not A.previewing)
bag={{itemID=279956,stackCount=2,isLocked=false}}
page.contributionRefresh.scripts.OnClick()
assert(page.contributionStatus:GetText():find('Mana Well x2',1,true) and not A.window:IsShown())
-- Multi-option groups share their row rather than allocating one row per toggle.
local function SameGrid(a,b) return a.frame:GetParent()==b.frame:GetParent() end
assert(SameGrid(page.campfireControls.showIcon,page.campfireControls.showText))
assert(SameGrid(page.sparkleControls.herbs,page.sparkleControls.ore))
assert(SameGrid(page.campfireControls.enabled,page.campfireControls.showInCombat))
-- Native color wheel: apply, cancel, dynamic colors, and optional gradients.
local pick=page.campfireColors.headerColor.pick
pick.scripts.OnClick();assert(ColorPickerFrame:IsShown())
ColorPickerFrame.r=0.1;ColorPickerFrame.g=0.2;ColorPickerFrame.b=0.3;ColorPickerFrame.info.swatchFunc()
assert(C.db.headerColor[1]==0.1 and C:HeaderText('Camp Buffs')=='|cff1a334dCamp Buffs|r')
ColorPickerFrame.info.cancelFunc();assert(C.db.headerColor[1]==1)
assert(C:SetOption('critColor',{0.2,0.3,0.4}) and C:BuffColor('2% Crit')[2]==0.3)
assert(C:SetOption('colorStats',false) and C:BuffColor('2% Crit')==C.db.textColor)
assert(not C:SetOption('headerColor',{9,0,0}),'invalid picker/profile colors rejected')
assert(C:SetOption('headerGradient',true) and C:HeaderText('Camp Buffs'):find('|r|cff',1,true))
for _,entry in ipairs(page.searchEntries) do assert(entry.label~='Native Camp Data' and entry.label~='Timer Color') end
page.contributionPreview.scripts.OnClick()
page.sectionTabs.buttons[1].scripts.OnClick();assert(not A.previewing and not A.window:IsShown())
page.sectionTabs.buttons[2].scripts.OnClick();page.contributionPreview.scripts.OnClick()
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not A.previewing and not A.window:IsShown() and #macroCalls==0)
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(not A.window:IsShown(),'combat must not restart sample')
page.contributionPreview.scripts.OnClick();C:SetOption('showContributionPopup',false)
assert(not A.previewing and not A.window:IsShown() and not pm.elements.campfireContributions.editMode)
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE+EXTRA)
restored.execute('''
assert(C.db.contributionX==125 and C.db.contributionY==90)
assert(C.db.headerGradient and C.db.critColor[2]==0.3 and not A.previewing)
C:SetOption('showContributionPopup',true);A:TogglePreview()
assert(addon.PositionManager:GetPosition('campfireContributions').x==125)
''')
print('PASS contribution preview/settings buttons, Edit Mode and uninterrupted dragging, detected kits, compact grids, native picker apply/cancel, plain/gradient colors, lifecycle and persistence (mock only)')
