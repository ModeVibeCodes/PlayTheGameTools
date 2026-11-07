local _, addon = ...

-- Optional media service. Never alter Blizzard FontObjects or copy provider files.
local M = {
    regions = setmetatable({}, { __mode = "k" }),
    fontListeners = setmetatable({}, { __mode = "k" }),
    borderListeners = setmetatable({}, { __mode = "k" }),
    borderRevision = 0,
    statusbarListeners = setmetatable({}, { __mode = "k" }), statusbarRevision = 0,
    textureFailures = {},
    soundListeners = setmetatable({}, { __mode = "k" }),
}
addon.Media = M
M.defaultStatusBar = "Interface\\Buttons\\WHITE8X8"
function M:RegisterStatusBarListener(owner,callback) self.statusbarListeners[owner]=callback end
function M:UnregisterStatusBarListener(owner) self.statusbarListeners[owner]=nil end
function M:GetStatusBar(style)
    if style=="default" then return self.defaultStatusBar end
    if type(style)~="string" or style:sub(1,6)~="media:" or not self.library then return end
    local name=style:sub(7)
    local entries=self.library:HashTable("statusbar")
    if not entries or not entries[name] then return end
    local path=self.library:GetGlobal("statusbar") and entries[name] or self.library:Fetch("statusbar",name,true)
    if type(path)=="string" and path~="" then return path end
