-- the data for LibTalentTree will be loaded (and cached) from blizzard's APIs when the Lib loads
-- @curseforge-project-slug: libtalenttree@
--- @diagnostic disable: duplicate-set-field

local MAJOR, MINOR = "LibTalentTree-1.0", 30;
--- @class LibTalentTree-1.0
local LibTalentTree = LibStub:NewLibrary(MAJOR, MINOR);

if not LibTalentTree then return end -- No upgrade needed

--- Whether the current game version is compatible with this library. This is generally always true on retail, and always false on classic.
function LibTalentTree:IsCompatible()
    return C_ClassTalents and C_ClassTalents.InitializeViewLoadout and true or false;
end

if not C_ClassTalents or not C_ClassTalents.InitializeViewLoadout then
    setmetatable(LibTalentTree, {
        __index = function()
            error('LibTalentTree requires C_ClassTalents.InitializeViewLoadout to be available');
        end,
    });

    return;
end

local isMidnight = select(4, GetBuildInfo()) >= 120000;

local MAX_LEVEL = 100; -- seems to not break if set too high, but can break things when set too low
local MAX_SUB_TREE_CURRENCY = isMidnight and 13 or 10; -- blizzard incorrectly reports 20 when asking for the maxQuantity of the currency
local HERO_TREE_REQUIRED_LEVEL = 71; -- while `C_ClassTalents.GetHeroTalentSpecsForClassSpec` returns this info, it's not immediately available on initial load
local APEX_TALENT_LEVEL = 81

-- taken from ClassTalentUtil.GetVisualsForClassID
local CLASS_OFFSETS = {
    [1] = { x = 30, y = 31, }, -- Warrior
    [2] = { x = -60, y = -29, }, -- Paladin
    [3] = { x = 0, y = -29, }, -- Hunter
    [4] = { x = 30, y = -29, }, -- Rogue
    [5] = { x = -30, y = -29, }, -- Priest
    [6] = { x = 0, y = 1, }, -- DK
    [7] = { x = 0, y = 1, }, -- Shaman
    [8] = { x = 30, y = -29, }, -- Mage
    [9] = { x = 0, y = 1, }, -- Warlock
    [10] = { x = 0, y = -29, }, -- Monk
    [11] = { x = 30, y = -29, }, -- Druid
    [12] = { x = 30, y = -29, }, -- Demon Hunter
    [13] = { x = 30, y = -29, }, -- Evoker
};
-- taken from ClassTalentTalentsTabTemplate XML
local BASE_PAN_OFFSET_X = 4;
local BASE_PAN_OFFSET_Y = -30;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function deepCopy(original)
    local copy;
    if (type(original) == 'table') then
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

local function getGridLineFromCoordinate(start, spacing, halfwayEnabled, coordinate)
    local bucketSpacing = halfwayEnabled and (spacing / 4) or (spacing / 2);
    -- breaks out at 25, which is well above the expected max
    for testLine = 1, 25, (halfwayEnabled and 0.5 or 1) do
        local bucketStart = (start - spacing) + (spacing * testLine) - bucketSpacing;
        local bucketEnd = bucketStart + (bucketSpacing * 2);
        if coordinate >= bucketStart and coordinate < bucketEnd then
            return testLine;
        end
    end

    return nil;
end

LibTalentTree.cacheWarmupRegistery = LibTalentTree.cacheWarmupRegistery or {};

