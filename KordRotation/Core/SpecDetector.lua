-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use only under the root LICENSE; unauthorized redistribution prohibited.
-- Copyright notices do not restrict lawful source review or external AI analysis.

local addonName, KR = ...
KR.SpecDetector = KR.SpecDetector or {}

-- Explicit class/tree labels to avoid locale-dependent profile IDs.
local TREES = {
    WARRIOR={"Оружие","Неистовство","Защита"},
    PALADIN={"Свет","Защита","Воздаяние"},
    HUNTER={"Повелитель зверей","Стрельба","Выживание"},
    ROGUE={"Ликвидация","Бой","Скрытность"},
    PRIEST={"Послушание","Свет","Тьма"},
    SHAMAN={"Стихии","Совершенствование","Исцеление"},
    MAGE={"Тайная магия","Огонь","Лёд"},
    WARLOCK={"Колдовство","Демонология","Разрушение"},
    DRUID={"Баланс","Сила зверя","Исцеление"},
}
local KEYS = {"TREE_1","TREE_2","TREE_3"}

local function pick(counts, previousIndex)
    local max = math.max(counts[1], counts[2], counts[3])
    if max == 0 then return nil, "no_points" end
    local tied = {}
    for i=1,3 do if counts[i] == max then tied[#tied+1] = i end end
    if #tied == 1 then return tied[1], "largest_tree" end
    for _, i in ipairs(tied) do
        if i == previousIndex then return i, "previous_on_tie" end
    end
    return nil, "unresolved_tie"
end

-- License notice (2/3): protected source under LICENSE, with no hidden DRM.
-- Never silently turn an ambiguous talent map into a combat recommendation profile.
function KR:RefreshCharacter(reason)
    local character = self.Character:Read()
    local talents = self.Talents:Read()
    local previous = self.characterState
    local result = {
        character=character, talents=talents,
        classToken=character.classToken, className=character.className,
        level=character.level, index=nil, specName=nil, profileID=nil,
        status="unavailable", reason=talents.reason, detection=nil,
        lastTrigger=reason or "unknown",
    }
    local labels = TREES[character.classToken]
    if character.status ~= "confirmed" or not labels then
        result.reason = "unsupported_or_missing_class"
    elseif talents.status == "ready" and talents.counts then
        local was = previous and previous.classToken == character.classToken and previous.index or nil
        local i, method = pick(talents.counts, was)
        result.detection = method
        if i then
            result.index=i
            result.specName=labels[i]
            result.profileID=character.classToken.."_"..KEYS[i]
            result.status=(talents.method=="header_groups") and "confirmed" or "provisional"
            result.reason=result.status=="provisional" and "position_mapping_requires_verification" or nil
        else
            result.status="undetermined"
            result.reason=method
        end
    end
    self.characterState = result
    if self.RefreshCharacterUI then self:RefreshCharacterUI() end
    return result
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Preserve attribution in authorized copies.
