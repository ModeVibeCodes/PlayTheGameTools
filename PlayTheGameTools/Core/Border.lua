local _, addon = ...
local B = {}
addon.Border = B

-- LSM supplies edge atlases, not universal insets. Own decorations only.
function B.Create(view, group)
    view.borderGroup = group
    view.iconBorder = CreateFrame("Frame", nil, group)
    view.iconBorder:EnableMouse(false)
    view.thinEdges = {}
    for i = 1, 4 do view.thinEdges[i] = view.iconBorder:CreateTexture(nil, "OVERLAY") end
    view.borderProbe = group:CreateTexture(nil, "BACKGROUND"); view.borderProbe:Hide()
    local ok, frame = pcall(CreateFrame, "Frame", nil, group, "BackdropTemplate")
    if ok and frame and frame.SetBackdrop and frame.SetBackdropBorderColor then
        frame:EnableMouse(false); frame:SetFrameLevel(group:GetFrameLevel() + 1); frame:Hide()
        view.borderFrame = frame
    end
end

function B.Apply(view, settings)
    local group, frame = view.borderGroup, view.borderFrame
    local descriptor = addon.Media:GetBorder(settings.borderStyle)
    local size = settings.size or math.min(group:GetWidth(), group:GetHeight())
    local edge = math.max(0.5, math.min(settings.borderSize or (descriptor and descriptor.edgeSize) or 1, 12, size / 4))
    local resolved = descriptor and (descriptor.kind .. ":" .. (descriptor.path or "")) or "missing"
    local outward = settings.inset and 0 or edge
    local key = table.concat({settings.borderStyle, edge, outward, addon.Media.borderRevision, resolved}, ":")
    if key ~= view.borderKey then
        view.borderKind = descriptor and descriptor.kind or "thin"
        if frame then frame:Hide() end
        view.iconBorder:ClearAllPoints(); view.iconBorder:SetAllPoints(group)
        for i, texture in ipairs(view.thinEdges) do
            texture:ClearAllPoints()
            if i <= 2 then
                local point = i == 1 and "TOP" or "BOTTOM"
                texture:SetPoint(point.."LEFT", group, point.."LEFT", -outward, i == 1 and outward or -outward)
                texture:SetPoint(point.."RIGHT", group, point.."RIGHT", outward, i == 1 and outward or -outward)
                texture:SetHeight(edge)
            else
                local point = i == 3 and "LEFT" or "RIGHT"
                texture:SetPoint("TOP"..point, group, "TOP"..point, i == 3 and -outward or outward, 0)
                texture:SetPoint("BOTTOM"..point, group, "BOTTOM"..point, i == 3 and -outward or outward, 0)
                texture:SetWidth(edge)
            end
        end
        if descriptor and descriptor.kind == "shared" then
            local ok = pcall(function()
                assert(frame, "BackdropTemplate unavailable")
                assert(view.borderProbe:SetTexture(descriptor.path), "Border texture unavailable")
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", group, "TOPLEFT", -outward, outward)
                frame:SetPoint("BOTTOMRIGHT", group, "BOTTOMRIGHT", outward, -outward)
                frame:SetBackdrop({edgeFile = descriptor.path, edgeSize = edge, tileEdge = true})
            end)
            if not ok then view.borderKind = "thin" end
        end
        view.borderKey, view.edgeSize = key, edge
    end
    local color, alpha = settings.borderColor, settings.borderOpacity or 1
    local colorKey = table.concat(color, ":") .. ":" .. alpha .. ":" .. key
    if view.borderColorKey ~= colorKey then
        for _, texture in ipairs(view.thinEdges) do texture:SetColorTexture(color[1], color[2], color[3], alpha) end
        if frame then
            local ok = pcall(frame.SetBackdropBorderColor, frame, color[1], color[2], color[3], alpha)
            if not ok and view.borderKind == "shared" then view.borderKind = "thin" end
        end
        view.borderColorKey = colorKey
    end
end

function B.Render(view)
    view.iconBorder:SetShown(view.borderKind == "thin")
    if view.borderFrame then view.borderFrame:SetShown(view.borderKind == "shared") end
end
