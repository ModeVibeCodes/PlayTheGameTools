local _,addon=...
local W,T,P,R=addon.ConfigWidgets,addon.InterfaceTheme,addon.ProfileManager,addon.ReloadManager
function addon:CreateProfileHub(page)
    local controls=page:Row('',92)
    local panel=controls.row;controls.rowLabel:Hide();controls:Hide()
    page.profileHub=panel
    local current=W.Label(panel,'',nil,12,-6,600,T.primary)
    local selected,renameTarget=P.activeName,P.activeName
    local draft,mode='',nil
    local function Options(empty)
        local items={};if empty then items[1]={id='',label='Use manual profile'} end
        for _,name in ipairs(P:List()) do items[#items+1]={id=name,label=name} end
        return items
    end
    local function Input(parent,width,placeholder)
        local box=CreateFrame('EditBox',nil,parent);box:SetSize(width,28);box:SetPoint('LEFT')
        box:SetAutoFocus(false);box:SetMaxLetters(200);box:SetFontObject(GameFontHighlight);box:SetTextInsets(6,6,0,0);box:SetText('')
        addon.Media:BindInterfaceFont(box,GameFontHighlight);W.Texture(box,'InputField')
        local hint=W.Label(box,placeholder or 'Enter profile name',nil,6,0,width-12,T.muted)
        hint:ClearAllPoints();hint:SetPoint('LEFT',6,0)
        box:HookScript('OnTextChanged',function() hint:SetShown(box:GetText()=='') end)
        box:SetScript('OnEscapePressed',function() box:ClearFocus() end)
        return box
    end
    local status=W.Label(panel,P.status or 'Profile selection requires reload. Create, duplicate and rename save immediately.',nil,12,-56,600,T.muted)
    status:SetWordWrap(true)
    local function Result(ok,reason) status:SetText(reason or (ok and 'Saved.' or 'Profile action failed.'));page:Refresh();page:Layout() end
    local select=W.Select(panel,260,function() return Options() end,function() return selected,selected end,function(name)
        local ok,reason=P:Select(name,true);if ok then selected=name end
        Result(ok,reason=='reload-required' and 'Profile pending. Use Reload in the header, or choose Later when closing.' or reason)
    end)
    select:ClearAllPoints();select:SetPoint('TOPLEFT',12,-24)
    local cancel=W.Button(panel,'Cancel Selection',132,28,'secondary');cancel:SetPoint('LEFT',select,'RIGHT',8,0)
    cancel:SetScript('OnClick',function() P:CancelSelection();selected=P.activeName;Result(true,P.status) end)
    local function Action(title,label,callback)
        local row=page:Row(title,44)
        local input=Input(row,220)
        local button=W.Button(row,label,100,28);button:SetPoint('LEFT',input,'RIGHT',8,0)
        button:SetScript('OnClick',function() Result(callback(input:GetText())) end)
        return input,button
    end
    local createInput,create=Action('Create New Profile','Create',function(name) return P:Create(name) end)
    local duplicateInput,duplicate=Action('Duplicate Profile','Duplicate',function(name) return P:Duplicate(selected,name) end)
    local renameRow=page:Row('Rename Profile',78)
    local renameSelect=W.Select(renameRow,220,function() return Options() end,function() return renameTarget,renameTarget end,function(name) renameTarget=name end)
    renameSelect:ClearAllPoints();renameSelect:SetPoint('TOPLEFT',0,0)
    local renameInput=Input(renameRow,220,'New name');renameInput:ClearAllPoints();renameInput:SetPoint('TOPLEFT',0,-34)
    local rename=W.Button(renameRow,'Rename',100,28);rename:SetPoint('LEFT',renameInput,'RIGHT',8,0)
    rename:SetScript('OnClick',function()
        local old=renameTarget;local name=P:Name(renameInput:GetText());local ok,reason=P:Rename(old,name)
        if ok then renameTarget=name;if selected==old then selected=name end end
        Result(ok,reason)
    end)
    local modeRow=page:Row('Import / Export',42)
    local import=W.Button(modeRow,'Import',88,28,'choice');import:SetPoint('LEFT')
    local export=W.Button(modeRow,'Export',88,28,'choice');export:SetPoint('LEFT',import,'RIGHT',8,0)
    import:SetSelected(false);export:SetSelected(false)
    local editControls=page:Row('Profile String',280)
    local editorRow=editControls.row
    editorRow.visibleWhen=function() return page.profileEditorOpen==true end
    editControls.rowLabel:Hide();editControls:Hide()
    local heading=W.Label(editorRow,'',nil,12,-6,300,T.secondary)
    local nameLabel=W.Label(editorRow,'Profile Name (Optional)',nil,12,-34,174)
    local importName=Input(editorRow,260,'Enter profile name');importName:ClearAllPoints();importName:SetPoint('TOPLEFT',190,-26)
    local scroll=CreateFrame('ScrollFrame',nil,editorRow);scroll:SetPoint('TOPLEFT',12,-66);scroll:SetPoint('BOTTOMRIGHT',-12,88)
    scroll:EnableMouseWheel(true)
    local edit=CreateFrame('EditBox',nil,scroll);edit:SetSize(500,110);edit:SetMultiLine(true);edit:SetAutoFocus(false)
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
    edit:SetScript("OnTextChanged",Resize);scroll:SetScript("OnSizeChanged",Resize)
    scroll:SetScript("OnShow",Resize)
    edit:SetScript("OnEscapePressed",function() edit:ClearFocus() end)
    scroll:SetScript("OnMouseWheel",function(_,delta)
        scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,edit:GetHeight()-scroll:GetHeight()),scroll:GetVerticalScroll()-delta*36)))
    end)
    local apply=W.Button(editorRow,'Import As New',130,28);apply:SetPoint('BOTTOMLEFT',12,10)
    local clear=W.Button(editorRow,'Clear',80,28,'secondary');clear:SetPoint('LEFT',apply,'RIGHT',8,0)
    local close=W.Button(editorRow,'Close',80,28,'secondary');close:SetPoint('LEFT',clear,'RIGHT',8,0)
    local feedback=W.Label(editorRow,'',nil,12,-196,600,T.muted);feedback:SetWordWrap(true);feedback:SetHeight(36)
    local cacheText,cacheName,cacheResult,cacheResolved,cacheReason
    local function ValidateImport()
        local text,name=draft,importName:GetText()
        if text~=cacheText or name~=cacheName then
            cacheText,cacheName=text,name
            cacheResult,cacheResolved,cacheReason=P:PrepareImport(text,name)
        end
        local trimmed=name:match('^%s*(.-)%s*$')
        apply.label:SetText(trimmed~='' and P:Name(name) and 'Import' or 'Import As New')
        apply:SetEnabled(mode=='import' and cacheResult~=nil)
        if mode=='import' then feedback:SetText(text=='' and 'Paste a Play The Game Tools profile string.' or cacheResult and ('Import as '..cacheResolved..'.') or cacheReason) end
    end
    local settingText=false
    edit:HookScript('OnTextChanged',function()
        if not settingText and mode=='import' then
            draft=edit:GetText();R:SetDraft('profile-import',draft:match('^%s*(.-)%s*$')~='');ValidateImport()
        end
    end)
    importName:HookScript('OnTextChanged',ValidateImport)
    local function SetMode(nextMode)
        if mode=='import' then draft=edit:GetText() end
        mode=nextMode;page.profileEditorOpen=true
        import:SetSelected(mode=='import');export:SetSelected(mode=='export')
        heading:SetText(mode=='import' and 'Import Profile' or 'Export Profile')
        nameLabel:SetShown(mode=='import');importName:SetShown(mode=='import');apply:SetShown(mode=='import');clear:SetShown(mode=='import')
        scroll:ClearAllPoints();scroll:SetPoint('TOPLEFT',12,mode=='import' and -66 or -30);scroll:SetPoint('BOTTOMRIGHT',-12,88)
        settingText=true
        if mode=='import' then edit:SetText(draft)
        else
            local text,reason=P:Export(selected)
            edit:SetText(text or '');feedback:SetText(text and 'Ctrl+A, Ctrl+C to copy this profile.' or reason)
        end
        settingText=false
        ValidateImport();page:Layout();edit:SetFocus()
        if mode=='export' then edit:HighlightText() end
    end
    import:SetScript('OnClick',function() SetMode('import') end)
    export:SetScript('OnClick',function() SetMode('export') end)
    clear:SetScript('OnClick',function()
        if mode~='import' then return end
        draft='';edit:SetText('');R:SetDraft('profile-import',false);ValidateImport()
    end)
    apply:SetScript('OnClick',function()
        if mode~='import' then return end
        local ok,reason=P:Import(draft,importName:GetText())
        if ok then draft='';edit:SetText('');R:SetDraft('profile-import',false);cacheText=nil end
        Result(ok,reason);ValidateImport()
    end)
    close:SetScript('OnClick',function()
        page.profileEditorOpen=false;import:SetSelected(false);export:SetSelected(false)
        edit:ClearFocus();importName:ClearFocus();page:Layout()
    end)
    local specControl=page:Row('Specialization Profiles',42)
    local specToggle=W.Button(specControl,'Enable Spec Profiles',190,28,'choice');specToggle:SetPoint('LEFT')
    specToggle:SetScript('OnClick',function() local c=P:Character();if c then Result(P:SetSpecEnabled(not c.specEnabled)) end end)
    specControl.row.visibleWhen=function() return not addon.Edition or addon.Edition.name~="Forever" end
    local specRows={}
    local help=page:Row('',52)
    help.row.visibleWhen=function() local c=P:Character();return c and c.specEnabled end
    help.rowLabel:Hide();help:ClearAllPoints();help:SetPoint('TOPLEFT',12,-4);help:SetPoint('BOTTOMRIGHT',-12,4)
    local text=W.Label(help,'Manual selection assigns the current spec. Unassigned specs use your manual profile. Apply a pending selection with Reload.',nil,0,0,600,T.muted);text:SetWordWrap(true)
    local function BuildSpecs()
        for _,spec in ipairs(P:Specs()) do
            if not specRows[spec.id] then
                local row=page:Row(spec.label,42);row.row.section=nil
                table.remove(page.rows)
                local insertion=1
                for i,item in ipairs(page.rows) do if item==help.row then insertion=i+1;break end end
                for _ in pairs(specRows) do insertion=insertion+1 end
                table.insert(page.rows,insertion,row.row)
                row.row.visibleWhen=help.row.visibleWhen
                local button=W.Select(row,260,function() return Options(true) end,function()
                    local c=P:Character();local value=c and c.specProfiles[spec.id] or '';return value,value~='' and value or 'Use manual profile'
                end,function(name) Result(P:Assign(spec.id,name~='' and name or nil)) end)
                specRows[spec.id]={row=row.row,button=button}
            end
        end
    end
    BuildSpecs()
    function panel:layoutChildren(width) current:SetWidth(width-24);status:SetWidth(width-24) end
    function editorRow:layoutChildren(width) feedback:SetWidth(width-24) end
    page.refreshers[#page.refreshers+1]=function()
        BuildSpecs()
        if not P.root.profiles[selected] then selected=P.activeName end
        if not P.root.profiles[renameTarget] then renameTarget=P.activeName end
        local c=P:Character();local pending=c and c.pendingProfile
        current:SetText('Current Profile: '..P.activeName..(pending and '  |  Pending: '..pending or ''))
        select:Refresh();renameSelect:Refresh();specToggle:SetSelected(c and c.specEnabled or false)
        cancel:SetEnabled(pending~=nil or P.queued~=nil);specToggle:SetEnabled(c~=nil)
        -- A renamed/imported profile can change conflict/default-name resolution.
        cacheText=nil;ValidateImport()
        for _,entry in pairs(specRows) do entry.button:Refresh() end
    end
    P:RegisterListener(panel,function() if P.status then status:SetText(P.status) end end)
    panel.current,panel.select,panel.nameInput=current,select,createInput
    panel.create,panel.duplicate,panel.rename=create,duplicate,rename
    panel.duplicateInput,panel.renameInput,panel.renameSelect=duplicateInput,renameInput,renameSelect
    panel.import,panel.export,panel.editor,panel.importApply=import,export,edit,apply
    panel.importNameInput,panel.clearImport,panel.closeEditor=importName,clear,close
    panel.cancel,panel.specToggle,panel.specRows=cancel,specToggle,specRows
    page.searchEntries[#page.searchEntries+1]={label='Profiles',keywords={'import','export','specialization'},row=panel,kind='setting'}
end
