local _,addon=...
local M,D=addon.CharacterReskin,addon.ForeverRogueData
if not M then return end

-- Snapshot only the geometry we deliberately change. Native scripts, checked
-- states, hit rectangles, equipment actions and model behavior stay untouched.
function M:RememberGeometry(region)
    if not region or self.savedGeometry[region] then return end
    local state={width=region:GetWidth(),height=region:GetHeight(),points={}}
    for i=1,region:GetNumPoints() do state.points[i]={region:GetPoint(i)} end
    if region.GetJustifyH then state.h=region:GetJustifyH();state.v=region:GetJustifyV() end
    self.savedGeometry[region]=state
end
function M:RestoreChrome()
    for region,state in pairs(self.savedGeometry) do
        region:ClearAllPoints();region:SetSize(state.width,state.height)
        for _,point in ipairs(state.points) do region:SetPoint(unpack(point)) end
        if state.h then region:SetJustifyH(state.h);region:SetJustifyV(state.v) end
    end
    self.savedGeometry={}
    for _,frame in pairs(self.decorations) do frame:Hide() end
end
function M:Edge(key,owner,target,color,size)
    local frame=self.decorations[key]
    if not frame then
        frame=CreateFrame("Frame",nil,owner);frame:EnableMouse(false)
        frame.edges={};for i=1,4 do frame.edges[i]=frame:CreateTexture(nil,"OVERLAY") end
        self.decorations[key]=frame
    end
    frame:SetFrameLevel(owner:GetFrameLevel()+2)
    frame:ClearAllPoints();frame:SetAllPoints(target)
    for i,edge in ipairs(frame.edges) do
        edge:ClearAllPoints()
        if i<=2 then
            local side=i==1 and "TOP" or "BOTTOM";local y=i==1 and size or -size
            edge:SetPoint(side.."LEFT",frame,side.."LEFT",-size,y)
            edge:SetPoint(side.."RIGHT",frame,side.."RIGHT",size,y);edge:SetHeight(size)
        else
            local side=i==3 and "LEFT" or "RIGHT";local x=i==3 and -size or size
            edge:SetPoint("TOP"..side,frame,"TOP"..side,x,0)
            edge:SetPoint("BOTTOM"..side,frame,"BOTTOM"..side,x,0);edge:SetWidth(size)
        end
        edge:SetColorTexture(color[1],color[2],color[3],color[4] or 1)
    end
    frame:Show();return frame
end
function M:StyleItem(slot,id)
    local icon=slot.Icon or slot.icon or _G["Character"..(id==0 and "Ammo" or "").."SlotIconTexture"]
    if not icon and slot.GetName then icon=_G[(slot:GetName() or "").."IconTexture"] end
    icon=icon or slot
    self:HideArt(slot.IconBorder)
    local quality=D.Call(GetInventoryItemQuality,"player",id)
    local color={.44,.44,.44,1}
    if D.Number(quality,0,8) and quality>1 then
        local native=D.Call(function() local r,g,b=GetItemQualityColor(quality);return {r,g,b} end)
        if native and D.Number(native[1],0,1) and D.Number(native[2],0,1) and D.Number(native[3],0,1) then color=native end
    end
    self.itemBorders[id]=self:Edge(slot,slot,icon,color,self.db.itemBorderSize)