local forceBuildCache;
local cacheWarmedUp = false;
do
    local function initCache()
        LibTalentTree.cache = {
            --- @type table<string, number> # className -> classID
            classFileMap = {},
            --- @type table<number, number> # specID -> classID
            specMap = {},
            --- @type table<number, number> # classID -> treeID
            classTreeMap = {},
            --- @type table<number, number> # nodeID -> treeID
            nodeTreeMap = {},
            --- @type table<number, number> # entryID -> treeID
            entryTreeMap = {},
            --- @type table<number, number> # entryID -> nodeID
            entryNodeMap = {},
            --- @type table<number, table<number, number>> # specID -> {entryIndex -> subTreeID}
            specSubTreeMap = {},
            --- @type table<number, table<number, boolean>> # subTreeID -> {specID -> true}
            subTreeSpecMap = {},
            --- @type table<number, number[]> # subTreeID -> nodeID[]
            subTreeNodesMap = {},
            --- @type table<number, treeCurrencyInfo[]> # treeID -> {currencyIndex|currencyID -> currencyInfo}
            treeCurrencyMap = {},
            --- @type table<number, libNodeInfo[]> # treeID -> {nodeID -> nodeInfo}
            nodeData = {},
            --- @type table<number, table<number, { currencyID: number, spentAmountRequired: number }>> # treeID -> {conditionID -> gateInfo}
            gateData = {},
            --- @type table<number, entryInfo[]> # treeID -> {entryID -> entryData}
            entryData = {},
            --- @type table<number, subTreeInfo> # subTreeID -> subTreeInfo
            subTreeData = {},
        };
        for classID = 1, GetNumClasses() do
            LibTalentTree.cache.classFileMap[select(2, GetClassInfo(classID))] = classID;

            local specID = GetSpecializationInfoForClassID(classID, 1);
            LibTalentTree.cache.classTreeMap[classID] = C_ClassTalents.GetTraitTreeForSpec(specID);
        end
    end

    local level = MAX_LEVEL;
    local configID = Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID;
    local initialSpecs = {
        [1] = 1446,
        [2] = 1451,
        [3] = 1448,
        [4] = 1453,
        [5] = 1452,
        [6] = 1455,
        [7] = 1444,
        [8] = 1449,
        [9] = 1454,
        [10] = 1450,
        [11] = 1447,
        [12] = 1456,
        [13] = 1465,
    };
    local function buildPartialCache(classID)
        local cache = LibTalentTree.cache;

        local nodes;
        local treeID = cache.classTreeMap[classID];
        local nodeData = {};
        local entryData = {};
        local gateData = {};
        cache.nodeData[treeID] = nodeData;
        cache.entryData[treeID] = entryData;
        cache.gateData[treeID] = gateData;

        local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID);
        for specIndex = 1, (numSpecs + 1) do
            local lastSpec = specIndex == (numSpecs + 1);
            local specID = GetSpecializationInfoForClassID(classID, specIndex) or initialSpecs[classID];
            cache.specMap[specID] = classID;

            C_ClassTalents.InitializeViewLoadout(specID, level);
            C_ClassTalents.ViewLoadout({});

            nodes = nodes or C_Traits.GetTreeNodes(treeID);
            local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, true);
            local classCurrencyID = treeCurrencyInfo[1].traitCurrencyID;
            cache.treeCurrencyMap[treeID] = cache.treeCurrencyMap[treeID] or treeCurrencyInfo;
            cache.treeCurrencyMap[treeID][1].isClassCurrency = true;
            cache.treeCurrencyMap[treeID][2].isSpecCurrency = true;
            for _, currencyInfo in ipairs(treeCurrencyInfo) do
                cache.treeCurrencyMap[treeID][currencyInfo.traitCurrencyID] = cache.treeCurrencyMap[treeID][currencyInfo.traitCurrencyID] or currencyInfo;
            end

            local treeInfo = C_Traits.GetTreeInfo(configID, treeID);
            for _, gateInfo in ipairs(treeInfo.gates) do
                local conditionID = gateInfo.conditionID;
                local conditionInfo = C_Traits.GetConditionInfo(configID, conditionID);
                gateData[conditionID] = conditionInfo and {
                    currencyID = conditionInfo.traitCurrencyID,
                    spentAmountRequired = conditionInfo.spentAmountRequired,
                };
            end

            for _, nodeID in pairs(nodes) do
                cache.nodeTreeMap[nodeID] = treeID;
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
                    data.subTreeID = nodeInfo.subTreeID;
                    data.isSubTreeSelection = nodeInfo.type == Enum.TraitNodeType.SubTreeSelection;
                    data.isApexTalent = false;
                    data.requiredPlayerLevel = 0;

                    data.visibleEdges = data.visibleEdges or {};
                    mergeTables(data.visibleEdges, nodeInfo.visibleEdges, 'targetNode');

                    data.conditionIDs = data.conditionIDs or {};
                    mergeTables(data.conditionIDs, nodeInfo.conditionIDs);

                    data.groupIDs = data.groupIDs or {};
                    mergeTables(data.groupIDs, nodeInfo.groupIDs);
                    for entryIndex, entryID in pairs(nodeInfo.entryIDs) do
                        cache.entryTreeMap[entryID] = treeID;
                        cache.entryNodeMap[entryID] = nodeID;
                        if not entryData[entryID] then
                            local entryInfo = C_Traits.GetEntryInfo(configID, entryID);
                            entryData[entryID] = {
                                definitionID = entryInfo.definitionID,
                                type = entryInfo.type,
                                maxRanks = entryInfo.maxRanks,
                                subTreeID = entryInfo.subTreeID,
                            }

                            if entryInfo.subTreeID then
                                cache.specSubTreeMap[specID] = cache.specSubTreeMap[specID] or {};
                                cache.specSubTreeMap[specID][entryIndex] = entryInfo.subTreeID;
                                cache.subTreeSpecMap[entryInfo.subTreeID] = cache.subTreeSpecMap[entryInfo.subTreeID] or {};
                                cache.subTreeSpecMap[entryInfo.subTreeID][specID] = true;
                                -- I previously used C_ClassTalents.GetHeroTalentSpecsForClassSpec, but it returns nil on initial load
                                -- it's not actually required to retrieve the data though
                                --- @type subTreeInfo|nil
                                local subTreeInfo = C_Traits.GetSubTreeInfo(configID, entryInfo.subTreeID); --- @diagnostic disable-line: assign-type-mismatch
                                if subTreeInfo then
                                    subTreeInfo.requiredPlayerLevel = HERO_TREE_REQUIRED_LEVEL;
                                    subTreeInfo.maxCurrency = MAX_SUB_TREE_CURRENCY;
                                    subTreeInfo.isActive = false;
                                    cache.subTreeData[entryInfo.subTreeID] = subTreeInfo;
                                    local currencyInfo = cache.treeCurrencyMap[treeID][subTreeInfo.traitCurrencyID];
                                    currencyInfo.quantity = MAX_SUB_TREE_CURRENCY;
                                    currencyInfo.maxQuantity = MAX_SUB_TREE_CURRENCY;
                                    currencyInfo.subTreeID = entryInfo.subTreeID;
                                    currencyInfo.subTreeIDs = currencyInfo.subTreeIDs or {};
                                    table.insert(currencyInfo.subTreeIDs, entryInfo.subTreeID);
                                end
                            end
                        end
                    end

                    for _, conditionID in pairs(data.conditionIDs) do
                        local cInfo = C_Traits.GetConditionInfo(configID, conditionID)
                        if cInfo then
                            if cInfo.isMet and cInfo.ranksGranted and cInfo.ranksGranted > 0 then
                                data.grantedForSpecs[specID] = true;
                            end
                            if cInfo.playerLevel then
                                data.requiredPlayerLevel = math.max(data.requiredPlayerLevel, cInfo.playerLevel);
                            end
                        end
                    end
                    if data.requiredPlayerLevel == 0 then
                        data.requiredPlayerLevel = nil;
                    elseif data.requiredPlayerLevel >= APEX_TALENT_LEVEL then
                        data.isApexTalent = true;
                    end

                    if nil == data.isClassNode then
                        data.isClassNode = false;
                        local nodeCost = C_Traits.GetNodeCost(configID, nodeID);
                        if not next(nodeCost) and data.grantedForSpecs[specID] then
                            data.isClassNode = true;
                        end
                        for _, cost in pairs(nodeCost) do
                            if cost.ID == classCurrencyID then
                                data.isClassNode = true;
                                break;
                            end
                        end
                    end
                end
                data.visibleForSpecs = data.visibleForSpecs or {};
                data.visibleForSpecs[specID] = nodeInfo.isVisible;

                if lastSpec then
                    if not data.posX then
                        nodeData[nodeID] = nil;
                    elseif data.subTreeID then
                        cache.subTreeNodesMap[data.subTreeID] = cache.subTreeNodesMap[data.subTreeID] or {};
                        table.insert(cache.subTreeNodesMap[data.subTreeID], nodeID);
                    end
                end
            end
        end
        for _, nodeInfo in pairs(nodeData) do
            -- some subtree nodes incorrectly suggest they are visible for all specs, so we just correct that
            if nodeInfo.subTreeID then
                for specID, _ in pairs(nodeInfo.visibleForSpecs) do
                    nodeInfo.visibleForSpecs[specID] = nodeInfo.visibleForSpecs[specID] and cache.subTreeSpecMap[nodeInfo.subTreeID][specID] or false;
                end
            end
        end
    end

    local frame = CreateFrame("Frame");
    local function onCacheCompleted()
        frame:SetScript("OnUpdate", nil);
        forceBuildCache = nil;
        cacheWarmedUp = true;
        for _, callback in ipairs(LibTalentTree.cacheWarmupRegistery) do
            securecallfunction(callback);
        end
        LibTalentTree.cacheWarmupRegistery = nil;
    end

    frame.currentClassID = 0;
    frame.numClasses = GetNumClasses();
    frame:SetScript("OnUpdate", function()
        local _, latestMinor = LibStub:GetLibrary(MAJOR);
        if latestMinor ~= MINOR then
            frame:SetScript("OnUpdate", nil);
            return;
        end
        local classID = frame.currentClassID + 1;
        if classID == 1 then
            initCache();
        elseif classID > frame.numClasses then
            onCacheCompleted();
            return;
        end
        frame.currentClassID = classID;

        -- buildPartialCache results in a significant amount of pointless taintlog entries when it's set to log level 11
        -- so we just disable it temporarily
        local backup = C_CVar.GetCVar('taintLog');
        if backup and backup == '11' then C_CVar.SetCVar('taintLog', 0); end
        buildPartialCache(classID);
        if backup and backup == '11' then C_CVar.SetCVar('taintLog', backup); end
    end);

    forceBuildCache = function()
        for classID = frame.currentClassID + 1, frame.numClasses do
            if classID == 1 then
                initCache();
            end
            buildPartialCache(classID);
        end
        onCacheCompleted();
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- @public
--- Register a callback to be called when the cache is fully built.
--- If you register the callback after the cache is built, it will be called immediately.
--- Using a function that requires the cache to be present, will force load the cache, which might result in a slight ms spike
--- @param callback fun() # called when all data is ready
function LibTalentTree:RegisterOnCacheWarmup(callback)
    assert(type(callback) == 'function', 'callback must be a function');

    if cacheWarmedUp then
        securecallfunction(callback);
    else
        table.insert(self.cacheWarmupRegistery, callback);
    end
