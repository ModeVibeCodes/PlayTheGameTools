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
reads=0; headerChanges=0; selected=12
function VisibleRows()
 local result={};local hidden=false
 for _,row in ipairs(questRows) do
  if row.isHeader then hidden=row.isCollapsed;result[#result+1]=row
  elseif not hidden then result[#result+1]=row end
 end
 return result
end
C_QuestLog={GetNumQuestLogEntries=function() return #VisibleRows(),3 end,
 GetInfo=function(i) return VisibleRows()[i] end,
 IsComplete=function() error('All-log XP must not filter by completion') end,
 GetSelectedQuest=function() return selected end,SetSelectedQuest=function(id) selected=id end}
function ExpandQuestHeader(index)
 assert(not testCombat and not testLockdown);local row=VisibleRows()[index];assert(row.isHeader)
 row.isCollapsed=false;headerChanges=headerChanges+1;selected=13;FireEvent('QUEST_LOG_UPDATE')
end
function CollapseQuestHeader(index)
 assert(not testCombat and not testLockdown);local row=VisibleRows()[index];assert(row.isHeader)
 row.isCollapsed=true;headerChanges=headerChanges+1;FireEvent('QUEST_LOG_UPDATE')
end
function GetQuestLogRewardXP(id) assert(id); reads=reads+1; return rewards[id] end
C_Texture={GetAtlasInfo=function() return {} end}
'''
lua, _ = load(before=SETUP)
lua.execute(r'''
local M=addon.EnhancedExperienceBar
assert(not M.enabled and not M.active and reads==0 and not M.frame:IsShown())
assert(addon.categories.questingLeveling.modules[#addon.categories.questingLeveling.modules]=='enhancedExperienceBar')
addon:SetModuleEnabled(M.id,true)
assert(M.active and M.questKnown and M.questXP==1080 and reads==3,'includes unfinished quests and deduplicates IDs')
assert(M.text:GetText():find('XP 42.0%%') and M.text:GetText():find('Rested 150.0%%'))
assert(M.text:GetText():find('Quest log %+108.0%%'))
assert(math.abs(M.xpFill.width-598*0.42)<0.001)
assert(math.abs(M.restedFill.width-598*0.58)<0.001,'rested clipped at next level')
assert(math.abs(M.questFill.width-598*0.58)<0.001,'quest pool clipped at next level')
assert(M.restedFill.points[1][5]==M.questFill.points[1][5],'same full-height overlay origin')
assert(M.restedFill.height==22 and M.questFill.height==22,'no split lanes')
assert(M.restedFill.vertexColor[4]==0.45 and M.questFill.vertexColor[4]==0.35,'independent translucent tints')
assert(M:SetOption('restedOverlayColor',{0.9,0.2,0.3}) and M.db.nativeColors)
assert(M.restedFill.vertexColor[1]==0.9 and M.xpFill.vertexColor[1]==0,'overlay color independent of native XP fill')
assert(M:SetOption('questColor',{0.2,0.8,0.4}) and M.questFill.vertexColor[2]==0.8)
assert(M.restedFill.vertexColor[1]==0.9 and M.restedFill.vertexColor[4]==0.45,'quest picker preserves rested color/opacity')
assert(not M.text:GetText():find('|',1,true) and not M.sessionText:GetText():find('|',1,true))
testClock=testClock+60;xp=520;FireEvent('PLAYER_XP_UPDATE','player')
assert(M.sessionXP==100 and M.sessionText:GetText():find('6000 XP/hr'))
local oldReads=reads;M.tick.callback();assert(reads==oldReads,'timer never scans log')
FireEvent('PLAYER_XP_UPDATE','pet');assert(M.sessionXP==100)
xp=30;level=21;maximum=1200;FireEvent('PLAYER_LEVEL_UP',21);FireEvent('PLAYER_XP_UPDATE','player')
assert(M.sessionXP==610,'rollover includes remainder of previous level')
FireEvent('PLAYER_XP_UPDATE','player');assert(M.sessionXP==610,'duplicate XP event')
questRows[1].isCollapsed=true;FireEvent('QUEST_LOG_UPDATE')
assert(M.questKnown and M.questXP==1080 and questRows[1].isCollapsed and selected==12,'hidden quests summed and layout/selection restored')
local changes=headerChanges;FireEvent('QUEST_LOG_UPDATE');assert(headerChanges==changes,'layout notifications do not loop')
testCombat=true;FireEvent('QUEST_ACCEPTED',1,11)
assert(not M.questKnown and headerChanges==changes,'no header changes in combat')
testCombat=false;FireEvent('PLAYER_REGEN_ENABLED')
assert(M.questKnown and M.questXP==1080 and questRows[1].isCollapsed,'combat-deferred scan')
questRows[1].isCollapsed=false;rewards[11]=nil;FireEvent('QUEST_DATA_LOAD_RESULT',11,true)
assert(not M.questKnown and M.questXP==900,'unavailable rewards not invented')
rewards[11]={secret=true};FireEvent('QUEST_DATA_LOAD_RESULT',11,true);assert(not M.questKnown)
rewards[11]=180;FireEvent('QUEST_DATA_LOAD_RESULT',11,true);assert(M.questKnown)
rested={secret=true};FireEvent('UPDATE_EXHAUSTION');assert(M.text:GetText():find('Rested unavailable'))
rested=nil;FireEvent('UPDATE_EXHAUSTION');assert(M.text:GetText():find('Rested 0.0%%'))
local getter=GetQuestLogRewardXP;GetQuestLogRewardXP=nil;FireEvent('QUEST_LOG_UPDATE');assert(not M.questKnown)
GetQuestLogRewardXP=getter;FireEvent('QUEST_DATA_LOAD_RESULT',11,true);assert(M.questKnown)
assert(not M:SetOption('width',0) and not M:SetOption('width',0/0))
assert(not M:SetOption('normalColor',{1,2,3}))
assert(M:SetOption('width',800) and M.frame.width==800)
function M.xpFill:SetAtlas(atlas) self.atlas=atlas end
assert(M:SetOption('barTexture','blizzardXP') and M.xpFill.atlas=='UI-HUD-ExperienceBar-Fill-Rested')
restState=2;FireEvent('UPDATE_EXHAUSTION');assert(M.xpFill.atlas=='UI-HUD-ExperienceBar-Fill-Experience')
C_Texture=nil;M:Render();assert(M.xpFill.texture==[[Interface\Buttons\WHITE8X8]],'atlas fallback')
assert(M:SetOption('barTexture','blizzardStatus') and M.xpFill.texture==[[Interface\TargetingFrame\UI-StatusBar]])
assert(M:SetOption('barTexture','media:Missing') and M.xpFill.texture==[[Interface\Buttons\WHITE8X8]])
local media=addon.Media
local oldTexture,oldChoices=media.GetStatusBar,media.GetStatusBars
function media:GetStatusBar(key) if key=='media:Fixture' then return 'FixtureTexture' end;return oldTexture(self,key) end
function media:GetStatusBars() return {{key='default',label='Flat'},{key='media:Fixture',label='Fixture'}} end
rested=1500
assert(#M:GetTextureChoices()==4)
assert(M:SetOption('barTexture','media:Fixture') and M.xpFill.texture=='FixtureTexture' and M.restedFill.texture=='FixtureTexture')
media.GetStatusBar,media.GetStatusBars=oldTexture,oldChoices
assert(M:SetOption('barTexture','blizzardXP'))
assert(M:SetOption('sessionFont','chat') and M.db.font=='game')
assert(M.sessionText.font[1]==ChatFontNormal:GetFont() and M.text.font[1]==GameFontHighlight:GetFont())
assert(M:SetOption('sessionOutline',false) and M.sessionText.font[3]=='' and M.text.font[3]=='OUTLINE')
assert(M:SetOption('sessionTextColor',{0.2,0.4,0.6}) and M.db.textColor[1]~=0.2)
assert(M:SetOption('sessionAlign','LEFT') and M.db.align=='CENTER')
assert(M:SetOption('opacity',50) and M.frame.alpha==1 and M.sessionText.alpha==1,'bar opacity independent of text')
assert(M:SetOption('sessionOpacity',60) and M.sessionText.alpha==0.6 and M.text.alpha==1)
assert(M:SetOption('separator','dot') and M.text:GetText():find('·',1,true))
assert(M.sessionText:GetText():find(' - ',1,true),'independent session separator')
assert(M:SetOption('questFormat','both') and M.text:GetText():find('1080 XP',1,true))
assert(M:SetOption('questFormat','value') and M.text:GetText():find('Quest log +1080 XP',1,true))
assert(M:SetOption('questFormat','percent'))
assert(not M:SetOption('barTexture','arbitrary/path') and not M:SetOption('sessionFont','invalid'))
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
assert(M.enabled and M.db.width==800 and M.db.barTexture=='blizzardXP' and M.sessionXP==0)
assert(M.db.sessionFont=='chat' and M.db.font=='game' and M.db.sessionOpacity==60)
assert(M.db.restedOverlayColor[1]==0.9 and M.db.questColor[2]==0.8,'overlay colors survive reload')
local p=addon.PositionManager:GetPosition(M.id);assert(p.x==125 and p.y==-210)
SlashCmdList.PLAYTHEGAMETOOLS();addon:SelectConfigPage(M.id)
assert(M.page and M.page.resetPositionButton and M.page.xPositionInput)
''')
legacy, _ = load(before=SETUP)
legacy.execute('''
local M=addon.EnhancedExperienceBar
local old={font='chat',fontMedia='',outline=false,align='RIGHT',width=800,
 textColor={0.1,0.2,0.3},blizzardStyle=true}
M.Initialize(old)
assert(old.barTexture=='blizzardXP' and old.sessionFont=='chat' and not old.sessionOutline)
assert(old.sessionAlign=='RIGHT' and old.sessionWidth==800 and old.sessionTextColor[1]==0.1)
old.sessionTextColor[1]=0.9;assert(old.textColor[1]==0.1,'copied legacy color is independent')
local custom={nativeColors=false,restedColor={0.3,0.5,0.7}}
M.Initialize(custom);assert(custom.restedOverlayColor[1]==0.3)
custom.restedOverlayColor[1]=0.8;assert(custom.restedColor[1]==0.3,'legacy overlay migration preserves fill color')
questRows={{isHeader=true,isCollapsed=true},{isHeader=false,questID=11},{isHeader=false,questID=12},
 {isHeader=true,isCollapsed=true},{isHeader=false,questID=13},{isHeader=false,questID=14}}
rewards[14]=250
C_QuestLog.GetNumQuestLogEntries=function() return #VisibleRows(),4 end
addon:SetModuleEnabled(M.id,true)
assert(M.questKnown and M.questXP==1330 and selected==12)
assert(questRows[1].isCollapsed and questRows[4].isCollapsed and headerChanges==4,'multiple headers restored in reverse order')
local changes=headerChanges;FireEvent('QUEST_LOG_UPDATE');assert(headerChanges==changes)
table.remove(questRows,6)
C_QuestLog.GetNumQuestLogEntries=function() return #VisibleRows(),3 end
FireEvent('QUEST_REMOVED',14)
assert(M.questKnown and M.questXP==1080,'hidden quest removals invalidate totals')
local reward=GetQuestLogRewardXP
GetQuestLogRewardXP=function(id) if id==11 then error('unavailable reward') end;return reward(id) end
FireEvent('QUEST_DATA_LOAD_RESULT',11,false)
assert(not M.questKnown and M.questXP==900 and questRows[1].isCollapsed and questRows[4].isCollapsed)
GetQuestLogRewardXP=reward;FireEvent('QUEST_DATA_LOAD_RESULT',11,true);assert(M.questKnown)
''')
print('PASS full-height overlays, all-log/hidden quest totals and restoration, texture choices, independent text, legacy migration, XP/session, modes/combat and profile reload')
