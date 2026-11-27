local _,addon=...
-- v2 one-time styling reset (approved exception to "never reset settings").
-- Before v2 each display had its own font, color and size settings on its
-- page. v2 styles displays only in Layout (the Style card, saved in position
-- records), so those old settings were retired. Once per profile, profile
-- validation (Core/ProfileValidation.lua) resets exactly the keys listed
-- below to the module defaults, the same way AdoptSplit and AdoptRoster run:
-- stored, selected, imported and exported profiles are all handled alike.
--
-- These lists are styling only: fonts, sizes, colors, textures, borders,
-- backgrounds, icon sizes and outline. They never name positions, anchors,
-- Style card records, behaviour or visibility switches, data, history or
-- profiles. Keys that change behaviour as well as look are kept and named in
-- the "kept" comment under each list.
local R={}
addon.StyleReset=R
R.MESSAGE="v2 resets each display's old font, color and size settings."
R.HINT="Use Layout to restyle displays."
-- Marker saved in each profile: { cleared = boolean }. Present = done.
R.MARKER="v2StyleReset"

-- Rogue Tools' lists left with the module (retired into Buff Reminders): a
-- module that is no longer registered has no defaults, so its table is skipped.
-- Profession & Food Bars share one key set (the food bar's lives in .food).
-- Kept: columns (Icons Per Row), showNames, showTooltips, x/y, hidden, selected.
local BAR={"scale","iconSize","spacing","padding","fontSize","font","fontMedia","outline",
    "backgroundColor","backgroundOpacity","borderColor","borderOpacity","textColor"}

R.lists={
    -- Combat Timer (Display section). Kept: appearance.format, position, showOutOfCombat.
    {module="combatTimer",path={"appearance"},keys={"font","fontMedia","fontSize","outline","textColor",
        "backgroundColor","backgroundOpacity","scale"}},
    {module="foreverQuickAccess",keys=BAR},
    {module="foreverQuickAccess",path={"food"},keys=BAR},
    -- Experience Bar. Kept: showXP, showValues, showRested, showQuests,
    -- questFormat, separator, sessionSeparator, showSession, showRate,
    -- sessionAbove, showRestedOverlay, showQuestOverlay, textOffset,
    -- sessionGap, sessionX (offsets), barChoice, hide*XP, blizzardStyle.
    {module="enhancedExperienceBar",keys={"barTexture","width","height","scale","opacity","restedOpacity","questOpacity",
        "outline","font","fontMedia","fontSize","textOpacity","textColor","align",
        "sessionFontSize","sessionWidth","sessionOpacity","sessionOutline","sessionFont","sessionFontMedia",
        "sessionTextColor","sessionAlign","nativeColors","normalColor","restedColor","restedOverlayColor",
        "questColor","backgroundColor","borderColor"}},
    -- Campfire icon, Camp Buffs and Camp Contributions (saved under
    -- lootSparkles.campfire since the split). Kept: compactBenefits,
    -- contributionVisibleRows, every show*/tooltip switch and x/y.
    {module="lootSparkles",path={"campfire"},keys={"textColor","headerGradient","headerColor","headerEndColor",
        "iconSize","fontSize","width","scale","opacity","backgroundOpacity",
        "colorStats","benefitsFontSize","benefitsWidth","benefitsScale","benefitsOpacity","benefitsBackgroundOpacity",
        "contributionScale","contributionOpacity","contributionBackgroundOpacity","contributionWidth","contributionPadding",
        "contributionBorderSize","contributionBorderOpacity","contributionBackgroundColor","contributionBorderColor",
        "contributionUseInterfaceFont","contributionOutline","contributionHeaderGradient","contributionFont","contributionFontMedia",
        "contributionTitleSize","contributionNameSize","contributionInfoSize","contributionActionSize","contributionHintSize",
        "contributionFooterSize","contributionDismissSize","contributionTitleColor","contributionTitleEndColor",
        "contributionNameColor","contributionInfoColor","contributionActionColor","contributionDismissColor",
        "contributionHintColor","contributionFooterColor","contributionTitleAlign","contributionTextAlign",
        "contributionIconSize","contributionIconOpacity","contributionRowHeight","contributionRowGap",
        "contributionRowColor","contributionRowOpacity","contributionHoverColor","contributionHoverOpacity"}},
}

-- Saved numbers may come back from SavedVariables slightly rounded.
local function Same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)=="number" then return math.abs(a-b)<1e-6 end
    if type(a)~="table" then return a==b end
    for key,value in pairs(a) do if not Same(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local function Walk(root,module,path)
    local node=type(root)=="table" and type(root.modules)=="table" and root.modules[module]
    for _,key in ipairs(path or {}) do node=type(node)=="table" and node[key] or nil end
    return type(node)=="table" and node or nil
end
-- Resets the listed keys of `profile` that differ from `template` (a fully
-- defaulted profile). Pure and idempotent; returns true if anything changed.
function R.Clear(profile,template)
    local cleared=false
    for _,list in ipairs(R.lists) do
        local target,defaults=Walk(profile,list.module,list.path),Walk(template,list.module,list.path)
        if target and defaults then
            for _,key in ipairs(list.keys) do
                local default=defaults[key]
                if default~=nil and target[key]~=nil and not Same(target[key],default) then
                    target[key]=addon.ProfileCodec.Copy(default);cleared=true
                end
            end
        end
    end
    return cleared
end

-- Notice state, outside every profile, kept per profile name:
-- { [profile] = { announced, dismissed } }. Dismissing one profile's notice
-- does not hide the notice of another profile reset later.
local function Notice()
    local manager=addon.ProfileManager
    local root=manager and manager.root
    local name=manager and manager.activeName
    if type(root)~="table" or type(name)~="string" then return {} end
    if type(root.styleResetNotice)~="table" then root.styleResetNotice={} end
    local notices=root.styleResetNotice
    if type(notices[name])~="table" then notices[name]={} end
    return notices[name]
end
-- The notice shows only when the active profile actually lost styling.
function R:Pending()
    local marker=addon.db and addon.db[R.MARKER]
    return type(marker)=="table" and marker.cleared==true and not Notice().dismissed
end
function R:Dismiss()
    Notice().dismissed=true
    if addon.RefreshStyleNotice then addon:RefreshStyleNotice() end
end
-- One chat line, once.
function R:Announce()
    if not self:Pending() then return end
    local notice=Notice()
    if notice.announced then return end
    notice.announced=true
    print("Play The Game Tools: "..R.MESSAGE.." "..R.HINT)
end
