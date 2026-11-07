local _,addon=...
local E={}
addon.AlertEffects=E
-- Same presentation curve in simulation; live frames use native animation groups.
function E.Alpha(settings,elapsed)
    local style,duration=settings.style,settings.duration
    local pulse=style=="pulse" or style=="pulseFade"
    local fade=style=="fade" or style=="pulseFade"
    if elapsed>=duration and not (pulse and settings.repeatPulse) then return 1 end
    local fadeDuration=style=="fade" and duration or math.min(0.6,duration/3)
    if fade and elapsed<fadeDuration then
        local t=elapsed/fadeDuration
        return 0.3+0.7*t*t*(3-2*t)
    end
    if pulse then return 0.86+0.14*math.cos(elapsed*math.pi*2/1.8) end
    return 1
end
function E.Stop(view)
    view.effectGeneration=(view.effectGeneration or 0)+1
    for _,group in ipairs(view.effectGroups or {}) do group:Stop() end
    view.frame:SetAlpha(1)
end
function E.Play(view,settings)
    E.Stop(view)
    if settings.style=="none" or not view.frame.CreateAnimationGroup then return end
    local generation=view.effectGeneration
    local pulse=settings.style=="pulse" or settings.style=="pulseFade"
    local fade=settings.style=="fade" or settings.style=="pulseFade"
    -- Cache groups per view; no live OnUpdate/polling or scale changes.
    if not view.effectGroups then
        view.effectGroups={}
        for i=1,2 do
            local group=view.frame:CreateAnimationGroup()
            group.parts={}
            for j=1,(i==1 and 1 or 2) do
                local part=group:CreateAnimation("Alpha")
                part:SetOrder(j);part:SetSmoothing("IN_OUT");group.parts[j]=part
            end
            view.effectGroups[i]=group
        end
    end
    local fadeGroup,pulseGroup=unpack(view.effectGroups)
    local function Pulse()
        if generation~=view.effectGeneration or not view.frame:IsShown() or not pulse then return end
        local part1,part2=unpack(pulseGroup.parts)
        part1:SetFromAlpha(1);part1:SetToAlpha(0.72);part1:SetDuration(0.9)
        part2:SetFromAlpha(0.72);part2:SetToAlpha(1);part2:SetDuration(0.9)
        pulseGroup:SetLooping("REPEAT");pulseGroup:Play()
    end
    if fade then
        local part=fadeGroup.parts[1]
        part:SetFromAlpha(0.3);part:SetToAlpha(1);part:SetDuration(settings.style=="fade" and settings.duration or math.min(0.6,settings.duration/3))
        fadeGroup:SetScript("OnFinished",Pulse);fadeGroup:Play()
    else Pulse() end
    if not (pulse and settings.repeatPulse) then
        C_Timer.After(settings.duration,function() if generation==view.effectGeneration then E.Stop(view) end end)
    end
end
function E.Sound(settings,testing,allowCombat)
    if not addon.Feedback:Allowed(allowCombat) or (not testing and not settings.playSound) then return false end
    local chosen=addon.Media:GetSound(settings.sound)
    local function Play(value)
        local fn=type(value)=="number" and PlaySound or type(value)=="string" and PlaySoundFile
        if type(fn)~="function" then return false end
        local channel=({Master=true,SFX=true,Music=true,Ambience=true,Dialog=true})[settings.channel] and settings.channel or "Master"
        local ok,played=pcall(fn,value,channel)
        return ok and (not (issecretvalue and issecretvalue(played))) and played==true
    end
    if Play(chosen) then return true end
    return Play(addon.Media:GetSound("default"))
end
