-- the data for LibTalentTree resides in LibTalentTree-1.0_data.lua

local MAJOR, MINOR = "LibTalentTree-0.1", 2
--- @class LibTalentTree
local LibTalentTree = LibStub:NewLibrary(MAJOR, MINOR)

if not LibTalentTree then return end -- No upgrade needed

LibTalentTree.MINOR = MINOR

local deepCopy;
function deepCopy(original)
    local originalType = type(original);
    local copy;
    if (originalType == 'table') then
        copy = {};
        for key, value in next, original, nil do
            copy[deepCopy(key)] = deepCopy(value);
        end
        setmetatable(copy, deepCopy(getmetatable(original)));
    else
        copy = original;
    end

    return copy;
end

---@alias edgeType
---| 0 # VisualOnly
---| 1 # DeprecatedRankConnection
---| 2 # SufficientForAvailability
---| 3 # RequiredForAvailability
---| 4 # MutuallyExclusive
---| 5 # DeprecatedSelectionOption

---@alias visualStyle
---| 0 # None
---| 1 # Straight

---@alias nodeType
---| 0 # single
---| 1 # Tiered
---| 2 # Selection

---@alias nodeFlags
---| 1 # ShowMultipleIcons

---@class visibleEdge
---@field type edgeType
---@field visualStyle visualStyle
---@field targetNode number # TraitNodeID

---@class libNodeInfo
---@field ID: number # TraitNodeID
---@field posX: number # some class trees have a global offset
---@field posY: number # some class trees have a global offset
---@field type: nodeType
---@field maxRanks: number
---@field flags: nodeFlags
---@field groupIDs: number[]
---@field visibleEdges: visibleEdge[] # The order does not always match C_Traits
---@field specInfo: table<number, number[]> # specId: conditionType[] see Enum.TraitConditionType
---@field isClassNode: boolean
---@field conditionIDs: number[]
---@field entryIDs: number[] # TraitEntryID - generally, choice nodes will have 2, otherwise there's just 1

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( libNodeInfo | nil )
function LibTalentTree:GetLibNodeInfo(treeId, nodeId)
    return self.nodeData[treeId] and self.nodeData[treeId][nodeId] and deepCopy(self.nodeData[treeId][nodeId]) or nil;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( libNodeInfo ) # libNodeInfo is enriched and overwritten by C_Traits information if possible
function LibTalentTree:GetNodeInfo(treeId, nodeId)
    local cNodeInfo = C_Traits.GetNodeInfo(C_ClassTalents.GetActiveConfigID(), nodeId);
    local libNodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    if (not libNodeInfo) then return cNodeInfo; end

    if cNodeInfo.ID == nodeId then
        cNodeInfo.specInfo = libNodeInfo.specInfo;

        return cNodeInfo;
    end

    return Mixin(cNodeInfo, libNodeInfo);
end

--- @public
--- @param class (string | number) # ClassID or ClassFilename - e.g. "DEATHKNIGHT" or 6 - See https://wowpedia.fandom.com/wiki/ClassId
--- @return ( number | nil ) # TraitTreeID
function LibTalentTree:GetClassTreeId(class)
    local classId = self.classFileMap[class] or class;

    return self.classTreeMap[classId] or nil;
end

--- @public
--- @param specId number # See https://wowpedia.fandom.com/wiki/SpecializationID
--- @param nodeId number # TraitNodeID
--- @return boolean # whether the node is visible for the given spec
function LibTalentTree:IsNodeVisibleForSpec(specId, nodeId)
    local class = select(6, GetSpecializationInfoByID(specId));
    local treeId = self:GetClassTreeId(class);
    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    if not nodeInfo then return false; end

    if (nodeInfo.specInfo[specId]) then
        for _, conditionType in pairs(nodeInfo.specInfo[specId]) do
            if (conditionType == Enum.TraitConditionType.Visible or conditionType == Enum.TraitConditionType.Granted) then
                return true;
            end
        end
    end
    if (nodeInfo.specInfo[0]) then
        for _, conditionType in pairs(nodeInfo.specInfo[0]) do
            if (conditionType == Enum.TraitConditionType.Visible or conditionType == Enum.TraitConditionType.Granted) then
                return true;
            end
        end
    end
    for id, conditionTypes in pairs(nodeInfo.specInfo) do
        if (id ~= specId) then
            for _, conditionType in pairs(conditionTypes) do
                if (conditionType == Enum.TraitConditionType.Visible) then
                    return false
                end
            end
        end
    end

    return true;
end

--- @public
--- @param specId number # See https://wowpedia.fandom.com/wiki/SpecializationID
--- @param nodeId number # TraitNodeID
--- @return boolean # whether the node is granted by default for the given spec
function LibTalentTree:IsNodeGrantedForSpec(specId, nodeId)
    local class = select(6, GetSpecializationInfoByID(specId));
    local treeId = self:GetClassTreeId(class);
    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    if (nodeInfo and nodeInfo.specInfo[specId]) then
        for _, conditionType in pairs(nodeInfo.specInfo[specId]) do
            if (conditionType == Enum.TraitConditionType.Granted) then
                return true;
            end
        end
    end

    return false;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( number|nil, number|nil) # posX, posY - some trees have a global offset
function LibTalentTree:GetNodePosition(treeId, nodeId)
    local nodeInfo = self:GetNodeInfo(treeId, nodeId);
    if (not nodeInfo) then return nil, nil; end

    return nodeInfo.posX, nodeInfo.posY;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( nil | visibleEdge[] ) # The order might not match C_Traits
function LibTalentTree:GetNodeEdges(treeId, nodeId)
    local nodeInfo = self:GetNodeInfo(treeId, nodeId);
    if (not nodeInfo) then return nil; end

    return nodeInfo.visibleEdges;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( boolean | nil ) # true if the node is a class node, false for spec nodes, nil if unknown
function LibTalentTree:IsClassNode(treeId, nodeId)
    local nodeInfo = self:GetNodeInfo(treeId, nodeId);
    if (not nodeInfo) then return nil; end

    return nodeInfo.isClassNode;
end
