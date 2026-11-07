local _,addon=...
local G={styles={border={label="Subtle Border",size=true},pulse={label="Animated Pulse",size=true,speed=true},
    pixel={label="Pixel Glow",size=true,speed=true},shape={label="Shape Glow",size=true,speed=true},
    gcd={label="GCD Glow",speed=true},autocast={label="Autocast Glow",size=true,speed=true},button={label="Button Glow",speed=true}}}
addon.Glow=G
-- Shared rendering contracts. Defaults migrate legacy thickness/period once.
local definitions={
    thickness={label="Thickness",minimum=1,maximum=12,step=1,default=3,legacy="size"},
    period={label="Animation Period (s)",minimum=0.4,maximum=5,step=0.1,default=1.8,legacy="speed"},
    count={label="Number of Lines",minimum=4,maximum=64,step=1,default=12,integer=true},
    length={label="Line Length (0 = Auto)",minimum=0,maximum=64,step=1,default=0},
    expansion={label="Expansion",minimum=0,maximum=24,step=1,default=0},
    particles={label="Particles Per Edge",minimum=1,maximum=16,step=1,default=4,integer=true},
    scale={label="Particle Scale",minimum=0.25,maximum=4,step=0.05,default=1},
    atlasScale={label="Glow Scale",minimum=1,maximum=2.5,step=0.05,default=1.45},
}
G.parameters={border={"thickness","expansion"},pulse={"thickness","period","expansion"},
    pixel={"count","period","thickness","length","expansion"},shape={"thickness","period","expansion"},
    gcd={"period","atlasScale","expansion"},autocast={"period","particles","scale","expansion"},button={"period","expansion"}}
G.definitions=definitions
local function Valid(parameter,value)
    return not (issecretvalue and issecretvalue(value)) and type(value)=="number" and value==value
        and value>=parameter.minimum and value<=parameter.maximum and (not parameter.integer or value==math.floor(value))
end
function G.Initialize(settings)
    if settings.styles==nil then settings.styles={} end
    assert(type(settings.styles)=="table","Play The Game Tools: invalid glow settings; preferences were not reset.")
    for style,parameters in pairs(G.parameters) do
        if settings.styles[style]==nil then settings.styles[style]={} end
        local values=settings.styles[style]
        assert(type(values)=="table","Play The Game Tools: invalid glow style; preferences were not reset.")
        for _,key in ipairs(parameters) do
            local definition=definitions[key]
            if values[key]==nil then
                values[key]=definition.legacy and settings[definition.legacy] or definition.default
                if style=="autocast" and key=="scale" then values[key]=(settings.size or 3)/3 end
            end
            assert(Valid(definition,values[key]),"Play The Game Tools: invalid glow parameter; preferences were not reset.")
        end
    end
end
function G.SetParameter(settings,style,key,value)
    for _,parameter in ipairs(G.parameters[style] or {}) do
        if parameter==key and Valid(definitions[key],value) then
            G.Initialize(settings);settings.styles[style][key]=value;return true
        end
    end
    return false
end
function G.Values(settings)
    local values={}
    for _,key in ipairs(G.parameters[settings.style] or {}) do
        local definition=definitions[key]
        values[key]=settings.styles and settings.styles[settings.style] and settings.styles[settings.style][key]
            or (definition.legacy and settings[definition.legacy]) or definition.default
    end
    return values
end
-- Symmetric outer allowance for fitted previews; ordinary owners remain unclipped.
function G.Padding(settings,w,h)
    local values=G.Values(settings)
    local dimension=math.max(w,h)+2*(values.expansion or 0)
    local extent=values.thickness or settings.size or 0
    if settings.style=="gcd" then extent=dimension*(values.atlasScale-1)/2
    elseif settings.style=="button" then extent=dimension*0.2
    elseif settings.style=="autocast" then extent=7*values.scale/2 end
    return (values.expansion or 0)+extent
end
local atlas="rotationhelper_ants_flipbook"
local function Library(style)
    if not LibStub then return end
    local ok,lib=pcall(LibStub,"LibCustomGlow-1.0",true)
    local prefix=style=="button" and "ButtonGlow" or "AutoCastGlow"
    if ok and lib and type(lib[prefix.."_Start"])=="function" and type(lib[prefix.."_Stop"])=="function" then return lib end
end
function G.Available(style)
    if style=="autocast" or style=="button" then return Library(style)~=nil end
    if style=="gcd" then
        if not C_Texture or type(C_Texture.GetAtlasInfo)~="function" then return false end
        local ok,info=pcall(C_Texture.GetAtlasInfo,atlas)
        return ok and not (issecretvalue and issecretvalue(info)) and type(info)=="table"
    end
    return G.styles[style]~=nil
