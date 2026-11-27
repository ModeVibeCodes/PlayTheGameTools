local _,addon=...
if not addon.Edition or addon.Edition.name~="Forever" then return end

-- Buff Reminders data: what each class can be reminded about, how each buff
-- is detected and cast, and the module's pure defaults and validation.
-- Spell and item IDs come from the addon's Forever trainer catalogs
-- (ForeverClassTrainingCatalog*.lua) and Wowhead's Forever data; see
-- docs/BUFF_REMINDERS.md for sources and the IDs still awaiting in-game checks.
local D={}
addon.BuffRemindersData=D

function D.Public(v) return not (issecretvalue and issecretvalue(v)) end
function D.Number(v,low,high) return D.Public(v) and type(v)=="number" and v==v and v>=(low or -math.huge) and v<=(high or math.huge) end
function D.Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d,e,f,g=pcall(fn,...)
    if ok then return a,b,c,d,e,f,g end
end
function D.Field(t,k)
    if D.Public(t) and type(t)=="table" then
        local ok,v=pcall(function() return t[k] end)
        if ok then return v end
    end
end
function D.Truthy(fn,...) local v=D.Call(fn,...);return D.Public(v) and v==true end
function D.InCombat() return D.Truthy(InCombatLockdown) or D.Truthy(UnitAffectingCombat,"player") end

-- Spell chains run lowest rank first; casts use the highest rank the player knows.
local chains={
    battleShout={6673,5242,6192,11549,11550,11551,25289},
    might={19740,19834,19835,19836,19837,19838,25291},greaterMight={25782,25916},
    wisdom={19742,19850,19852,19853,19854,25290},greaterWisdom={25894,25918},
    kings={20217},greaterKings={25898},
    righteousFury={25780},
    devotion={465,10290,643,10291,1032,10292,10293},retribution={7294,10298,10299,10300,10301},
    concentration={19746},shadowResistance={19876,19895,19896},frostResistance={19888,19897,19898},
    fireResistance={19891,19899,19900},sanctity={20218},
    hawk={13165,14318,14319,14320,14321,14322},beast={13161,1299445,1299446,1299447},
    monkey={13163},cheetah={5118},pack={13159},wild={20043,20190},
    trueshot={1299346,1299348,19506,20905,20906},
    fortitude={1243,1244,1245,2791,10937,10938},prayerFortitude={21562,21564},
    innerFire={588,7128,602,1006,10951,10952},
    divineSpirit={14752,14818,14819,27841},prayerSpirit={27681},
    shadowProtection={976,10957,10958},prayerShadow={27683},shadowform={15473},
    rockbiter={8017,8018,8019,10399,16314,16315,16316},flametongue={8024,8027,8030,16339,16341,16342},
    frostbrand={8033,8038,10456,16355,16356},windfury={8232,8235,10486,16362},
    lightningShield={324,325,905,945,8134,10431,10432},waterShield={408510},
    arcaneIntellect={1459,1460,1461,10156,10157},arcaneBrilliance={23028},
    frostArmor={168,7300,7301},iceArmor={7302,7320,10219,10220},mageArmor={6117,22782,22783},
    dampen={604,8450,8451,10173,10174},amplify={1008,8455,10169,10170},
    demonSkin={687,696},demonArmor={706,1086,11733,11734,11735},
    imp={688},voidwalker={697},succubus={712},felhunter={691},
    createSoulstone={693,20752,20755,20756,20757},soulstoneAura={20707,20762,20763,20764,20765},
    demonicSacrifice={18789,18790,18791,18792},
    markOfTheWild={1126,5232,6756,5234,8907,9884,9885},giftOfTheWild={21849,21850},
    thorns={467,782,1075,8914,9756,9910},
    callPet={883},
}
D.chains=chains

