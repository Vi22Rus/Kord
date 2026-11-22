-- IT-01/1.8: isolated item eligibility gate (not a spell gate).
-- No WoW client; execute with Lua 5.1 from repository root.
local KR={}
local function ready(value) return {status="READY",value=value} end
local counts=1
local cooldownActive=false
local sharedStatus="NOT_APPLICABLE"
local sharedActive=false
local usable=true
local omitZone=false
local failCooldown=false
local failUsability=false
local itemReads,cooldownReads,usableReads=0,0,0
local snapshot={player={exists=ready(true),dead=ready(false),
    combat=ready(false),level=ready(40)},
    target={exists=ready(true),dead=ready(false),
    attackable=ready(true),assistable=ready(true)}}
KR.GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}
KR.GameState={
 ReadInventoryItemObservation=function(_,id)
    itemReads=itemReads+1
    if counts=="UNKNOWN" then return {status="UNKNOWN",itemID=id} end
    return {status="READY",itemID=id,inventoryScope="BAGS_ONLY",count=counts}
 end,
 ReadItemCooldownObservation=function(_,id)
    cooldownReads=cooldownReads+1
    if failCooldown then return {status="UNKNOWN",itemID=id} end
    return {status="READY",itemID=id,active=cooldownActive,
        sharedStatus=sharedStatus,sharedActive=sharedActive}
 end,
 ReadItemUsabilityObservation=function(_,id,opts)
    usableReads=usableReads+1
    assert(opts.target=="self" and opts.combat=="any")
    if failUsability then return {status="UNKNOWN",itemID=id} end
    return {status="READY",itemID=id,usable=usable,
        combatAllowed=true,levelAllowed=true,targetAllowed=true,
        zoneAllowed=not omitZone and true or nil}
 end,
 GetSnapshot=function() return snapshot end,
}
assert(loadfile("KordRotation/Core/AbilityEligibility.lua"))("KordRotation",KR)
local A=KR.AbilityEligibility
local policy={target="self",combat="any",minLevel=30}
local function run() return A:EvaluateItem(5512,policy) end
assert(run().status=="READY")
assert(run().actionType=="ITEM" and run().itemID==5512 and run().spellID==nil)
counts=0
local before=cooldownReads
assert(run().reason=="item_missing" and cooldownReads==before)
counts="UNKNOWN"
assert(run().status=="UNKNOWN")
counts=1
assert(A:EvaluateItem(5512,{target="self",combat="unknown"}).status=="UNKNOWN")
assert(A:EvaluateItem(5512,{target="self",combat="any",minLevel=41}).reason=="item_level_too_low")
cooldownActive=true
assert(run().reason=="item_on_cooldown")
cooldownActive=false
sharedStatus="READY";sharedActive=true
assert(run().reason=="item_shared_cooldown")
sharedActive=false
assert(run().status=="READY")
sharedStatus="UNKNOWN"
assert(run().reason=="item_shared_cooldown_unverified")
sharedStatus="NOT_APPLICABLE"
usable=false
assert(run().status=="BLOCKED")
usable=true
omitZone=true
assert(run().reason=="item_usability_partial")
omitZone=false
failCooldown=true
assert(run().status=="UNKNOWN")
failCooldown=false
failUsability=true
assert(run().status=="UNKNOWN")
failUsability=false
local original=KR.GameState.ReadItemCooldownObservation
KR.GameState.ReadItemCooldownObservation=nil
assert(run().reason=="item_cooldown_provider_missing")
KR.GameState.ReadItemCooldownObservation=original
assert(A:EvaluateItem("SECRET",policy).reason=="invalid_item_id")
assert(A:EvaluateItem(5512,"SECRET").reason=="item_options_unverified")
assert(A:EvaluateItem(5512,{target="self",combat="any",minLevel="SECRET"}).reason=="item_policy_protected")
assert(A:EvaluateItem(5512,{target="self",combat="any",stateSnapshot="SECRET"}).reason=="item_policy_protected")
print("inventory_item_eligibility_mock PASS")
