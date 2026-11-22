-- Optional DevTools launch contract; no WoW client is required.
local n=0
local function eq(actual,expected,label)
 n=n+1
 assert(actual==expected,(label or "assert").." got "..tostring(actual)
  .." expected "..tostring(expected))
end
local D={ui={frame={}}}
local showCount,refreshCount=0,0
function D.ui.frame:Show() showCount=showCount+1 end
function D:RefreshUI() refreshCount=refreshCount+1 end
assert(loadfile("KordRotationDevTools/UI.lua"))("KordRotationDevTools",D)
-- Isolate OpenUI's refresh contract; the production UI module defines its
-- own RefreshUI which requires the full WoW widget hierarchy in game.
D.RefreshUI=function() refreshCount=refreshCount+1 end
eq(D:OpenUI(),true,"public OpenUI accepts available window")
eq(showCount,1,"public OpenUI shows real window")
eq(refreshCount,1,"public OpenUI refreshes status")
D.ui.frame.Show=function()error("simulated unavailable frame")end
eq(D:OpenUI(),false,"public OpenUI handles broken window")
-- Button label/help/result text must exist for every supported main-addon locale.
for _,locale in ipairs({"enUS","ruRU","deDE","frFR","esES","ptBR"}) do
 GetLocale=function()return locale end
 local KR={}
 assert(loadfile("KordRotation/Core/Locale.lua"))("KordRotation",KR)
 for _,key in ipairs({"DIAG_OPEN_DEVTOOLS","TIP_DIAG_OPEN_DEVTOOLS",
   "DIAG_DEVTOOLS_OPENED","DIAG_DEVTOOLS_MISSING"}) do
  local text=KR:L(key)
  eq(type(text),"string",locale.." "..key.." text exists")
  eq(text~=key,true,locale.." "..key.." translated")
 end
end
print("PASS optional DevTools window launch/locale mock: "..n.." assertions")
