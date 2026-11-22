-- Kord Rotation (c) 2026 Vi22Rus. Reference: Sonah/Core/Atoms/Auras.lua
-- Read-only evidence from the player's own observed casts. Never casts spells.
-- Only a proven, bounded positive history is published. Missing history is
-- UNKNOWN; do not invent a negative aura observation during secret combat.
local _,KR=...
KR.AuraEvidence=KR.AuraEvidence or {}
local T=KR.AuraEvidence
local persistent={[13165]=true,[13163]=true,[5118]=true,[13159]=true}
local MAX_AGE=3600 -- Sonah persistent-aspect bounded projection (seconds)
local function safe(v)
 local api=KR.GameAPI
 return api and type(api.IsSafeValue)=="function" and api:IsSafeValue(v)
end
local function clock()
 local api=KR.GameAPI
 if not api then return nil end
 local now=api:Read("GetTime","number")
 return now.status=="READY" and now.value or nil
end
function T:ObserveCast(unit,id)
 if unit~="player" or not safe(id) or type(id)~="number"
     or not persistent[id] then return end
 local t=clock()
 if not t then return end
 self.seen=self.seen or {}
 -- Aspects are mutually exclusive. Another observed successful aspect
 -- invalidates the older positive record, but does not by itself prove
 -- any other specific aura is absent.
 for key in pairs(persistent) do self.seen[key]=nil end
 self.seen[id]=t
 if KR.EventBus then KR.EventBus:MarkDirty("auras") end
end
function T:Read(id)
 if not persistent[id] then return nil end
 local now=clock()
 local stamped=self.seen and self.seen[id]
 if not stamped or not now or now<stamped or now-stamped>MAX_AGE then
     return nil
 end
 -- Positive cast observation, not a claim of an exact live aura duration.
 return {status="READY",value=true,source="AuraEvidence.own_cast"}
end
function T:Reset()
 self.seen={}
 if KR.EventBus then KR.EventBus:MarkDirty("auras") end
end
function T:Initialize()
 if self.frame then return true end
 if type(CreateFrame)~="function" then return false end
 local frame=CreateFrame("Frame")
 for _,event in ipairs({"UNIT_SPELLCAST_SUCCEEDED",
        "PLAYER_ENTERING_WORLD","PLAYER_DEAD"}) do
  pcall(frame.RegisterEvent,frame,event)
 end
 frame:SetScript("OnEvent",function(_,event,unit,castGUID,spellID)
  if event=="UNIT_SPELLCAST_SUCCEEDED" then
   T:ObserveCast(unit,spellID)
  else T:Reset() end
 end)
 self.frame=frame
 return true
end
-- Initializes independently of the rotation display and DevTools.
T:Initialize()