end
function M:GetStatusBars()
    local choices={{key="default",label="Play The Game Tools Default"}}; local seen={}
    if self.library then
        for _,name in ipairs(self.library:List("statusbar") or {}) do
            if type(name)=="string" and not seen[name] and self:GetStatusBar("media:"..name) then
                seen[name]=true; choices[#choices+1]={key="media:"..name,label=name}
            end
        end
    end
    return choices
end
function M:RefreshStatusBars()
    if InCombatLockdown() or UnitAffectingCombat("player") then self.statusbarPending=true; self.pending=true; return end
    self.statusbarPending=false; self.statusbarRevision=self.statusbarRevision+1
    for owner,callback in pairs(self.statusbarListeners) do callback(owner) end
end

-- Source originals and runtime cutouts share one bundled asset registry.
M.textureBase = "Interface\\AddOns\\PlayTheGameTools\\Media\\Textures\\"
M.Textures = {
    ReadyCheck = { file = "Ready_Check.tga", transparent = true },
    Window = { file = "Panel_Graphite_Cutout.tga", slice = 16, rounded = true },
    Header = { file = "Header_Satin_Cutout.tga", slice = 16, rounded = true },
    Sidebar = { file = "Sidebar_Graphite.tga" },
    RaisedPanel = { file = "Panel_Raised.tga" },
    InsetPanel = { file = "Panel_Inset.tga" },
    ButtonDefault = { file = "Button_Default_Cutout.tga", slice = 12, rounded = true },
    ButtonHover = { file = "Button_Hover_Cutout.tga", slice = 12, rounded = true },
    ButtonPressed = { file = "Button_Pressed_Cutout.tga", slice = 12, rounded = true },
    ButtonDisabled = { file = "Button_Disabled_Cutout.tga", slice = 12, rounded = true },
    ButtonActive = { file = "Button_Active_Cutout.tga", slice = 12, rounded = true },
    ButtonSecondary = { file = "Button_Secondary_Cutout.tga", slice = 12, rounded = true },
    TabDefault = { file = "Tab_Default_Cutout.tga", slice = 12, rounded = true },
    TabSelected = { file = "Tab_Selected_Cutout.tga", slice = 12, rounded = true },
    BorderSilver = { file = "Border_Silver.tga", slice = 16, transparent = true },
    AccentMint = { file = "Line_Accent_Mint.tga", crop = { 0, 1, 0.25, 0.75 } },
    AccentLavender = { file = "Line_Accent_Lavender.tga", crop = { 0, 1, 0.25, 0.75 } },
    UnderlineMint = { file = "Underline_Mint.tga", crop = { 0, 1, 13 / 32, 19 / 32 } },
    ToggleOff = { file = "Toggle_Off_Cutout.tga", rounded = true },
    ToggleMint = { file = "Toggle_Mint_Cutout.tga", rounded = true },
    CheckboxOff = { file = "Checkbox_Off.tga" },
    CheckboxMint = { file = "Checkbox_Mint.tga" },
    SliderTrack = { file = "Slider_Track_Cutout.tga", slice = 12, rounded = true },
    InputField = { file = "Input_Field_Cutout.tga", slice = 12, rounded = true },
    RoundMarker = { file = "Round_Marker.tga", rounded = true },
}

-- The settings interface is drawn from flat fills (Config/Widgets.lua) and
-- no longer reads bundled configuration art.

-- Return path and read-only rendering metadata; unknown names return nil.
function M:GetTexture(name)
    local asset = self.Textures[name]
    if asset then return self.textureBase .. asset.file, asset end
end

function M:ApplyTexture(texture, key, fallback)
    local asset = assert(self.Textures[key], "Play The Game Tools: unknown texture " .. tostring(key))
    if texture.ClearTextureSlice then texture:ClearTextureSlice() end
    texture:SetTexCoord(0, 1, 0, 1)
    local usable = (not asset.slice or texture.SetTextureSliceMargins ~= nil)
        and texture:SetTexture(self.textureBase .. asset.file, "CLAMP", "CLAMP")
    if usable then
        if asset.slice then texture:SetTextureSliceMargins(asset.slice, asset.slice, asset.slice, asset.slice) end
        if asset.crop then texture:SetTexCoord(unpack(asset.crop)) end
    else
        local color = fallback or { 0, 0, 0, 1 }
        -- A solid rectangular fallback would reintroduce protruding corners.
        texture:SetColorTexture(color[1], color[2], color[3], (asset.transparent or asset.rounded) and 0 or (color[4] or 1))
        if not self.textureFailures[key] then
            self.textureFailures[key] = true
            print("Play The Game Tools: texture unavailable (" .. key .. "); using a plain fallback.")
        end
    end
    return usable
end

-- Listeners receive their owner after out-of-combat font refreshes.
function M:RegisterFontListener(owner, callback)
    assert(type(owner) == "table" and type(callback) == "function", "Play The Game Tools: media listener requires owner and callback.")
    self.fontListeners[owner] = callback
end

function M:UnregisterFontListener(owner)
    self.fontListeners[owner] = nil
end

function M:RegisterBorderListener(owner, callback)
    assert(type(owner) == "table" and type(callback) == "function", "Play The Game Tools: border listener requires owner and callback.")
    self.borderListeners[owner] = callback
end

function M:UnregisterBorderListener(owner) self.borderListeners[owner] = nil end

-- LSM supplies paths, not per-border edge dimensions. Native backdrop strips
-- use a conservative tiled edge, capped by the consuming icon's size.
function M:GetBorder(style)
    if style == "none" then return { kind = "none" } end
    if style == "thin" then return { kind = "thin", edgeSize = 1 } end
    if type(style) ~= "string" or style:sub(1, 6) ~= "media:" or not self.library then return end
    local name = style:sub(7)
    local entries = self.library:HashTable("border")
    if not entries or not entries[name] then return end
    local path = self.library:GetGlobal("border") and entries[name] or self.library:Fetch("border", name, true)
    if type(path) == "string" and path ~= "" then return { kind = "shared", path = path, edgeSize = 8 } end
end

function M:GetBorders()
    local choices = { { key = "none", label = "None" }, { key = "thin", label = "Play The Game Tools Thin" } }
    local seen = {}
    if self.library then
        for _, name in ipairs(self.library:List("border") or {}) do
            if type(name) == "string" and not seen[name] and self:GetBorder("media:" .. name) then
                seen[name] = true
                choices[#choices + 1] = { key = "media:" .. name, label = name }
            end
        end
    end
    return choices
end

function M:RefreshBorders()
    if InCombatLockdown() or UnitAffectingCombat("player") then self.borderPending = true; return end
    self.borderPending = false
    self.borderRevision = self.borderRevision + 1
    for owner, callback in pairs(self.borderListeners) do callback(owner) end
end

function M:GetInterfaceFont(fallbackPath)
    return self:GetFont("Expressway") or fallbackPath or GameFontHighlight:GetFont()
end

local function InCombat()
    return InCombatLockdown() or UnitAffectingCombat("player")
end

function M:AttachLibrary()
    local library = LibStub and LibStub("LibSharedMedia-3.0", true)
    if library then
        for _, method in ipairs({ "List", "Fetch", "HashTable", "GetGlobal" }) do
            if type(library[method]) ~= "function" then return false end
        end
    end
    if not library or library == self.library then return false end
    if self.library and self.library.UnregisterCallback then
        self.library.UnregisterCallback(self, "LibSharedMedia_Registered")
        self.library.UnregisterCallback(self, "LibSharedMedia_SetGlobal")
    end
    self.library = library
    if library.RegisterCallback then
        library.RegisterCallback(self, "LibSharedMedia_Registered", "OnMediaRegistered")
        library.RegisterCallback(self, "LibSharedMedia_SetGlobal", "OnMediaRegistered")
    end
    return true
end

function M:GetFont(name)
    if type(name) ~= "string" or name == "" or not self.library then return end
    -- Fetch may honor an LSM global override; prefer the exact registered entry.
    local media = self.library:HashTable("font")
    if not media or not media[name] then return end
    local path = self.library:GetGlobal("font") and media[name] or self.library:Fetch("font", name, true)
    if type(path) == "string" and path ~= "" then return path end
end

function M:GetFonts()
    local choices = {
        { key = "game", label = "Game font", path = GameFontHighlight:GetFont() },
        { key = "chat", label = "Chat font", path = ChatFontNormal:GetFont() },
    }
    local seen = {}
    if self.library then
        for _, name in ipairs(self.library:List("font") or {}) do
            local path = self:GetFont(name)
            if path and not seen[name] then
                seen[name] = true
                choices[#choices + 1] = { key = "media:" .. name, label = name, path = path, media = name }
            end
        end
    end
    return choices
end

function M:GetGlobalFont()
    local name=self.library and self.library:GetGlobal("font")
    if type(name)=="string" then return self:GetFont(name) end
end
function M:GetDisplayFont(appearance, respectGlobal)
    return (respectGlobal and self:GetGlobalFont()) or self:GetFont(appearance.fontMedia or "")
        or (appearance.font == "chat" and ChatFontNormal:GetFont() or GameFontHighlight:GetFont())
end

function M:ApplyInterfaceFont(region, spec)
    local preferred = self:GetInterfaceFont(spec.path)
    if not region:SetFont(preferred, spec.size, spec.flags) then
        region:SetFont(spec.path, spec.size, spec.flags)
    end
end

function M:BindInterfaceFont(region, fontObject, fontSize)
    local path, size, flags = fontObject:GetFont()
    local spec = { path = path, size = fontSize or size, flags = flags or "" }
    self.regions[region] = spec
    self:ApplyInterfaceFont(region, spec)
end
function M:UnbindInterfaceFont(region) self.regions[region] = nil end

function M:RefreshFonts()
    self:AttachLibrary()
    if InCombat() then self.pending = true; return end
    self.pending = false
    for region, spec in pairs(self.regions) do self:ApplyInterfaceFont(region, spec) end
    for owner, callback in pairs(self.fontListeners) do callback(owner) end
    if self.statusbarPending then self:RefreshStatusBars() end
    if self.soundPending then self:RefreshSounds() end
end

function M:OnMediaRegistered(_, mediaType)
    if mediaType == "font" then self:RefreshFonts() end
    if mediaType == "border" then self:RefreshBorders() end
    if mediaType == "statusbar" then self:RefreshStatusBars() end
    if mediaType == "sound" then self:RefreshSounds() end
end

function M:Initialize()
    if self.events then return end
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function()
        if self:AttachLibrary() then self:RefreshFonts(); self:RefreshBorders(); self:RefreshStatusBars(); self:RefreshSounds() end
        if addon.Positioning then addon.Positioning:Discover() end
    end)
    self.events = events
    self:RefreshFonts()
    self:RefreshBorders()
    self:RefreshStatusBars()
end

function M:GetSound(style)
    if style=="default" then return SOUNDKIT and SOUNDKIT.RAID_WARNING end
    if type(style)~="string" or style:sub(1,6)~="media:" or not self.library then return end
    local entries=self.library:HashTable("sound")
    if (issecretvalue and issecretvalue(entries)) or type(entries)~="table" or (issecrettable and issecrettable(entries))
        or (canaccesstable and not canaccesstable(entries)) then return end
    local value=entries and entries[style:sub(7)]
    if issecretvalue and issecretvalue(value) then return end
    if (type(value)=="string" and value~="") or (type(value)=="number" and value>0 and value<math.huge and value==math.floor(value)) then return value end
end
function M:GetSounds()
    local choices={{key="default",label="Blizzard Warning"}}
    if self.library then for _,name in ipairs(self.library:List("sound") or {}) do
        if type(name)=="string" and self:GetSound("media:"..name) then choices[#choices+1]={key="media:"..name,label=name} end
    end end
    return choices
end
function M:RegisterSoundListener(owner,callback) self.soundListeners[owner]=callback end
function M:RefreshSounds()
    if InCombat() then self.soundPending=true;self.pending=true;return end
    self.soundPending=false
    for owner,callback in pairs(self.soundListeners) do callback(owner) end
end
