-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
local addonName, D = ...
D = D or {}
D.version = "0.1.0-dev"
D.matrix = "v14"
D.active = false
D.session = nil
D.maxRecords = 256
D.maxExport = 32768
D.maxSessions = 3
D.maxText = 160
D.maxDuration = 900
D.dropped = 0
D.sequence = 0
D.records = {}
D.settings = {}
local function safe(v)
    local api=KordRotation and KordRotation.GameAPI
    if not api or type(api.IsSafeValue)~="function" then return false end
    local ok,result=pcall(api.IsSafeValue,api,v)
    return ok and result==true
end
function D:Safe(v) return safe(v) end
function D:ReadCore()
    local kr=KordRotation
    if not kr or not kr.CoreObservation or type(kr.CoreObservation.Read)~="function" then
        return {status="UNAVAILABLE",engineStatus="UNKNOWN"}
    end
    local ok,value=pcall(kr.CoreObservation.Read,kr.CoreObservation)
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
host:SetScript("OnEvent",function(_,event)
    if event=="PLAYER_LOGIN" then D:Boot() end
end)
_G.KordRotationDevTools=D
