local _,addon=...
local P,C={listeners={}},addon.ProfileCodec
addon.ProfileManager=P
-- Forever talent-group semantics are deferred; retain stored assignments untouched.
local specProfilesAvailable=not addon.Edition or addon.Edition.name~="Forever"
local function Combat() return InCombatLockdown() or UnitAffectingCombat("player") end
local function Public(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c=pcall(fn,...)
    if not ok then return end
    local function Safe(v) if not (issecretvalue and issecretvalue(v)) then return v end end
    return Safe(a),Safe(b),Safe(c)
end
function P:Name(name)
    if type(name)~="string" or (issecretvalue and issecretvalue(name)) then return end
    name=name:match("^%s*(.-)%s*$")
    if #name<1 or #name>48 or name:find("[%z\1-\31\127|]") then return end
    return name
end
function P:CharacterKey()
    local guid=Public(UnitGUID,"player")
    if type(guid)=="string" and guid~="" then return guid end
    local name,realm=Public(UnitFullName,"player")
    if type(name)=="string" and name~="" then
        realm=realm or Public(GetNormalizedRealmName)
        if type(realm)=="string" and realm~="" then return name.."-"..realm end
    end
end
local function SpecAPI(name) return C_SpecializationInfo and C_SpecializationInfo[name] or _G[name] end
function P:Specs()
    if not specProfilesAvailable then return {} end
    local _,_,classID=Public(UnitClass,"player")
    local count=Public(C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID,classID)
    if not C.Number(count) then count=Public(GetNumSpecializations) end
    local specs={}
    if not C.Number(count) or count<0 or count>10 then return specs end
    for index=1,count do
        local id,name=Public(SpecAPI("GetSpecializationInfo"),index)
        if C.Number(id) and id>0 and type(name)=="string" then specs[#specs+1]={id=id,label=name} end
    end
    return specs
end
function P:Spec()
    if not specProfilesAvailable then return end
    local index=Public(SpecAPI("GetSpecialization"))
    if not C.Number(index) or index<1 then return end
    local id=Public(SpecAPI("GetSpecializationInfo"),index)
    if C.Number(id) and id>0 then return id end
end
function P:Character()
    if not specProfilesAvailable then
        if not self.root.accountSelection then
            local previous=self.root.characters[self:CharacterKey() or ""]
            self.root.accountSelection=previous and C.Copy(previous) or {
                activeProfile=self.root.defaultProfile,manualProfile=self.root.defaultProfile,specEnabled=false,specProfiles={}}
            self.root.accountSelection.specEnabled=false
        end
        local selection=self.root.accountSelection
        assert(type(selection)=="table" and type(selection.activeProfile)=="string" and type(selection.specProfiles)=="table", "Invalid account profile selection; retained.")
        return selection
    end
    local key=self:CharacterKey()
    if not key then return end
    local character=self.root.characters[key]
    if not character then
        local name,realm=Public(UnitFullName,"player")
        realm=realm or Public(GetNormalizedRealmName)
        if type(name)=="string" and name~="" and type(realm)=="string" and realm~="" then
            local fallback=name.."-"..realm
            if key~=fallback and self.root.characters[fallback] then
                character=self.root.characters[fallback]
                self.root.characters[key]=character;self.root.characters[fallback]=nil
            end
        end
    end
    if not character then
        local name=self.root.defaultProfile
        character={activeProfile=name,manualProfile=name,specEnabled=false,specProfiles={}};self.root.characters[key]=character
    end
    assert(type(character)=="table" and type(character.specProfiles)=="table" and type(character.activeProfile)=="string","Play The Game Tools: invalid character profile assignment; retained.")
    assert(type(character.specEnabled)=="boolean","Play The Game Tools: invalid specialization preference; retained.")
    character.manualProfile=character.manualProfile or character.activeProfile
    return character
end
function P:List()
    local names={};for name in pairs(self.root.profiles) do names[#names+1]=name end
    table.sort(names);return names
end
function P:RegisterListener(owner,callback) self.listeners[owner]=callback end
function P:Notify(kind)
    if addon.ReloadManager then addon.ReloadManager:SyncProfile() end
    for owner,callback in pairs(self.listeners) do pcall(callback,owner,kind,self.activeName) end
    if addon.RefreshConfig and addon.configWindow then addon:RefreshConfig() end
end
function P:Feedback(text)
    self.status=text
    print("Play The Game Tools: "..text)
    self:Notify("status")
end
local function Backup(root,reason)
    -- Never replace the source on failed migration/validation. Keep one bounded
    -- recoverable snapshot; repeated failures do not nest backups recursively.
    if root.profileRecovery==nil then
        local ok,copy=pcall(C.Copy,root)
        if ok then root.profileRecovery={reason=tostring(reason):sub(-240),backup=copy} end
    end
end
function P:Initialize(root)
    assert(root.schemaVersion==nil or root.schemaVersion==1,"Play The Game Tools: unsupported database version; settings retained.")
    if root.profileVersion==nil then
        local candidate,reason=addon.ProfileValidation:Validate(root)
        if not candidate then Backup(root,reason);error(reason) end
        -- Commit the new root only after the complete detached candidate passes.
        local backup=C.Copy(root)
        root={schemaVersion=1,profileVersion=1,defaultProfile="Default",profiles={Default=candidate},characters={},migrationBackup=backup}
        PTGToolsDB=root
    end
    assert(root.profileVersion==1 and type(root.profiles)=="table" and type(root.characters)=="table","Play The Game Tools: unsupported profile database; retained.")
    self.root=root
    for name in pairs(root.profiles) do assert(self:Name(name)==name,"Play The Game Tools: invalid profile name; retained.") end
    root.defaultProfile=root.defaultProfile or "Default"
    local character=self:Character()
    local requested=character and (character.pendingProfile or character.activeProfile) or root.defaultProfile
    if specProfilesAvailable and character and character.specEnabled and not character.pendingProfile then requested=character.specProfiles[self:Spec()] or character.manualProfile or requested end
    if character and requested==character.failedProfile and not character.pendingProfile then requested=character.activeProfile end
    self.startupDeferred=false
    if character and Combat() and requested~=character.activeProfile then
        self.queued={name=requested,manual=character.pendingManual==true,spec=self:Spec()}
        self.startupDeferred=true;requested=character.activeProfile
        self.status="Profile request deferred until combat ends; reload afterwards to apply."
    end
    local candidate,reason
    if root.profiles[requested] then candidate,reason=addon.ProfileValidation:Validate(root.profiles[requested]) end
    if not candidate then
        self.status="Assigned profile unavailable or invalid; previous profile retained."
        requested=character and character.activeProfile or root.defaultProfile
        if root.profiles[requested] then candidate,reason=addon.ProfileValidation:Validate(root.profiles[requested]) end
        if not candidate then requested=root.defaultProfile;candidate,reason=addon.ProfileValidation:Validate(root.profiles[requested]) end
    end
    if not candidate then Backup(root,reason);error(reason or "Play The Game Tools: no valid profile; settings retained.") end
    root.profiles[requested]=candidate
    addon.db=candidate;self.activeName=requested
    self.startupCharacter=character
end
function P:CommitInitialization()
    local character=self.startupCharacter
    if character then
        if not self.startupDeferred and character.pendingProfile==self.activeName and character.pendingManual then
            character.manualProfile=self.activeName
            if specProfilesAvailable and character.specEnabled and character.pendingSpec then character.specProfiles[character.pendingSpec]=self.activeName end
        end
        character.activeProfile=self.activeName
        if not self.startupDeferred then character.pendingProfile,character.pendingManual,character.pendingSpec=nil,nil,nil end
    end
    self.startupCharacter=nil
end
function P:InitializationFailed(reason)
    local character=self.startupCharacter
    if character then
        character.failedProfile=self.activeName
        character.pendingProfile,character.pendingManual,character.pendingSpec=nil,nil,nil
    end
    -- No claim of native transactional rollback: old selection remains persisted,
    -- and a later reload returns to it instead of retrying a failed spec loop.
    self.startupCharacter=nil
    print("Play The Game Tools: profile initialization failed; previous selection retained. Reload to recover.")
end
function P:Create(name,source)
    name=self:Name(name)
    if not name then return false,"Use 1–48 bytes without control characters or |." end
    if self.root.profiles[name] then return false,"Profile name already exists." end
    source=source or self.activeName
    local candidate,reason=addon.ProfileValidation:Validate(self.root.profiles[source])
    if not candidate then return false,reason end
    self.root.profiles[name]=candidate;self:Notify("created")
    return true,"Profile created. Select it to apply after reload."
end
function P:Duplicate(source,name) return self:Create(name,source) end
function P:Rename(old,name)
    name=self:Name(name)
    if not name then return false,"Invalid profile name (1–48 bytes)." end
    if not self.root.profiles[old] then return false,"Profile not found." end
    if self.root.profiles[name] then return false,"Profile name already exists." end
    for _,character in pairs(self.root.characters) do
        if type(character)~="table" or type(character.specProfiles)~="table" then return false,"Invalid character assignments; rename cancelled." end
    end
    self.root.profiles[name]=self.root.profiles[old];self.root.profiles[old]=nil
    if self.root.accountSelection then
        for _,key in ipairs({"activeProfile","manualProfile","pendingProfile","failedProfile"}) do
            if self.root.accountSelection[key]==old then self.root.accountSelection[key]=name end
        end
    end
    for _,character in pairs(self.root.characters) do
        for _,key in ipairs({"activeProfile","manualProfile","pendingProfile","failedProfile"}) do if character[key]==old then character[key]=name end end
        for spec,assigned in pairs(character.specProfiles) do if assigned==old then character.specProfiles[spec]=name end end
    end
    if self.activeName==old then self.activeName=name end
    if self.root.defaultProfile==old then self.root.defaultProfile=name end
    if self.queued and self.queued.name==old then self.queued.name=name end
    self:Notify("renamed");return true,"Profile renamed."
end
function P:Select(name,manual)
    if not self.root.profiles[name] then return false,"Profile not found; assignment retained." end
    local character=self:Character()
    if not character then return false,"Character identity is not available yet." end
    local candidate,reason=addon.ProfileValidation:Validate(self.root.profiles[name])
    if not candidate then return false,reason end
    if Combat() then
        self.queued={name=name,manual=manual~=false,spec=self:Spec()}
        self:Feedback("Profile request deferred until combat ends.");return true,"deferred"
    end
    character.failedProfile=nil
    character.pendingProfile=name~=self.activeName and name or nil
    character.pendingManual=character.pendingProfile and manual~=false or nil
    character.pendingSpec=character.pendingManual and self:Spec() or nil
    if manual~=false then
        if not character.pendingProfile then
            character.manualProfile=name
            if character.specEnabled then local spec=self:Spec();if spec then character.specProfiles[spec]=name end end
        end
    end
    self:Notify("selection-requested")
    if character.pendingProfile then self:Feedback("Profile ready. Reload to apply all modules together.")
    else self.status="Current profile retained.";self:Notify("status") end
    return true,character.pendingProfile and "reload-required" or "active"
end
function P:SetSpecEnabled(enabled)
    if not specProfilesAvailable then return false,"Specialization profiles are unavailable in the Forever foundation." end
    if type(enabled)~="boolean" then return false,"Invalid toggle." end
    local character=self:Character();if not character then return false,"Character not available." end
    character.specEnabled=enabled
    if not enabled then
        if not character.pendingManual then character.pendingProfile,character.pendingSpec=nil,nil end
        if self.queued and not self.queued.manual then self.queued=nil end
    end
    if enabled then self:OnSpecChanged() end
    self:Notify("spec-assignments");return true,"Specialization preference saved."
end
function P:Assign(spec,name)
    local found=false;for _,entry in ipairs(self:Specs()) do if entry.id==spec then found=true end end
    if not found or (name~=nil and not self.root.profiles[name]) then return false,"Invalid specialization or profile." end
    local character=self:Character();if not character then return false,"Character not available." end
    character.specProfiles[spec]=name;self:Notify("spec-assignments")
    if character.specEnabled and self:Spec()==spec then self:OnSpecChanged() end
    return true,"Specialization assignment saved."
end
function P:OnSpecChanged()
    if not specProfilesAvailable then return end
    local character=self:Character();if not character or not character.specEnabled then return end
    local requested=character.specProfiles[self:Spec()] or character.manualProfile
    if requested==character.failedProfile then self:Feedback("Assigned profile failed startup; previous profile retained. Select manually to retry.");return end
    if requested and self.root.profiles[requested] then
        local ok,reason=self:Select(requested,false);if not ok then self:Feedback(reason) end
    else self:Feedback("Assigned profile missing; current profile retained.") end
end
function P:CancelSelection()
    local character=self:Character();if character then character.pendingProfile,character.pendingManual,character.pendingSpec=nil,nil,nil end
    self.queued=nil;self.status="Profile request cancelled; current profile retained.";self:Notify("cancelled")
end
function P:ValidatePending()
    local character=self:Character()
    if not character or not character.pendingProfile then return false,"Select a profile first." end
    local candidate,reason=addon.ProfileValidation:Validate(self.root.profiles[character.pendingProfile])
    if not candidate then return false,reason end
    return true
end
function P:Reload()
    return addon.ReloadManager:Reload()
end
local runtimeKeys={records=true,history=true,frames=true,events=true,handlers=true,contexts=true,listeners=true,mediaRegistry=true,sharedMediaActivation=true,
    diagnosticHistory=true,characters=true,characterGUID=true,guid=true,profiles=true,migrationBackup=true,profileRecovery=true}
local function SettingsOnly(value,reject)
    for key,item in pairs(value) do
        if runtimeKeys[key] then
            if reject then return false end
            value[key]=nil
        elseif type(item)=="table" and not SettingsOnly(item,reject) then return false end
    end
    return true
end
function P:Export(name)
    local profile,reason=addon.ProfileValidation:Validate(self.root.profiles[name])
    if not profile then return nil,reason end
    -- Export only owned module settings/positions/preferences; never the account
    -- root, assignments, migration backup, arbitrary legacy root keys or logs.
    local owned={schemaVersion=1,modules={},positions=profile.positions or {},developer=profile.developer,window=profile.window,globalMedia=profile.globalMedia,globalOptions=profile.globalOptions}
    for _,id in ipairs(addon.moduleOrder) do owned.modules[id]=profile.modules[id] end
    SettingsOnly(owned,false)
    local ok,text=pcall(C.Encode,{version=1,name=name,profile=owned})
    if ok then return text end;return nil,tostring(text):sub(-240)
end
function P:UniqueImportName(base)
    if not self.root.profiles[base] then return base end
    if #base>40 then base="Imported Profile" end
    if not self.root.profiles[base] then return base end
    local index=2
    while self.root.profiles[base.." ("..index..")"] do index=index+1 end
    return base.." ("..index..")"
end
function P:PrepareImport(text,name)
    local ok,envelope=pcall(C.Decode,text)
    if not ok then return nil,nil,"Invalid or unsupported profile string." end
    if type(envelope)~="table" or envelope.version~=1 or type(envelope.profile)~="table" then return nil,nil,"Unsupported profile schema." end
    if name~=nil and type(name)~="string" then return nil,nil,"Enter a valid imported profile name." end
    local explicit=name and name:match("^%s*(.-)%s*$")~=""
    if explicit then
        name=self:Name(name)
        if not name then return nil,nil,"Enter a valid profile name (1–48 bytes without control characters)." end
        if self.root.profiles[name] then return nil,nil,"Name already exists; choose another name. Nothing overwritten." end
    else name=self:UniqueImportName(self:Name(envelope.name) or "Imported Profile") end
    local allowed={schemaVersion=true,modules=true,positions=true,developer=true,window=true,globalMedia=true,globalOptions=true}
    for key in pairs(envelope.profile) do if not allowed[key] then return nil,nil,"Unexpected account or runtime data." end end
    if not SettingsOnly(envelope.profile,true) then return nil,nil,"Unexpected account, identity or runtime history data." end
    if envelope.profile.modules~=nil and type(envelope.profile.modules)~="table" then return nil,nil,"Invalid modules table." end
    for id in pairs(envelope.profile.modules or {}) do if not addon.modules[id] then return nil,nil,"Unknown module in profile." end end
    local candidate,reason=addon.ProfileValidation:Validate(envelope.profile)
    if not candidate then return nil,nil,reason end
    return candidate,name
end
function P:Import(text,name)
    local candidate,resolved,reason=self:PrepareImport(text,name)
    if not candidate then return false,reason end
    name=resolved
    self.root.profiles[name]=candidate;self:Notify("imported")
    return true,"Imported "..name..". Select it to apply after reload.",name
end
function P:Start()
    if self.events then return end
    self.events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_LOGIN","PLAYER_SPECIALIZATION_CHANGED","PLAYER_REGEN_ENABLED"}) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent",function(_,event,unit)
        if event=="PLAYER_SPECIALIZATION_CHANGED" and unit~="player" then return end
        if event=="PLAYER_REGEN_ENABLED" then
            if Combat() then return end
            local request=self.queued;self.queued=nil
            if request then
                if request.manual or request.spec==self:Spec() then self:Select(request.name,request.manual) else self:OnSpecChanged() end
            end
        else
            local character=self:Character()
            if character and not character.pendingProfile and character.activeProfile~=self.activeName then self:Select(character.activeProfile,false) end
            self:OnSpecChanged()
        end
    end)
    self:Notify("applied")
end
