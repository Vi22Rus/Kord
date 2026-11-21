-- Validate all six locales, aliases, button labels and tooltips.
local languages={"enUS","ruRU","frFR","deDE","ptBR","esES"}
local keys={"TITLE","START","STOP","PROBE","MEASURE","EXPORT","CLEAR","CLOSE",
    "STATE_ON","STATE_OFF","HELP","STATUS","RESULT","METRIC","UNAVAILABLE",
    "TIP_START","TIP_STOP","TIP_PROBE","TIP_MEASURE","TIP_EXPORT",
    "TIP_CLEAR","TIP_CLOSE"}
local n=0
for _,lang in ipairs(languages) do
    GetLocale=function()return lang end
    local D={}
    assert(loadfile("KordRotationDevTools/Locale.lua"))("KordRotationDevTools",D)
    assert(D.locale==lang,lang.." locale missing")
    for _,key in ipairs(keys) do
        local value=D:L(key)
        assert(type(value)=="string" and #value>0 and value~=key,lang.."/"..key.." untranslated")
        n=n+1
    end
    assert(type(D:Format("STATUS","off",0,0))=="string",lang.." format")
end
for _,pair in ipairs({{"enGB","enUS"},{"esMX","esES"},{"ptPT","ptBR"}}) do
    GetLocale=function()return pair[1] end
    local D={}
    assert(loadfile("KordRotationDevTools/Locale.lua"))("KordRotationDevTools",D)
    assert(D.locale==pair[2],"alias "..pair[1])
end
print("PASS DevTools 6 locale mock: "..n.." translated values")
