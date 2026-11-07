local _,addon=...
local R={}
addon.ContextualAlertDisplay=R
local function Plain(v) return not (issecretvalue and issecretvalue(v)) end
local function Number(v) return Plain(v) and type(v)=="number" and v==v and math.abs(v)<math.huge end
local function Literal(text) return text:gsub("|","||") end

-- Literal substitution only. Unknown tokens, percent signs and Lua-like text stay text.
function R.Message(template,names,color)
    local prefix=string.format("|cff%02x%02x%02x",math.floor(color[1]*255+0.5),math.floor(color[2]*255+0.5),math.floor(color[3]*255+0.5))
    return Literal(template):gsub("{([%a]+)}",function(key)
        if key=="lootSpec" or key=="activeSpec" then return prefix..Literal(names[key]).."|r" end
        return "{"..key.."}"
    end)
end
function R.Create(parent,name)
    local view={frame=CreateFrame("Frame",name,parent)}
    view.frame:SetSize(320,48);view.frame:EnableMouse(false)
    view.background=view.frame:CreateTexture(nil,"BACKGROUND");view.background:SetAllPoints()
    view.text=view.frame:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
    view.text:SetPoint("TOPLEFT",12,-10);view.text:SetWordWrap(true)
    addon.Border.Create(view,view.frame)
    view.specIcon=CreateFrame("Frame",nil,view.frame)
    view.specIcon:EnableMouse(false)
    view.iconView={}
    view.iconView.texture=view.specIcon:CreateTexture(nil,"ARTWORK");view.iconView.texture:SetAllPoints()
    addon.Border.Create(view.iconView,view.specIcon)
    return view
end
function R.Apply(view,a,message,layout,names)
    local path=addon.Media:GetDisplayFont(a)
    local icon=names and names.lootIcon
    local showIcon=a.showSpecIcon and icon~=nil
    local extra=showIcon and (a.iconSize+a.iconGap) or 0
    local key=table.concat({path,a.fontSize,tostring(a.outline),a.scale,a.alignment,message,tostring(icon),extra,a.iconPosition},":")
    if layout and view.layoutKey~=key then
        if not view.text:SetFont(path,a.fontSize,a.outline and "OUTLINE" or "") then
            view.text:SetFont(GameFontHighlight:GetFont(),a.fontSize,a.outline and "OUTLINE" or "")
        end
        view.text:SetWidth(0);view.text:SetText(message)
        local width=view.text:GetStringWidth()
        width=Number(width) and width or 280
        width=math.max(120,math.min(900,width+24+extra));view.text:SetWidth(width-24-extra)
        local height=view.text:GetStringHeight()
        height=Number(height) and height or a.fontSize
        view.frame:SetSize(width,math.max(a.fontSize+20,height+20,showIcon and a.iconSize+20 or 0));view.frame:SetScale(a.scale)
        view.text:ClearAllPoints();view.text:SetPoint("LEFT",view.frame,"LEFT",12+(a.iconPosition=="left" and extra or 0),0)
        view.specIcon:SetSize(a.iconSize,a.iconSize);view.specIcon:ClearAllPoints()
        view.specIcon:SetPoint(a.iconPosition=="left" and "LEFT" or "RIGHT",view.frame,a.iconPosition=="left" and "LEFT" or "RIGHT",a.iconPosition=="left" and 12 or -12,0)
        view.specIcon:SetShown(showIcon and true or false)
        if showIcon then
            local ok,usable=pcall(view.iconView.texture.SetTexture,view.iconView.texture,icon)
            if not ok or usable==false then view.specIcon:Hide() end
        end
        view.text:SetJustifyH(a.alignment)
        view.layoutKey=key
    end
    if view.lastText~=message then view.text:SetText(message);view.lastText=message end
    view.text:SetTextColor(unpack(a.textColor))
    view.background:SetColorTexture(a.backgroundColor[1],a.backgroundColor[2],a.backgroundColor[3],a.backgroundOpacity)
    view.background:SetShown(a.showBackground)
    if layout then
        addon.Border.Apply(view,a);addon.Border.Render(view)
        addon.Border.Apply(view.iconView,{borderStyle=a.iconBorderStyle,borderSize=a.iconBorderSize,borderColor=a.iconBorderColor,borderOpacity=a.iconBorderOpacity,inset=true})
        addon.Border.Render(view.iconView)
    end
end
