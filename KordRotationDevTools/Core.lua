-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
local addonName, D = ...
D = D or {}
D.version = "0.1.0-dev"
D.matrix = "v14"
D.active = false
D.session = nil
D.maxRecords = 512
D.maxExport = 32768
D.maxSessions = 12
D.maxText = 160
D.maxDuration = 900
D.dropped = 0
D.sequence = 0
D.records = {}
D.settings = {}
local function safe(v)
    -- The diagnostic namespace has no access to KR.GameAPI internals.
    -- Only client secrecy checks are used; protected data are discarded.
    if type(issecretvalue)=="function" then
        local ok,secret=pcall(issecretvalue,v)
        if not ok or secret==true then return false end
    end
    if type(issecrettable)=="function" then
        local ok,secret=pcall(issecrettable,v)
        if not ok or secret==true then return false end
    end
    if type(canaccessvalue)=="function" then
        local ok,allowed=pcall(canaccessvalue,v)
        if not ok or allowed~=true then return false end
    end
    return true
end
function D:Safe(v) return safe(v) end
function D:ReadCore()
    local bridge=_G.KordRotationCoreObservation
    if type(bridge)~="table" or type(bridge.Read)~="function" then
        return {status="UNAVAILABLE",engineStatus="UNKNOWN"}
    end
    local ok,value=pcall(bridge.Read)
    if not ok or type(value)~="table" then
        return {status="ERROR",engineStatus="UNKNOWN"}
    end
    return value
end
function D:Print(key)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff00caff[Kord DevTools]|r "..self:L(key)) end
end
function D:Boot()
    self.active=false -- never resume recording after reload
    self.records={}
    self.dropped=0
    self.sequence=0
    self.settings=type(KordRotationDevToolsDB)=="table" and KordRotationDevToolsDB or {}
    self:CreateUI()
end
local host=CreateFrame("Frame")
host:RegisterEvent("PLAYER_LOGIN")
host:RegisterEvent("PLAYER_LOGOUT")
host:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then D:Boot()
    elseif event=="PLAYER_LOGOUT" and D.active and type(D.Stop)=="function" then
        -- Finish a manually started session before WoW saves its variables.
        D:Stop()
    end
end)
_G.KordRotationDevTools=D
