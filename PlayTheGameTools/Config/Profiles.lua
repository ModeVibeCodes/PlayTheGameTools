local _,addon=...
local W,T,P,R=addon.ConfigWidgets,addon.InterfaceTheme,addon.ProfileManager,addon.ReloadManager
local function Combat() return InCombatLockdown() or UnitAffectingCombat("player") end
local DANGER={1,0.54,0.54,1}

-- Muted line under a row's label. The row grows to fit the wrapped text.
function addon:AddSettingsHint(controls,text,minimum)
    local row=controls.row
    local hint=W.Label(row,text,"GameFontHighlightSmall",0,-36,172,T.muted)
    hint:SetWordWrap(true)
    local previous=row.layoutChildren
    function row:layoutChildren(width)
        if previous then previous(self,width) end
        local height=hint:GetStringHeight()
        if (issecretvalue and issecretvalue(height)) or type(height)~="number" or height~=height or height<0 or height==math.huge then height=28 end
        self:SetHeight(math.max(minimum or 52,self:GetHeight(),44+height))
    end
    row.settingsHint=hint
    return hint
end

local function Input(parent,width,placeholder)
    local box=CreateFrame('EditBox',nil,parent);box:SetSize(width,28);box:SetPoint('LEFT')
    box:SetAutoFocus(false);box:SetMaxLetters(200);box:SetFontObject(GameFontHighlight);box:SetTextInsets(6,6,0,0);box:SetText('')
    addon.Media:BindInterfaceFont(box,GameFontHighlight);W.Texture(box,'InputField')
    local hint=W.Label(box,placeholder or 'Enter profile name',nil,6,0,width-12,T.muted)
    hint:ClearAllPoints();hint:SetPoint('LEFT',6,0)
    box:HookScript('OnTextChanged',function() hint:SetShown(box:GetText()=='') end)
    box:SetScript('OnEscapePressed',function() box:ClearFocus() end)
    box.placeholder=hint
    return box
end

-- What each Manage action shows. "target" actions choose which profile they
-- act on; the others create a new one.
local ACTIONS={
    new={title='New profile',confirm='Create',name='Name for the new profile'},
    duplicate={title='Duplicate profile',confirm='Duplicate',target=true,name='Name for the copy'},
    rename={title='Rename profile',confirm='Rename',target=true,name='New name'},
    import={title='Import profile',confirm='Import As New',name='Name (optional)',text=true},
    export={title='Export profile',target=true,text=true},
    delete={title='Delete profile',confirm='Delete',target=true,danger=true},
}
addon.ProfileActions={'new','duplicate','rename','import','export','delete'}

