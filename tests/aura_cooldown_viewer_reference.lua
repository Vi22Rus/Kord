-- Rotation Master Platform/cooldown_viewer.lua port regression (Lua 5.1).
-- Tests Blizzard Cooldown Manager presence as plain bit, not secret value.
local KR={}
KR.GameAPI={IsSafeValue=function(_,v) return v~="SECRET" end}
local events={}
local item={cooldownID=11,auraDataUnit="player",auraInstanceID="SECRET",handlers={}}
function item:HookScript(name,fn) self.handlers[name]=fn end
local viewer={}
function viewer:GetChildren() return item end
BuffIconCooldownViewer=viewer
C_CooldownViewer={GetCooldownViewerCooldownInfo=function(id)
 if id~=11 then return nil end
 return {spellID=13165,overrideSpellID=14318,linkedSpellIDs={25296}}
end}
InCombatLockdown=function() return false end
issecretvalue=function(v) return v=="SECRET" end
CreateFrame=function()
 local f={}
 function f:RegisterEvent(event) events[event]=true end
 function f:SetScript(key,fn) self[key]=fn end
 return f
end
local loadModule1=assert(loadfile("KordRotation/Core/AuraCooldownViewer.lua"))
loadModule1("KordRotation",KR)
local V=KR.AuraCooldownViewer
assert(V and V.frame,"event-driven viewer initialized")
assert(events.COOLDOWN_VIEWER_DATA_LOADED,"refresh event registered")
V:Refresh()
assert(V:GetPresence(13165,"player")==true,
 "secret auraInstanceID is plain presence=true")
assert(V:GetPresence(14318,"player")==true,"override ID mapped")
assert(V:GetPresence(25296,"player")==true,"linked ID mapped")
assert(V:GetPresence(13163,"player")==nil,"untracked aura unknown")
item.auraInstanceID=nil
item.handlers.OnHide()
assert(V:GetPresence(13165,"player")==false,
 "nonsecret nil instance means tracked buff absent")
V:Observe(13165,false)
assert(V:GetObserved(13165)==false,"verified visible absence tracked")
V:Observe(13165,true)
assert(V:GetObserved(13165)==true,"positive supersedes negative")
-- Do not inspect child frames while combat-lockdown prevents it.
InCombatLockdown=function() return true end
V.frame.OnEvent(V.frame,"PLAYER_ENTERING_WORLD")
assert(V:GetObserved(13165)==nil,"world transition clears observation")
V:Refresh()
assert(V:GetPresence(13165,"player")==nil,
 "world transition cleared stale viewer cache and combat denies refresh")
print("PASS Rotation Master Cooldown Viewer aura presence port")
