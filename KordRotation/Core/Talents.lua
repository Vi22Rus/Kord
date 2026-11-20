-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Personal use only under the root LICENSE; unauthorized redistribution prohibited.
-- Copyright notices do not restrict lawful source review or external AI analysis.

local addonName, KR = ...
KR.Talents = KR.Talents or {}

local function plainNumber(value)
    return type(value) == "number" and value or nil
end

local function guarded(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function rankOf(node)
    return plainNumber(node.activeRank) or plainNumber(node.currentRank)
        or plainNumber(node.ranksPurchased)
end

-- Nodes within a single Forever config can occupy three talent SECTIONS.
-- Group metadata is preferred; X-gap segmentation is a provisional fallback,
-- never a proof of correct class-tree assignment.
local function byX(nodes)
    local columns, keys = {}, {}
    for _, node in ipairs(nodes) do
        local x = node.x
        if not columns[x] then columns[x] = {}; keys[#keys+1] = x end
        columns[x][#columns[x]+1] = node
    end
    table.sort(keys)
    if #keys < 3 then return nil, "not_enough_columns" end
    local gaps = {}
    for i = 2, #keys do gaps[#gaps+1] = { at = i, width = keys[i] - keys[i-1] } end
    table.sort(gaps, function(a,b)
        if a.width ~= b.width then return a.width > b.width end
        return a.at < b.at
    end)
    if #gaps < 2 or gaps[2].width <= 0 then return nil, "missing_column_gaps" end
    local a, b = gaps[1].at, gaps[2].at
    if a > b then a,b = b,a end
    local result = {{},{},{}}
    for index, x in ipairs(keys) do
        local section = (index < a and 1) or (index < b and 2) or 3
        for _, node in ipairs(columns[x]) do
            result[section][#result[section]+1] = node
        end
    end
    for i=1,3 do if #result[i] == 0 then return nil, "empty_section" end end
    return result, nil
end

local function groupSections(nodes, groupNames)
    -- Assign only when every node belongs to exactly one recognized tree header.
    local groups = {}
    for _, node in ipairs(nodes) do
        local candidates = {}
        for _, gid in ipairs(node.groups or {}) do
            if groupNames[gid] then candidates[#candidates+1] = gid end
        end
        if #candidates ~= 1 then return nil end
        local id = candidates[1]
        local g = groups[id]
        if not g then g = { id = id, name = groupNames[id], sumX = 0, nodes = {} }; groups[id] = g end
        g.nodes[#g.nodes+1] = node
        g.sumX = g.sumX + node.x
    end
    local sorted = {}
    for _, g in pairs(groups) do sorted[#sorted+1] = g end
    if #sorted ~= 3 then return nil end
    table.sort(sorted, function(a,b)
        local x, y = a.sumX / #a.nodes, b.sumX / #b.nodes
        if x ~= y then return x < y end
        return a.id < b.id
    end)
    return {sorted[1].nodes, sorted[2].nodes, sorted[3].nodes},
           {sorted[1].name, sorted[2].name, sorted[3].name}
end

-- License notice (2/3): original talent adapter is protected by LICENSE.
-- A missing API / uncertain section map must produce a diagnostic status, not a guessed spec.
function KR.Talents:Read()
    local result = {
        status = "unavailable", reason = "traits_api_missing",
        counts = nil, names = nil, configID = nil, method = nil,
    }
    if type(C_Traits) ~= "table" or type(C_Traits.GetConfigInfo) ~= "function"
        or type(C_Traits.GetTreeNodes) ~= "function"
        or type(C_Traits.GetNodeInfo) ~= "function" then return result end

    local configID
    if type(C_ClassTalents) == "table" then
        configID = guarded(C_ClassTalents.GetActiveConfigID)
    end
    if not plainNumber(configID) and type(C_SpecializationInfo) == "table" then
        local group = guarded(C_SpecializationInfo.GetActiveSpecGroup)
        if plainNumber(group) then
            configID = guarded(C_SpecializationInfo.GetCombatConfigIDForSpecGroup, group)
        end
    end
    if not plainNumber(configID) then result.reason = "active_config_missing"; return result end
    result.configID = configID

    local config = guarded(C_Traits.GetConfigInfo, configID)
    if type(config) ~= "table" or type(config.treeIDs) ~= "table" then
        result.reason = "tree_config_unavailable"; return result
    end
    local nodes, groupNames = {}, {}
    local seen = {}
    for _, treeID in ipairs(config.treeIDs) do
        if plainNumber(treeID) then
            local displayInfos = guarded(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
            if type(displayInfos) == "table" then
                for _, info in ipairs(displayInfos) do
                    if type(info) == "table" and plainNumber(info.groupID)
                        and type(info.displayName) == "string" then
                        groupNames[info.groupID] = info.displayName
                    end
                end
            end
            local ids = guarded(C_Traits.GetTreeNodes, treeID)
            if type(ids) == "table" then
                for _, nodeID in ipairs(ids) do
                    if plainNumber(nodeID) and not seen[nodeID] then
                        seen[nodeID] = true
                        local node = guarded(C_Traits.GetNodeInfo, configID, nodeID)
                        if type(node) == "table" and node.isVisible ~= false then
                            local x, y = plainNumber(node.posX), plainNumber(node.posY)
                            local rank = rankOf(node)
                            if x and y and x <= 20000 and y <= 10000 then
                                -- Rank nil means API cannot be trusted; a zero rank is valid.
                                if rank == nil or rank < 0 then
                                    result.reason = "rank_unavailable"; return result
                                end
                                nodes[#nodes+1] = {
                                    x=x, y=y, rank=rank,
                                    groups=type(node.groupIDs) == "table" and node.groupIDs or {},
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    if #nodes == 0 then result.reason = "no_visible_nodes"; return result end

    local sections, names = groupSections(nodes, groupNames)
    if sections then result.method = "header_groups"
    else
        sections = byX(nodes)
        if sections then result.method = "position_fallback" end
    end
    if not sections then result.reason = "three_sections_unresolved"; return result end

    result.counts = {0,0,0}
    result.names = names
    for i=1,3 do
        for _, node in ipairs(sections[i]) do result.counts[i] = result.counts[i] + node.rank end
    end
    result.status = "ready"
    result.reason = nil
    return result
end

-- Copyright notice (3/3): (c) 2026 Vi22Rus; see root LICENSE.
-- Preserve attribution in authorized copies.
