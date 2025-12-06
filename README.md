# LibTalentTree-1.0

LibTalentTree-1.0 is a library that provides an interface for accessing talent trees and talent node information.

Blizzard's C_Traits API isn't always easy to use, and getting talent information for other classes/specs can be tedious. This library aims to make your life easier.
> If you're interested in using the library, but have questions or feedback, I would love to hear from you!

## Known issues
 * None, let me know if you find any!

## License
Full permission is granted to publish, distribute, or otherwise share **unmodified** versions of this library with your addon.
All API functions and other data objects exposed by this library, may be freely used by your addon, without restriction.
All other rights are reserved.

## Usage

### Distributing the library with your addon
If you want to distribute the library with your addon, you can do so by including the following entry in your .pkgmeta file (this is just an example!):
```yaml
externals:
    libs/LibStub: https://repos.wowace.com/wow/ace3/trunk/LibStub
    libs/LibTalentTree-1.0:
        url: https://github.com/NumyAddon/LibTalentTree-1.0
        curse-slug: libtalenttree
```
Add `libs\LibTalentTree-1.0\LibTalentTree-1.0.xml`, as well as LibStub, to your toc file, and you're good to go!

### Upgrade notes
Previous versions of the library, used `Id` instead of `ID` in most function names.
These functions have been renamed, and deprecated aliases have been removed.

Table structures are not affected, as these were already using `ID`.

#### Expansion and minor patch features
When a new expansion or minor patch is available for early testing, the library will be updated to support the new features in a backwards compatible manor whenever possible.
It is intended that the library will always work on the current live game version, but should generally work out of the box for any upcoming PTR/Beta versions.

