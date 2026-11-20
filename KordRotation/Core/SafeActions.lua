-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Use subject to root LICENSE; attribution must be retained.
-- Non-combat protected transitions are queued, never simulated in combat.
local addonName, KR = ...
KR.SafeActions = KR.SafeActions or {}
local Q = KR.SafeActions
local function combat()
    if type(InCombatLockdown) ~= "function" then return nil end
    local ok, active = pcall(InCombatLockdown)
    if ok and type(active)=="boolean" then return active end
    return nil
end
-- License notice (2/3): no protected spells or cast actions are scheduled here.
function Q:Run(key, callback)
    if type(key) ~= "string" or type(callback) ~= "function" then return false, "invalid" end
    local active=combat()
    if active==nil then
        if KR.Diagnostics then KR.Diagnostics:Log("WARN","Combat","Lockdown state unavailable: "..key) end
        return false, "unavailable"
    end
    if active then
        self.pending = self.pending or {}
        self.pending[key] = callback
        if KR.Diagnostics then KR.Diagnostics:Log("INFO", "Combat", "Deferred "..key) end
        return true, "deferred"
    end
    local ok, result = pcall(callback)
    if not ok and KR.Diagnostics then KR.Diagnostics:Log("ERROR", "Combat", result) end
    return ok and result ~= false, ok and "applied" or "error"
end
function Q:Flush()
    if combat()~=false or not self.pending then return end
    local actions = self.pending
    self.pending = {}
    for key, callback in pairs(actions) do self:Run(key, callback) end
end
function Q:Status()
    local total = 0
    for _ in pairs(self.pending or {}) do total = total + 1 end
    return total
end
function Q:Initialize()
    if self.frame then return end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function() Q:Flush() end)
    self.frame = frame
end
-- Copyright notice (3/3): 2026 Vi22Rus; see LICENSE.
