local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end
local D={families={8679,2823,3408,5761,13219},limit=32}
addon.ForeverRogueData=D
function D.Public(v) return type(issecretvalue)=="function" and not issecretvalue(v) end
function D.Number(v,lo,hi) return D.Public(v) and type(v)=="number" and v==v and v>=lo and v<=hi end
function D.Try(fn,...)
    if type(fn)~="function" then return false end
    local ok,v=pcall(fn,...);return ok and D.Public(v),v
end
function D.Call(fn,...) local ok,v=D.Try(fn,...);if ok then return v end end
function D.Field(t,k)
    if D.Public(t) and type(t)=="table" then return D.Call(function() return t[k] end) end
end
function D.OutsideCombat()
    return D.Call(InCombatLockdown)==false and D.Call(UnitAffectingCombat,"player")==false
end
function D.Key(v)
    return type(v)=="string" and #v<40 and (v:match("^item:%d+$") or v:match("^spell:%d+$"))~=nil
end
function D.Spell(id)
    local info=D.Call(C_Spell and C_Spell.GetSpellInfo,id)
    local name,icon=D.Field(info,"name"),D.Field(info,"iconID")
    if type(name)=="string" and name~="" and D.Number(icon,1,2147483647) then return {id=id,name=name,icon=icon} end
end
function D.ItemInfo(id)
    if not C_Item or type(C_Item.GetItemInfoInstant)~="function" then return end
    local ok,a,b,c,d,e,f=pcall(C_Item.GetItemInfoInstant,id)
    if ok and D.Public(d) and D.Public(e) and D.Public(f) then return a,b,c,d,e,f end
end
D.ranges={threshold={5,20,1},visibleRows={1,10,1},x={-10000,10000,1},y={-10000,10000,1},menuX={-10000,10000,1},menuY={-10000,10000,1}}
D.styleRanges={iconSize={20,80,1},fontSize={8,24,1},timerSize={8,28,1},scale={50,200,5},opacity={10,100,5},
    padding={0,32,1},spacing={0,40,1},cellWidth={80,320,5},labelGap={0,16,1},columns={1,3,1},
    backgroundOpacity={0,100,5},borderOpacity={0,100,5},borderSize={0,6,1},iconPadding={0,16,1},
    iconBorderSize={0,6,1},iconBorderOpacity={0,100,5},iconOpacity={0,100,5},iconBackgroundOpacity={0,100,5}}
local styleDefaults={iconSize=40,fontSize=12,timerSize=14,scale=100,opacity=100,padding=10,spacing=12,cellWidth=110,
    labelGap=4,columns=1,backgroundOpacity=85,borderOpacity=100,borderSize=1,font="game",fontMedia="",
    outline=true,cropIcons=true,showIcons=true,showHands=true,showTimers=true,showNames=false,showCounts=true,tooltips=true,
    vertical=false,timerPosition="CENTER",backgroundColor={0.035,0.045,0.06},borderColor={0.32,0.4,0.48},
    textColor={0.9,0.93,0.97},timerColor={1,0.85,0.4},iconColor={1,1,1},labelText="Poisons",labelPosition="BOTTOM",
    iconPadding=0,iconBorderSize=0,iconBorderOpacity=100,iconOpacity=100,iconBackgroundOpacity=0,
    iconBorderColor={0.32,0.4,0.48},iconBackgroundColor={0.035,0.045,0.06}}
