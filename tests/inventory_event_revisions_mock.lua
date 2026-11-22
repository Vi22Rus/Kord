-- IT-01/1.6: inventory invalidation, per-bag revisions, coalescing,
-- and explicit refresh (including missing Soulwell bag event).
-- Source-only mock, no client API claims.
local KR={}
assert(loadfile("KordRotation/Core/EventBus.lua"))("KordRotation",KR)
local E=KR.EventBus
assert(E:GetInventoryRevision()==0)
assert(E:GetBagRevision(0)==0 and E:GetBagRevision(4)==0)
assert(E:GetBagRevision(5)==nil)
local calls={}
assert(E:Subscribe("inventory","it01",function(channel,rev)
    calls[#calls+1]={channel=channel,rev=rev}
end))
assert(E:HandleEvent("BAG_UPDATE",1))
assert(E:GetInventoryRevision()==1)
assert(E:GetBagRevision(1)==1 and E:GetBagRevision(0)==0)
assert(E:HandleEvent("BAG_UPDATE",1))
assert(E:GetInventoryRevision()==2 and E:GetBagRevision(1)==2)
assert(#calls==0)
E:Tick(0.19)
assert(#calls==0)
E:Tick(0.02)
assert(#calls==1 and calls[1].rev==2)
assert(E:HandleEvent("BAG_UPDATE_DELAYED"))
assert(E:GetInventoryRevision()==3)
for bag=0,4 do
    assert(E:GetBagRevision(bag)==(bag==1 and 3 or 1))
end
-- Optional container event with an unknown bag parameter invalidates all bags.
assert(E:HandleEvent("BAG_CONTAINER_UPDATE","unknown"))
assert(E:GetInventoryRevision()==4)
for bag=0,4 do
    assert(E:GetBagRevision(bag)==(bag==1 and 4 or 2))
end
local before=E:GetInventoryRevision()
local returned=E:RequestInventoryRefresh("soulwell_interaction")
assert(returned==before+1)
assert(E.inventoryLastReason=="soulwell_interaction")
E:Tick(0.25)
assert(#calls==2 and calls[2].rev==returned)
assert(E:HandleEvent("NOT_AN_EVENT")==false)
assert(E:GetInventoryRevision()==returned)
assert(E:Unsubscribe("inventory","it01"))
assert(E:RequestInventoryRefresh("explicit") == returned+1)
E:Flush()
assert(#calls==2)
-- Event with protected numeric parameter must never throw.
local protected=setmetatable({}, {__lt=function() error("protected") end})
assert(E:HandleEvent("BAG_UPDATE",protected))
assert(E:GetInventoryRevision()==returned+2)
print("inventory_event_revisions_mock PASS")
