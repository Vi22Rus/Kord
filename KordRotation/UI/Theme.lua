-- Kord Rotation (c) 2026 Vi22Rus. All rights reserved.
-- Licensed for personal use under the repository LICENSE; no redistribution or derivatives without permission.
-- Retain this notice and LICENSE. Missing/altered LICENSE does not create permission or silently change existing rights.

local addonName, KR = ...
KR = KR or {}
KR.UI = KR.UI or {}

KR.UI.colors = {
    background = { 0.043, 0.067, 0.105, 0.985 },
    sidebar = { 0.055, 0.092, 0.137, 1 },
    panel = { 0.075, 0.113, 0.170, 1 },
    line = { 0.165, 0.259, 0.357, 1 },
    cyan = { 0.06, 0.79, 0.98, 1 },
    text = { 0.91, 0.94, 0.99, 1 },
    muted = { 0.60, 0.68, 0.79, 1 },
}

local function paint(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

function KR.UI:Background(frame, color)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints(frame)
    paint(texture, color)
    return texture
end

-- License notice (2/3): All original Modern Dark UI styling is copyrighted by Vi22Rus.
-- Do not redistribute these source files without authorization (see LICENSE).
function KR.UI:Border(frame, color, thickness)
    local parts = {}
    local offsets = {
        { "TOPLEFT", "TOPRIGHT", 0, -1 },
        { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 1 },
    }
    for index = 1, 4 do
        local texture = frame:CreateTexture(nil, "BORDER")
        paint(texture, color)
        if index <= 2 then
            local o = offsets[index]
            texture:SetPoint(o[1], frame, o[1], 0, o[3])
            texture:SetPoint(o[2], frame, o[2], 0, o[3])
            texture:SetHeight(thickness or 1)
        else
            texture:SetPoint(index == 3 and "TOPLEFT" or "TOPRIGHT", frame,
                index == 3 and "TOPLEFT" or "TOPRIGHT", index == 3 and 1 or -1, 0)
            texture:SetPoint(index == 3 and "BOTTOMLEFT" or "BOTTOMRIGHT", frame,
                index == 3 and "BOTTOMLEFT" or "BOTTOMRIGHT", index == 3 and 1 or -1, 0)
            texture:SetWidth(thickness or 1)
        end
        parts[#parts + 1] = texture
    end
    return parts
end

function KR.UI:Label(parent, text, size, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(size == "title" and "GameFontNormalLarge" or "GameFontHighlight")
    label:SetText(text or "")
    if color then label:SetTextColor(color[1], color[2], color[3], color[4]) end
    label:SetJustifyH("LEFT")
    return label
end

-- Kord Rotation copyright notice (3/3): see LICENSE in repository root.
-- Do not remove attribution or redistribute modified builds without authorization.