local function Style(db,kind,legacy)
    for k,v in pairs(styleDefaults) do
        if db[k]==nil then
            if legacy and (k=="iconSize" or k=="fontSize" or k=="scale" or k=="opacity") then db[k]=legacy[k] end
            if db[k]==nil then
                if type(v)=="table" then db[k]={unpack(v)} else db[k]=v end
                if kind=="flyoutStyle" then
                    if k=="iconSize" then db[k]=32 elseif k=="cellWidth" then db[k]=210 elseif k=="showNames" then db[k]=true end
                elseif kind=="launcherStyle" and k=="borderColor" then db[k]={0.72,0.3,1}
                elseif kind=="launcherStyle" and k=="iconBorderColor" then db[k]={0.72,0.3,1}
                elseif kind=="launcherStyle" and k=="padding" then db[k]=3
                elseif kind=="launcherStyle" and k=="borderSize" then db[k]=2 end
                if kind=="watchStyle" and (k=="backgroundOpacity" or k=="borderSize") then db[k]=0 end
                if kind=="watchStyle" and (k=="showTimers" or k=="showCounts") then db[k]=false end
                if kind=="launcherStyle" and k=="showCounts" then db[k]=false end
            end
        end
        if D.styleRanges[k] then
            local r=D.styleRanges[k];assert(D.Number(db[k],r[1],r[2]) and db[k]%1==0,"Invalid poison appearance: "..k)
        elseif type(v)=="table" then
            assert(type(db[k])=="table","Invalid poison color")
            for i=1,3 do assert(D.Number(db[k][i],0,1),"Invalid poison color") end
        else assert(type(db[k])==type(v),"Invalid poison appearance: "..k) end
    end
    assert(db.font=="game" or db.font=="chat","Invalid poison font")
    assert(#db.fontMedia<=128,"Invalid poison media font")
    assert(db.timerPosition=="CENTER" or db.timerPosition=="TOP" or db.timerPosition=="BOTTOM","Invalid timer position")
    assert(#db.labelText<=40 and not db.labelText:find("[%c|]"),"Invalid poison label")
    assert(db.labelPosition=="CENTER" or db.labelPosition=="TOP" or db.labelPosition=="BOTTOM","Invalid label position")
end
function D.Initialize(db)
    local defaults={watcher=true,flyout=false,threshold=5,locked=true,flyoutLocked=true,alwaysShow=false,
        showInCombat=true,dismissOnRightClick=true,quickApply="last",visibleRows=6,direction="UP",x=0,y=-140,menuX=200,menuY=-140}
    for k,v in pairs(defaults) do
        if db[k]==nil then db[k]=v end
        if D.ranges[k] then local r=D.ranges[k];assert(D.Number(db[k],r[1],r[2]) and db[k]%1==0,"Invalid Rogue setting: "..k)
        else assert(type(db[k])==type(v),"Invalid Rogue setting: "..k) end
    end
    local family=type(db.quickApply)=="string" and tonumber(db.quickApply:match("^family:(%d+)$"))
    local validFamily=false;for _,id in ipairs(D.families) do if family==id then validFamily=true end end
    assert(db.quickApply=="last" or D.Key(db.quickApply) or validFamily,"Invalid poison quick apply")
    if db.reminderVisibility==nil then db.reminderVisibility=db.showInCombat and "needed" or "neededOOC" end
    assert(db.reminderVisibility=="needed" or db.reminderVisibility=="neededOOC" or db.reminderVisibility=="alwaysOOC" or db.reminderVisibility=="always","Invalid reminder visibility")
    assert(db.direction=="UP" or db.direction=="DOWN" or db.direction=="LEFT" or db.direction=="RIGHT","Invalid poison flyout direction")
    for _,k in ipairs({"watchStyle","flyoutStyle","launcherStyle"}) do
        if db[k]==nil then db[k]={} end
        assert(type(db[k])=="table","Invalid poison appearance group")
        -- Migrate only the untouched original preset; preserve customized styles.
        if k=="watchStyle" and db.reminderDefaultsVersion==nil and next(db[k]) then
            local unchanged=true
            for key,value in pairs(db[k]) do
                local old=styleDefaults[key]
                if type(old)=="table" then
                    if type(value)~="table" then unchanged=false else for i=1,3 do if value[i]~=old[i] then unchanged=false end end end
                elseif value~=old then unchanged=false end
            end
            if unchanged then db[k].backgroundOpacity=0;db[k].borderSize=0;db[k].showTimers=false;db[k].showCounts=false end
        end
        Style(db[k],k,k=="watchStyle" and db or nil)
    end
    db.reminderDefaultsVersion=1
    if db.history==nil then db.history={} end
    assert(type(db.history)=="table","Invalid poison history")
    local count=0
    for guid,row in pairs(db.history) do
        count=count+1;assert(count<=200 and type(guid)=="string" and #guid<=100 and type(row)=="table","Invalid poison history")
        for _,k in ipairs({"main","off","last"}) do assert(row[k]==nil or D.Key(row[k]),"Invalid last-used poison") end
    end
end
function D.Font(text,style,timer)
    local flags=style.outline and "OUTLINE" or ""
    local size=timer and style.timerSize or style.fontSize
    if not text:SetFont(addon.Media:GetDisplayFont(style),size,flags) then text:SetFont(GameFontHighlight:GetFont(),size,flags) end
    text:SetTextColor(unpack(timer and style.timerColor or style.textColor))
end
