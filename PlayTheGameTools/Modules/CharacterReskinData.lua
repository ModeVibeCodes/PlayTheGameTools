local _,addon=...
local M,D=addon.CharacterReskin,addon.ForeverRogueData
if not M then return end
local function Number(fn,...)
    local v=D.Call(fn,...);if D.Number(v,-1e12,1e12) then return v end
end
function M:UpdateStats(host)
    if not self.stats then self.stats=host:CreateFontString(nil,"OVERLAY");self.stats:SetJustifyV("TOP");self.stats:SetWordWrap(false) end
    local t,db=self.stats,self.db
    t:Hide();if not db.quickStats then return end
    local rows={}
    local function Add(name,value,percent)
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
    self:Font(t);t:SetWidth(db.statsWidth);t:SetHeight((db.fontSize+3)*#rows)
    t:ClearAllPoints();t:SetPoint(db.statsAnchor,host,db.statsAnchor,db.statsX,db.statsY)
    t:SetJustifyH(db.statsAlign);t:SetText(table.concat(rows,"\n"));t:Show()
end
-- Only typed permanent-enchantment lines are summarized. Ordinary item stats
-- must never be mistaken for enchant stats. Unknown effects retain a short name.
function M.Summarize(text)
    if not D.Public(text) or type(text)~="string" then return "Unknown" end
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
    local a,b=text:match("(%S+)%s*(%S*)");return a and (a..(b~="" and " "..b or "")) or "Unknown"
end
function M:Enhancement(slot)
    local parts={};local permanent=Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent
    local info=D.Call(C_TooltipInfo and C_TooltipInfo.GetInventoryItem,"player",slot)
    local lines=D.Field(info,"lines")
    if permanent and type(lines)=="table" then
        for i=1,100 do
            local line=D.Field(lines,i);if not line then break end
            if D.Field(line,"type")==permanent then
                parts[#parts+1]={text=self.Summarize(D.Field(line,"leftText")),color=self.db.enchantColor}
            end
        end
    end
    -- Item links confirm an enchant exists even when its tooltip is unavailable.
    local link=D.Call(GetInventoryItemLink,"player",slot)
    if #parts==0 and type(link)=="string" then
        local id=link:match("item:%d+:(%d+)")
        if id and id~="0" then parts[#parts+1]={text="Unknown",color=self.db.unknownColor} end
    end
    if slot==16 or slot==17 then
        local weapon=Enum and Enum.WeaponSlot and (slot==16 and Enum.WeaponSlot.MainHand or Enum.WeaponSlot.OffHand)
        local imbue=Enum and Enum.ItemEnchantType and Enum.ItemEnchantType.Imbue
        local enchants=weapon and D.Call(C_Item and C_Item.GetWeaponEnchantInfo,weapon)
        if type(enchants)=="table" and imbue then for i=1,16 do
            local e=D.Field(enchants,i);if not e then break end
            if D.Field(e,"enchantType")==imbue and D.Field(e,"hasEnchant")==true then
                local text="Imbue";local icon=D.Field(e,"enchantIconID")
                -- Existing client-verified Rogue catalog supplies effect names, no spell guessing.
                if D.Number(icon,1,2147483647) then
                    for _,id in ipairs(D.families) do
                        local spell=D.Spell(id)
                        if spell and spell.icon==icon then text=spell.name;break end
                    end
                end
                parts[#parts+1]={text=self.Summarize(text),color=self.db.imbueColor}
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
                text:SetText(self:Enhancement(e[2]));text:Show()
            end
        end
    end
end