end

--- @public
--- @param nodeID number # TraitNodeID
--- @return number|nil treeID # TraitTreeID
function LibTalentTree:GetTreeIDForNode(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return self.cache.nodeTreeMap[nodeID];
end

--- @public
--- @param entryID number # TraitEntryID
--- @return number|nil treeID # TraitTreeID
function LibTalentTree:GetTreeIDForEntry(entryID)
    assert(type(entryID) == 'number', 'entryID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return self.cache.entryTreeMap[entryID];
end

--- @public
--- @param entryID number # TraitEntryID
--- @return number|nil nodeID # TraitNodeID
function LibTalentTree:GetNodeIDForEntry(entryID)
    assert(type(entryID) == 'number', 'entryID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return self.cache.entryNodeMap[entryID];
end

--- @public
--- @param nodeID number # TraitNodeID
--- @return libNodeInfo|nil nodeInfo
function LibTalentTree:GetLibNodeInfo(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    local treeID = self:GetTreeIDForNode(nodeID);
    local nodeData = self.cache.nodeData;

    local nodeInfo = nodeData[treeID] and nodeData[treeID][nodeID] and deepCopy(nodeData[treeID][nodeID]) or nil;
    if nodeInfo then nodeInfo.ID = nodeID; end

    return nodeInfo;
end

--- @public
--- @param nodeID number # TraitNodeID
--- @return libNodeInfo|TraitNodeInfo nodeInfo # libNodeInfo is enriched and overwritten by C_Traits information if possible
function LibTalentTree:GetNodeInfo(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    local cNodeInfo = C_Traits.GetNodeInfo(
        C_ClassTalents.GetActiveConfigID() or Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID or -3,
        nodeID
    )
    local libNodeInfo = self:GetLibNodeInfo(nodeID);

    if not libNodeInfo then return cNodeInfo; end

    ---@diagnostic disable-next-line: missing-fields
    if not cNodeInfo then cNodeInfo = {}; end

    if cNodeInfo.ID == nodeID then
        return Mixin(libNodeInfo, cNodeInfo);
    end

    return Mixin(cNodeInfo, libNodeInfo);
end

--- @public
--- @param entryID number # TraitEntryID
--- @return entryInfo|nil entryInfo
function LibTalentTree:GetEntryInfo(entryID)
    assert(type(entryID) == 'number', 'entryID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    local treeID = self:GetTreeIDForEntry(entryID);
    local entryData = self.cache.entryData;

    local entryInfo = entryData[treeID] and entryData[treeID][entryID] and deepCopy(entryData[treeID][entryID]) or nil;
    if (entryInfo) then
        entryInfo.isAvailable = true;
        entryInfo.conditionIDs = {};
    end

    return entryInfo;
end

--- @public
--- @param class string|number # ClassID or ClassFilename - e.g. "DEATHKNIGHT" or 6 - See https://warcraft.wiki.gg/wiki/ClassID
--- @return number|nil treeID # TraitTreeID
function LibTalentTree:GetClassTreeID(class)
    assert(type(class) == 'string' or type(class) == 'number', 'class must be a string or number');
    if forceBuildCache then forceBuildCache(); end;

    local classFileMap = self.cache.classFileMap;
    local classTreeMap = self.cache.classTreeMap;

    local classID = classFileMap[class] or class;

    return classTreeMap[classID] or nil;
end

--- @public
--- @param treeID number # a class' TraitTreeID
--- @return number|nil classID # ClassID or nil - See https://warcraft.wiki.gg/wiki/ClassID
function LibTalentTree:GetClassIDByTreeID(treeID)
    treeID = tonumber(treeID); ---@diagnostic disable-line: cast-local-type
    if forceBuildCache then forceBuildCache(); end;

    if not self.inverseClassMap then
        local classTreeMap = self.cache.classTreeMap;
        self.inverseClassMap = {};
        for classID, mappedTreeID in pairs(classTreeMap) do
            self.inverseClassMap[mappedTreeID] = classID;
        end
    end

    return self.inverseClassMap[treeID];
end

--- @public
--- @param specID number # See https://warcraft.wiki.gg/wiki/SpecializationID
--- @param nodeID number # TraitNodeID
--- @return boolean isVisible # whether the node is visible for the given spec
function LibTalentTree:IsNodeVisibleForSpec(specID, nodeID)
    assert(type(specID) == 'number', 'specID must be a number');
    assert(type(nodeID) == 'number', 'nodeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    local specMap = self.cache.specMap;
    local class = specMap[specID];
    assert(class, 'Unknown specID: ' .. specID);

    local nodeInfo = self:GetLibNodeInfo(nodeID);

    if not nodeInfo then return false; end

    return nodeInfo.visibleForSpecs[specID];
end

--- @public
--- @param specID number # See https://warcraft.wiki.gg/wiki/SpecializationID
--- @param nodeID number # TraitNodeID
--- @return boolean isGranted # whether the node is granted by default for the given spec
function LibTalentTree:IsNodeGrantedForSpec(specID, nodeID)
    assert(type(specID) == 'number', 'specID must be a number');
    assert(type(nodeID) == 'number', 'nodeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    local specMap = self.cache.specMap;
    local class = specMap[specID];
    assert(class, 'Unknown specID: ' .. specID);

    local nodeInfo = self:GetLibNodeInfo(nodeID);

    if not nodeInfo then return false; end

    return nodeInfo.grantedForSpecs[specID];
end

--- @public
--- @param nodeID number # TraitNodeID
--- @return number|nil posX # some trees have a global offset
--- @return number|nil posY # some trees have a global offset
function LibTalentTree:GetNodePosition(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');

    local nodeInfo = self:GetLibNodeInfo(nodeID);
    if not nodeInfo then return nil, nil; end

    return nodeInfo.posX, nodeInfo.posY;
end

local gridPositionCache = {};

--- @public
--- Returns an abstraction of the node positions into a grid of columns and rows.
--- Some specs may have nodes that sit between 2 columns, these columns end in ".5". This happens for example in the Druid and Demon Hunter trees.
---
--- The top row is 1, the bottom row is 10.
--- The first class column is 1, the last class column is 9.
--- The first spec column is 13. In Midnight this is 14 instead.
---
--- Hero talents are placed in between the class and spec trees, in columns 10, 11, 12.
--- Midnight adds another column to the hero talents, making them sit in columns 10 - 13.
--- Hero talent subTrees are stacked to overlap, all subTrees on rows 1 - 5. You're responsible for adjusting this yourself.
---
--- The Hero talent selection node, is hardcoded to row 5.5 and column 10. Making it sit right underneath the sub trees themselves.
---
--- @param nodeID number # TraitNodeID
--- @return number|nil column # some nodes sit between 2 columns, these columns end in ".5"
--- @return number|nil row
function LibTalentTree:GetNodeGridPosition(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');

    local treeID = self:GetTreeIDForNode(nodeID);
    local classID = treeID and self:GetClassIDByTreeID(treeID);
    if not classID or not treeID then return nil, nil end

    gridPositionCache[treeID] = gridPositionCache[treeID] or {};
    if gridPositionCache[treeID][nodeID] then
        return unpack(gridPositionCache[treeID][nodeID]);
    end

    local posX, posY = self:GetNodePosition(nodeID);
    if (not posX or not posY) then return nil, nil; end

    local offsetX = BASE_PAN_OFFSET_X - (CLASS_OFFSETS[classID] and CLASS_OFFSETS[classID].x or 0);
    local offsetY = BASE_PAN_OFFSET_Y - (CLASS_OFFSETS[classID] and CLASS_OFFSETS[classID].y or 0);

    local rawX, rawY = posX, posY;

    posX = (round(posX) / 10) - offsetX;
    posY = (round(posY) / 10) - offsetY;
    local colSpacing = 60;
    local subTreeColSpacing = colSpacing * 10
    local subTreeColOffset = 9;

    local row, col;
    local nodeInfo = self:GetLibNodeInfo(nodeID);
    local subTreeID = nodeInfo and nodeInfo.subTreeID;

    if subTreeID then
        local subTreeInfo = self:GetSubTreeInfo(subTreeID);
        if subTreeInfo then
            local topCenterPosX = subTreeInfo.posX;
            local topCenterPosY = subTreeInfo.posY;

            local colStart = topCenterPosX - (subTreeColSpacing * (isMidnight and 1.5 or 1));
            local halfColEnabled = true;
            col = subTreeColOffset + getGridLineFromCoordinate(colStart, subTreeColSpacing, halfColEnabled, rawX);

            local rowStart = topCenterPosY;
            local rowSpacing = 2400 / 4; -- 2400 is generally the height of a sub tree, 4 is number of "gaps" between 5 rows
            local halfRowEnabled = false;
            row = getGridLineFromCoordinate(rowStart, rowSpacing, halfRowEnabled, rawY) or 0;
        end
    elseif nodeInfo and nodeInfo.isSubTreeSelection then
        col = 10;
        row = 5.5;
    end
    if not row or not col then
        local colStart = 176;
        local halfColEnabled = true;
        local classColEnd = 656;
        local specColStart = 956;
        local subTreeOffset = (isMidnight and 4 or 3) * colSpacing;
        local classSpecGap = (specColStart - classColEnd) - subTreeOffset;
        if (posX > (classColEnd + (classSpecGap / 2))) then
            -- remove the gap between the class and spec trees
            posX = posX - classSpecGap + colSpacing;
        end
        col = getGridLineFromCoordinate(colStart, colSpacing, halfColEnabled, posX);

        local rowStart = 151;
        local rowSpacing = 60;
        local halfRowEnabled = false;
        row = getGridLineFromCoordinate(rowStart, rowSpacing, halfRowEnabled, posY);
    end

    gridPositionCache[treeID][nodeID] = { col, row };

    return col, row;
end

--- @public
--- @param nodeID number # TraitNodeID
--- @return nil|visibleEdge[] edges
function LibTalentTree:GetNodeEdges(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');

    local nodeInfo = self:GetLibNodeInfo(nodeID);
    if not nodeInfo then return nil; end

    return nodeInfo.visibleEdges;
end

--- @public
--- @param nodeID number # TraitNodeID
--- @return boolean|nil isClassNode # true if the node is a class node, false otherwise; nil if the node isn't found
function LibTalentTree:IsClassNode(nodeID)
    assert(type(nodeID) == 'number', 'nodeID must be a number');

    local nodeInfo = self:GetLibNodeInfo(nodeID);
    if not nodeInfo then return nil; end

    return nodeInfo.isClassNode;
end

local gateCache = {}

--- @public
--- @param specID number # See https://warcraft.wiki.gg/wiki/SpecializationID
--- @return gateInfo[] gates # list of gates for the given spec, sorted by spending required
function LibTalentTree:GetGates(specID)
    -- an optimization step is likely trivial in 10.1.0, but well.. effort, and this also works fine still :)
    -- 1 expansion later, and now I wish I wrote down what the trivial optimization was :D
    assert(type(specID) == 'number', 'specID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    if gateCache[specID] then return deepCopy(gateCache[specID]); end
    local specMap = self.cache.specMap;
    local class = specMap[specID];
    assert(class, 'Unknown specID: ' .. specID);

    local treeID = self:GetClassTreeID(class);
    local gates = {};

    local nodesByConditions = {};
    local gateData = self.cache.gateData;
    local conditions = gateData[treeID];

    local nodeData = self.cache.nodeData;

    for nodeID, nodeInfo in pairs(nodeData[treeID]) do
        if (nodeInfo.conditionIDs and #nodeInfo.conditionIDs > 0 and self:IsNodeVisibleForSpec(specID, nodeID)) then
            for _, conditionID in pairs(nodeInfo.conditionIDs) do
                if conditions[conditionID] then
                    nodesByConditions[conditionID] = nodesByConditions[conditionID] or {};
                    nodesByConditions[conditionID][nodeID] = nodeInfo;
                end
            end
        end
    end

    for conditionID, gateInfo in pairs(conditions) do
        local nodes = nodesByConditions[conditionID];
        if (nodes) then
            local minX, minY, topLeftNode = 9999999, 9999999, nil;
            for nodeID, nodeInfo in pairs(nodes) do
                local roundedX, roundedY = round(nodeInfo.posX), round(nodeInfo.posY);

                if (roundedY < minY) then
                    minY = roundedY;
                    minX = roundedX;
                    topLeftNode = nodeID
                elseif (roundedY == minY and roundedX < minX) then
                    minX = roundedX;
                    topLeftNode = nodeID
                end
            end
            if (topLeftNode) then
                table.insert(gates, {
                    topLeftNodeID = topLeftNode,
                    conditionID = conditionID,
                    spentAmountRequired = gateInfo.spentAmountRequired,
                    traitCurrencyID = gateInfo.currencyID,
                });
            end
        end
    end
    table.sort(gates, function(a, b)
        return a.spentAmountRequired < b.spentAmountRequired;
    end);
    gateCache[specID] = gates;

    return deepCopy(gates);
end

--- @public
--- @param treeID number # TraitTreeID
--- @return treeCurrencyInfo[] treeCurrencies # list of currencies for the given tree, first entry is class currency, second is spec currency, the rest are sub tree currencies. The list is additionally indexed by the traitCurrencyID.
function LibTalentTree:GetTreeCurrencies(treeID)
    assert(type(treeID) == 'number', 'treeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return deepCopy(self.cache.treeCurrencyMap[treeID]);
end

--- @public
--- @param subTreeID number # TraitSubTreeID
--- @return number[] subTreeNodes # list of TraitNodeIDs that belong to the given sub tree
function LibTalentTree:GetSubTreeNodeIDs(subTreeID)
    assert(type(subTreeID) == 'number', 'subTreeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return deepCopy(self.cache.subTreeNodesMap[subTreeID]) or {};
end

--- @public
--- @param specID number # See https://warcraft.wiki.gg/wiki/SpecializationID
--- @return number[] subTrees # list of TraitSubTreeIDs that belong to the given spec
function LibTalentTree:GetSubTreeIDsForSpecID(specID)
    assert(type(specID) == 'number', 'specID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return deepCopy(self.cache.specSubTreeMap[specID]) or {};
end

--- @public
--- @param subTreeID number # TraitSubTreeID
--- @return subTreeInfo|nil subTreeInfo
function LibTalentTree:GetSubTreeInfo(subTreeID)
    assert(type(subTreeID) == 'number', 'subTreeID must be a number');
    if forceBuildCache then forceBuildCache(); end;

    return deepCopy(self.cache.subTreeData[subTreeID]);
end

--- @public
--- @param specID number # See https://warcraft.wiki.gg/wiki/SpecializationID
--- @param subTreeID number # TraitSubTreeID
--- @return number? nodeID # TraitNodeID; or nil if not found
--- @return number? entryID # TraitEntryID; or nil if not found
function LibTalentTree:GetSubTreeSelectionNodeIDAndEntryIDBySpecID(specID, subTreeID)
    assert(type(specID) == 'number', 'specID must be a number');
    assert(type(subTreeID) == 'number', 'subTreeID must be a number');

    local subTreeInfo = self:GetSubTreeInfo(subTreeID);
    for _, selectionNodeID in ipairs(subTreeInfo and subTreeInfo.subTreeSelectionNodeIDs or {}) do
        if self:IsNodeVisibleForSpec(specID, selectionNodeID) then
            local nodeInfo = self:GetLibNodeInfo(selectionNodeID);
            for _, entryID in ipairs(nodeInfo and nodeInfo.entryIDs or {}) do
                local entryInfo = self:GetEntryInfo(entryID);
                if entryInfo and entryInfo.subTreeID == subTreeID then
                    return selectionNodeID, entryID;
                end
            end
            break;
        end
    end

    return nil;
end