local function Join(...)
    local out={}
    for _,list in ipairs({...}) do for _,id in ipairs(list) do out[#out+1]=id end end
    return out
end

-- Items, best first where the reminder uses the item itself.
D.items={
    instant={8928,8927,8926,6950,6949,6947},deadly={20844,8985,8984,2893,2892},
    crippling={3776,3775},mindNumbing={9186,6951,5237},wound={10922,10921,10920,10918},
    soulstone={16896,16895,16893,16892,5232},soulShard={6265},
    firestone={13701,13700,13699,1254},spellstone={13603,13602,5522},
    weaponOil={20749,20748,20750,20747,20746,20745,20744,18262,12404,7964,2871,2863,2862,12643,7965,3241,3240,3239},
}

-- Well Fed auras: Classic IDs plus the Forever food auras (+5% kill XP and
-- stats). Any of these, or any aura carrying one of their names, counts as fed.
D.foodAuras={19705,19706,19708,19709,19710,19711,24799,25694,25941,1248406,1249517,1249519,1249520,1249521,1225778,1225780,1225782,1294007}
-- Elixirs and flasks [Classic IDs, unverified on Forever].
D.elixirAuras={17538,11405,11334,11328,11396,17539,11474,26276,3593,11348,24363,17535,17537,3166,17626,17627,17628,17629}
-- Item spell names that mark a carried food (not a drink).
D.foodSpells={433,24869}

-- Choice lists. Each choice names the chain cast for it; ranks are never chosen.
D.choices={
    blessing={{id="might",label="Blessing of Might",cast="might"},{id="wisdom",label="Blessing of Wisdom",cast="wisdom"},{id="kings",label="Blessing of Kings",cast="kings"}},
    paladinAura={{id="devotion",label="Devotion Aura"},{id="retribution",label="Retribution Aura"},{id="concentration",label="Concentration Aura"},
        {id="shadowResistance",label="Shadow Resistance Aura"},{id="frostResistance",label="Frost Resistance Aura"},{id="fireResistance",label="Fire Resistance Aura"},{id="sanctity",label="Sanctity Aura"}},
    aspect={{id="hawk",label="Aspect of the Hawk"},{id="beast",label="Aspect of the Beast"},{id="monkey",label="Aspect of the Monkey"},
        {id="cheetah",label="Aspect of the Cheetah"},{id="pack",label="Aspect of the Pack"},{id="wild",label="Aspect of the Wild"}},
    imbue={{id="rockbiter",label="Rockbiter Weapon"},{id="flametongue",label="Flametongue Weapon"},{id="frostbrand",label="Frostbrand Weapon"},{id="windfury",label="Windfury Weapon"}},
    shield={{id="lightningShield",label="Lightning Shield"},{id="waterShield",label="Water Shield"}},
    armor={{id="auto",label="Best known"},{id="frostArmor",label="Frost Armor"},{id="iceArmor",label="Ice Armor"},{id="mageArmor",label="Mage Armor"}},
    demon={{id="imp",label="Imp"},{id="voidwalker",label="Voidwalker"},{id="succubus",label="Succubus"},{id="felhunter",label="Felhunter"}},
    poisonMain={{id="instant",label="Instant Poison"},{id="deadly",label="Deadly Poison"},{id="crippling",label="Crippling Poison"},{id="mindNumbing",label="Mind-numbing Poison"},{id="wound",label="Wound Poison"}},
}
D.choices.poisonOff=D.choices.poisonMain
D.choices.stone={{id="firestone",label="Firestone"},{id="spellstone",label="Spellstone"}}

-- Totem types per element. The icon casts the highest rank known.
D.ELEMENTS={{id="earth",label="Earth",slot=2},{id="fire",label="Fire",slot=1},{id="water",label="Water",slot=3},{id="air",label="Air",slot=4}}
D.totems={
    earth={{id="strengthOfEarth",label="Strength of Earth Totem",spells={8075,8160,8161,10442,25361}},
        {id="stoneskin",label="Stoneskin Totem",spells={8071,8154,8155,10406,10407,10408}},
        {id="tremor",label="Tremor Totem",spells={8143}}},
    fire={{id="flametongueTotem",label="Flametongue Totem",spells={8227,8249,10526,16387}},
        {id="frostResistanceTotem",label="Frost Resistance Totem",spells={8181,10478,10479}}},
    water={{id="manaSpring",label="Mana Spring Totem",spells={5675,10495,10496,10497}},
        {id="healingStream",label="Healing Stream Totem",spells={5394,6375,6377,10462,10463}},
        {id="fireResistanceTotem",label="Fire Resistance Totem",spells={8184,10537,10538}},
        {id="poisonCleansing",label="Poison Cleansing Totem",spells={8166}},
        {id="diseaseCleansing",label="Disease Cleansing Totem",spells={8170}}},
    air={{id="windfuryTotem",label="Windfury Totem",spells={8512,10613,10614}},
        {id="graceOfAir",label="Grace of Air Totem",spells={8835,10627,25359}},
        {id="natureResistance",label="Nature Resistance Totem",spells={10595,10600,10601}},
        {id="windwall",label="Windwall Totem",spells={15107,15111,15112}}},
}
D.TOTEM_DURATION=300

--[[ A buff:
  key       saved key (db.buffs[key]); class "ALL" or a class file
  kind      aura | weapon | totem | pet | active | food | group
  detect    aura spell IDs that count as present (every rank, group versions)
  cast      chain name, or choice = choice list whose pick names the chain
  mine      only your own aura counts (blessings)
  party     the group watcher tracks it on each group member
  charges   warn at this many charges (aura applications) or fewer
  resource  mana | reagent | item  (what applying it costs)
  hand      weapon reminders: 1 main hand, 2 off hand
]]
D.buffs={
    {key="food",class="ALL",kind="food",name="Food buff",short="Food",icon=133971,default=true,resource="item",duration=900,detect=D.foodAuras},
    {key="elixir",class="ALL",kind="aura",name="Elixirs and flasks",short="Elixir",icon=134743,default=false,duration=3600,detect=D.elixirAuras,noClick=true},
    {key="weaponOil",class="ALL",kind="weapon",enchant="Temporary",hand=1,name="Weapon oils and stones",short="Oil",icon=134877,default=false,resource="item",duration=1800,items="weaponOil"},

    {key="battleShout",class="WARRIOR",kind="aura",name="Battle Shout",short="Shout",default=true,duration=180,detect=chains.battleShout,cast="battleShout",resource="rage"},

    {key="blessing",class="PALADIN",kind="aura",name="Blessing",short="Blessing",default=true,duration=3600,mine=true,party=true,
        detect=Join(chains.might,chains.greaterMight,chains.wisdom,chains.greaterWisdom,chains.kings,chains.greaterKings),choice="blessing",resource="mana"},
    {key="paladinAura",class="PALADIN",kind="active",name="Paladin aura",short="Aura",default=true,choice="paladinAura",resource="mana",
        detect=Join(chains.devotion,chains.retribution,chains.concentration,chains.shadowResistance,chains.frostResistance,chains.fireResistance,chains.sanctity)},
    {key="righteousFury",class="PALADIN",kind="aura",name="Righteous Fury",short="Fury",default=false,duration=1800,detect=chains.righteousFury,cast="righteousFury",resource="mana"},

    {key="aspect",class="HUNTER",kind="active",name="Aspect",short="Aspect",default=true,choice="aspect",resource="mana",
        detect=Join(chains.hawk,chains.beast,chains.monkey,chains.cheetah,chains.pack,chains.wild)},
    {key="trueshot",class="HUNTER",kind="aura",name="Trueshot Aura",short="Trueshot",default=true,duration=1800,detect=chains.trueshot,cast="trueshot",resource="mana"},
    {key="huntPet",class="HUNTER",kind="pet",name="Pet",short="Pet",default=true,cast="callPet"},

    {key="poisonMain",class="ROGUE",kind="weapon",enchant="Imbue",hand=1,name="Main-hand poison",short="Poison",default=true,duration=1800,choice="poisonMain",resource="item",poison=true},
    {key="poisonOff",class="ROGUE",kind="weapon",enchant="Imbue",hand=2,name="Off-hand poison",short="Poison",default=true,duration=1800,choice="poisonOff",resource="item",poison=true},

    {key="fortitude",class="PRIEST",kind="aura",name="Power Word: Fortitude",short="Fortitude",default=true,duration=3600,party=true,
        detect=Join(chains.fortitude,chains.prayerFortitude),cast="fortitude",resource="mana"},
    {key="innerFire",class="PRIEST",kind="aura",name="Inner Fire",short="Inner Fire",default=true,duration=600,charges=5,detect=chains.innerFire,cast="innerFire",resource="mana"},
    {key="divineSpirit",class="PRIEST",kind="aura",name="Divine Spirit",short="Spirit",default=false,duration=3600,party=true,
        detect=Join(chains.divineSpirit,chains.prayerSpirit),cast="divineSpirit",resource="mana"},
    {key="shadowProtection",class="PRIEST",kind="aura",name="Shadow Protection",short="Shadow Prot",default=false,duration=600,
        detect=Join(chains.shadowProtection,chains.prayerShadow),cast="shadowProtection",resource="mana"},
    {key="shadowform",class="PRIEST",kind="active",name="Shadowform",short="Shadowform",default=false,detect=chains.shadowform,cast="shadowform",resource="mana"},

    {key="imbueMain",class="SHAMAN",kind="weapon",enchant="Imbue",hand=1,name="Main-hand imbue",short="Imbue",default=true,duration=3600,choice="imbue",resource="mana"},
    {key="imbueOff",class="SHAMAN",kind="weapon",enchant="Imbue",hand=2,name="Off-hand imbue",short="Imbue",default=true,duration=3600,choice="imbue",resource="mana"},
    {key="shield",class="SHAMAN",kind="aura",name="Elemental shield",short="Shield",default=true,duration=600,charges=1,choice="shield",resource="mana",
        detect=Join(chains.lightningShield,chains.waterShield)},

    {key="arcaneIntellect",class="MAGE",kind="aura",name="Arcane Intellect",short="Intellect",default=true,duration=3600,party=true,
        detect=Join(chains.arcaneIntellect,chains.arcaneBrilliance),cast="arcaneIntellect",resource="mana"},
    {key="armor",class="MAGE",kind="aura",name="Armor",short="Armor",default=true,duration=1800,choice="armor",resource="mana",
        detect=Join(chains.frostArmor,chains.iceArmor,chains.mageArmor)},
    {key="dampenAmplify",class="MAGE",kind="aura",name="Dampen or Amplify Magic",short="Magic",default=false,duration=600,
        detect=Join(chains.dampen,chains.amplify),cast="dampen",resource="mana"},

    {key="demonArmor",class="WARLOCK",kind="aura",name="Demon Armor",short="Armor",default=true,duration=1800,
        detect=Join(chains.demonSkin,chains.demonArmor),cast="demonArmor",fallback="demonSkin",resource="mana"},
    {key="demonPet",class="WARLOCK",kind="pet",name="Demon",short="Demon",default=true,choice="demon",skipAura=chains.demonicSacrifice},
    {key="soulstone",class="WARLOCK",kind="group",name="Soulstone",short="Soulstone",default=true,duration=1800,detect=chains.soulstoneAura,groupOnly=true,resource="reagent"},
    {key="weaponStone",class="WARLOCK",kind="weapon",enchant="Imbue",hand=1,name="Firestone or Spellstone",short="Stone",default=false,duration=3600,choice="stone",resource="item"},

    {key="markOfTheWild",class="DRUID",kind="aura",name="Mark of the Wild",short="Mark",default=true,duration=3600,party=true,
        detect=Join(chains.markOfTheWild,chains.giftOfTheWild),cast="markOfTheWild",resource="mana"},
    {key="thorns",class="DRUID",kind="group",name="Thorns",short="Thorns",default=false,duration=600,detect=chains.thorns,cast="thorns",resource="mana"},
}
D.byKey={}
for _,b in ipairs(D.buffs) do D.byKey[b.key]=b end
-- Shaman totems are reminders too, one per element, chosen in db.totems.
for _,element in ipairs(D.ELEMENTS) do
    local b={key="totem:"..element.id,class="SHAMAN",kind="totem",element=element.id,slot=element.slot,
        name=element.label.." totem",short=element.label,default=false,duration=D.TOTEM_DURATION,resource="mana"}
    D.byKey[b.key]=b;D.buffs[#D.buffs+1]=b
end

D.CLASS_NAMES={WARRIOR="Warrior",PALADIN="Paladin",HUNTER="Hunter",ROGUE="Rogue",PRIEST="Priest",SHAMAN="Shaman",MAGE="Mage",WARLOCK="Warlock",DRUID="Druid"}

-- Blessing given to each class when the watcher has seen none from you yet.
D.DEFAULT_BLESSING={WARRIOR="might",ROGUE="might",HUNTER="might",PALADIN="kings",PRIEST="wisdom",MAGE="wisdom",WARLOCK="wisdom",DRUID="wisdom",SHAMAN="wisdom"}

D.WHEN={needed=true,neededOOC=true,alwaysOOC=true,always=true}
D.MODES={icons=true,text=true,single=true}
D.CANT={dim=true,hide=true}
D.RESTING={show=true,hide=true,only=true}
D.WATCH_MODES={icons=true,list=true}
D.TOTEM_MODES={each=true,one=true}
D.GROW={right=true,left=true,center=true,down=true,up=true}
D.TIMER={below=true,above=true,bottom=true,center=true,top=true,hidden=true}
D.OUTLINES={none=true,outline=true,thick=true}
D.TIMER_COLORS={state=true,white=true}
D.LABEL_STYLES={short=true,long=true}
D.LABEL_POSITIONS={above=true,top=true,under=true}
D.DIRECTIONS={up=true,down=true,left=true,right=true}
D.NAME_POSITIONS={bottom=true,top=true,below=true}
D.NAME_COLORS={class=true,white=true}
D.WARN_CHOICES={0,1,2,3,5,10,15}

-- Icons have no background and 1px borders by default.
local LOOK={grow="right",iconWidth=40,iconHeight=40,spacing=6,borderSize=1,fineBorder=true,
    colorMissing={0.87,0.23,0.2},colorExpiring={0.9,0.74,0.26},colorFine={0,0,0},menuDirection="up",
    timer="below",timerFont="game",timerSize=12,timerOutline="outline",timerColor="state",
    labels=true,labelStyle="short",labelSize=10,labelPosition="above",glow=true,sound=false}
local WATCH_LOOK={iconSize=30,spacing=3,names=true,namePosition="bottom",nameColor="class",nameSize=9,nameLetters=5,timers=true}
D.LOOK,D.WATCH_LOOK=LOOK,WATCH_LOOK
D.ranges={warnMinutes={0,15},poisonWarn={5,20},poisonCharges={5,25},x={-10000,10000},y={-10000,10000},groupX={-10000,10000},groupY={-10000,10000}}
D.lookRanges={iconWidth={16,96},iconHeight={16,96},spacing={0,30},borderSize={0,6},timerSize={8,24},labelSize={7,16}}
D.watchRanges={iconSize={16,64},spacing={0,20},nameSize={6,18},nameLetters={2,12}}

local function Defaults(t,defaults)
    for k,v in pairs(defaults) do if t[k]==nil then t[k]=v end end
end
local function Whole(v,range,label) assert(D.Number(v,range[1],range[2]) and v%1==0,"Invalid Buff Reminders setting: "..label) end
local function Pick(v,set,label) assert(type(v)=="string" and set[v],"Invalid Buff Reminders setting: "..label) end
local function ChoiceSet(list) local set={};for _,c in ipairs(list) do set[c.id]=true end;return set end

-- Pure defaults and validation. Profile validation runs this on detached copies.
function D.Initialize(db)
    Defaults(db,{show=true,when="needed",timeReminder=true,warnMinutes=0,chargeReminder=true,showCharges=true,
        mode="icons",cant="dim",click=true,dismiss=true,watchGroup=true,watchMode="icons",totemMode="each",
        resting="show",hideMounted=true,hideDead=true,poisonWarn=5,poisonCharges=10,x=0,y=-160,groupX=0,groupY=-230,rogueAdopted=false})
    for _,k in ipairs({"show","timeReminder","chargeReminder","showCharges","click","dismiss","watchGroup","hideMounted","hideDead","rogueAdopted"}) do
        assert(type(db[k])=="boolean","Invalid Buff Reminders setting: "..k)
    end
    Pick(db.when,D.WHEN,"when");Pick(db.mode,D.MODES,"mode");Pick(db.cant,D.CANT,"cant")
    Pick(db.resting,D.RESTING,"resting");Pick(db.watchMode,D.WATCH_MODES,"watchMode");Pick(db.totemMode,D.TOTEM_MODES,"totemMode")
    for key,range in pairs(D.ranges) do Whole(db[key],range,key) end
    local warnOK=false;for _,v in ipairs(D.WARN_CHOICES) do warnOK=warnOK or db.warnMinutes==v end
    assert(warnOK,"Invalid Buff Reminders setting: warnMinutes")

    if db.buffs==nil then db.buffs={} end
    assert(type(db.buffs)=="table","Invalid Buff Reminders buffs")
    for _,b in ipairs(D.buffs) do
        if b.kind~="totem" then
            if db.buffs[b.key]==nil then db.buffs[b.key]=b.default end
            assert(type(db.buffs[b.key])=="boolean","Invalid Buff Reminders buff: "..b.key)
        end
    end

    if db.totems==nil then db.totems={} end
    assert(type(db.totems)=="table","Invalid Buff Reminders totems")
    Defaults(db.totems,{earth="",fire="",water="",air="windfuryTotem"})
    for _,element in ipairs(D.ELEMENTS) do
        local v=db.totems[element.id];local ok=v==""
        for _,t in ipairs(D.totems[element.id]) do ok=ok or v==t.id end
        assert(type(v)=="string" and ok,"Invalid Buff Reminders totem: "..element.id)
    end

    if db.choices==nil then db.choices={} end
    assert(type(db.choices)=="table","Invalid Buff Reminders choices")
    Defaults(db.choices,{blessing="might",paladinAura="devotion",aspect="hawk",imbue="rockbiter",shield="lightningShield",
        armor="auto",demon="imp",poisonMain="instant",poisonOff="deadly",stone="firestone"})
    for name,list in pairs(D.choices) do Pick(db.choices[name],ChoiceSet(list),"choice "..name) end

    if db.where==nil then db.where={} end
    assert(type(db.where)=="table","Invalid Buff Reminders places")
    Defaults(db.where,{world=true,dungeon=true,raid=true,battleground=false})
    for _,k in ipairs({"world","dungeon","raid","battleground"}) do assert(type(db.where[k])=="boolean","Invalid Buff Reminders place: "..k) end

    if db.look==nil then db.look={} end
    assert(type(db.look)=="table","Invalid Buff Reminders look")
    -- Earlier test builds had one square icon size and an "inside" timer.
    local square=db.look.iconSize
    if D.Number(square,16,96) and square%1==0 then
        if db.look.iconWidth==nil then db.look.iconWidth=square end
        if db.look.iconHeight==nil then db.look.iconHeight=square end
    end
    if db.look.timer=="inside" then db.look.timer="bottom" end
    for k,v in pairs(LOOK) do
        if db.look[k]==nil then db.look[k]=type(v)=="table" and {v[1],v[2],v[3]} or v end
    end
    Pick(db.look.grow,D.GROW,"look.grow");Pick(db.look.timer,D.TIMER,"look.timer")
    Pick(db.look.timerOutline,D.OUTLINES,"look.timerOutline");Pick(db.look.timerColor,D.TIMER_COLORS,"look.timerColor")
    Pick(db.look.labelStyle,D.LABEL_STYLES,"look.labelStyle");Pick(db.look.labelPosition,D.LABEL_POSITIONS,"look.labelPosition")
    Pick(db.look.menuDirection,D.DIRECTIONS,"look.menuDirection")
    for _,k in ipairs({"glow","sound","labels","fineBorder"}) do assert(type(db.look[k])=="boolean","Invalid Buff Reminders look: "..k) end
    assert(type(db.look.timerFont)=="string" and #db.look.timerFont<=140 and (db.look.timerFont=="game" or db.look.timerFont=="chat" or db.look.timerFont:sub(1,6)=="media:"),"Invalid Buff Reminders look: timerFont")
    for _,k in ipairs({"colorMissing","colorExpiring","colorFine"}) do
        local c=db.look[k]
        assert(type(c)=="table","Invalid Buff Reminders look: "..k)
        for i=1,3 do assert(D.Number(c[i],0,1),"Invalid Buff Reminders look: "..k) end
    end
    for key,range in pairs(D.lookRanges) do Whole(db.look[key],range,"look."..key) end

    -- What each icon applied last, per character: poisons per hand, food, oils, stones.
    if db.lastUsed==nil then db.lastUsed={} end
    assert(type(db.lastUsed)=="table","Invalid Buff Reminders last used")
    local characters=0
    for guid,row in pairs(db.lastUsed) do
        characters=characters+1
        assert(characters<=200 and type(guid)=="string" and #guid<=100 and type(row)=="table","Invalid Buff Reminders last used")
        for k,v in pairs(row) do
            assert(type(k)=="string" and #k<=40,"Invalid Buff Reminders last used")
            assert((type(v)=="string" and #v<=64) or (D.Number(v,1,2147483647) and v%1==0),"Invalid Buff Reminders last used")
        end
    end

    if db.watchLook==nil then db.watchLook={} end
    assert(type(db.watchLook)=="table","Invalid Buff Reminders group look")
    Defaults(db.watchLook,WATCH_LOOK)
    Pick(db.watchLook.namePosition,D.NAME_POSITIONS,"watchLook.namePosition");Pick(db.watchLook.nameColor,D.NAME_COLORS,"watchLook.nameColor")
    assert(type(db.watchLook.names)=="boolean" and type(db.watchLook.timers)=="boolean","Invalid Buff Reminders group look")
    for key,range in pairs(D.watchRanges) do Whole(db.watchLook[key],range,"watchLook."..key) end
end

-- One-time adoption of the Rogue Tools Poison Reminder settings, for a
-- Buff Reminders table that has never been set up. Rogue settings stay as they are.
function D.AdoptRogue(db,modules)
    if type(db)~="table" or db.rogueAdopted~=nil then return end
    local fresh=db.when==nil and db.poisonWarn==nil
    db.rogueAdopted=true
    local rogue=type(modules)=="table" and modules.foreverRogue
    if not fresh or type(rogue)~="table" then return end
    local function Copy(from,to,check) if check(rogue[from]) then db[to]=rogue[from] end end
    local function Bool(v) return type(v)=="boolean" end
    local function Range(lo,hi) return function(v) return D.Number(v,lo,hi) and v%1==0 end end
    Copy("threshold","poisonWarn",Range(5,20));Copy("chargeThreshold","poisonCharges",Range(5,25))
    Copy("timeReminder","timeReminder",Bool);Copy("chargeReminder","chargeReminder",Bool)
    Copy("dismissOnRightClick","dismiss",Bool)
    Copy("reminderVisibility","when",function(v) return type(v)=="string" and D.WHEN[v]==true end)
end

function D.ChoiceLabel(name,id)
    for _,c in ipairs(D.choices[name] or {}) do if c.id==id then return c.label end end
end
function D.TotemType(element,id)
    for _,t in ipairs(D.totems[element] or {}) do if t.id==id then return t end end
end
