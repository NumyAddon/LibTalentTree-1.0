# LibTalentTree-1.0

LibTalentTree-1.0 is a library that provides an interface for accessing talent trees and talent node information.

Blizzard's C_Traits API fails to provide any information for spec specific nodes, and there is no API to retrieve the TreeID for any particular class. This library aims to resolve both those problems, by providing a few basic functions. 
> If you're interested in using the library, but have questions or feedback, I would love to hear from you :)

## Known issues
 * The visibleEdges list is not in the same order as it is when fetched through C_Traits.
   * This seems to be mostly unimportant for most use cases, and cannot be fixed.
 * The starter build info might not be fully accurate for all specs.

## Usage

### Distributing the library with your addon
If you want to distribute the library with your addon, you can do so by including the following entry in your .pkgmeta file (this is just an example!):
```
externals:
    libs/LibStub: https://repos.wowace.com/wow/ace3/trunk/LibStub
    libs/LibTalentTree-1.0:
        url: https://github.com/Numynum/LibTalentTree-1.0
        curse-slug: libtalenttree
```
Add `libs\LibTalentTree-1.0\LibTalentTree-1.0.xml` as well as LibStub to your toc file, and you're good to go!
Full permission is granted to distribute unmodified version of this library with your addon.

### Quick reference
Most of the information returned matches the in-game C_Traits API, which has up-to-date documentation on [wowpedia C_Traits](https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_Traits).
 * `nodeInfo = LibTalentTree:GetNodeInfo(treeId, nodeId)` [#GetNodeInfo](#getnodeinfo)
   * Returns a table containing all the information for a given node, enriched with C_Traits data if available.
 * `nodeInfo = LibTalentTree:GetLibNodeInfo(treeId, nodeId)` [#GetLibNodeInfo](#getlibnodeinfo)
   * Returns a table containing all the information for a given node, without any C_Traits data.
 * `treeId = LibTalentTree:GetClassTreeId(classId | classFileName)` [#GetClassTreeId](#getclasstreeid)
   * Returns the treeId for a given class.
 * `isVisible = LibTalentTree:IsNodeVisibleForSpec(specId, nodeId)` [#IsNodeVisibleForSpec](#isnodevisibleforspec)
   * Returns whether or not a node is visible for a given spec.
 * `isGranted = LibTalentTree:IsNodeGrantedForSpec(specId, nodeId)` [#IsNodeGrantedForSpec](#isnodegrantedforspec)
   * Returns whether or not a node is granted by default for a given spec.
 * `posX, posY = LibTalentTree:GetNodePosition(treeId, nodeId)` [#GetNodePosition](#getnodeposition)
   * Returns the position of a node in a given tree.
 * `isClassNode = LibTalentTree:IsClassNode(treeId, nodeId)` [#IsClassNode](#isclassnode)
   * Returns whether a node is a class node, or a spec node.
 * `edges = LibTalentTree:GetNodeEdges(treeId, nodeId)` [#GetNodeEdges](#getnodeedges)
   * Returns a list of edges for a given node.
 * `gates = LibTalentTree:GetGates(specId)` [#GetGates](#getgates)
   * Returns a list of gates for a given spec.
 * `starterBuild = LibTalentTree:GetStarterBuildBySpec(specId)` [#GetStarterBuildBySpec](#getStarterBuildBySpec)
   * Returns a list of starter build entries for the given spec, sorted by suggested spending order.

### GetClassTreeId
Get the TreeId for a class
#### Syntax
`treeId = LibTalentTree:GetClassTreeId(classId | classFileName)`
#### Arguments
* [number] classId - The [ClassId](https://wowpedia.fandom.com/wiki/ClassId) of the class you want to get the TraitTreeID for.
* [string] classFile - Locale-independent name, e.g. `"WARRIOR"`.

#### Returns
* [number|nil] treeId - TraitTreeID for the class' talent tree, nil for invalid arguments.

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
-- the following 2 lines are equivalent
local treeId = LibTalentTree:GetClassTreeId(2)
local treeId = LibTalentTree:GetClassTreeId('PALADIN')
local nodes = C_Traits.GetTreeNodes(treeId)
```


### IsNodeVisibleForSpec
Get node visibility
#### Syntax
`isVisible = LibTalentTree:IsNodeVisibleForSpec(specId, nodeId)`
#### Arguments
* [number] specId - [SpecializationID](https://wowpedia.fandom.com/wiki/SpecializationID)
* [number] nodeId - TraitNodeID

#### Returns
* [boolean] isVisible - Whether the node is visible for the given spec.

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local isVisible = LibTalentTree:IsNodeVisibleForSpec(65, 12345)
```


### IsNodeGrantedForSpec
Check if a node is granted by default
#### Syntax
`isGranted = LibTalentTree:IsNodeGrantedForSpec(specId, nodeId)`
#### Arguments
* [number] specId - [SpecializationID](https://wowpedia.fandom.com/wiki/SpecializationID)
* [number] nodeId - TraitNodeID

#### Returns
* [boolean] isGranted - Whether the node is granted by default for the given spec.

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local isGranted = LibTalentTree:IsNodeGrantedForSpec(65, 12345)
```


### GetNodePosition
#### Syntax
`posX, posY = LibTalentTree:GetNodePosition(treeId, nodeId)`
#### Arguments
* [number] treeId - TraitTreeID
* [number] nodeId - TraitNodeID

#### Returns
* [number|nil] posX - X position of the node, some trees have a global offset
* [number|nil] posY - Y position of the node, some trees have a global offset

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local treeId = LibTalentTree:GetClassTreeId('PALADIN');
local posX, posY = LibTalentTree:GetNodePosition(treeId, 12345)
```


### IsClassNode
Check if a node is part of the class or spec tree
#### Syntax
`isClassNode = LibTalentTree:IsClassNode(treeId, nodeId)`
#### Arguments
* [number] treeId - TraitTreeID
* [number] nodeId - TraitNodeID

#### Returns
* [boolean|nil] isClassNode - Whether the node is part of the class tree, or the spec tree.

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local treeId = LibTalentTree:GetClassTreeId('PALADIN');
local isClassNode = LibTalentTree:IsClassNode(treeId, 12345)
```


### GetNodeEdges
> The order of node edges is not guaranteed to be consistent with C_Traits info.
#### Syntax
`edges = LibTalentTree:GetNodeEdges(treeId, nodeId)`
#### Arguments
* [number] treeId - TraitTreeID
* [number] nodeId - TraitNodeID

#### Returns
* [table] edges - A list of visibleEdges.
##### visibleEdges
| Field                | Differences from C_Traits | Extra info                                                                                                                                               |
|----------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] type        | None                      | 0: VisualOnly, 1: DeprecatedRankConnection, 2: SufficientForAvailability, 3: RequiredForAvailability, 4: MutuallyExclusive, 5: DeprecatedSelectionOption |
| [number] visualStyle | None                      | 0: None, 1: Straight                                                                                                                                     |
| [number] targetNode  | None                      | TraitNodeID                                                                                                                                              |

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local treeId = LibTalentTree:GetClassTreeId('PALADIN');
local edges = LibTalentTree:GetNodeEdges(treeId, 12345)
for _, edge in ipairs(edges) do
  print(edge.targetNode)
end
```


### GetNodeInfo
if available, C_Traits nodeInfo is used instead, and specInfo is mixed in.
If C_Traits nodeInfo returns a zeroed out table, the table described below is mixed in.
#### Syntax
`nodeInfo = LibTalentTree:GetNodeInfo(treeId, nodeId)`
#### Arguments
* [number] treeId - TraitTreeID
* [number] nodeId - TraitNodeID

#### Returns
* [table] nodeInfo

##### nodeInfo
| Field                 | Differences from C_Traits                                           | Extra info                                                                                                                                                         |
|-----------------------|---------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] ID           | None                                                                |                                                                                                                                                                    |
| [number] posX         | None                                                                | some class trees have a global offset                                                                                                                              |
| [number] posY         | None                                                                | some class trees have a global offset                                                                                                                              |
| [number] type         | None                                                                | 0: single, 1: Tiered, 2: Selection                                                                                                                                 |
| [number] maxRanks     | None                                                                |                                                                                                                                                                    |
| [number] flags        | None                                                                | &1: ShowMultipleIcons                                                                                                                                              |
| [table] groupIDs      | None                                                                | list of [number] groupIDs                                                                                                                                          |
| [table] visibleEdges  | isActive field is missing, the order does not always match C_Traits | list of [table] visibleEdges                                                                                                                                       |
| [table] conditionIDs  | None                                                                | list of [number] conditionIDs                                                                                                                                      |
| [table] entryIDs      | None                                                                | list of [number] entryIDs; generally, choice nodes will have 2, otherwise there's just 1                                                                           |
| [table] specInfo      | Lib-only field                                                      | table of [number] [specId](https://wowpedia.fandom.com/wiki/SpecializationID) = [table] list of conditionTypes; specId 0 means global; see Enum.TraitConditionType |
| [boolean] isClassNode | Lib-only field                                                      | whether the node is part of the class tree or spec tree                                                                                                            |

##### visibleEdges
| Field                | Differences from C_Traits | Extra info                                                                                                                                               |
|----------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] type        | None                      | 0: VisualOnly, 1: DeprecatedRankConnection, 2: SufficientForAvailability, 3: RequiredForAvailability, 4: MutuallyExclusive, 5: DeprecatedSelectionOption |
| [number] visualStyle | None                      | 0: None, 1: Straight                                                                                                                                     |
| [number] targetNode  | None                      | TraitNodeID                                                                                                                                              |

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0");
local treeId = LibTalentTree:GetClassTreeId('PALADIN');
local nodes = C_Traits.GetTreeNodes(treeId);
local configId = C_ClassTalents.GetActiveConfigID();
for _, nodeId in ipairs(nodes) do
    local nodeInfo = LibTalentTree:GetNodeInfo(treeId, nodeId);
    local entryInfo = C_Traits.GetEntryInfo(configId, nodeInfo.entryIDs[1]);
end
```


### GetLibNodeInfo
Get node info as stored in the library
#### Syntax
`nodeInfo = LibTalentTree:GetLibNodeInfo(treeId, nodeId)`
#### Arguments
* [number] treeId - The TraitTreeID of the tree you want to get the node info for.
* [number] nodeId - The TraitNodeID of the node you want to get the info for.

#### Returns
* [table|nil] nodeInfo, nil if not found

##### nodeInfo
| Field                 | Differences from C_Traits                                           | Extra info                                                                                                                                                         |
|-----------------------|---------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] ID           | None                                                                |                                                                                                                                                                    |
| [number] posX         | None                                                                | some class trees have a global offset                                                                                                                              |
| [number] posY         | None                                                                | some class trees have a global offset                                                                                                                              |
| [number] type         | None                                                                | 0: single, 1: Tiered, 2: Selection                                                                                                                                 |
| [number] maxRanks     | None                                                                |                                                                                                                                                                    |
| [number] flags        | None                                                                | &1: ShowMultipleIcons                                                                                                                                              |
| [table] groupIDs      | None                                                                | list of [number] groupIDs                                                                                                                                          |
| [table] visibleEdges  | isActive field is missing, the order does not always match C_Traits | list of [table] visibleEdges                                                                                                                                       |
| [table] conditionIDs  | None                                                                | list of [number] conditionIDs                                                                                                                                      |
| [table] entryIDs      | None                                                                | list of [number] entryIDs; generally, choice nodes will have 2, otherwise there's just 1                                                                           |
| [table] specInfo      | Lib-only field                                                      | table of [number] [specId](https://wowpedia.fandom.com/wiki/SpecializationID) = [table] list of conditionTypes; specId 0 means global; see Enum.TraitConditionType |
| [boolean] isClassNode | Lib-only field                                                      | whether the node is part of the class tree or spec tree                                                                                                            |

##### visibleEdges
| Field                | Differences from C_Traits | Extra info                                                                                                                                               |
|----------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [number] type        | None                      | 0: VisualOnly, 1: DeprecatedRankConnection, 2: SufficientForAvailability, 3: RequiredForAvailability, 4: MutuallyExclusive, 5: DeprecatedSelectionOption |
| [number] visualStyle | None                      | 0: None, 1: Straight                                                                                                                                     |
| [number] targetNode  | None                      | TraitNodeID                                                                                                                                              |

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0");
local treeId = LibTalentTree:GetClassTreeId('PALADIN');
local nodes = C_Traits.GetTreeNodes(treeId);
local configId = C_ClassTalents.GetActiveConfigID();
for _, nodeId in ipairs(nodes) do
    local nodeInfo = LibTalentTree:GetLibNodeInfo(treeId, nodeId);
    local entryInfo = C_Traits.GetEntryInfo(configId, nodeInfo.entryIDs[1]);
end
```

### GetGates
Returns a list of gates for a given spec.
The data is similar to C_Traits.GetTreeInfo and C_Traits.GetConditionInfo, essentially aiming to supplement both APIs.
#### Syntax
`gates = LibTalentTree:GetGates(specId)`
#### Arguments
* [number] specId - The [specId](https://wowpedia.fandom.com/wiki/SpecializationID) of the spec you want to get the gates for.

#### Returns
* [table] gates - list of [table] gateInfo - the order is not guaranteed to be the same as C_Traits.GetTreeInfo, but is will always be sorted by spentAmountRequired

##### gateInfo
| Field                        | Differences from C_Traits                                                                                  | Extra info                                                                                                     |
|------------------------------|------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| [number] topLeftNodeID       | (TraitGateInfo) None                                                                                       | The UI uses this node to anchor the Gate UI element to                                                         |
| [number] conditionID         | (TraitGateInfo) None                                                                                       |                                                                                                                |
| [number] spentAmountRequired | (TraitCondInfo) Always gives the **total** spending required, rather than [ totalRequired - alreadySpent ] | Especially useful for finding out the real gate cost when you're already spend points in your character's tree |
| [number] traitCurrencyID     | (TraitCondInfo) None                                                                                       |                                                                                                                |


### GetStarterBuildBySpec
Returns Starter Build information for a given spec.
The data returned is similar to what you'd get from `C_ClassTalents.GetNextStarterBuildPurchase()`, but has no iteration logic.
#### Syntax
`starterBuild = LibTalentTree:GetStarterBuildBySpec(specId)`
#### Arguments
* [number] specId - The [specId](https://wowpedia.fandom.com/wiki/SpecializationID) of the spec you want to get the starter build info for.

#### Returns
* [table | nil] starterBuild - list of [table] starterBuildEntryInfo - ordered by suggested spending order; nil if no starter build is available.

##### starterBuildEntryInfo
| Field              | Extra info                                          |
|--------------------|-----------------------------------------------------|
| [number] nodeID    | TraitNodeID                                         |
| [?number] entryID  | TraitEntryID - only present in case of choice nodes |
| [number] numPoints | The number of points to spend in this node          |

#### Example

```lua
local LibTalentTree = LibStub("LibTalentTree-1.0");
local specId = 65; -- Holy Paladin
local starterBuild = LibTalentTree:GetStarterBuildBySpec(specId);
if starterBuild then
    for _, entry in ipairs(starterBuild) do
        purchaseNode(entry.nodeID, entry.entryID, entry.numPoints);
    end
end
```
