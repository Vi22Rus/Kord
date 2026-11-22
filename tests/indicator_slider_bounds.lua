-- Lua 5.1 regression: Indicators tab passes explicit bounds to every slider.
-- Reproduces: Missing numeric bounds for IND_HIGHLIGHT_STRENGTH.
local recorded={}
local function frame()
 local f={}
 setmetatable(f,{__index=function(_,k)
  return function()end
 end})
 return f
end
CreateFrame=function()return frame()end
local KR={
 UI={colors={panel={},line={},text={},muted={},sidebar={}}},
 Pages={},
 IndicatorSettings={Get=function()return 1 end,Set=function()return true end},
 AppearanceProfiles={},
}
function KR:L(key)return key end
function KR.UI:Label()return frame()end
function KR.UI:Background()end
function KR.UI:Border()end
function KR.UI:ToggleRow()return frame()end
function KR.UI:ChoiceRow()return frame()end
function KR.UI:StepRow(_,key,x,y,width,getter,setter,step,formatter,minimum,maximum)
 assert(type(minimum)=="number" and type(maximum)=="number",
  "Missing numeric bounds for "..tostring(key))
 assert(minimum<=maximum,"inverted bounds for "..tostring(key))
 assert(formatter==nil,"formatter must not receive minimum for "..tostring(key))
 assert(type(step)=="number" and step>=1,"invalid step")
 recorded[key]={minimum,maximum}
 return frame()
end
local loadPage=assert(loadfile("KordRotation/UI/Pages/IndicatorsProfiles.lua"))
loadPage("KordRotation",KR)
KR.Pages:Indicators(frame())
local expected={
 IND_HIGHLIGHT_STRENGTH={0,100},
 IND_DEFENSIVE_SLOTS={1,3},
 IND_DEFENSIVE_SIZE={24,128},
 IND_DEFENSIVE_ALPHA={0,100},
 IND_INTERRUPT_SIZE={24,128},
 IND_INTERRUPT_SPELL={0,9999999},
 IND_SOUND_THROTTLE={1,30},
}
local count=0
for key,range in pairs(expected) do
 local got=assert(recorded[key],"missing slider: "..key)
 assert(got[1]==range[1] and got[2]==range[2],
  "wrong range for "..key)
 count=count+1
end
for key in pairs(recorded) do
 assert(expected[key],"unexpected slider: "..key)
end
print("PASS Indicators slider bounds: "..count.." sliders")
