-- Kord Rotation stage 2.4: isolated mock regression.
-- Run from repository root: texlua tests/stage_02_04_spell_catalogue.lua
local KR={}
local now=100
GetTime=function() return now end
BOOKTYPE_SPELL="spell"
local revision=1
local slots={
    {id=101,name="Strike",rank="Rank 1",icon=1101},
    {id=102,name="Strike",rank="Rank 2",icon=1102},
    {id=201,name="Guard",rank=nil,icon=1201},
}
GetNumSpellTabs=function() return 1 end
GetSpellTabInfo=function() return "General",nil,0,#slots end
GetSpellBookItemInfo=function(slot) return "SPELL",slots[slot].id end
GetSpellBookItemName=function(slot) return slots[slot].name,slots[slot].rank end
GetSpellBookItemTexture=function(slot) return slots[slot].icon end
GetSpellInfo=function(id) return "Fallback " .. id end
GetSpellTexture=function(id) return 1000+id end
local frames={}
CreateFrame=function()
    local frame={scripts={}}
    function frame:RegisterEvent() end
    function frame:SetScript(event,fn) self.scripts[event]=fn end
    frames[#frames+1]=frame
    return frame
end
issecretvalue=function(x) return x=="SECRET" end
local function load(path)
    local fn=assert(loadfile("KordRotation/"..path))
    fn("KordRotation",KR)
end
load("Core/GameAPI.lua")
load("Core/EventBus.lua")
load("Core/SpellCatalogue.lua")
local function check(v,expected,msg)
    if v~=expected then error((msg or "failed")..": "..tostring(v).." vs "..tostring(expected),2) end
end
check(KR.EventBus:Initialize(),true)
check(KR.SpellCatalogue:Initialize(),true)
local s=KR.SpellCatalogue:Read()
check(s.status,"ready")
check(#s.entries,3)
check(s.entries[1].id,201) -- alphabetical Guard before Strike
check(s.entries[2].id,101)
check(s.entries[3].id,102)
check(s.entries[2].rank,"Rank 1")
check(s.entries[3].rankNumber,2)
check(s.entries[3].displayName,"Strike (Rank 2)")
check(KR.SpellCatalogue:Read().revision,s.revision,"cached")
s.entries[1].name="Corrupt"
check(KR.SpellCatalogue:Read().entries[1].name,"Guard","isolated copy")
-- Learning and unlearning spells invalidates via the spellbook revision.
slots[4]={id=300,name="New",icon=1300}
KR.EventBus:HandleEvent("SPELLS_CHANGED")
local changed=KR.SpellCatalogue:GetSnapshot()
check(#changed.entries,4)
check(changed.revision,s.revision+1)
table.remove(slots,4)
KR.EventBus:HandleEvent("PLAYER_TALENT_UPDATE")
check(#KR.SpellCatalogue:GetSnapshot().entries,3)
-- Duplicate slots for the same spell ID do not duplicate entries.
slots[4]={id=101,name="Strike",rank="Rank 1"}
KR.EventBus:HandleEvent("SKILL_LINES_CHANGED")
check(#KR.SpellCatalogue:GetSnapshot().entries,3)
table.remove(slots,4)
-- Unsupported response invalidates whole catalogue, never partial output.
GetSpellBookItemInfo=function(slot)
    if slot==2 then error("protected") end
    return "SPELL",slots[slot].id
end
KR.SpellCatalogue:Invalidate("api_failure")
local broken=KR.SpellCatalogue:Read()
check(broken.status,"unavailable")
check(#broken.entries,0)
-- Recover after API restoration.
GetSpellBookItemInfo=function(slot) return "SPELL",slots[slot].id end
KR.SpellCatalogue:Invalidate("recover")
check(KR.SpellCatalogue:Read().status,"ready")
-- The modern path is a genuine alternative, not a synthetic spell list.
GetNumSpellTabs=nil
Enum={SpellBookSpellBank={Player=0},SpellBookItemType={Spell=1}}
C_SpellBook={}
C_SpellBook.GetNumSpellBookSkillLines=function() return 1 end
C_SpellBook.GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=1} end
C_SpellBook.GetSpellBookItemInfo=function() return {itemType=1,spellID=999} end
C_SpellBook.GetSpellBookItemName=function() return "Modern" end
C_SpellBook.GetSpellBookItemTexture=function() return 13579 end
KR.SpellCatalogue:Invalidate("new_client")
local modern=KR.SpellCatalogue:Read()
check(modern.status,"ready")
check(modern.method,"modern")
check(modern.entries[1].id,999)
-- Unknown bank must fail closed.
Enum.SpellBookSpellBank={}
KR.SpellCatalogue:Invalidate("bank_missing")
local unavailable=KR.SpellCatalogue:Read()
check(unavailable.status,"unavailable")
check(#unavailable.entries,0)
print("PASS stage 2.4 spell catalogue mock scenarios")
