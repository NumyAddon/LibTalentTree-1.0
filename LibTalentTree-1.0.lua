-- the data for LibTalentTree resides in LibTalentTree-1.0_data.lua
-- as of 10.1.0, most data will be loaded (and cached) from blizzard's APIs when the Lib loads
-- @curseforge-project-slug: libtalenttree@

local MAJOR, MINOR = "LibTalentTree-1.0", 6
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
---@field specInfo: table<number, number[]> # specId: conditionType[] Deprecated, will be removed in 10.1.0; see Enum.TraitConditionType
---@field visibleForSpecs: table<number, boolean> # specId: true/false, true if a node is visible for a spec; added in 10.1.0
---@field grantedForSpecs: table<number, boolean> # specId: true/false, true if a node is granted for free, for a spec; added in 10.1.0
---@field isClassNode: boolean

---@class entryInfo
---@field definitionID number # TraitDefinitionID
---@field type number # see Enum.TraitNodeEntryType
---@field maxRanks number
---@field isAvailable boolean # LibTalentTree always returns true
---@field conditionIDs number[] # list of TraitConditionID, LibTalentTree always returns an empty table

---@class gateInfo
---@field topLeftNodeID number # TraitNodeID - the node that is the top left corner of the gate
---@field conditionID number # TraitConditionID
---@field spentAmountRequired number # the total amount of currency required to unlock the gate
---@field traitCurrencyID number # TraitCurrencyID

---@class starterBuildEntryInfo
---@field nodeID number # TraitNodeID
---@field entryID number|nil # TraitEntryID - only present in case of choice nodes
---@field numPoints number # the number of points to spend in this node

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

local function mergeTables(target, source, keyToUse)
    local lookup = {};
    for _, value in pairs(target) do
        if keyToUse then
            lookup[value[keyToUse]] = true;
        else
            lookup[value] = true;
        end
    end
    for _, value in pairs(source) do
        if (keyToUse and not lookup[value[keyToUse]]) or (not keyToUse and not lookup[value]) then
            table.insert(target, value);
        end
    end
end

local roundingFactor = 100;
local function round(coordinate)
    return math.floor((coordinate / roundingFactor) + 0.5) * roundingFactor;
end

local function buildCache()
    local level = 70;
    local configID = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID;

    LibTalentTree.cache = {};
    local cache = LibTalentTree.cache;
    cache.classFileMap = {};
    cache.specMap = {};
    cache.classTreeMap = {};
    cache.nodeData = {};
    cache.gateData = {};
    cache.entryData = {};
    for classID = 1, GetNumClasses() do
        cache.classFileMap[select(2, GetClassInfo(classID))] = classID;

        local nodes;
        local nodeData = {};
        local entryData = {};
        local gateData = {};
        local treeID;

        local numSpecs = GetNumSpecializationsForClassID(classID);
        for specIndex = 1, numSpecs do
            local lastSpec = specIndex == numSpecs;
            local specID = GetSpecializationInfoForClassID(classID, specIndex);
            cache.specMap[specID] = classID;

            treeID = treeID or C_ClassTalents.GetTraitTreeForSpec(specID);
            cache.classTreeMap[classID] = treeID;

            C_ClassTalents.InitializeViewLoadout(specID, level);
            C_ClassTalents.ViewLoadout({});

            nodes = nodes or C_Traits.GetTreeNodes(treeID);
            local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, true);
            local classCurrencyID = treeCurrencyInfo[1].traitCurrencyID;
            local specCurrencyID = treeCurrencyInfo[2].traitCurrencyID;

            local treeInfo = C_Traits.GetTreeInfo(configID, treeID);
            for _, gateInfo in ipairs(treeInfo.gates) do
                local conditionID = gateInfo.conditionID;
                local conditionInfo = C_Traits.GetConditionInfo(configID, conditionID);
                gateData[conditionID] = {
                    currencyId = conditionInfo.traitCurrencyID,
                    spentAmountRequired = conditionInfo.spentAmountRequired,
                };
            end

            for _, nodeID in ipairs(nodes) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID);
                nodeData[nodeID] = nodeData[nodeID] or {};
                local data = nodeData[nodeID];
                data.grantedForSpecs = data.grantedForSpecs or {};
                data.grantedForSpecs[specID] = false; -- true check is done only if the node is visible
                if nodeInfo.isVisible then
                    data.posX = nodeInfo.posX;
                    data.posY = nodeInfo.posY;
                    data.type = nodeInfo.type;
                    data.maxRanks = nodeInfo.maxRanks;
                    data.flags = nodeInfo.flags;
                    data.entryIDs = nodeInfo.entryIDs;

                    data.visibleEdges = data.visibleEdges or {}
                    mergeTables(data.visibleEdges, nodeInfo.visibleEdges, 'targetNode');

                    data.conditionIDs = data.conditionIDs or {}
                    mergeTables(data.conditionIDs, nodeInfo.conditionIDs);

                    data.groupIDs = data.groupIDs or {}
                    mergeTables(data.groupIDs, nodeInfo.groupIDs);

                    if data.isClassNode == nil then
                        data.isClassNode = false;
                        for _, cost in ipairs(C_Traits.GetNodeCost(configID, nodeID)) do
                            if cost.ID == classCurrencyID then
                                data.isClassNode = true;
                                break;
                            end
                        end
                    end
                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        if not entryData[entryID] then
                            local entryInfo = C_Traits.GetEntryInfo(configID, entryID);
                            entryData[entryID] = {
                                definitionID = entryInfo.definitionID,
                                type = entryInfo.type,
                                maxRanks = entryInfo.maxRanks,
                            }
                        end
                    end

                    for _, conditionID in ipairs(data.conditionIDs) do
                        local cInfo = C_Traits.GetConditionInfo(configID, conditionID)
                        if cInfo and cInfo.isMet and cInfo.ranksGranted and cInfo.ranksGranted > 0 then
                            data.grantedForSpecs[specID] = true;
                        end
                    end
                end
                data.visibleForSpecs = data.visibleForSpecs or {};
                data.visibleForSpecs[specID] = nodeInfo.isVisible;

                if lastSpec and not data.posX then
                    nodeData[nodeID] = nil;
                end
            end
        end

        cache.nodeData[treeID] = nodeData;
        cache.entryData[treeID] = entryData;
        cache.gateData[treeID] = gateData;
    end
