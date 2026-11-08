"""XP/reward/session arithmetic, lifecycle, modes and settings; not native WoW."""
from smoke import load

SETUP = r'''
xp=420; maximum=1000; level=20; rested=1500; restState=1; capped=false; locked=false
function UnitXP(unit) assert(unit=='player'); return xp end
function UnitXPMax(unit) assert(unit=='player'); return maximum end
function UnitLevel(unit) assert(unit=='player'); return level end
function GetXPExhaustion() return rested end
function GetRestState() return restState end
function IsXPUserDisabled() return locked end
GameRulesUtil={IsPlayerAtEffectiveMaxLevel=function() return capped end}
questRows={{isHeader=true,isCollapsed=false},{isHeader=false,questID=11},
 {isHeader=false,questID=12},{isHeader=false,questID=13},{isHeader=false,questID=11}}
complete={[11]=true,[12]=false,[13]=true}; rewards={[11]=180,[12]=900,[13]=0}
reads=0
C_QuestLog={GetNumQuestLogEntries=function() return #questRows end,
 GetInfo=function(i) return questRows[i] end,IsComplete=function(id) return complete[id] end}
function GetQuestLogRewardXP(id) assert(id and id~=12); reads=reads+1; return rewards[id] end
C_Texture={GetAtlasInfo=function() return {} end}
'''
lua, _ = load(before=SETUP)
lua.execute(r'''
local M=addon.EnhancedExperienceBar
assert(not M.enabled and not M.active and reads==0 and not M.frame:IsShown())
assert(addon.categories.questingLeveling.modules[#addon.categories.questingLeveling.modules]=='enhancedExperienceBar')
addon:SetModuleEnabled(M.id,true)
assert(M.active and M.questKnown and M.questXP==180 and reads==2)
assert(M.text:GetText():find('XP 42.0%%') and M.text:GetText():find('Rested 150.0%%'))
assert(M.text:GetText():find('Quests %+18.0%%'))
assert(math.abs(M.xpFill.width-598*0.42)<0.001)
assert(math.abs(M.restedFill.width-598*0.58)<0.001,'rested clipped at next level')
assert(math.abs(M.questFill.width-598*0.18)<0.001,'no rested multiplier on quests')
assert(M.restedFill.points[1][5]~=M.questFill.points[1][5],'distinct lanes')
testClock=testClock+60;xp=520;FireEvent('PLAYER_XP_UPDATE','player')
assert(M.sessionXP==100 and M.sessionText:GetText():find('6000 XP/hr'))
local oldReads=reads;M.tick.callback();assert(reads==oldReads,'timer never scans log')
FireEvent('PLAYER_XP_UPDATE','pet');assert(M.sessionXP==100)
xp=30;level=21;maximum=1200;FireEvent('PLAYER_LEVEL_UP',21);FireEvent('PLAYER_XP_UPDATE','player')
assert(M.sessionXP==610,'rollover includes remainder of previous level')
FireEvent('PLAYER_XP_UPDATE','player');assert(M.sessionXP==610,'duplicate XP event')
questRows[1].isCollapsed=true;FireEvent('QUEST_LOG_UPDATE')
assert(not M.questKnown and M.text:GetText():find('incomplete'))
questRows[1].isCollapsed=false;rewards[11]=nil;FireEvent('QUEST_DATA_LOAD_RESULT',11,true)
assert(not M.questKnown and M.questXP==0,'unavailable rewards not invented')
rewards[11]={secret=true};FireEvent('QUEST_LOG_UPDATE');assert(not M.questKnown)
rewards[11]=180;FireEvent('QUEST_LOG_UPDATE');assert(M.questKnown)
rested={secret=true};FireEvent('UPDATE_EXHAUSTION');assert(M.text:GetText():find('Rested unavailable'))
rested=nil;FireEvent('UPDATE_EXHAUSTION');assert(M.text:GetText():find('Rested 0.0%%'))
local getter=GetQuestLogRewardXP;GetQuestLogRewardXP=nil;FireEvent('QUEST_LOG_UPDATE');assert(not M.questKnown)
GetQuestLogRewardXP=getter;FireEvent('QUEST_LOG_UPDATE');assert(M.questKnown)
assert(not M:SetOption('width',0) and not M:SetOption('width',0/0))
assert(not M:SetOption('normalColor',{1,2,3}))
assert(M:SetOption('width',800) and M.frame.width==800)
function M.xpFill:SetAtlas(atlas) self.atlas=atlas end
assert(M:SetOption('blizzardStyle',true) and M.xpFill.atlas=='UI-HUD-ExperienceBar-Fill-Rested')
restState=2;FireEvent('UPDATE_EXHAUSTION');assert(M.xpFill.atlas=='UI-HUD-ExperienceBar-Fill-Experience')
C_Texture=nil;M:Render();assert(M.xpFill.texture==[[Interface\Buttons\WHITE8X8]],'atlas fallback')
locked=true;FireEvent('PLAYER_XP_UPDATE','player');assert(not M.questFill:IsShown() and M.text:GetText():find('XP locked'))
locked=false;capped=true;FireEvent('PLAYER_LEVEL_UP',60);assert(not M.frame:IsShown())
addon:SetPreviewMode(true);assert(M.frame:IsShown() and M.text:GetText():find('PREVIEW'))
assert(M.sessionXP==610,'sample never counts XP')
addon:SetPreviewMode(false);assert(not M.frame:IsShown())
assert(addon:SetEditMode(true) and M.frame:IsShown())
local PM=addon.PositionManager
assert(PM:SelectElement(M.id));assert(PM:StartDragging(M.id));PM:StopDragging(M.id)
assert(PM:SetOffsets(M.id,125,-210))
addon:SetEditMode(false)
capped=false;FireEvent('PLAYER_LEVEL_UP',21);assert(M.frame:IsShown())
testCombat=true;testLockdown=true;FireEvent('PLAYER_REGEN_DISABLED')
assert(not M:SetOption('width',900) and not M:ResetSession())
xp=130;FireEvent('PLAYER_XP_UPDATE','player');assert(M.sessionXP==710 and M.frame:IsShown())
testCombat=false;testLockdown=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(M:ResetSession() and M.sessionXP==0)
level=24;xp=50;FireEvent('PLAYER_XP_UPDATE','player');assert(M.sessionIncomplete and M.sessionXP==0)
assert(M.sessionText:GetText():find('~0 XP/hr'),'gap marked approximate')
local ticker=M.tick;addon:SetModuleEnabled(M.id,false)
assert(ticker.cancelled and not M.tick and not M.frame:IsShown() and next(M.events.events)==nil)
local r=reads;FireEvent('QUEST_LOG_UPDATE');assert(reads==r,'disabled makes no reads')
addon:SetModuleEnabled(M.id,true);assert(M.tick~=ticker and M.sessionXP==0)
local candidate,reason=addon.ProfileValidation:Validate(addon.db);assert(candidate,reason)
local bad=addon.ProfileCodec.Copy(addon.db);bad.modules[M.id].width=9999
assert(not addon.ProfileValidation:Validate(bad),'profile import validates bounds')
''')
state = lua.eval('addon.ProfileCodec.Encode(PTGToolsDB)')
restored, _ = load(encoded=state, before=SETUP)
restored.execute('''
local M=addon.EnhancedExperienceBar
assert(M.enabled and M.db.width==800 and M.db.blizzardStyle and M.sessionXP==0)
local p=addon.PositionManager:GetPosition(M.id);assert(p.x==125 and p.y==-210)
SlashCmdList.PLAYTHEGAMETOOLS();addon:SelectConfigPage(M.id)
assert(M.page and M.page.resetPositionButton and M.page.xPositionInput)
''')
print('PASS XP forecasts, reward availability, rollover/session, modes/dragging, combat, lifecycle, profile validation and reload retention')