-- One small dialog for every Manage action, over the settings page.
local function Dialog(page,hub)
    local dialog=hub.dialog
    if dialog then return dialog end
    dialog=CreateFrame('Frame',nil,page);dialog:Hide();hub.dialog=dialog
    dialog:SetSize(460,190);dialog:SetPoint('CENTER');dialog:SetFrameStrata('DIALOG')
    dialog:SetFrameLevel(page:GetFrameLevel()+100);dialog:EnableMouse(true);dialog:SetClampedToScreen(true)
    W.Texture(dialog,'Window');W.Texture(dialog,'BorderSilver','BORDER')
    local title=W.Heading(dialog,'',T.fontSize.section,16,-14,428)
    local message=W.Label(dialog,'',nil,16,-44,428,T.muted);message:SetWordWrap(true)
    local targetLabel=W.Label(dialog,'Profile',nil,16,0,90,T.text)
    local target,name,kind
    local targetSelect=W.Select(dialog,260,function()
        local items={};for _,profile in ipairs(P:List()) do items[#items+1]={id=profile,label=profile} end;return items
    end,function() return target,target end,function(chosen)
        target=chosen
        if kind=='rename' then name:SetText(chosen) end
        dialog:Update()
    end)
    name=Input(dialog,260,'')
    local nameLabel=W.Label(dialog,'Name',nil,16,0,90,T.text)
    local scroll=CreateFrame('ScrollFrame',nil,dialog);scroll:EnableMouseWheel(true)
    local edit=CreateFrame('EditBox',nil,scroll);edit:SetSize(400,110);edit:SetMultiLine(true);edit:SetAutoFocus(false)
    edit:SetMaxLetters(addon.ProfileCodec.limit);edit:SetFontObject(GameFontHighlight);addon.Media:BindInterfaceFont(edit,GameFontHighlight)
    W.Texture(edit,'InputField');scroll:SetScrollChild(edit)
    local resizing=false
    local function Resize()
        if resizing then return end
        resizing=true
        local width=math.max(200,scroll:GetWidth()-8)
        if edit:GetWidth()~=width then edit:SetWidth(width) end
        -- EditBox has no GetStringHeight (that belongs to FontString). Its
        -- native line count includes wrapping at the width applied above.
        local _,fontHeight=edit:GetFont()
        local lines=edit:GetNumLines()
        local height=math.max(110,lines*fontHeight+math.max(0,lines-1)*edit:GetSpacing()+12)
        if edit:GetHeight()~=height then edit:SetHeight(height) end
        local maximum=math.max(0,height-scroll:GetHeight())
        if scroll:GetVerticalScroll()>maximum then scroll:SetVerticalScroll(maximum) end
        resizing=false
    end
    edit:SetScript('OnTextChanged',Resize);scroll:SetScript('OnSizeChanged',Resize);scroll:SetScript('OnShow',Resize)
    edit:SetScript('OnEscapePressed',function() edit:ClearFocus() end)
    scroll:SetScript('OnMouseWheel',function(_,delta)
        scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,edit:GetHeight()-scroll:GetHeight()),scroll:GetVerticalScroll()-delta*36)))
    end)
    local feedback=W.Label(dialog,'',nil,16,0,428,T.muted);feedback:SetWordWrap(true)
    feedback:ClearAllPoints();feedback:SetPoint('BOTTOMLEFT',16,50);feedback:SetWidth(428)
    local confirm=W.Button(dialog,'',130,28,'primary');confirm:SetPoint('BOTTOMLEFT',16,14)
    -- Delete uses a plain button with a red label; red on the accent fill reads poorly.
    local remove=W.Button(dialog,'Delete',130,28);remove:SetPoint('BOTTOMLEFT',16,14);remove:SetLabelColor(DANGER);remove:Hide()
    local cancel=W.Button(dialog,'Cancel',100,28,'secondary');cancel:SetPoint('LEFT',confirm,'RIGHT',8,0)
    local draft,settingText=''
    kind=''
    local cacheText,cacheName,cacheResult,cacheResolved,cacheReason
    local function ValidateImport()
        local text,typed=draft,name:GetText()
        if text~=cacheText or typed~=cacheName then
            cacheText,cacheName=text,typed
            cacheResult,cacheResolved,cacheReason=P:PrepareImport(text,typed)
        end
        local trimmed=typed:match('^%s*(.-)%s*$')
        confirm.label:SetText(trimmed~='' and P:Name(typed) and 'Import' or 'Import As New')
        confirm:SetEnabled(cacheResult~=nil)
        feedback:SetText(text=='' and 'Paste a Play The Game Tools profile string.' or cacheResult and ('Import as '..cacheResolved..'.') or cacheReason)
    end
    edit:HookScript('OnTextChanged',function()
        if not settingText and kind=='import' then
            draft=edit:GetText();R:SetDraft('profile-import',draft:match('^%s*(.-)%s*$')~='');ValidateImport()
        end
    end)
    name:HookScript('OnTextChanged',function() if kind=='import' then ValidateImport() end end)
    -- Places the parts each action uses, top to bottom.
    function dialog:Update()
        local action=ACTIONS[kind]
        title:SetText(action.title)
        local subject=action.target and target or P.activeName
        local text
        if kind=='new' then text='Starts as a copy of '..P.activeName..', the profile in use.'
        elseif kind=='duplicate' then text='Copies every setting of the chosen profile.'
        elseif kind=='rename' then text='Renames the chosen profile everywhere it is used.'
        elseif kind=='import' then text='Paste a profile string. Nothing you have is overwritten.'
        elseif kind=='export' then text='Ctrl+A, then Ctrl+C, copies the string below.'
        else text='Deletes '..(subject or '')..' and all of its settings. This cannot be undone.' end
        message:SetText(text)
        local y=-44-math.max(14,message:GetStringHeight())-14
        targetLabel:SetShown(action.target==true);targetSelect:SetShown(action.target==true)
        if action.target then
            targetLabel:ClearAllPoints();targetLabel:SetPoint('TOPLEFT',16,y-8)
            targetSelect:ClearAllPoints();targetSelect:SetPoint('TOPLEFT',110,y);targetSelect:Refresh()
            y=y-38
        end
        nameLabel:SetShown(action.name~=nil);name:SetShown(action.name~=nil)
        if action.name then
            name.placeholder:SetText(action.name)
            nameLabel:ClearAllPoints();nameLabel:SetPoint('TOPLEFT',16,y-8)
            name:ClearAllPoints();name:SetPoint('TOPLEFT',110,y)
            y=y-38
        end
        scroll:SetShown(action.text==true)
        local height=-y+(action.text and 150 or 0)+70
        dialog:SetHeight(height)
        if action.text then
            scroll:ClearAllPoints();scroll:SetPoint('TOPLEFT',16,y);scroll:SetPoint('BOTTOMRIGHT',-16,74)
            settingText=true
            if kind=='import' then edit:SetText(draft)
            else
                local exported,reason=P:Export(subject)
                edit:SetText(exported or '');feedback:SetText(exported and '' or reason or '')
            end
            settingText=false
        end
        local button=action.danger and remove or confirm
        confirm:SetShown(action.confirm~=nil and not action.danger);remove:SetShown(action.danger==true)
        if action.confirm then button.label:SetText(action.confirm) end
        button:SetEnabled(true)
        cancel.label:SetText(action.confirm and 'Cancel' or 'Close')
        cancel:ClearAllPoints()
        if action.confirm then cancel:SetPoint('LEFT',button,'RIGHT',8,0) else cancel:SetPoint('BOTTOMLEFT',16,14) end
        if kind=='import' then ValidateImport() end
        if kind=='export' then edit:SetFocus();edit:HighlightText() end
    end
    function dialog:Open(nextKind,selected)
        kind=nextKind;target=selected
        if kind=='delete' and (target==P.activeName or target==hub.Shown()) then
            -- Offer a profile that can actually be deleted.
            for _,candidate in ipairs(P:List()) do
                if candidate~=P.activeName and candidate~=hub.Shown() then target=candidate;break end
            end
        end
        feedback:SetText('');name:SetText(kind=='rename' and (target or '') or '')
        cacheText=nil
        self:Show();self:Update()
        if name:IsShown() then name:SetFocus() end
    end
    local function Confirm()
        local ok,reason
        if kind=='new' then ok,reason=P:Create(name:GetText())
        elseif kind=='duplicate' then ok,reason=P:Duplicate(target,name:GetText())
        elseif kind=='rename' then ok,reason=P:Rename(target,name:GetText())
        elseif kind=='import' then
            ok,reason=P:Import(draft,name:GetText())
            if ok then draft='';R:SetDraft('profile-import',false) end
        elseif kind=='delete' then ok,reason=P:Delete(target) end
        if ok then dialog:Hide();hub.Result(reason) else feedback:SetText(reason or 'Profile action failed.') end
    end
    confirm:SetScript('OnClick',Confirm);remove:SetScript('OnClick',Confirm)
    cancel:SetScript('OnClick',function() dialog:Hide() end)
    dialog:SetScript('OnHide',function() edit:ClearFocus();name:ClearFocus() end)
    dialog.title,dialog.message,dialog.feedback,dialog.confirm,dialog.remove,dialog.cancel=title,message,feedback,confirm,remove,cancel
    dialog.target,dialog.nameInput,dialog.editor,dialog.scroll=targetSelect,name,edit,scroll
    function dialog:Kind() return kind end
    function dialog:Target() return target end
    addon.Dialogs:Register(dialog,{group='settings'})
    return dialog