end
function G.Options()
    local items={}
    for _,id in ipairs({"border","pulse","pixel","gcd","autocast","button","shape"}) do
        if G.Available(id) then items[#items+1]={id=id,label=G.styles[id].label} end
    end
    return items
end
function G.Supports(style,property) return G.styles[style] and G.styles[style][property]==true end
-- Owned frames only. No protected-frame hooks or mandatory glow dependency.
function G.Create(owner)
    local view={owner=owner,frame=CreateFrame("Frame",nil,owner),groups={}}
    view.frame:SetPoint("CENTER",owner,"CENTER",0,0);view.frame:EnableMouse(false)
    -- Opacity stays on the host; pulse/flipbook animation belongs to its child.
    view.layer=CreateFrame("Frame",nil,view.frame);view.layer:SetPoint("CENTER");view.layer:EnableMouse(false)
    addon.Border.Create(view,view.layer);view.frame:Hide()
    view.frame:SetScript("OnHide",function() G.Stop(view) end)
    return view
end
function G.Stop(view)
    if view.stopping then return end
    view.stopping=true
    -- Hidden library host releases ButtonGlow immediately instead of fading out
    -- over the next style. Never reach into the library's private pooled frames.
    view.frame:Hide()
    for _,group in ipairs(view.groups) do group:Stop() end
    if view.external then
        if view.externalStyle=="button" then pcall(view.external.ButtonGlow_Stop,view.layer)
        else pcall(view.external.AutoCastGlow_Stop,view.layer,"PlayTheGameTools") end
        view.external=nil;view.externalStyle=nil
    end
    if view.pixels then for _,pixel in ipairs(view.pixels) do pixel:Hide() end end
    if view.shapeEdges then for _,edge in ipairs(view.shapeEdges) do edge:Hide() end end
    if view.flip then view.flip:Hide() end
    view.key=nil;view.activeStyle=nil
    view.stopping=false
end
local function Group(view,region)
    local group=region:CreateAnimationGroup();view.groups[#view.groups+1]=group
    group:SetLooping("REPEAT");return group
end
local function Pulse(view,period)
        if not view.animation then
            view.animation=Group(view,view.layer);view.parts={}
            for i=1,2 do local part=view.animation:CreateAnimation("Alpha");part:SetOrder(i);part:SetSmoothing("IN_OUT");view.parts[i]=part end
        end
        view.parts[1]:SetFromAlpha(1);view.parts[1]:SetToAlpha(0.35);view.parts[1]:SetDuration(period/2)
        view.parts[2]:SetFromAlpha(0.35);view.parts[2]:SetToAlpha(1);view.parts[2]:SetDuration(period/2)
        view.animation:SetLooping("REPEAT");view.animation:Play()
end
local function Pixels(view,settings,w,h,values)
    view.pixels=view.pixels or {}
    local count=values.count
    for i=1,count do
        local texture=view.pixels[i]
        if not texture then
            texture=view.layer:CreateTexture(nil,"OVERLAY");texture:SetBlendMode("ADD")
            texture.group=Group(view,texture);texture.parts={}
            for j=1,4 do local part=texture.group:CreateAnimation("Alpha");part:SetOrder(j);texture.parts[j]=part end
            view.pixels[i]=texture
        end
        texture:ClearAllPoints()
        local edge=math.floor((i-1)*4/count)
        local first=math.ceil(edge*count/4)+1
        local last=math.ceil((edge+1)*count/4)
        local fraction=(i-first+0.5)/(last-first+1)
        local x,y,horizontal
        if edge==0 then x,y,horizontal=w*fraction,0,true
        elseif edge==1 then x,y,horizontal=w,-h*fraction,false
        elseif edge==2 then x,y,horizontal=w*(1-fraction),-h,true
        else x,y,horizontal=0,-h*(1-fraction),false end
        local length=values.length>0 and values.length or (2*(w+h)/count/2)
        length=math.min(length,horizontal and w or h)
        texture:SetSize(horizontal and length or values.thickness,horizontal and values.thickness or length)
        texture:SetPoint("CENTER",view.layer,"TOPLEFT",x,y)
        texture:SetColorTexture(settings.color[1],settings.color[2],settings.color[3],settings.intensity)
        for j,part in ipairs(texture.parts) do
            part:SetFromAlpha(j==3 and 1 or 0.2);part:SetToAlpha(j==2 and 1 or 0.2)
            local duration=j==1 and (i-1)/count or j==4 and (count-i)/count or 1/(2*count)
            part:SetDuration(duration*values.period)
        end
        texture:Show();texture.group:Play()
    end
end
-- Optional outward border extent is measured by the consumer's Border view.
-- Existing consumers can omit it; owner scale is inherited, never applied twice.
function G.Apply(view,settings,show,outset)
    if not show or not settings.enabled then G.Stop(view);return end
    local c=settings.color
    local values=G.Values(settings)
    outset=math.max(0,outset or 0)+(values.expansion or 0)
    local w,h=view.owner:GetWidth()+2*outset,view.owner:GetHeight()+2*outset
    -- Consumers with sibling statusbars/borders can supply an owned overlay floor.
    local level=math.max(view.owner:GetFrameLevel()+6,view.minimumLevel or 0)
    local lib=(settings.style=="autocast" or settings.style=="button") and Library(settings.style)
    local key=table.concat({settings.style,c[1],c[2],c[3],settings.intensity,settings.size,settings.speed,w,h,level,tostring(lib)},":")
    for _,parameter in ipairs(G.parameters[settings.style] or {}) do key=key..":"..values[parameter] end
    -- Opacity is independent of animation identity: do not stop or restart.
    view.frame:SetAlpha(settings.opacity or 1)
    if view.key==key and view.frame:IsShown() then return end
    G.Stop(view)
    local style=settings.style
    if not G.Available(style) then style="border" end
    view.frame:SetSize(w,h);view.layer:SetSize(w,h)
    view.frame:SetFrameLevel(level);view.layer:SetFrameLevel(level+1)
    view.iconBorder:SetFrameLevel(level+2)
    if view.borderFrame then view.borderFrame:SetFrameLevel(level+2) end
    view.frame:SetAlpha(settings.opacity or 1);view.layer:SetAlpha(1);view.frame:Show()
    local thickness=values.thickness or settings.size
    local period=values.period or settings.speed
    addon.Border.Apply(view,{borderStyle=(style=="border" or style=="pulse") and "thin" or "none",
        borderSize=thickness,borderColor=c,borderOpacity=settings.intensity})
    addon.Border.Render(view)
    local ok=pcall(function()
        if style=="pulse" then Pulse(view,period)
        elseif style=="shape" then
            if not view.shapeEdges then
                view.shapeEdges={}
                for i=1,4 do
                    local edge=view.layer:CreateTexture(nil,"OVERLAY");edge:SetBlendMode("ADD");view.shapeEdges[i]=edge
                end
            end
            -- Four hollow strips surround the border; no full-artwork wash.
            for i,edge in ipairs(view.shapeEdges) do
                edge:ClearAllPoints()
                if i<=2 then
                    local point=i==1 and "TOP" or "BOTTOM"
                    edge:SetPoint(point.."LEFT",view.layer,point.."LEFT",-thickness,i==1 and thickness or -thickness)
                    edge:SetPoint(point.."RIGHT",view.layer,point.."RIGHT",thickness,i==1 and thickness or -thickness)
                    edge:SetHeight(thickness)
                else
                    local point=i==3 and "LEFT" or "RIGHT"
                    edge:SetPoint("TOP"..point,view.layer,"TOP"..point,i==3 and -thickness or thickness,0)
                    edge:SetPoint("BOTTOM"..point,view.layer,"BOTTOM"..point,i==3 and -thickness or thickness,0)
                    edge:SetWidth(thickness)
                end
                edge:SetColorTexture(c[1],c[2],c[3],settings.intensity);edge:Show()
            end
            Pulse(view,period)
        elseif style=="pixel" then Pixels(view,settings,w,h,values)
        elseif style=="gcd" then
            if not view.flip then
                view.flip=view.layer:CreateTexture(nil,"OVERLAY");view.flip:SetPoint("CENTER")
                view.flipGroup=Group(view,view.flip);view.flipAnimation=view.flipGroup:CreateAnimation("FlipBook")
                view.flipAnimation:SetFlipBookRows(6);view.flipAnimation:SetFlipBookColumns(5);view.flipAnimation:SetFlipBookFrames(30)
                view.flipAnimation:SetFlipBookFrameWidth(0);view.flipAnimation:SetFlipBookFrameHeight(0)
            end
            view.flip:SetAtlas(atlas);view.flip:SetSize(w*values.atlasScale,h*values.atlasScale);view.flip:SetDesaturated(true)
            view.flip:SetVertexColor(c[1],c[2],c[3],settings.intensity);view.flipAnimation:SetDuration(period)
            view.flip:Show();view.flipGroup:Play()
        elseif style=="autocast" then
            view.external=lib;view.externalStyle=style
            lib.AutoCastGlow_Start(view.layer,{c[1],c[2],c[3],settings.intensity},values.particles,1/period,values.scale,0,0,"PlayTheGameTools")
        elseif style=="button" then
            view.external=lib;view.externalStyle=style
            lib.ButtonGlow_Start(view.layer,{c[1],c[2],c[3],settings.intensity},1/period)
        end
    end)
    if not ok then
        G.Stop(view);style="border";view.frame:Show()
        addon.Border.Apply(view,{borderStyle="thin",borderSize=thickness,borderColor=c,borderOpacity=settings.intensity})
        addon.Border.Render(view)
    end
    view.key=key;view.activeStyle=style
end
