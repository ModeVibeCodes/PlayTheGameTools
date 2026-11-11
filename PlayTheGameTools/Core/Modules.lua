local _, addon = ...

addon.modules = {}
addon.moduleOrder = {}

function addon:RegisterModule(id, module)
    assert(not self.initialized, "Play The Game Tools: register modules before initialization.")
    assert(type(id) == "string" and id ~= "", "Play The Game Tools: module ID required.")
    assert(type(module) == "table" and type(module.title) == "string", "Play The Game Tools: module title required.")
    assert(not self.modules[id], "Play The Game Tools: duplicate module ID: " .. id)
    assert(not self.categories[id], "Play The Game Tools: category/module IDs must be distinct.")
    if module.category then
        assert(self.categories[module.category] and not module.developer, "Play The Game Tools: valid gameplay category required.")
        local members = self.categories[module.category].modules
        members[#members + 1] = id
    end
    module.id = id
    module.enabled = false
    self.modules[id] = module
    self.moduleOrder[#self.moduleOrder + 1] = id
end

local function Transition(module, enabled)
    if module.planned then module.enabled=false;return end
    if module.enabled == enabled then
        return
    end
    local callback
    if enabled then
        callback = module.OnEnable
    else
        callback = module.OnDisable
    end
    if callback then
        callback(module)
    end
    module.enabled = enabled
    if not enabled and addon.PreviewStates then addon.PreviewStates:Stop(module.id) end
end

function addon:InitializeModules()
    for _, id in ipairs(self.moduleOrder) do
        local module = self.modules[id]
        local settings = self.db.modules[id]
        if settings == nil then
            settings = { enabled = module.defaultEnabled ~= false }
            self.db.modules[id] = settings
        end
        assert(type(settings) == "table", "Play The Game Tools: invalid settings for " .. id)
        if settings.enabled == nil then
            settings.enabled = module.defaultEnabled ~= false
        end
        assert(type(settings.enabled) == "boolean", "Play The Game Tools: invalid enabled setting for " .. id)
        module.db = settings
        if module.OnInitialize then
            module:OnInitialize()
        end
        Transition(module, settings.enabled)
        if self.SyncModuleDisplayModes then self:SyncModuleDisplayModes(module) end
    end
end

function addon:SetModuleEnabled(id, enabled)
    assert(self.initialized and self.modules[id], "Play The Game Tools: module unavailable.")
    assert(type(enabled) == "boolean", "Play The Game Tools: enabled must be boolean.")
    local module = self.modules[id]
    if module.planned then return end
    Transition(module, enabled)
    module.db.enabled = enabled
    if self.SyncModuleDisplayModes then self:SyncModuleDisplayModes(module) end
    if self.EditMode then self.EditMode:RefreshElements() end
    if self.RefreshConfig then self:RefreshConfig() end
end