end

-- Active profile chooser and its Manage menu (Settings -> Profile).
function addon:CreateProfileHub(page)
    local controls=page:Row('Active profile',76,{'profile','profiles','new','duplicate','rename','import','export','delete'})
    local panel=controls.row
    page.profileHub=panel
    addon:AddSettingsHint(controls,'Each profile keeps its own copy of every setting.',76)
    local hub,message={},nil
    local function Shown() local c=P:Character();return c and c.pendingProfile or P.activeName end
    hub.Shown=Shown
    local status=W.Label(controls,'',nil,0,-36,420,T.muted);status:SetWordWrap(true)
    -- A waiting switch outranks the last action's result.
    local function StatusText()
        local shown=Shown()
        if shown~=P.activeName then return 'Switches to '..shown..' after a reload. Choose '..P.activeName..' to stay.' end
        return message or ''
    end
    function hub.Result(text) message=text;page:Refresh();page:Layout() end
    local select=W.Select(controls,220,function()
        local items={};for _,name in ipairs(P:List()) do items[#items+1]={id=name,label=name} end;return items
    end,function() local name=Shown();return name,name end,function(name)
        local ok,reason=P:Select(name,true)
        if not ok then hub.Result(reason)
        elseif reason=='deferred' then hub.Result('Profile change waits until combat ends.')
        else hub.Result(nil) end
    end)
    select:ClearAllPoints();select:SetPoint('TOPLEFT',0,0)
    local manage=W.Button(controls,'Manage',100,30);manage:SetPoint('LEFT',select,'RIGHT',8,0)
    local menu=W.Popup(manage,180,10)
    W.Texture(menu,'Window')
    local labels={new='New profile…',duplicate='Duplicate…',rename='Rename…',import='Import…',export='Export…',delete='Delete profile…'}
    local items,y={},-6
    for index,kind in ipairs(addon.ProfileActions) do
        if index==4 or index==6 then
            local line=W.Fill(menu,T.line,'ARTWORK');line:ClearAllPoints()
            line:SetPoint('TOPLEFT',10,y-4);line:SetPoint('TOPRIGHT',-10,y-4);line:SetHeight(1)
            y=y-9
        end
        local item=W.Button(menu,labels[kind],168,26,'tab');item:SetPoint('TOPLEFT',6,y)
        item.label:SetJustifyH('LEFT');item.label:SetWidth(148)
        if kind=='delete' then item:SetLabelColor(DANGER) end
        item:SetScript('OnClick',function() menu:Hide();Dialog(page,hub):Open(kind,Shown()) end)
        items[kind]=item;y=y-28
    end
    menu:SetHeight(-y+6)
    manage:SetScript('OnClick',function()
        if Combat() or not manage:IsEnabled() then return end
        local shown=menu:IsShown();if addon.CloseFontDropdown then addon:CloseFontDropdown() end
        W.PlacePopup(menu,manage);menu:SetShown(not shown)
    end)
    manage:SetScript('OnHide',function() menu:Hide() end)
    addon.fontDropdownMenus=addon.fontDropdownMenus or {};addon.fontDropdownMenus[menu]=true
    local previous=panel.layoutChildren
    function panel:layoutChildren(width)
        status:SetWidth(math.max(120,width-198))
        local height=status:GetStringHeight()
        if (issecretvalue and issecretvalue(height)) or type(height)~="number" or height~=height or height<0 or height==math.huge then height=14 end
        self:SetHeight(math.max(76,status:GetText()~='' and 56+height or 0))
        if previous then previous(self,width) end
    end
    page.refreshers[#page.refreshers+1]=function() select:Refresh();status:SetText(StatusText()) end
    P:RegisterListener(panel,function() page:Refresh() end)
    panel.select,panel.manage,panel.menu,panel.menuItems,panel.status=select,manage,menu,items,status
    function panel:Dialog() return Dialog(page,hub) end
end
