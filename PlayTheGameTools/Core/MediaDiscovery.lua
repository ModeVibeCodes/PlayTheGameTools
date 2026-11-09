local _,addon=...
local M=addon.Media
local kinds={font=true,statusbar=true,background=true,border=true}
local limit=4096
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
-- Explicit SharedMedia activation requested by the owner. Other media providers
-- remain passive. Adopt each installed service once; later manual disables win.
function M:EnsureSharedMedia()
    if self.startingSharedMedia then return end
    if InCombatLockdown() or UnitAffectingCombat("player") then self.sharedMediaPending=true;return end
    self.sharedMediaPending=false
    local api=C_AddOns
    local root=addon.ProfileManager and addon.ProfileManager.root
    if not root or not (api and api.DoesAddOnExist and api.IsAddOnLoaded and api.GetAddOnEnableState) then return end
    if root.sharedMediaActivation==nil then root.sharedMediaActivation={} end
    if type(root.sharedMediaActivation)~="table" then return end
    self.startingSharedMedia=true
    self.sharedMediaAttempted=self.sharedMediaAttempted or {}
    self.sharedMediaStatus="Not installed"
    for _,name in ipairs({"SharedMedia","SharedMedia_MyMedia"}) do
        local ok,exists=pcall(api.DoesAddOnExist,name)
        if ok and Public(exists) and exists==true then
            local loadedOk,loaded=pcall(api.IsAddOnLoaded,name)
            if loadedOk and Public(loaded) and loaded==true then
                root.sharedMediaActivation[name]=true
                if name=="SharedMedia" then self.sharedMediaStatus="Ready" end
            elseif not self.sharedMediaAttempted[name] then
                self.sharedMediaAttempted[name]=true
                local stateOk,state=pcall(api.GetAddOnEnableState,name)
                if stateOk and Public(state) and type(state)=="number" then
                    if state==0 and not root.sharedMediaActivation[name] and api.EnableAddOn then
                        pcall(api.EnableAddOn,name)
                        stateOk,state=pcall(api.GetAddOnEnableState,name)
                        if stateOk and Public(state) and type(state)=="number" and state>0 and api.SaveAddOns then pcall(api.SaveAddOns) end
                    end
                    if stateOk and Public(state) and type(state)=="number" and state>0 then
                        root.sharedMediaActivation[name]=true
                        if api.LoadAddOn then pcall(api.LoadAddOn,name) end
                        loadedOk,loaded=pcall(api.IsAddOnLoaded,name)
                        if name=="SharedMedia" then self.sharedMediaStatus=loadedOk and Public(loaded) and loaded==true and "Ready" or "Reload or check AddOns" end
                    elseif name=="SharedMedia" then self.sharedMediaStatus="Disabled in AddOns" end
                end
            elseif name=="SharedMedia" then self.sharedMediaStatus=self.sharedMediaLastStatus or "Reload needed" end
        end
    end
    self.sharedMediaLastStatus=self.sharedMediaStatus
    self.startingSharedMedia=false
end
local function Valid(kind,name,path)
    return Public(kind) and Public(name) and Public(path) and kinds[kind]
        and type(name)=="string" and #name>0 and #name<=160 and not name:find("[%z\1-\31]")
        and type(path)=="string" and #path<=1024 and not path:find("[%z\1-\31]")
        and not path:find("..",1,true) and path:lower():match("^interface\\addons\\[^\\]+\\.+")
end
local function Installed(path)
    local provider=path:match("^[^\\]+\\[^\\]+\\([^\\]+)\\")
    if not provider or not (C_AddOns and C_AddOns.DoesAddOnExist and C_UIFileAsset and C_UIFileAsset.IsKnownFile) then return false end
    local ok,exists=pcall(C_AddOns.DoesAddOnExist,provider)
    if not ok or not Public(exists) or exists~=true then return false end
    local known,asset=pcall(C_UIFileAsset.IsKnownFile,path)
    return known and Public(asset) and asset==true
end
function M:RememberMedia(kind,name)
    if self.discoveryRunning or not self.library then return end
    local root=addon.ProfileManager and addon.ProfileManager.root
    if not root then return end
    if root.mediaRegistry==nil then root.mediaRegistry={} end
    if type(root.mediaRegistry)~="table" then return end -- Preserve unknown data.
    local cache=root.mediaRegistry
    if not self.mediaRegistryCount then
        self.mediaRegistryCount=0
        for k in pairs(kinds) do
            if type(cache[k])=="table" then for _ in pairs(cache[k]) do self.mediaRegistryCount=self.mediaRegistryCount+1 end end
        end
    end
    local function Remember(k,n,path)
        if Public(path) and type(path)=="string" then path=path:gsub("/","\\") end
        if not Valid(k,n,path) then return end
        if cache[k]==nil then cache[k]={} end
        if type(cache[k])~="table" then return end
        if cache[k][n]==nil then
            if self.mediaRegistryCount>=limit then return end
            self.mediaRegistryCount=self.mediaRegistryCount+1
        end
        cache[k][n]=path
    end
    if kinds[kind] and type(name)=="string" then
        local entries=self.library:HashTable(kind)
        if entries then Remember(kind,name,entries[name]) end
    else
        for k in pairs(kinds) do for n,path in pairs(self.library:HashTable(k) or {}) do Remember(k,n,path) end end
    end
end
function M:DiscoverMedia()
    if self.discoveryRunning or not self.library or type(self.library.Register)~="function" then return end
    self.discoveryRunning=true
    local accepted=0
    local function Register(kind,name,path)
        if accepted>=limit or not Valid(kind,name,path) then return end
        local entries=self.library:HashTable(kind)
        if entries and entries[name] then return end -- Active provider wins collisions.
        if Installed(path) then
            accepted=accepted+1
            pcall(self.library.Register,self.library,kind,name,path)
        end
    end
    for _,entry in ipairs(self.providerCatalog or {}) do Register(entry[1],entry[2],entry[3]) end
    local root=addon.ProfileManager and addon.ProfileManager.root
    local cache=root and root.mediaRegistry
    if type(cache)=="table" then
        for kind in pairs(kinds) do
            if type(cache[kind])=="table" then for name,path in pairs(cache[kind]) do Register(kind,name,path) end end
        end
    end
    self.discoveryRunning=false
    self:RememberMedia()
end
