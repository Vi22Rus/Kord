-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Minimal opt-in Hunter BM smoke-test profile, NOT the full Hunter rotation.
-- This profile deliberately avoids unknown aura absence, enemy counts and TTD.
local addonName, KR = ...
if not KR or not KR.RotationProfiles then return end

KR.RotationProfiles:Register("HUNTER", 1, {
    contractVersion=1,
    id="HUNTER_BM_PILOT_EXPERIMENTAL",
    version="0.1.0",
    classToken="HUNTER", specIndex=1,
    levelMin=1, levelMax=100,
    status="experimental",
    Spells={ArcaneShot=3044},
    Needs={auras={},ranges={},enemyCount=false,ttd=false,swing=false},
    Config={},
    Rules={{
        id="arcane_shot_pilot",
        type="SPELL",spell="ArcaneShot",
        category="damage",target="enemy",cast="idle",
        chargesRequired=false,mode="single",
        onUnknown="stop",reason="Experimental single-target Arcane Shot",
        -- Target existence, relation, life and range are verified by
        -- AbilityEligibility. Do not pre-block on a stale snapshot boolean;
        -- this pilot's condition has no additional decision to make.
        when=function()
            return true
        end
    }}
})