### Quick reference
Most of the information returned matches the in-game C_Traits API, which has up-to-date documentation on [wiki C_Traits](https://warcraft.wiki.gg/wiki/Category:API_namespaces/C_Traits).
 * `LibTalentTree:RegisterOnCacheWarmup(callback)` [#RegisterOnCacheWarmup](#registeroncachewarmup)
   * Registers a callback to be called when the talent tree cache is fully built.
 * `nodeInfo = LibTalentTree:GetNodeInfo(nodeID)` [#GetNodeInfo](#getnodeinfo)
   * Returns a table containing all the information for a given node, enriched with C_Traits data if available.
 * `nodeInfo = LibTalentTree:GetLibNodeInfo(nodeID)` [#GetLibNodeInfo](#getlibnodeinfo)
   * Returns a table containing all the information for a given node, without any C_Traits data.
 * `entryInfo = LibTalentTree:GetEntryInfo(entryID)` [#GetEntryInfo](#getentryinfo)
   * Returns a table containing all the information for a given node entry.
 * `treeID = LibTalentTree:GetTreeIDForNode(nodeID)` [#GetTreeIDForNode](#gettreeidfornode)
   * Returns the treeID for a given node.
 * `treeID = LibTalentTree:GetTreeIDForEntry(entryID)` [#GetTreeIDForEntry](#gettreeidforentry)
   * Returns the treeID for a given NodeEntry.
 * `nodeID = LibTalentTree:GetNodeIDForEntry(entryID)` [#GetNodeIDForEntry](#getnodeidforentry)
   * Returns the nodeID for a given NodeEntry.
 * `treeID = LibTalentTree:GetClassTreeID(classID | classFileName)` [#GetClassTreeID](#getclasstreeid)
   * Returns the treeID for a given class.
 * `classID = LibTalentTree:GetClassIDByTreeID(treeID)` [#GetClassIDByTreeID](#getclassidbytreeid)
   * Returns the classID for a given tree.
 * `isVisible = LibTalentTree:IsNodeVisibleForSpec(specID, nodeID)` [#IsNodeVisibleForSpec](#isnodevisibleforspec)
   * Returns whether a node is visible for a given spec.
 * `isGranted = LibTalentTree:IsNodeGrantedForSpec(specID, nodeID)` [#IsNodeGrantedForSpec](#isnodegrantedforspec)
   * Returns whether a node is granted by default for a given spec.
 * `posX, posY = LibTalentTree:GetNodePosition(nodeID)` [#GetNodePosition](#getnodeposition)
   * Returns the position of a node in a given tree.
 * `column, row = LibTalentTree:GetNodeGridPosition(nodeID)` [#GetNodeGridPosition](#getnodegridposition)
   * Returns an abstracted grid position of a node in a given tree.
 * `isClassNode = LibTalentTree:IsClassNode(nodeID)` [#IsClassNode](#isclassnode)
   * Returns true if the node is part of the class tree, false if it's a spec or hero spec node.
 * `edges = LibTalentTree:GetNodeEdges(nodeID)` [#GetNodeEdges](#getnodeedges)
   * Returns a list of edges for a given node.
 * `gates = LibTalentTree:GetGates(specID)` [#GetGates](#getgates)
   * Returns a list of gates for a given spec.
 * `treeCurrencies = LibTalentTree:GetTreeCurrencies(treeID)` [#GetTreeCurrencies](#gettreecurrencies)
   * Returns a list of currencies for a given tree.
 * `subTreeNodes = LibTalentTree:GetSubTreeNodeIDs(subTreeID)` [#GetSubTreeNodeIDs](#getsubtreenodeids)
   * Returns a list of nodes for a given sub tree.
 * `subTrees = LibTalentTree:GetSubTreeIDsForSpecID(specID)` [#GetSubTreeIDsForSpecID](#getsubtreeidsforspecid)
   * Returns a list of sub trees for a given spec.
 * `subTreeInfo = LibTalentTree:GetSubTreeInfo(subTreeID)` [#GetSubTreeInfo](#getsubtreeinfo)
   * Returns the sub tree info for a given sub tree.
 * `isCompatible = LibTalentTree:IsCompatible()` [#IsCompatible](#iscompatible)
   * Returns the library is compatible with the current game version.


### RegisterOnCacheWarmup
Register a callback to be called when the cache is fully built.
If you register the callback after the cache is built, it will be called immediately.
Using a function that requires the cache to be present, will force load the cache, which might result in a slight ms spike.
It's recommended to use this function for any action performed during the initial loading screen, to reduce loading screen time.
#### Syntax
`LibTalentTree:RegisterOnCacheWarmup(callback)`
#### Arguments
* `function` callback - called when all data is ready


### GetNodeInfo
If available, C_Traits nodeInfo is used instead, and specInfo is mixed in.
If C_Traits nodeInfo returns a zeroed out table, the table described below is mixed in.
#### Syntax
```lua
nodeInfo = LibTalentTree:GetNodeInfo(nodeID)
```
#### Arguments
* `number` nodeID - The TraitNodeID of the node you want to get the info for.
#### Returns
* `table` nodeInfo
##### nodeInfo
| Field                        | Differences from C_Traits | Extra info                                                                               |
|------------------------------|---------------------------|------------------------------------------------------------------------------------------|
| `number` ID                  | None                      |                                                                                          |
| `number` posX                | None                      | some class trees have a global offset                                                    |
| `number` posY                | None                      | some class trees have a global offset                                                    |
| `number` type                | None                      | see Enum.TraitNodeType                                                                   |
| `number` maxRanks            | None                      |                                                                                          |
| `number` flags               | None                      | see Enum.TraitNodeFlag                                                                   |
| `number[]` groupIDs          | None                      | list of `number` groupIDs                                                                |
| `table` visibleEdges         | isActive field is missing | list of `table` visibleEdges                                                             |
| `number[]` conditionIDs      | None                      | list of `number` conditionIDs                                                            |
| `number[]` entryIDs          | None                      | list of `number` entryIDs; generally, choice nodes will have 2, otherwise there's just 1 |
| `number?` subTreeID          | None                      | hero spec / subTree ID if applicable, nil otherwise                                      |
| `table` visibleForSpecs      | Lib-only field            | `specID` = true/false - true if a node is visible for a spec                             |
| `table` grantedForSpecs      | Lib-only field            | `specID` = true/false - true if a node is granted for free, for a spec                   |
| `boolean` isClassNode        | Lib-only field            | true if the node is part of the class tree, false if it's a spec or hero spec node       |
| `boolean` isSubTreeSelection | Lib-only field            | true for sub tree selection nodes                                                        |
##### visibleEdges
| Field                | Differences from C_Traits | Extra info                    |
|----------------------|---------------------------|-------------------------------|
| `number` type        | None                      | see Enum.TraitNodeEdgeType    |
| `number` visualStyle | None                      | see Enum.TraitEdgeVisualStyle |
| `number` targetNode  | None                      | TraitNodeID                   |
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0");
local treeID = LibTalentTree:GetClassTreeID('PALADIN');
local nodes = C_Traits.GetTreeNodes(treeID);
local configID = C_ClassTalents.GetActiveConfigID();
for _, nodeID in ipairs(nodes) do
    local nodeInfo = LibTalentTree:GetNodeInfo(nodeID);
    local entryInfo = C_Traits.GetEntryInfo(configID, nodeInfo.entryIDs[1]);
end
```


### GetLibNodeInfo
Get node info as stored in the library
#### Syntax
```lua
nodeInfo = LibTalentTree:GetLibNodeInfo(nodeID)
```
#### Arguments
* `number` nodeID - The TraitNodeID of the node you want to get the info for.
#### Returns
* `table|nil` nodeInfo, nil if not found
##### nodeInfo
| Field                         | Differences from C_Traits | Extra info                                                                                                                 |
|-------------------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `number` ID                   | None                      |                                                                                                                            |
| `number` posX                 | None                      | some class trees have a global offset                                                                                      |
| `number` posY                 | None                      | some class trees have a global offset                                                                                      |
| `number` type                 | None                      | see Enum.TraitNodeType                                                                                                     |
| `number` maxRanks             | None                      |                                                                                                                            |
| `number` flags                | None                      | see Enum.TraitNodeFlag                                                                                                     |
| `number[]` groupIDs           | None                      | list of `number` groupIDs                                                                                                  |
| `table` visibleEdges          | isActive field is missing | list of `table` visibleEdges                                                                                               |
| `number[]` conditionIDs       | None                      | list of `number` conditionIDs                                                                                              |
| `number[]` entryIDs           | None                      | list of `number` entryIDs; generally, choice nodes will have 2, otherwise there's just 1                                   |
| `number?` subTreeID           | None                      | hero spec / subTree ID if applicable, nil otherwise                                                                        |
| `table` visibleForSpecs       | Lib-only field            | `specID` = true/false - true if a node is visible for a spec                                                               |
| `table` grantedForSpecs       | Lib-only field            | `specID` = true/false - true if a node is granted for free, for a spec                                                     |
| `boolean` isClassNode         | Lib-only field            | true if the node is part of the class tree, false if it's a spec or hero spec node                                         |
| `boolean` isSubTreeSelection  | Lib-only field            | true for sub tree selection nodes                                                                                          |
| `boolean` isApexTalent        | Lib-only field            | true for "apex" talents (Midnight lvl 81+ talents)                                                                         |
| `number?` requiredPlayerLevel | Lib-only field            | the required level, even if all other conditions are met (such as gates and edges), currently only applies to Apex talents |
##### visibleEdges
| Field                | Differences from C_Traits | Extra info                    |
|----------------------|---------------------------|-------------------------------|
| `number` type        | None                      | see Enum.TraitNodeEdgeType    |
| `number` visualStyle | None                      | see Enum.TraitEdgeVisualStyle |
| `number` targetNode  | None                      | TraitNodeID                   |
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0");
local treeID = LibTalentTree:GetClassTreeID('PALADIN');
local nodes = C_Traits.GetTreeNodes(treeID);
local configID = C_ClassTalents.GetActiveConfigID();
for _, nodeID in ipairs(nodes) do
    local nodeInfo = LibTalentTree:GetLibNodeInfo(nodeID);
    local entryInfo = C_Traits.GetEntryInfo(configID, nodeInfo.entryIDs[1]);
end
```


### GetEntryInfo
Get the entry info for a node entry
#### Syntax
```lua
entryInfo = LibTalentTree:GetEntryInfo(entryID)
```
#### Arguments
* `number` entryID - The TraitEntryID of the node entry you want to get the info for.
#### Returns
* `table|nil` entryInfo, nil if not found
##### entryInfo
| Field                   | Differences from C_Traits         | Extra info                                                       |
|-------------------------|-----------------------------------|------------------------------------------------------------------|
| `number` definitionID   | None                              |                                                                  |
| `number` type           | None                              | see Enum.TraitNodeEntryType                                      |
| `number` maxRanks       | None                              |                                                                  |
| `boolean` isAvailable   | LibTalentTree always returns true |                                                                  |
| `number[]` conditionIDs | LibTalentTree always returns {}   | talent node entries usually have no conditions attached to them  |
| `number?` subTreeID     | None                              | the sub tree ID that the entry will select if any, nil otherwise |
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0");
local entryInfo = LibTalentTree:GetEntryInfo(123);
local definitionInfo = entryInfo and C_Traits.GetDefinitionInfo(entryInfo.definitionID);
local spellID = definitionInfo and definitionInfo.spellID;
```


### GetTreeIDForNode
Get the TreeID for a node
#### Syntax
`treeID = LibTalentTree:GetTreeIDForNode(nodeID)`
#### Arguments
* `number` nodeID - The TraitNodeID of the node you want to get the TraitTreeID for.
#### Returns
* `number|nil` treeID - TraitTreeID for the node, nil if not found.


### GetTreeIDForEntry
Get the TreeID for a node entry
#### Syntax
`treeID = LibTalentTree:GetTreeIDForEntry(entryID)`
#### Arguments
* `number` entryID - The TraitEntryID of the node entry you want to get the TraitTreeID for.
#### Returns
* `number|nil` treeID - TraitTreeID for the node entry, nil if not found.


### GetClassTreeID
Get the TreeID for a class
#### Syntax
`treeID = LibTalentTree:GetClassTreeID(classID | classFileName)`
#### Arguments
* `number` classID - The [ClassID](https://warcraft.wiki.gg/wiki/ClassID) of the class you want to get the TraitTreeID for.
* `string` classFile - Locale-independent name, e.g. `"WARRIOR"`.
#### Returns
* `number|nil` treeID - TraitTreeID for the class' talent tree, nil for invalid arguments.
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
-- the following 2 lines are equivalent
local treeID = LibTalentTree:GetClassTreeID(2)
local treeID = LibTalentTree:GetClassTreeID('PALADIN')
local nodes = C_Traits.GetTreeNodes(treeID)
```


### GetClassIDByTreeID
Get the ClassID for a tree
#### Syntax
`classID = LibTalentTree:GetClassIDByTreeID(treeID)`
#### Arguments
* `number` treeID - The TraitTreeID of the tree you want to get the ClassID for.
#### Returns
* `number|nil` classID - [ClassID](https://warcraft.wiki.gg/wiki/ClassID) for the tree, nil if not found.


### IsNodeVisibleForSpec
Get node visibility
#### Syntax
`isVisible = LibTalentTree:IsNodeVisibleForSpec(specID, nodeID)`
#### Arguments
* `number` specID - [SpecializationID](https://warcraft.wiki.gg/wiki/SpecializationID)
* `number` nodeID - TraitNodeID
#### Returns
* `boolean` isVisible - Whether the node is visible for the given spec.
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local isVisible = LibTalentTree:IsNodeVisibleForSpec(65, 12345)
```


### IsNodeGrantedForSpec
Check if a node is granted by default
#### Syntax
`isGranted = LibTalentTree:IsNodeGrantedForSpec(specID, nodeID)`
#### Arguments
* `number` specID - [SpecializationID](https://warcraft.wiki.gg/wiki/SpecializationID)
* `number` nodeID - TraitNodeID
#### Returns
* `boolean` isGranted - Whether the node is granted by default for the given spec.
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local isGranted = LibTalentTree:IsNodeGrantedForSpec(65, 12345)
```


### GetNodePosition
Returns the x / y position of a node. Note that some trees have a global offset.
#### Syntax
```lua
posX, posY = LibTalentTree:GetNodePosition(nodeID)
```
#### Arguments
* `number` nodeID - TraitNodeID
#### Returns
* `number|nil` posX - X position of the node
* `number|nil` posY - Y position of the node
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local posX, posY = LibTalentTree:GetNodePosition(12345)
```


### GetNodeGridPosition
Returns an abstraction of the node positions into a grid of columns and rows.\
Some specs may have nodes that sit between 2 columns, these columns end in ".5". This happens for example in the Druid and Demon Hunter trees.\
\
The top row is 1, the bottom row is 10\
The first class column is 1, the last class column is 9\
The first spec column is 10
#### Syntax
```lua
column, row = LibTalentTree:GetNodeGridPosition(nodeID)
```
#### Arguments
* `number` nodeID - TraitNodeID
#### Returns
* `number|nil` column - Column of the node, nil if not found. Can be a decimal with .5 for nodes that sit between 2 columns.
* `number|nil` row - Row of the node, nil if not found
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local column, row = LibTalentTree:GetNodeGridPosition(12345)
```


### IsClassNode
Check if a node is part of the class tree or not
#### Syntax
```lua
isClassNode = LibTalentTree:IsClassNode(nodeID)
```
#### Arguments
* `number` nodeID - TraitNodeID
#### Returns
* `boolean|nil` isClassNode - true if the node is a class node, false otherwise; nil if the node isn't found
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local isClassNode = LibTalentTree:IsClassNode(12345)
```


### GetNodeEdges
#### Syntax
```lua
edges = LibTalentTree:GetNodeEdges(nodeID)
```
#### Arguments
* `number` nodeID - TraitNodeID
#### Returns
* `table` edges - A list of visibleEdges.
##### visibleEdges
| Field                | Differences from C_Traits | Extra info                                                                                                                                               |
|----------------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `number` type        | None                      | 0: VisualOnly, 1: DeprecatedRankConnection, 2: SufficientForAvailability, 3: RequiredForAvailability, 4: MutuallyExclusive, 5: DeprecatedSelectionOption |
| `number` visualStyle | None                      | 0: None, 1: Straight                                                                                                                                     |
| `number` targetNode  | None                      | TraitNodeID                                                                                                                                              |

#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local edges = LibTalentTree:GetNodeEdges(12345)
for _, edge in ipairs(edges) do
  print(edge.targetNode)
end
```


### GetGates
Returns a list of gates for a given spec.
The data is similar to C_Traits.GetTreeInfo and C_Traits.GetConditionInfo, essentially aiming to supplement both APIs.
#### Syntax
`gates = LibTalentTree:GetGates(specID)`
#### Arguments
* `number` specID - The [specID](https://warcraft.wiki.gg/wiki/SpecializationID) of the spec you want to get the gates for.
#### Returns
* `table` gates - list of `table` gateInfo - the order is not guaranteed to be the same as C_Traits.GetTreeInfo, but is will always be sorted by spentAmountRequired
##### gateInfo
| Field                        | Differences from C_Traits                                                                                  | Extra info                                                                                                     |
|------------------------------|------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| `number` topLeftNodeID       | (TraitGateInfo) None                                                                                       | The UI uses this node to anchor the Gate UI element to                                                         |
| `number` conditionID         | (TraitGateInfo) None                                                                                       |                                                                                                                |
| `number` spentAmountRequired | (TraitCondInfo) Always gives the **total** spending required, rather than [ totalRequired - alreadySpent ] | Especially useful for finding out the real gate cost when you're already spend points in your character's tree |
| `number` traitCurrencyID     | (TraitCondInfo) None                                                                                       |                                                                                                                |


### GetTreeCurrencies
Returns a list of TraitCurrencyInfo for a given TraitTree
The data is similar to `C_Traits.GetTreeCurrencyInfo`, but enriched with more info
#### Syntax
`treeCurrencies = LibTalentTree:GetTreeCurrencies(treeID)`
#### Arguments
* `number` treeID - TraitTreeID
#### Returns
* `table` treeCurrencies - list of `table` treeCurrencyInfo - first entry is class currency, second is spec currency, the rest are sub tree currencies. The list is additionally indexed by the traitCurrencyID
##### treeCurrencyInfo
| Field                      | Differences from C_Traits                | Extra info                                                                            |
|----------------------------|------------------------------------------|---------------------------------------------------------------------------------------|
| `number` traitCurrencyID   | None                                     |                                                                                       |
| `number` quantity          | Always matches maxQuantity for max level |                                                                                       |
| `number?` maxQuantity      | Always matches maxQuantity for max level |                                                                                       |
| `number` spent             | Always 0                                 |                                                                                       |
| `boolean?` isClassCurrency | Lib-Only                                 | true if the currency is a class tree currency, nil otherwise                          |
| `boolean?` isSpecCurrency  | Lib-Only                                 | true if the currency is a spec tree currency, nil otherwise                           |
| `number?` subTreeID        | Lib-Only                                 | DEPRECATED! one of the subTreeIDs that the currency is used for if any, nil otherwise |
| `number[]?` subTreeIDs     | Lib-Only                                 | the subTreeIDs that the currency is used for if any, nil otherwise                    |
#### Example
```lua
local LibTalentTree = LibStub("LibTalentTree-1.0")
local treeID = LibTalentTree:GetClassTreeID('PALADIN')
local treeCurrencies = LibTalentTree:GetTreeCurrencies(treeID)
local classCurrency = treeCurrencies[1]
local specCurrency = treeCurrencies[2]
```


### GetSubTreeNodeIDs
Returns a list hero spec nodes for a given sub tree
#### Syntax
`subTreeNodes = LibTalentTree:GetSubTreeNodeIDs(subTreeID)`
#### Arguments
* `number` subTreeID - [HeroSpecID](https://warcraft.wiki.gg/wiki/HeroSpecID)
#### Returns
* `number[]` subTreeNodes - list of nodeIDs


### GetSubTreeIDsForSpecID
Returns the hero spec SubTreeIDs for a given spec
#### Syntax
`subTrees = LibTalentTree:GetSubTreeIDsForSpecID(specID)`
#### Arguments
* `number` specID - [SpecID](https://warcraft.wiki.gg/wiki/SpecializationID)
#### Returns
* `number[]` subTrees - list of [HeroSpecIDs](https://warcraft.wiki.gg/wiki/HeroSpecID)


### GetSubTreeInfo
Returns the sub tree info for a given sub tree
Alternative to `C_Traits.GetSubTreeInfo`
#### Syntax
`subTreeInfo = LibTalentTree:GetSubTreeInfo(subTreeID)`
#### Arguments
* `number` subTreeID - [HeroSpecID](https://warcraft.wiki.gg/wiki/HeroSpecID)
#### Returns
* `table|nil` subTreeInfo - nil if not found
##### subTreeInfo
| Field                              | Differences from C_Traits | Extra info                                                                               |
|------------------------------------|---------------------------|------------------------------------------------------------------------------------------|
| `number` ID                        | None                      |                                                                                          |
| `string` name                      | None                      | localized name                                                                           |
| `string` description               | None                      | localized description                                                                    |
| `string` iconElementID             | None                      | icon atlas                                                                               |
| `number` posX                      | None                      | generally corresponds to posX of the top center node                                     |
| `number` posY                      | None                      | generally corresponds to posY of the top center node                                     |
| `number` traitCurrencyID           | None                      | TraitCurrencyID spent when learning talents in this sub tree                             |
| `number[]` subTreeSelectionNodeIDs | None                      | list of TraitNodeIDs - the selection nodes that specify whether the sub tree is selected |
| `boolean` isActive                 | Always false              |                                                                                          |
| `number` maxCurrency               | Lib-Only                  | maximum amount of currency that can be spent in this sub tree                            |
| `number` requiredPlayerLevel       | Lib-Only                  |                                                                                          |


### GetSubTreeSelectionNodeIDAndEntryIDBySpecID
Returns the selection node and entry for a given spec and sub tree
#### Syntax
`nodeID, entryID = LibTalentTree:GetSubTreeSelectionNodeIDAndEntryIDBySpecID(specID, subTreeID)`
#### Arguments
* `number` specID - [SpecID](https://warcraft.wiki.gg/wiki/SpecializationID)
* `number` subTreeID - [HeroSpecID](https://warcraft.wiki.gg/wiki/HeroSpecID)
#### Returns
* `number|nil` nodeID - TraitNodeID; or nil if not found
* `number|nil` entryID - TraitEntryID; or nil if not found


### IsCompatible
Returns whether the library is compatible with the current game version.
This is generally always true for Retail, and always false for Classic.
#### Syntax
` `boolean` isCompatible = LibTalentTree:IsCompatible()`
#### Returns
* `boolean` isCompatible - Whether the library is compatible with the current game version.
