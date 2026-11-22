-- IT-02/2.9: diagnostic code sanitization, no raw item IDs.
local D={active=true,records={},sequence=0,maxRecords=100,
 maxDuration=1000,Safe=function(_,v) return v~="SECRET" end}
assert(loadfile("KordRotationDevTools/Recorder.lua"))("KordRotationDevTools",D)
assert(type(D.RecordItemCooldownDiagnostic)=="function")
local names={"item_cd_api_missing","item_cd_secret","item_cd_disabled",
 "item_cd_invalid_tuple","item_cd_gcd_only","item_cd_remaining_unknown",
 "item_cd_group_unknown","item_cd_group_partial",
 "item_cd_group_estimated","item_cd_group_conflict",
 "item_cd_use_attribution_unknown","item_cd_ready_confirmed"}
for _,reason in ipairs(names) do
 local ok=D:RecordItemCooldownDiagnostic(reason)
 assert(ok==true,reason)
 local row=D.records[#D.records]
 assert(row.reason==reason)
 if reason=="item_cd_ready_confirmed" then assert(row.status=="READY")
 else assert(row.status=="UNKNOWN") end
 assert(row.detail==nil and row.method==nil)
end
local before=#D.records
assert(D:RecordItemCooldownDiagnostic("SECRET")==false)
assert(D:RecordItemCooldownDiagnostic("item_cd_123456")==false)
assert(D:RecordItemCooldownDiagnostic(123456)==false)
assert(D:RecordItemCooldownDiagnostic("player name")==false)
assert(#D.records==before)
D.active=false
assert(D:RecordItemCooldownDiagnostic("item_cd_secret")==false)
print("item_cooldown_devtools_mock PASS")
