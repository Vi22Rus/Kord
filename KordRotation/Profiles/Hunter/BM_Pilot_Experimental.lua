-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Opt-in single-spell Hunter BM pilot, NOT the full rotation.
-- Arcane Shot has eight distinct spell IDs on WoW Forever.
local addonName,KR=...
if not KR or not KR.RotationProfiles then return end

local ranks={
    {name="ArcaneShotR8",id=14287,level=60},
    {name="ArcaneShotR7",id=14286,level=52},
    {name="ArcaneShotR6",id=14285,level=44},
    {name="ArcaneShotR5",id=14284,level=36},
    {name="ArcaneShotR4",id=14283,level=28},
    {name="ArcaneShotR3",id=14282,level=20},
    {name="ArcaneShotR2",id=14281,level=12},
    {name="ArcaneShotR1",id=3044,level=6},
}
local spells,rules={},{}
for index,rank in ipairs(ranks) do
    local name,id,level=rank.name,rank.id,rank.level
    -- Lower ranks are not fallback casts when a higher rank was learned.
    -- Freeze the preceding (higher) ranks for each callback individually.
    local higher={}
    for j=1,index-1 do
        higher[#higher+1]={id=ranks[j].id,level=ranks[j].level}
    end
    spells[name]=id
    rules[#rules+1]={
        id="arcane_shot_rank_"..tostring(level),
        type="SPELL",spell=name,category="damage",
        target="enemy",cast="idle",chargesRequired=false,
        mode="single",onUnknown="stop",
        reason="Experimental Arcane Shot, learned rank only",
        when=function(S)
            -- Level gates only avoid querying ranks above the player's level.
            -- Do NOT infer that a rank was actually trained from level alone.
            local eligibleLevel=S:ge("player.level",level)
            if eligibleLevel~=true then return eligibleLevel end
            -- Prefer the highest TRAINED rank. Never recommend lower rank
            -- merely because the highest one is casting/on cooldown.
            -- For a possibly learned higher rank whose fact is UNKNOWN,
            -- stop conservatively rather than silently downrank.
            for _,candidate in ipairs(higher) do
                local highLevel=S:ge("player.level",candidate.level)
                if highLevel==nil then return nil end
                if highLevel==true then
                    local highKnown=S:spellFact(candidate.id,"known")
                    if highKnown==true then return false end
                    if highKnown==nil then return nil end
                end
            end
            local learned=S:spellFact(id,"known")
            if learned~=true then return learned end
            return S:is("target.exists")
        end
    }
end
KR.RotationProfiles:Register("HUNTER",1,{
    contractVersion=1,
    id="HUNTER_BM_PILOT_EXPERIMENTAL",
    version="0.1.2",
    classToken="HUNTER",specIndex=1,
    levelMin=61,levelMax=100,status="experimental",
    Spells=spells,
    Needs={auras={},ranges={},enemyCount=false,ttd=false,swing=false},
    Config={},Rules=rules
})
