-- Kord Rotation (c) 2026 Vi22Rus. Read-only aura presence adapter.
-- Algorithm adapted from Rotation Master Platform/cooldown_viewer.lua
-- Copyright 2018-2026 Preston A. Elder (PreZ), MIT + Attribution.
-- See THIRD_PARTY_NOTICES.md; no protected actions, no addon dependency.
local _,KR=...
KR.AuraCooldownViewer=KR.AuraCooldownViewer or {}
local V=KR.AuraCooldownViewer
local viewerNames={"BuffIconCooldownViewer","BuffBarCooldownViewer"}
local tracked={}
local idsByItem=setmetatable({},{__mode="k"})
local unitByItem=setmetatable({},{__mode="k"})
local hooked=setmetatable({},{__mode="k"})
local items={}
local function safe(value)
 local api=KR.GameAPI
 if not api or type(api.IsSafeValue)~="function" then return false end
 local ok,yes=pcall(api.IsSafeValue,api,value)
 return ok and yes==true
end
local function field(item,key)
 if type(item)~="table" then return nil end
 local ok,v=pcall(rawget,item,key)
 if ok and safe(v) then return v end
 return nil
end
local function readIDs(item)
 if idsByItem[item] then return idsByItem[item] end
 local cooldownID=field(item,"cooldownID")
 if type(cooldownID)~="number" or cooldownID<=0
     or not safe(C_CooldownViewer)
     or type(C_CooldownViewer)~="table" then return nil end
 local fn=C_CooldownViewer.GetCooldownViewerCooldownInfo
 if not safe(fn) or type(fn)~="function" then return nil end
 local ok,info=pcall(fn,cooldownID)
 if not ok or not safe(info) or type(info)~="table" then return nil end
 local set,list={},{}
 local function add(id)
  if safe(id) and type(id)=="number" and id>0
      and id==math.floor(id) and id<=99999999 and not set[id] then
   set[id]=true
   list[#list+1]=id
  end
 end
 add(field(info,"spellID"))
 add(field(info,"overrideSpellID"))
 local links=field(info,"linkedSpellIDs")
 if type(links)=="table" then
  local okWalk=pcall(function()
   for _,id in ipairs(links) do add(id) end
  end)
  if not okWalk then return nil end
 end
 if #list==0 then return nil end
 idsByItem[item]=list
 return list
end
function V:ReadItem(item)
 local ids=readIDs(item)
 if not ids then return end
 local unit=field(item,"auraDataUnit")
 if unit=="player" or unit=="target" then unitByItem[item]=unit end
 unit=unitByItem[item]
 if not unit then return end
 local ok,instance=pcall(rawget,item,"auraInstanceID")
 if not ok then return end
 -- RM uses *only* the secret bit as evidence that an instance exists:
 -- never compare/convert a protected instance ID.
 local secret=false
 if type(issecretvalue)=="function" then
  local good,yes=pcall(issecretvalue,instance)
  if not good or type(yes)~="boolean" then return end
  secret=yes
 end
 local present=secret or (safe(instance) and instance~=nil)
 for _,id in ipairs(ids) do
  tracked[id]=tracked[id] or {}
  tracked[id][unit]=present
 end
end
-- RM Core/aura_conditions.lua remembers the last readable player aura.
-- Kord keeps only independently verified observations, never infers an
-- initial negative from a hidden no-value response.
local observed={}
function V:Observe(id,present)
 if not safe(id) or type(id)~="number" or
     (present~=true and present~=false) then return end
 observed[id]=present
end
function V:GetObserved(id)
 if not safe(id) or type(id)~="number" then return nil end
 return observed[id]
end
function V:GetPresence(id,unit)
 if not safe(id) or type(id)~="number"
     or (unit~="player" and unit~="target") then return nil end
 local entry=tracked[id]
 return entry and entry[unit]
end
function V:Refresh()
 if type(InCombatLockdown)~="function" then return end
 local ok,combat=pcall(InCombatLockdown)
 if not ok or not safe(combat) or combat~=false then return end
 items={}
 for _,name in ipairs(viewerNames) do
  local viewer=type(_G)=="table" and rawget(_G,name)
  if type(viewer)=="table" and safe(viewer)
      and type(viewer.GetChildren)=="function" then
   local okChildren,children=pcall(function()
    return {viewer:GetChildren()}
   end)
   if okChildren and type(children)=="table" then
    for _,item in ipairs(children) do
     if type(item)=="table" and safe(item)
         and field(item,"cooldownID")~=nil then
      items[#items+1]=item
      if not hooked[item] and type(item.HookScript)=="function" then
       local okHook=pcall(function()
        item:HookScript("OnShow",function() V:ReadItem(item) end)
        item:HookScript("OnHide",function() V:ReadItem(item) end)
       end)
       if okHook then hooked[item]=true end
      end
      self:ReadItem(item)
     end
    end
   end
  end
 end
end
function V:Initialize()
 if self.frame then return true end
 if type(CreateFrame)~="function" then return false end
 local ok,frame=pcall(CreateFrame,"Frame")
 if not ok or not frame then return false end
 local events={"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED",
  "COOLDOWN_VIEWER_DATA_LOADED","PLAYER_TARGET_CHANGED",
  "PLAYER_SPECIALIZATION_CHANGED"}
 for _,event in ipairs(events) do pcall(frame.RegisterEvent,frame,event) end
 frame:SetScript("OnEvent",function(_,event)
  if event=="PLAYER_ENTERING_WORLD" then
   observed={}
   tracked={}
  end
  if event=="PLAYER_TARGET_CHANGED" then
   for _,record in pairs(tracked) do record.target=nil end
   for _,item in ipairs(items) do V:ReadItem(item) end
  else V:Refresh() end
 end)
 self.frame=frame
 return true
end
V:Initialize()
