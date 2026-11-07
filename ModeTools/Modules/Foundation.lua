local _, addon = ...

-- An explicit lifecycle demonstration, with no gameplay behavior or events.
addon:RegisterModule("foundation", {
    title = "Developer Mode",
    developer = true,
    description = "Foundation and interrupt diagnostics, optional session logging and copyable reports. The registry toggle is a lifecycle check.",
    defaultEnabled = true,
    OnInitialize = function(self)
        self.status = "Disabled"
    end,
    OnEnable = function(self)
        self.status = "Enabled"
    end,
    OnDisable = function(self)
        if addon.PartyCooldownNative then addon.PartyCooldownNative:SetChargePilot(false) end
        if addon.PartyCooldownLifecycle then addon.PartyCooldownLifecycle:SetEnabled(false) end
        self.status = "Disabled"
    end,
})
