-- the data for LibTalentTree resides in LibTalentTree-1.0_data.lua

local MAJOR, MINOR = "LibTalentTree-1.0", 1
--- @class LibTalentTree
local LibTalentTree = LibStub:NewLibrary(MAJOR, MINOR)

if not LibTalentTree then return end -- No upgrade needed

LibTalentTree.dataVersion = 0 -- overwritten in LibTalentTree-1.0_data.lua

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
---| 2 # NeverPurchasable
---| 4 # TestPositionLocked
---| 8 # TestGridPositioned

---@class visibleEdge
---@field type edgeType # see Enum.TraitNodeEdgeType
---@field visualStyle visualStyle # see Enum.TraitEdgeVisualStyle
---@field targetNode number # TraitNodeID

---@class libNodeInfo
---@field ID: number # TraitNodeID
---@field posX: number
---@field posY: number
---@field type: nodeType # see Enum.TraitNodeType
---@field maxRanks: number
---@field flags: nodeFlags # see Enum.TraitNodeFlag
---@field groupIDs: number[]
---@field visibleEdges: visibleEdge[] # The order does not always match C_Traits
---@field conditionIDs: number[]
---@field entryIDs: number[] # TraitEntryID - generally, choice nodes will have 2, otherwise there's just 1
---@field specInfo: table<number, number[]> # specId: conditionType[] see Enum.TraitConditionType
---@field isClassNode: boolean

---@class gateInfo
---@field topLeftNodeID number # TraitNodeID - the node that is the top left corner of the gate
---@field conditionID number # TraitConditionID
---@field spentAmountRequired number # the total amount of currency required to unlock the gate
---@field traitCurrencyID number # TraitCurrencyID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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


--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( libNodeInfo | nil )
function LibTalentTree:GetLibNodeInfo(treeId, nodeId)
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local nodeInfo = self.nodeData[treeId] and self.nodeData[treeId][nodeId] and deepCopy(self.nodeData[treeId][nodeId]) or nil;
    if (nodeInfo) then nodeInfo.ID = nodeId; end

    return nodeInfo;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( libNodeInfo ) # libNodeInfo is enriched and overwritten by C_Traits information if possible
function LibTalentTree:GetNodeInfo(treeId, nodeId)
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local cNodeInfo = C_Traits.GetNodeInfo(C_ClassTalents.GetActiveConfigID(), nodeId);
    local libNodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    if (not libNodeInfo) then return cNodeInfo; end

    if cNodeInfo.ID == nodeId then
        cNodeInfo.specInfo = libNodeInfo.specInfo;
        cNodeInfo.isClassNode = libNodeInfo.isClassNode;

        return cNodeInfo;
    end

    return Mixin(cNodeInfo, libNodeInfo);
end

--- @public
--- @param class (string | number) # ClassID or ClassFilename - e.g. "DEATHKNIGHT" or 6 - See https://wowpedia.fandom.com/wiki/ClassId
--- @return ( number | nil ) # TraitTreeID
function LibTalentTree:GetClassTreeId(class)
    assert(type(class) == 'string' or type(class) == 'number', 'class must be a string or number');

    local classId = self.classFileMap[class] or class;

    return self.classTreeMap[classId] or nil;
end

--- @public
--- @param specId number # See https://wowpedia.fandom.com/wiki/SpecializationID
--- @param nodeId number # TraitNodeID
--- @return boolean # whether the node is visible for the given spec
function LibTalentTree:IsNodeVisibleForSpec(specId, nodeId)
    assert(type(specId) == 'number', 'specId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local class = LibTalentTree.specMap[specId];
    assert(class, 'Unknown specId: ' .. specId);

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
    assert(type(specId) == 'number', 'specId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local class = LibTalentTree.specMap[specId];
    assert(class, 'Unknown specId: ' .. specId);

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
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);
    if (not nodeInfo) then return nil, nil; end

    return nodeInfo.posX, nodeInfo.posY;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( nil | visibleEdge[] ) # The order might not match C_Traits
function LibTalentTree:GetNodeEdges(treeId, nodeId)
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);
    if (not nodeInfo) then return nil; end

    return nodeInfo.visibleEdges;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( boolean | nil ) # true if the node is a class node, false for spec nodes, nil if unknown
function LibTalentTree:IsClassNode(treeId, nodeId)
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);
    if (not nodeInfo) then return nil; end

    return nodeInfo.isClassNode;
end

local gateCache = {}
local roundingFactor = 100;
local function round(coordinate)
    return math.floor((coordinate / roundingFactor) + 0.5) * roundingFactor;
end

--- @public
--- @param specId number # See https://wowpedia.fandom.com/wiki/SpecializationID
--- @return ( gateInfo[] ) # list of gates for the given spec, sorted by spending required
function LibTalentTree:GetGates(specId)
    assert(type(specId) == 'number', 'specId must be a number');

    if (gateCache[specId]) then return deepCopy(gateCache[specId]); end
    local class = LibTalentTree.specMap[specId];
    assert(class, 'Unknown specId: ' .. specId);

    local treeId = self:GetClassTreeId(class);
    local gates = {};

    local nodesByConditions = {};
    local conditions = self.gateData[treeId];

    for nodeId, nodeInfo in pairs(self.nodeData[treeId]) do
        if (#nodeInfo.conditionIDs > 0 and self:IsNodeVisibleForSpec(specId, nodeId)) then
            for _, conditionId in pairs(nodeInfo.conditionIDs) do
                if conditions[conditionId] then
                    nodesByConditions[conditionId] = nodesByConditions[conditionId] or {};
                    nodesByConditions[conditionId][nodeId] = nodeInfo;
                end
            end
        end
    end

    for conditionId, gateInfo in pairs(conditions) do
        local nodes = nodesByConditions[conditionId];
        if (nodes) then
            local minX, minY, topLeftNode = 9999999, 9999999, nil;
            for nodeId, nodeInfo in pairs(nodes) do
                local roundedX, roundedY = round(nodeInfo.posX), round(nodeInfo.posY);

                if (roundedY < minY) then
                    minY = roundedY;
                    minX = roundedX;
                    topLeftNode = nodeId
                elseif (roundedY == minY and roundedX < minX) then
                    minX = roundedX;
                    topLeftNode = nodeId
                end
            end
            if (topLeftNode) then
                table.insert(gates, {
                    topLeftNodeID = topLeftNode,
                    conditionID = conditionId,
                    spentAmountRequired = gateInfo.spentAmountRequired,
                    traitCurrencyID = gateInfo.currencyId,
                });
            end
        end
    end
    table.sort(gates, function(a, b)
        return a.spentAmountRequired < b.spentAmountRequired;
    end);
    gateCache[specId] = gates;

    return deepCopy(gates);
end