end

local useCache = false;
if C_ClassTalents and C_ClassTalents.InitializeViewLoadout then
    buildCache();
    useCache = true;
end

function ExposeLTT()
    return LibTalentTree;
end

--- @public
--- @param treeId number # TraitTreeID
--- @param nodeId number # TraitNodeID
--- @return ( libNodeInfo | nil )
function LibTalentTree:GetLibNodeInfo(treeId, nodeId)
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(nodeId) == 'number', 'nodeId must be a number');

    local nodeData = useCache and self.cache.nodeData or self.nodeData;

    local nodeInfo = nodeData[treeId] and nodeData[treeId][nodeId] and deepCopy(nodeData[treeId][nodeId]) or nil;
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

    local cNodeInfo = C_ClassTalents.GetActiveConfigID()
            and C_Traits.GetNodeInfo(C_ClassTalents.GetActiveConfigID(), nodeId)
            or C_Traits.GetNodeInfo(Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID or -3, nodeId);
    local libNodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    if (not libNodeInfo) then return cNodeInfo; end
    if (not cNodeInfo) then cNodeInfo = {}; end

    if cNodeInfo.ID == nodeId then
        cNodeInfo.specInfo = libNodeInfo.specInfo;
        cNodeInfo.isClassNode = libNodeInfo.isClassNode;
        cNodeInfo.visibleForSpecs = libNodeInfo.visibleForSpecs;
        cNodeInfo.grantedForSpecs = libNodeInfo.grantedForSpecs;

        return cNodeInfo;
    end

    return Mixin(cNodeInfo, libNodeInfo);
end

--- @public
--- @param treeId number # TraitTreeID
--- @param entryId number # TraitEntryID
--- @return ( entryInfo | nil )
function LibTalentTree:GetEntryInfo(treeId, entryId)
    assert(type(treeId) == 'number', 'treeId must be a number');
    assert(type(entryId) == 'number', 'entryId must be a number');

    local entryData = useCache and self.cache.entryData or self.entryData;

    local entryInfo = entryData[treeId] and entryData[treeId][entryId] and deepCopy(entryData[treeId][entryId]) or nil;
    if (entryInfo) then
        entryInfo.isAvailable = true;
        entryInfo.conditionIDs = {};
    end

    return entryInfo;
end

--- @public
--- @param class (string | number) # ClassID or ClassFilename - e.g. "DEATHKNIGHT" or 6 - See https://wowpedia.fandom.com/wiki/ClassId
--- @return ( number | nil ) # TraitTreeID
function LibTalentTree:GetClassTreeId(class)
    assert(type(class) == 'string' or type(class) == 'number', 'class must be a string or number');

    local classFileMap = useCache and self.cache.classFileMap or self.classFileMap;
    local classTreeMap = useCache and self.cache.classTreeMap or self.classTreeMap;

    local classId = classFileMap[class] or class;

    return classTreeMap[classId] or nil;
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

    -- >= 10.1.0
    if nodeInfo.visibleForSpecs then
        return nodeInfo.visibleForSpecs[specId];
    end

    -- < 10.1.0
    for id, conditionTypes in pairs(nodeInfo.specInfo) do
        if (id ~= specId) then
            for _, conditionType in pairs(conditionTypes) do
                if (conditionType == Enum.TraitConditionType.Visible) then
                    return false
                end
            end
        end
    end
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

    -- >= 10.1.0
    if nodeInfo and nodeInfo.grantedForSpecs then
        return nodeInfo.grantedForSpecs[specId];
    end

    -- < 10.1.0
    if (nodeInfo and nodeInfo.specInfo[specId]) then
        for _, conditionType in pairs(nodeInfo.specInfo[specId]) do
            if (conditionType == Enum.TraitConditionType.Granted) then
                return true;
            end
        end
    end

    if (nodeInfo and nodeInfo.specInfo[0]) then
        for _, conditionType in pairs(nodeInfo.specInfo[0]) do
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

--- @public
--- @param specId number # See https://wowpedia.fandom.com/wiki/SpecializationID
--- @return ( gateInfo[] ) # list of gates for the given spec, sorted by spending required
function LibTalentTree:GetGates(specId)
    -- an optimization step is likely trivial in 10.1.0, but well.. effort, and this also works fine still :)
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

--- @public
--- @param specId number # See https://wowpedia.fandom.com/wiki/SpecializationID
--- @return starterBuildEntryInfo[]|nil # list of starter build entries for the given spec, sorted by suggested spending order; nil if no starter build is available
function LibTalentTree:GetStarterBuildBySpec(specId)
    assert(type(specId) == 'number', 'specId must be a number');

    local starterBuild = self.starterBuilds[specId];
    if not starterBuild then return nil end

    local entries = {};
    for _, entry in pairs(starterBuild) do
        table.insert(entries, {
            nodeID = entry.node,
            entryID = entry.entry or nil,
            numPoints = entry.points or 1,
        });
    end

    return entries;
end
