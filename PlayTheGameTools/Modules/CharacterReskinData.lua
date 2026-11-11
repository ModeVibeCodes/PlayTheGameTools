local _,addon=...
local M,D=addon.CharacterReskin,addon.ForeverRogueData
if not M then return end
local function Number(fn,...)
    local v=D.Call(fn,...);if D.Number(v,-1e12,1e12) then return v end
end
function M:UpdateStats(host)
    if not self.stats then
        self.stats=CreateFrame("Frame",nil,_G.PaperDollFrame or host);self.stats:EnableMouse(false);self.stats.rows={}
    end
    local t,db=self.stats,self.db
    t:Hide();if not db.quickStats then return end
    local rows={}
    local function Add(name,value,percent)
        if not db.statsShown[name] then return end
        rows[#rows+1]=name..": "..(value and string.format(percent and "%.1f%%" or "%.0f",value) or "—")
    end
    for i,name in ipairs({"Strength","Agility","Stamina","Intellect","Spirit"}) do
        Add(name,Number(function() local _,effective=UnitStat("player",i);return effective end))
    end
    Add("Armor",Number(function() local _,effective=UnitArmor("player");return effective end))
    Add("Attack Power",Number(function()
        local base,pos,neg=UnitAttackPower("player")
        if D.Number(base,-1e12,1e12) and D.Number(pos,-1e12,1e12) and D.Number(neg,-1e12,1e12) then return base+pos+neg end
    end))
    Add("Holy Spell Power",Number(GetSpellBonusDamage,2))
    Add("Healing",Number(GetSpellBonusHealing))
    Add("Melee Crit",Number(GetCritChance),true);Add("Spell Crit",Number(GetSpellCritChance),true)
    Add("Melee Hit",Number(function()
        local rating,bonus=Number(GetCombatRatingBonus,CR_HIT_MELEE),Number(GetHitModifier)
        if rating and bonus then return rating+bonus end
    end),true)
    Add("Melee Haste",Number(GetMeleeHaste),true);Add("Spell Haste",Number(UnitSpellHaste,"player"),true)
    Add("Expertise",Number(GetExpertise));Add("Dodge",Number(GetDodgeChance),true)
    Add("Parry",Number(GetParryChance),true);Add("Block",Number(GetBlockChance),true)
    local helm=_G.CharacterHeadSlot
    if not helm then return end
    for _,row in ipairs(t.rows) do row:SetText("");row:Hide() end
    if #rows==0 then return end
    local height=db.quickStyle.fontSize+3
    t:SetFrameLevel(math.max(host:GetFrameLevel(),helm:GetFrameLevel())+5)
    t:SetSize(db.quickStatsWidth,height*#rows)
    t:ClearAllPoints();t:SetPoint("TOPLEFT",helm,"TOPRIGHT",db.quickStatsX,db.quickStatsY)
    for i,value in ipairs(rows) do
        local row=t.rows[i]
        if not row then row=t:CreateFontString(nil,"OVERLAY");t.rows[i]=row end
        self:Font(row,db.quickStyle.textColor,nil,db.quickStyle);row:SetWordWrap(false);row:SetJustifyH("LEFT");row:SetJustifyV("MIDDLE")
        row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(i-1)*height);row:SetSize(db.quickStatsWidth,height)
        row:SetText(value);row:Show()
    end
    t:Show()
end
function M:UpdateFooter(root,paper,model)
    if not self.footer then
        self.footer=CreateFrame("Frame",nil,paper);self.footer:EnableMouse(false)
        self.footer.gold=self.footer:CreateFontString(nil,"OVERLAY")
        self.footer.durability=self.footer:CreateFontString(nil,"OVERLAY")
    end
    local view,db=self.footer,self.db
    view:Hide();view.gold:Hide();view.durability:Hide()
    if not db.showGold and not db.showDurability then return end
    view:ClearAllPoints();view:SetPoint("BOTTOMLEFT",root.LeftPaneHost or paper,"BOTTOMLEFT",16,12)
    view:SetSize(125,(db.fontSize+4)*2);view:SetFrameLevel((model or paper):GetFrameLevel()+5)
    local function Row(text,y,color)
        self:Font(text,color);text:ClearAllPoints();text:SetPoint("BOTTOMLEFT",view,"BOTTOMLEFT",0,y)
        text:SetSize(125,db.fontSize+4);text:SetWordWrap(false);text:SetJustifyH("LEFT");text:Show()
    end
    if db.showGold then
        Row(view.gold,0,{.83,.73,.48})
        local copper=Number(GetMoney)
        if copper and copper>=0 then
            copper=math.floor(copper)
            view.gold:SetText(string.format("%dg %02ds %02dc",math.floor(copper/10000),math.floor(copper/100)%100,copper%100))
        else view.gold:SetText("Gold: —") end
    end
    if db.showDurability then
        Row(view.durability,db.showGold and db.fontSize+5 or 0,db.textColor)
        local total,maximum,unknown=0,0,type(GetInventoryItemDurability)~="function"
        if not unknown then for slot=1,18 do
            local ok,current,limit=pcall(GetInventoryItemDurability,slot)
            if not ok or not D.Public(current) or not D.Public(limit) then unknown=true
            elseif current~=nil or limit~=nil then
                if D.Number(current,0,1e9) and D.Number(limit,1,1e9) and current<=limit then total=total+current;maximum=maximum+limit
                else unknown=true end
            end
        end end
        local percent=not unknown and maximum>0 and math.floor(100*total/maximum+.5)
        view.durability:SetText("Durability: "..(percent and percent.."%" or "—"))
    end
    view:Show()
end
-- Only typed permanent-enchantment lines are summarized. Ordinary item stats
-- must never be mistaken for enchant stats. Unknown effects retain a short name.
function M.Summarize(text)
    if not D.Public(text) or type(text)~="string" or text=="Unknown" then return end
    text=text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|T.-|t","")
    local lower=text:lower();local found={}
    for _,e in ipairs({{"all stats","All Stats"},{"strength","Str"},{"agility","Agi"},{"stamina","Sta"},
        {"intellect","Int"},{"spirit","Spi"},{"attack power","AP"},{"spell power","SP"},{"healing","Healing"},
        {"critical","Crit"},{"crit","Crit"},{"haste","Haste"},{"hit","Hit"},{"expertise","Expertise"},
        {"armor","Armor"},{"defense","Defense"},{"resistance","Resist"},{"mana","Mana"},{"speed","Speed"}}) do
        if lower:find(e[1],1,true) then
            local duplicate=false;for _,v in ipairs(found) do if v==e[2] then duplicate=true end end
            if not duplicate then found[#found+1]=e[2] end
        end
    end
    if #found>0 then return table.concat(found," / ") end
    -- Localized or proc effects cannot be translated to an invented stat weight.
    text=text:gsub("^.-:%s*",""):gsub("[%(%)]","")
    local a,b=text:match("(%S+)%s*(%S*)");return a and (a..(b~="" and " "..b or "")) or nil
end
function M:Enhancement(slot)
    local parts={};local permanent=Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent
    local info=D.Call(C_TooltipInfo and C_TooltipInfo.GetInventoryItem,"player",slot)
    local lines=D.Field(info,"lines")
    if permanent and type(lines)=="table" then
        for i=1,100 do
            local line=D.Field(lines,i);if not line then break end
            if D.Field(line,"type")==permanent then
                local text=self.Summarize(D.Field(line,"leftText"))
                if text then parts[#parts+1]={text=text,color=self.db.enchantColor} end
            end
        end
    end
    if slot==16 or slot==17 then
        local weapon=Enum and Enum.WeaponSlot and (slot==16 and Enum.WeaponSlot.MainHand or Enum.WeaponSlot.OffHand)
        local imbue=Enum and Enum.ItemEnchantType and Enum.ItemEnchantType.Imbue
        local enchants=weapon and D.Call(C_Item and C_Item.GetWeaponEnchantInfo,weapon)
        if type(enchants)=="table" and imbue then for i=1,16 do
            local e=D.Field(enchants,i);if not e then break end
            if D.Field(e,"enchantType")==imbue and D.Field(e,"hasEnchant")==true then
                local text;local icon=D.Field(e,"enchantIconID")
                -- Existing client-verified Rogue catalog supplies effect names, no spell guessing.
                if D.Number(icon,1,2147483647) then
                    for _,id in ipairs(D.families) do
                        local spell=D.Spell(id)
                        if spell and spell.icon==icon then text=spell.name;break end
                    end
                end
                if text then parts[#parts+1]={text=self.Summarize(text),color=self.db.imbueColor} end
            end
        end end
    end
    local result={}
    for _,p in ipairs(parts) do local c=p.color
        result[#result+1]=string.format("|cff%02x%02x%02x%s|r",math.floor(c[1]*255),math.floor(c[2]*255),math.floor(c[3]*255),p.text)
    end
    return table.concat(result,"\n")
end
function M:UpdateEnhancements()
    for _,e in ipairs(self.slots) do
        local slot=_G["Character"..e[1].."Slot"]
        if slot then
            local text=self.labels[e[2]]
            if not text then text=slot:CreateFontString(nil,"OVERLAY");self.labels[e[2]]=text end
            text:Hide()
            if self.db.enhancements then
                local db=self.db;self:Font(text);text:SetWordWrap(true);text:SetWidth(db.enchantWidth);text:SetHeight(0)
                text:ClearAllPoints()
                if e[3]=="bottom" then text:SetPoint("TOP",slot,"BOTTOM",db.enchantX,-5+db.enchantY)
                elseif e[3]=="right" then text:SetPoint("RIGHT",slot,"LEFT",-db.enchantX,db.enchantY)
                else text:SetPoint("LEFT",slot,"RIGHT",db.enchantX,db.enchantY) end
                text:SetJustifyH(db.enchantAlign~="AUTO" and db.enchantAlign or e[3]=="right" and "RIGHT" or e[3]=="bottom" and "CENTER" or "LEFT")
                local value=self:Enhancement(e[2]);text:SetText(value);text:SetShown(value~="")
            end
        end
    end
end
