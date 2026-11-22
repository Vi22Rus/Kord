-- Kord Rotation (c) 2026 Vi22Rus. Reference: Sonah/Core/Atoms/Auras.lua
-- Read-only evidence from the player's own observed casts. Never casts spells.
-- Only a proven, bounded positive history is published. Missing history is
-- UNKNOWN; do not invent a negative aura observation during secret combat.
local _,KR=...
KR.AuraEvidence=KR.AuraEvidence or {}
local T=KR.AuraEvidence
-- Sonah/Classes/Hunter.lua: travel aspect consumed by a combat aspect.
-- Families include learned ranks; the cast spellID and aura spellID may differ.
local families={
 [13165]="hawk",[14318]="hawk",[14319]="hawk",[14320]="hawk",
 [14321]="hawk",[14322]="hawk",[25296]="hawk",
 [13163]="monkey",
 [5118]="cheetah",[13159]="pack",
 [13161]="beast",[1299445]="beast",[1299446]="beast",[1299447]="beast",
 [20043]="wild",[20190]="wild"
}
local travel={cheetah=true,pack=true}
local MAX_AGE=3600
local LIVE_TRAVEL_MAX_AGE=120
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
local function remembered(self,family,window)
 local t=clock()
 local stamp=self.seen and self.seen[family]
 if not t or not stamp or t<stamp.t or t-stamp.t>window then return false end
 return true
end
function T:ObserveCast(unit,id)
 if unit~="player" or not safe(id) or type(id)~="number" then return end
 local family=families[id]
 if not family then return end
 local t=clock()
 if not t then return end
 -- Sonah C.consumed: a successfully cast combat aspect consumes an
 -- earlier observed Cheetah/Pack, including when auras become secret.
 self.seen={[family]={t=t,source="own_cast"}}
 if KR.EventBus then KR.EventBus:MarkDirty("auras") end
end
function T:ObserveLive(id)
 if not safe(id) or type(id)~="number" then return end
 local family=families[id]
 if not travel[family] then return end
 local t=clock()
 if not t then return end
 self.seen=self.seen or {}
 -- Only store a positive, ID-verified observation, not a nil lookup.
 -- Do not erase a more recent own combat-aspect cast with a stale read.
 for key in pairs(self.seen) do
  if not travel[key] then return end
 end
 self.seen={[family]={t=t,source="verified_live"}}
end
function T:Read(id)
 local family=families[id]
 if not family or not remembered(self,family,MAX_AGE) then return nil end
 return {status="READY",value=true,source="AuraEvidence.own_or_live_positive"}
end
function T:ReadTravel()
 local now=clock()
 if not now then return nil end
 for family in pairs(travel) do
  local rec=self.seen and self.seen[family]
  local window=rec and rec.source=="verified_live"
      and LIVE_TRAVEL_MAX_AGE or MAX_AGE
  if remembered(self,family,window) then
   return {status="READY",value=true,
       source="AuraEvidence.travel_not_consumed"}
  end
 end
 return nil
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