end
function M:SkinButton(button,glyph,iconSize)
    if not button then return end
    local icon=button.Icon
    for _,region in ipairs({button:GetRegions()}) do
        if region:IsObjectType("Texture") and (region~=icon or glyph) then self:HideArt(region) end
    end
    for _,method in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetCheckedTexture","GetDisabledTexture"}) do
        self:HideArt(D.Call(button[method],button))
    end
    if icon and not glyph and iconSize then
        self:RememberGeometry(icon);icon:ClearAllPoints();icon:SetPoint("CENTER",button,"CENTER",0,0);icon:SetSize(iconSize,iconSize)
    end
    self:Surface(button,true)
    local surface=self.surfaces[button]
    -- Native model controls deliberately overlap their 32-unit hit rectangles.
    -- Insetting just the custom artwork keeps their original layout functional.
    surface:ClearAllPoints();surface:SetPoint("TOPLEFT",button,"TOPLEFT",3,-3);surface:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-3,3)
    local state=self.buttonSkins[button]
    if not state then
        state={};self.buttonSkins[button]=state
        state.face=CreateFrame("Frame",nil,button);state.face:SetAllPoints(button)
        state.face:SetFrameLevel(button:GetFrameLevel()+2);state.face:EnableMouse(false)
        state.label=state.face:CreateFontString(nil,"OVERLAY");state.label:SetAllPoints();state.label:SetJustifyH("CENTER");state.label:SetJustifyV("MIDDLE")
        self.decorations[state]=state.face
        local function Render()
            if not self.active or not D.OutsideCombat() or not _G.CharacterFrame or not CharacterFrame:IsShown() then return end
            local selected=D.Call(button.GetChecked,button)==true
            local color=(selected or state.hovered) and self.db.accentColor or self.db.frameColor
            surface:SetBackdropBorderColor(color[1],color[2],color[3],selected and .8 or self.db.frameOpacity/100)
            surface.fill:SetVertexColor(state.pressed and .10 or 35/255,state.pressed and .10 or 35/255,state.pressed and .10 or 35/255,1)
            surface.line:SetColorTexture(color[1],color[2],color[3],.6);surface.line:SetShown(selected)
        end
        state.render=Render
        for _,script in ipairs({"OnEnter","OnLeave","OnMouseDown","OnMouseUp","OnEnable","OnDisable"}) do
            local event=script
            button:HookScript(event,function()
                if event=="OnEnter" then state.hovered=true elseif event=="OnLeave" then state.hovered=false;state.pressed=false
                elseif event=="OnMouseDown" then state.pressed=true elseif event=="OnMouseUp" then state.pressed=false end
                Render()
            end)
        end
        button:HookScript("OnClick",function() if self.active and D.OutsideCombat() then self:Refresh() end end)
    end
    self:Font(state.label,self.db.textColor,14);state.label:SetText(glyph or "");state.face:Show();state.render()
end
function M:StyleChrome(root,paper,model)
    local portrait=root.PortraitContainer and root.PortraitContainer.portrait
    if portrait then
        local source=D.Call(portrait.GetTexture,portrait)
        if source then
            local view=self.portraitView
            if not view then
                view=CreateFrame("Frame",nil,root.PortraitContainer);view:EnableMouse(false)
                view.rim=view:CreateTexture(nil,"BACKGROUND");view.rim:SetAllPoints()
                view.icon=view:CreateTexture(nil,"ARTWORK");view.icon:SetPoint("CENTER",view,"CENTER",0,0)
                view.mask=view:CreateMaskTexture();view.mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
                view.mask:SetPoint("TOPLEFT",view,"TOPLEFT",1,-1);view.mask:SetPoint("BOTTOMRIGHT",view,"BOTTOMRIGHT",-1,1)
                view.icon:AddMaskTexture(view.mask)
                self.portraitView=view;self.decorations[view]=view
            end
            local size=self.db.portraitSize
            view:ClearAllPoints();view:SetPoint("TOPLEFT",root,"TOPLEFT",10,-5);view:SetSize(size,size);view.icon:SetSize(size,size)
            addon.Media:ApplyTexture(view.rim,"ModeThumb")
            view.rim:SetVertexColor(self.db.frameColor[1],self.db.frameColor[2],self.db.frameColor[3],self.db.frameOpacity/100)
            view.icon:SetTexture(source)
            if portrait.GetTexCoord then view.icon:SetTexCoord(portrait:GetTexCoord()) end
            self:HideArt(portrait);view:Show()
        end
    end
    local container=root.TitleContainer
    local name=container and container.TitleText
    if container and name then
        local view=self.headerTitle
        if not view then
            view=CreateFrame("Frame",nil,container);view:EnableMouse(false);view:SetFrameLevel(container:GetFrameLevel()+1)
            view.text=view:CreateFontString(nil,"OVERLAY");view.text:SetAllPoints();view.text:SetJustifyH("CENTER");view.text:SetJustifyV("MIDDLE")
            self.headerTitle=view;self.decorations[view]=view
        end
        -- Share the level/class heading's model-pane center, including when
        -- the stats pane is expanded. The native left host starts at y=-20.
        local host=root.LeftPaneHost or root
        local y=root.LeftPaneHost and 15 or -5
        view:ClearAllPoints();view:SetPoint("TOPLEFT",host,"TOPLEFT",48,y);view:SetPoint("TOPRIGHT",host,"TOPRIGHT",-48,y);view:SetHeight(28)
        self:Font(view.text,self.db.textColor,self.db.titleSize)
        local title=D.Call(name.GetText,name);view.text:SetText(type(title)=="string" and title or "")
        self:HideArt(name);view:Show()
    end
    if root.CloseButton then
        self:RememberGeometry(root.CloseButton);root.CloseButton:ClearAllPoints();root.CloseButton:SetSize(26,26)
        root.CloseButton:SetPoint("TOPRIGHT",root,"TOPRIGHT",-6,-6);self:SkinButton(root.CloseButton,"X")
    end
    self:SkinButton(root.RightPaneToggleButton,D.Call(root.IsRightPaneCollapsed,root)==true and ">" or "<")
    for i=1,4 do self:SkinButton(_G["PaperDollSidebarTab"..i],nil,28) end
    local controls=model and model.ControlFrame
    if controls then
        for _,entry in ipairs({{"zoomInButton","+"},{"zoomOutButton","-"},{"rotateLeftButton","<"},{"rotateRightButton",">"},{"resetButton","R"}}) do
            self:SkinButton(controls[entry[1]],entry[2])
        end
    end
    local ammo=_G.CharacterAmmoSlot
    if ammo then
        local icon=_G.CharacterAmmoSlotIconTexture or ammo.Icon or ammo.icon
        for _,region in ipairs({ammo:GetRegions()}) do if region:IsObjectType("Texture") and region~=icon and region~=ammo.IconBorder then self:HideArt(region) end end
        for _,method in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture"}) do self:HideArt(D.Call(ammo[method],ammo)) end
        for _,child in ipairs({ammo:GetChildren()}) do
            for _,region in ipairs({child:GetRegions()}) do
                if D.Call(region.GetAtlas,region)=="UI-Character-Info-GearSlot-Arrow" then self:HideArt(region) end
            end
        end
        self:StyleItem(ammo,0)
    end
