local _, addon = ...
addon.categories, addon.categoryOrder = {}, {}

-- Categories organize existing modules; they have no enable state or lifecycle.
function addon:RegisterCategory(id, definition)
    assert(not self.initialized, "Play The Game Tools: register categories before initialization.")
    assert(type(id) == "string" and id ~= "" and id ~= "dashboard" and not self.categories[id], "Play The Game Tools: unique category ID required.")
    assert(not self.modules or not self.modules[id], "Play The Game Tools: category/module IDs must be distinct.")
    assert(type(definition) == "table" and type(definition.title) == "string", "Play The Game Tools: category title required.")
    self.categories[id] = { id = id, title = definition.title, modules = {} }
    self.categoryOrder[#self.categoryOrder + 1] = id
end

-- Both editions share supported Timers and Quality of Life modules.
addon:RegisterCategory("timers", { title = "Timers" })
if not addon.Edition or addon.Edition.name ~= "Forever" then
    addon:RegisterCategory("mythicPlus", { title = "Mythic+" })
end
addon:RegisterCategory("qualityOfLife", { title = "Quality of Life" })
