# LibTalentTree-1.0

LibTalentTree-1.0 is a library that provides an interface for accessing talent trees and talent node information.

Blizzard's C_Traits API fails to provide any information for spec specific nodes, and there is no API to retrieve the TreeID for any particular class. This library aims to resolve both those problems, by providing a few basic functions. 
> If you're interested in using the library, but have questions or feedback, I would love to hear from you :)

## Usage

> This library is not in it's final state, and until it is, the mayor is LibTalentTree-0.1

### Getting the TreeId for a class
#### Syntax
`treeId = LibTalentTree:GetClassTreeId(classId | classFileName)`
#### Arguments
* [number] classId - The class ID of the class you want to get the TreeID for.
* [string] classFile - Locale-independent name, e.g. `"WARRIOR"`.

#### Returns
* [number] treeId - The TraitTreeID for the class' talent tree.

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-0.1")
-- the following 2 lines are equivalent
local treeId = LibTalentTree:GetClassTreeId(2)
local treeId = LibTalentTree:GetClassTreeId('PALADIN')
local nodes = C_Traits.GetTreeNodes(treeId)
```


### Get node info
if available, C_Traits nodeInfo is used instead, and specInfo is mixed in.
If C_Traits nodeInfo returns a zeroed out table, the table described below is mixed in.
#### Syntax
`nodeInfo = LibTalentTree:GetNodeInfo(treeId, nodeId)`
#### Arguments
* [number] treeId - The TraitTreeID of the tree you want to get the node info for.
* [number] nodeId - The TraitNodeID of the node you want to get the info for.

#### Returns
* [table] nodeInfo

##### nodeInfo
| Field                | Differences from C_Traits                | Extra info                                                                                                             |
|----------------------|------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [number] ID          | None                                     |                                                                                                                        |
| [number] posX        | None                                     |                                                                                                                        |
| [number] posY        | None                                     |                                                                                                                        |
| [number] type        | None                                     | 0: single, 1: Tiered, 2: Selection                                                                                     |
| [number] maxRanks    | None                                     |                                                                                                                        |
| [number] flags       | None                                     | &1: ShowMultipleIcons                                                                                                  |
| [table] groupIDs     | None                                     | list of [number] groupIDs                                                                                              |
| [table] visibleEdges | isActive field is missing                | list of [table] visibleEdges                                                                                           |
| [table] specInfo     | Lib-only field                           | list of [number] specId = [string] behaviour; specId 0 means global; behaviour is 'available', 'visible', or 'granted' |
| [table] conditionIDs | The order does not always match C_Traits | list of [number] conditionIDs                                                                                          |
| [table] entryIDs     | None                                     | list of [number] entryIDs; generally only applies to choice nodes                                                      |

##### visibleEdges
| Field                | Differences from C_Traits | Extra info                                                                                                                                               |
|----------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] type        | None                      | 0: VisualOnly, 1: DeprecatedRankConnection, 2: SufficientForAvailability, 3: RequiredForAvailability, 4: MutuallyExclusive, 5: DeprecatedSelectionOption |
| [number] visualStyle | None                      | 0: None, 1: Straight                                                                                                                                     |
| [number] targetNode  | None                      |                                                                                                                                                          |

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-0.1")
local treeId = LibTalentTree:GetClassTreeId('PALADIN')
local nodes = C_Traits.GetTreeNodes(treeId)
local spec = 65 -- Holy
for _, nodeId in ipairs(nodes) do
    local nodeInfo = LibTalentTree:GetNodeInfo(treeId, nodeId)
    local visible = true
    for specId, behaviour in pairs(nodeInfo.specInfo) do
        if specId ~= spec and behaviour == 'visible' then visible = false end
    end
    if nodeInfo.specInfo[spec] == 'visible' or nodeInfo.specInfo[spec] == 'granted' then visible = true end
end
```


### Get node info as stored in the library
> This function is likely to change, and may even disappear from the public interface.
#### Syntax
`nodeInfo = LibTalentTree:GetLibNodeInfo(treeId, nodeId)`
#### Arguments
* [number] treeId - The TraitTreeID of the tree you want to get the node info for.
* [number] nodeId - The TraitNodeID of the node you want to get the info for.

#### Returns
* [table] nodeInfo

##### nodeInfo
| Field                | Differences from C_Traits                | Extra info                                                                                                             |
|----------------------|------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| [number] ID          | None                                     |                                                                                                                        |
| [number] posX        | None                                     |                                                                                                                        |
| [number] posY        | None                                     |                                                                                                                        |
| [number] type        | None                                     | 0: single, 1: Tiered, 2: Selection                                                                                     |
| [number] maxRanks    | None                                     |                                                                                                                        |
| [number] flags       | None                                     | &1: ShowMultipleIcons                                                                                                  |
| [table] groupIDs     | None                                     | list of [number] groupIDs                                                                                              |
| [table] visibleEdges | isActive field is missing                | list of [table] visibleEdges                                                                                           |
| [table] specInfo     | Lib-only field                           | list of [number] specId = [string] behaviour; specId 0 means global; behaviour is 'available', 'visible', or 'granted' |
| [table] conditionIDs | The order does not always match C_Traits | list of [number] conditionIDs                                                                                          |
| [table] entryIDs     | None                                     | list of [number] entryIDs; generally only applies to choice nodes                                                      |

##### visibleEdges
| Field                | Differences from C_Traits | Extra info                                                                                                                                               |
|----------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] type        | None                      | 0: VisualOnly, 1: DeprecatedRankConnection, 2: SufficientForAvailability, 3: RequiredForAvailability, 4: MutuallyExclusive, 5: DeprecatedSelectionOption |
| [number] visualStyle | None                      | 0: None, 1: Straight                                                                                                                                     |
| [number] targetNode  | None                      |                                                                                                                                                          |

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-0.1")
local treeId = LibTalentTree:GetClassTreeId('PALADIN')
local nodes = C_Traits.GetTreeNodes(treeId)
local spec = 65 -- Holy
for _, nodeId in ipairs(nodes) do
    local nodeInfo = LibTalentTree:GetLibNodeInfo(treeId, nodeId)
    local visible = true
    for specId, behaviour in pairs(nodeInfo.specInfo) do
        if specId ~= spec and behaviour == 'visible' then visible = false end
    end
    if nodeInfo.specInfo[spec] == 'visible' or nodeInfo.specInfo[spec] == 'granted' then visible = true end
end
```

