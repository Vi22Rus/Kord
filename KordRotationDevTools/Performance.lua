-- Kord Rotation DevTools (c) 2026 Vi22Rus; see root LICENSE.
-- Manual bounded profiling of read-only observation, no gameplay timing hooks.
local _,D=...
local function ms()
    if type(debugprofilestop)~="function" then return nil end
    local ok,v=pcall(debugprofilestop)
    if not ok or not D:Safe(v) or type(v)~="number" or v~=v
        or v<0 or v>1000000000 then return nil end
    return v
end
function D:Measure()
    local first=ms()
    if not first then
        return {status="UNAVAILABLE",reason="profiling_api_missing"}
    end
    local observed=self:ReadCore()
    local final=ms()
    if not final or final<first then
        return {status="UNKNOWN",reason="profiling_clock_unknown"}
    end
    -- Only observation overhead, NOT whole addon CPU/FPS usage.
    local duration=math.floor(final-first+0.5)
    if duration>1000000 then
        return {status="UNKNOWN",reason="profiling_elapsed_invalid"}
    end
    self.lastMeasure={status="READY",durationMs=duration,
        engineStatus=observed.engineStatus}
    if self.active then
        self:Record("PERFORMANCE","READY","manual_sample",nil,duration)
    end
    return self.lastMeasure
end
