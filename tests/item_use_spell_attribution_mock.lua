-- IT-02/2.6: source-backed use-spell attribution (synthetic Lua 5.1 mock).
-- Spell events must never prove potion shared cooldown READY.
local now=100
local mode="valid"
local KR={GameAPI={
    IsSafeValue=function(_,v) return v~="SECRET" end,
    Read=function(_,name,expected)
        assert(name=="GetTime" and expected=="number")
        return {status="READY",value=now}
    end,
    ReadValues=function(_,name,itemID)
        assert(name=="C_Item.GetItemSpell")
        if mode=="missing" and itemID==118 then
            return {status="UNAVAILABLE",reason="api_missing"}
        end
        local spellID=itemID+10000
        if mode=="collision" and itemID==858 then spellID=10118 end
        return {status="READY",value={"Potion effect",spellID}}
    end,
}}
assert(loadfile("KordRotation/Core/ItemFamilyCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/SharedCooldownGroupCatalog.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/GameState.lua"))("KordRotation",KR)
assert(loadfile("KordRotation/Core/EventBus.lua"))("KordRotation",KR)
local C,S,E=KR.SharedCooldownGroupCatalog,KR.GameState,KR.EventBus
local prepared=C:PrepareUseSpellIndex("POTION_SHARED")
assert(prepared.status=="UNKNOWN" and prepared.reason=="item_cd_use_spell_index_prepared")
assert(prepared.mappedCount==19)
assert(C:FindObservedUseSpell(10118).itemID==118)
assert(C:FindObservedUseSpell(10118).status=="UNKNOWN")
assert(C:FindObservedUseSpell(99999).itemID==nil)
assert(not S:ObserveSuccessfulItemUseSpell(99999))
-- An actual player event is required; a target's cast cannot attribute use.
assert(E:HandleEvent("UNIT_SPELLCAST_SUCCEEDED","target","g",10118))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==nil)
assert(E:HandleEvent("UNIT_SPELLCAST_SUCCEEDED","player","g",10118))
local observed=S:ReadObservedItemUse("POTION_SHARED")
assert(observed.status=="UNKNOWN" and observed.groupStatus=="UNKNOWN")
assert(observed.reason=="item_cd_use_attribution_estimated")
assert(observed.confidence=="ESTIMATED" and observed.candidateItemID==118)
assert(observed.source=="UNIT_SPELLCAST_SUCCEEDED")
assert(observed.remaining==nil and observed.active==nil)
local group=S:ReadSharedItemCooldownObservation("POTION_SHARED")
assert(group.status=="UNKNOWN" and group.groupStatus=="UNKNOWN")
assert(group.useAttribution=="ESTIMATED" and group.remaining==nil)
assert(group.active==nil)
now=281
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==nil)
now=100
assert(E:HandleEvent("UNIT_SPELLCAST_SUCCEEDED","player","g",10118))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==118)
-- A small zone transition must not reuse the previous use-spell estimate.
assert(E:HandleEvent("ZONE_CHANGED"))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==nil)
assert(E:HandleEvent("UNIT_SPELLCAST_SUCCEEDED","player","g",10118))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==118)
-- Death also invalidates a pre-death correlation.
local beforeDeath=E:GetItemCooldownRevision()
assert(E:HandleEvent("PLAYER_DEAD"))
assert(E:GetItemCooldownRevision()==beforeDeath+1)
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==nil)
assert(E:HandleEvent("UNIT_SPELLCAST_SUCCEEDED","player","g",10118))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==118)
assert(E:HandleEvent("PLAYER_REGEN_ENABLED"))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==nil)
-- Explicit re-index after source changes MUST fail closed.
local original=KR.ItemFamilyCatalog
KR.ItemFamilyCatalog={GetRevision=function() return 2 end,
    GetFamily=original.GetFamily}
local stale=C:FindObservedUseSpell(10118)
assert(stale.reason=="item_cd_use_spell_index_stale")
KR.ItemFamilyCatalog=original
mode="missing"
local missing=C:PrepareUseSpellIndex("POTION_SHARED")
assert(missing.reason=="item_cd_use_spell_mapping_unverified")
assert(C:FindObservedUseSpell(10118).itemID==nil)
mode="collision"
assert(C:PrepareUseSpellIndex("POTION_SHARED").reason=="item_cd_use_spell_mapping_unverified")
assert(C:FindObservedUseSpell(10118).itemID==nil)
mode="valid"
assert(C:PrepareUseSpellIndex("POTION_SHARED").mappedCount==19)
assert(E:HandleEvent("UNIT_SPELLCAST_SUCCEEDED","player","g","SECRET"))
assert(S:ReadObservedItemUse("POTION_SHARED").candidateItemID==nil)
print("item_use_spell_attribution_mock PASS")
