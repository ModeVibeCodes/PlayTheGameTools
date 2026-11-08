"""Contribution customization parity, actual controls and section jumps."""
from camp_contributions import EXTRA
from campfire_monitor import FIXTURE
from smoke import load

lua,_=load(before=FIXTURE+EXTRA)
lua.execute(r'''
addon:ToggleConfig();addon:SelectConfigPage('lootSparkles')
local page=M.page;page.sectionTabs.buttons[2].scripts.OnClick()
addon:SetModuleEnabled('lootSparkles',true);C:SetOption('enabled',true)
page:Layout()
for _,id in ipairs({'monitor','buffs','contributions'}) do
 page.campfireJumps[id].scripts.OnClick()
 local expected=math.min(math.max(0,page.campfireJumpTargets[id].row.offset-8),select(2,page.scrollbar:GetMinMaxValues()))
 assert(page.scrollbar:GetValue()==expected and page.selectedSection==page.sections[2],'jump lands in actual section')
end
page.contributionPreview.scripts.OnClick()
local f=A.window;local sample=f.sample
local input=page.campfireSliders.contributionWidth.numericInput
input:SetText('607');input.scripts.OnEnterPressed(input)
assert(input:GetText()=='610' and f:GetWidth()==610,'actual width numeric control snaps and applies')
local function Set(key,value) assert(C:SetOption('contribution'..key,value),key) end
Set('Width',600);Set('Padding',16);Set('RowHeight',70);Set('RowGap',8);Set('VisibleRows',1)
Set('IconSize',48);Set('IconOpacity',65);Set('TitleSize',22);Set('NameSize',20)
Set('InfoSize',16);Set('ActionSize',18);Set('HintSize',15);Set('FooterSize',14)
Set('Outline',true);Set('BorderSize',3);Set('BorderOpacity',45);Set('RowOpacity',60)
Set('TextAlign','CENTER');Set('TitleAlign','RIGHT')
Set('TitleColor',{0.1,0.2,0.3});Set('NameColor',{0.3,0.4,0.5});Set('InfoColor',{0.2,0.4,0.6})
Set('ActionColor',{0.8,0.6,0.4});Set('BackgroundColor',{0.2,0.1,0.05});Set('BorderColor',{0.9,0.3,0.2})
Set('RowColor',{0.4,0.2,0.1});Set('HoverColor',{0.1,0.8,0.3});Set('HoverOpacity',40)
assert(f:GetWidth()==600 and sample:GetHeight()==70 and f.rowPitch==78)
assert(f.viewport:GetWidth()==568 and sample.icon:GetWidth()==48 and sample.icon:GetAlpha()==0.65)
assert(sample.name.font[2]==20 and sample.info.font[2]==16 and sample.action.font[2]==18)
assert(sample.name.font[3]=='OUTLINE' and sample.name.justifyH=='CENTER' and f.title.justifyH=='RIGHT')
assert(sample.name.color[1]==0.3 and sample.info.color[3]==0.6)
local pick=page.campfireColors.contributionNameColor.pick
pick.scripts.OnClick();ColorPickerFrame.r=0.45;ColorPickerFrame.g=0.5;ColorPickerFrame.b=0.55
ColorPickerFrame.info.swatchFunc();assert(sample.name.color[1]==0.45)
ColorPickerFrame.info.cancelFunc();assert(sample.name.color[1]==0.3)
Set('DismissSize',19);Set('DismissColor',{0.4,0.6,0.8})
f.close.scripts.OnEnter(f.close)
assert(f.close.label.font[2]==19 and f.close.label.color[3]==0.8,'dismiss styling survives hover')
assert(f.title.font[2]==22 and f.hint.font[2]==15 and f.footer.font[2]==14)
assert(f.backdrop.edgeSize==3 and f.borderColor[4]==0.45 and sample.bg:GetAlpha()==0.6)
Set('ShowTitle',false);Set('ShowHint',false);Set('ShowFooter',false)
Set('ShowIcons',false);Set('ShowNames',false);Set('ShowProfession',false);Set('ShowCount',false);Set('ShowAction',false)
assert(not f.title:IsShown() and not f.hint:IsShown() and not f.footer:IsShown())
assert(not sample.icon:IsShown() and sample.name:IsShown(),'retain identity if both name/icon disabled')
assert(not sample.info:IsShown() and not sample.action:IsShown())
Set('ShowIcons',true);Set('ShowNames',true);Set('ShowProfession',true);Set('ShowCount',true);Set('ShowAction',true)
Set('ShowTitle',true);Set('HeaderGradient',true)
assert(f.title:GetText():find('|r|cff',1,true),'optional independent contribution gradient')
-- Actual existing font dropdown switches off interface-font inheritance.
page.contributionFont.scripts.OnClick();page.contributionFont.rows[2].scripts.OnClick()
assert(not C.db.contributionUseInterfaceFont and C.db.contributionFont=='chat')
assert(sample.name.font[1]==ChatFontNormal:GetFont())
addon.Media:RefreshFonts();assert(sample.name.font[1]==ChatFontNormal:GetFont())
local before=C:HeaderText('Camp Buffs');Set('TitleColor',{0.7,0.2,0.1})
assert(C:HeaderText('Camp Buffs')==before,'contribution colors independent of buffs')
page.contributionPreview.scripts.OnClick()
auras={{spellId=C.NEARBY,auraInstanceID=101}};FireEvent('UNIT_AURA','player')
local row=A.buttons[1]
assert(f:IsShown() and row:GetWidth()==568 and row.name.font[2]==20 and row.name.font[3]=='OUTLINE')
assert(row.info.color[3]==0.6 and row.icon:GetWidth()==48 and row.bg:GetAlpha()==0.6)
assert(row.highlight:GetAlpha()==0.4 and f.maxScroll==78,'scroll range uses styled row pitch')
assert(row:GetScript('OnClick')==row.nativeClick and row:GetAttribute('macrotext1'):find('item:279956',1,true),'styling preserves native action')
Set('Locked',true);f.header.scripts.OnDragStart();assert(not f.dragging)
page.contributionPreview.scripts.OnClick();f.header.scripts.OnDragStart();assert(f.dragging,'preview remains movable when locked')
f.header.scripts.OnDragStop()
assert(C:SetOption('contributionX',80) and C.db.contributionX==80 and addon.PositionManager:GetPosition('campfireContributions').x==80)
assert(not C:SetOption('contributionTextAlign','UP') and not C:SetOption('contributionFont','bad'))
local candidate=addon.ProfileCodec.Copy(addon.db);candidate.modules.lootSparkles.campfire.contributionWidth=100
assert(not addon.ProfileValidation:Validate(candidate),'invalid style rejected without replacing live settings')
''')
state=lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored,_=load(state,before=FIXTURE+EXTRA)
restored.execute('''
assert(C.db.contributionWidth==600 and C.db.contributionIconSize==48 and C.db.contributionFont=='chat')
assert(C.db.contributionX==80 and C.db.contributionLocked)
A:TogglePreview();assert(A.window:GetWidth()==600 and A.window.sample.name.font[2]==20)
''')
print('PASS section jumps, responsive window/rows/text/icons/colors/visibility/font/alignment, preview-live parity, scrolling, locks/offsets, native actions, profile validation and persistence (mock only)')
