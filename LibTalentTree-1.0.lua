-- the data for LibTalentTree resides in LibTalentTree-1.0_data.lua

local MAJOR, MINOR = "LibTalentTree-0.1", 2
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

function LibTalentTree:GetLibNodeInfo(treeId, nodeId)
    return self.nodeData[treeId] and deepCopy(self.nodeData[treeId][nodeId]) or nil;
end

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

function LibTalentTree:GetClassTreeId(class)
    local classId = self.classFileMap[class] or class;

    return self.classTreeMap[classId] or nil;
end

function LibTalentTree:IsNodeVisibleForSpec(specId, nodeId)
    local class = select(6, GetSpecializationInfoByID(specId));
    local treeId = self:GetClassTreeId(class);
    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    if not nodeInfo then return false; end

    local visible = true;
    for id, behaviour in pairs(nodeInfo.specInfo) do
        if (id ~= specId and behaviour == 'visible') then
            visible = false;
        end
    end
    if (nodeInfo.specInfo[specId] == 'visible' or nodeInfo.specInfo[specId] == 'granted') then
        visible = true;
    end

    return visible;
end

function LibTalentTree:IsNodeGrantedForSpec(specId, nodeId)
    local class = select(6, GetSpecializationInfoByID(specId));
    local treeId = self:GetClassTreeId(class);
    local nodeInfo = self:GetLibNodeInfo(treeId, nodeId);

    return nodeInfo and nodeInfo.specInfo[specId] == 'granted';
end

function LibTalentTree:GetNodePosition(treeId, nodeId)
    local nodeInfo = self:GetNodeInfo(treeId, nodeId);

    return nodeInfo.posX, nodeInfo.posY;
end

function LibTalentTree:GetNodeEdges(treeId, nodeId)
    local nodeInfo = self:GetNodeInfo(treeId, nodeId);

    return nodeInfo.visibleEdges;
end
