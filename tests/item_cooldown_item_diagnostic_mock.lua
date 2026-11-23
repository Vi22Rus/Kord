-- IT-02/2.9: manual item cooldown provenance, fixed codes and privacy.
local KR={
 GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end},
 GameState={ReadItemCooldownObservation=function(_,id)
    assert(id==118)
    return {status="READY",source="C_Item.GetItemCooldown",
        active=true,remaining=15, itemID=118,rawItemName="private"}
 end}
}
assert(loadfile("KordRotation/Core/CoreObservation.lua"))("KordRotation",KR)
local bridge=_G.KordRotationCoreObservation
local safe=bridge.ItemCooldownDiagnostic(bridge,118)
assert(safe.status=="UNKNOWN" and safe.code=="item_cd_item_active")
assert(safe.source=="C_Item.GetItemCooldown" and safe.activity=="ACTIVE")
assert(safe.itemID==nil and safe.remaining==nil and safe.rawItemName==nil)
KR.GameState.ReadItemCooldownObservation=function()
 return {status="READY",source="GetItemCooldown",active=false,remaining=0}
end
local idle=bridge.ItemCooldownDiagnostic(bridge,118)
assert(idle.status=="READY" and idle.code=="item_cd_ready_confirmed"
    and idle.activity=="IDLE")
KR.GameState.ReadItemCooldownObservation=function()
 return {status="UNKNOWN",reason="item_cd_revision_unavailable",
    source="SECRET",itemID=118}
end
local noRevision=bridge.ItemCooldownDiagnostic(bridge,118)
assert(noRevision.code=="item_cd_revision_unavailable"
    and noRevision.source=="UNKNOWN" and noRevision.activity=="UNKNOWN")
assert(bridge.ItemCooldownDiagnostic(bridge,0).code=="item_cd_id_unverified")
local D={active=true,records={},maxRecords=100,maxDuration=1000,
 Safe=function(_,v) return v~="SECRET" end}
assert(loadfile("KordRotationDevTools/Recorder.lua"))("KordRotationDevTools",D)
assert(loadfile("KordRotationDevTools/Probe.lua"))("KordRotationDevTools",D)
local output=D:ItemCooldownDiagnostic(118)
assert(output.code=="item_cd_revision_unavailable")
assert(#D.records==1 and D.records[1].reason=="item_cd_revision_unavailable")
assert(D.records[1].detail==nil)
local before=#D.records
assert(D:ItemCooldownDiagnostic(0).code=="item_cd_id_unverified")
assert(#D.records==before)
_G.KordRotationCoreObservation={
 ItemCooldownDiagnostic=function()
  return {status="READY",code="item_cd_ready_confirmed",
   activity="ACTIVE",source="SECRET",itemID=118}
 end}
local rejected=D:ItemCooldownDiagnostic(118)
assert(rejected.status=="UNKNOWN" and rejected.code=="item_cd_remaining_unknown")
assert(#D.records==before)
_G.KordRotationCoreObservation=bridge
print("item_cooldown_item_diagnostic_mock PASS")