end
function M:HidePaneDivider(root)
    local host=root.RightPaneHost
    if host then for _,child in ipairs({host:GetChildren()}) do for _,region in ipairs({child:GetRegions()}) do
        if D.Call(region.GetAtlas,region)=="common-framedivider" then self:HideArt(region) end
    end end end
end
function M:StyleScrollBar(bar)
    if not bar or not bar.Track or not bar.Track.Thumb then return end
    self.scrollViews=self.scrollViews or {}
    local view=self.scrollViews[bar]
    if not view then
        local function Face(parent)
            local frame=CreateFrame("Frame",nil,parent);frame:SetAllPoints(parent);frame:SetFrameLevel(parent:GetFrameLevel()+2);frame:EnableMouse(false)
            self.decorations[frame]=frame;return frame
        end
        view={track=Face(bar.Track),thumb=Face(bar.Track.Thumb),arrows={}}
        view.track.line=view.track:CreateTexture(nil,"OVERLAY")
        view.track.line:SetPoint("TOP",view.track,"TOP",0,0);view.track.line:SetPoint("BOTTOM",view.track,"BOTTOM",0,0);view.track.line:SetWidth(1)
        view.track.line:SetColorTexture(66/255,66/255,66/255,.35)
        view.thumb.line=view.thumb:CreateTexture(nil,"OVERLAY")
        addon.Media:ApplyTexture(view.thumb.line,"ModeScrollThumb")
        view.thumb.line:SetPoint("TOP",view.thumb,"TOP",0,0);view.thumb.line:SetPoint("BOTTOM",view.thumb,"BOTTOM",0,0);view.thumb.line:SetWidth(2)
        local palette=addon.InterfaceThemes.mode.palette
        local function Tint(color) view.thumb.line:SetVertexColor(unpack(color)) end
        Tint(palette.lineStrong)
        bar.Track.Thumb:HookScript("OnEnter",function() if self.active and D.OutsideCombat() then Tint(palette.muted) end end)
        bar.Track.Thumb:HookScript("OnLeave",function() if self.active and D.OutsideCombat() then Tint(palette.lineStrong) end end)
        for _,entry in ipairs({{bar.Back,"^"},{bar.Forward,"v"}}) do
            local button,glyph=entry[1],entry[2]
            if button then
                local face=Face(button);face.text=face:CreateFontString(nil,"OVERLAY");face.text:SetAllPoints()
                face.text:SetJustifyH("CENTER");face.text:SetJustifyV("MIDDLE");self:Font(face.text,palette.muted,10);face.text:SetText(glyph)
                view.arrows[#view.arrows+1]=face
            end
        end
        self.scrollViews[bar]=view
    end
    self:HideTextures(bar.Track);self:HideTextures(bar.Track.Thumb)
    if bar.Back then self:HideTextures(bar.Back) end
    if bar.Forward then self:HideTextures(bar.Forward) end
    view.track:Show();view.thumb:Show();for _,face in ipairs(view.arrows) do face:Show() end
end
