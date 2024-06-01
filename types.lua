-- this file contains some of the type definitions used in this library


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
---@field ID number # TraitNodeID
---@field posX number
---@field posY number
---@field type nodeType # see Enum.TraitNodeType
---@field maxRanks number
---@field flags nodeFlags # see Enum.TraitNodeFlag
---@field groupIDs number[]
---@field visibleEdges visibleEdge[] # The order does not always match C_Traits
---@field conditionIDs number[]
---@field entryIDs number[] # TraitEntryID - generally, choice nodes will have 2, otherwise there's just 1
---@field specInfo table<number, number[]> # specId: conditionType[] Deprecated, will be removed in 10.1.0; see Enum.TraitConditionType
---@field visibleForSpecs table<number, boolean> # specId: true/false, true if a node is visible for a spec; added in 10.1.0
---@field grantedForSpecs table<number, boolean> # specId: true/false, true if a node is granted for free, for a spec; added in 10.1.0
---@field isClassNode boolean

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
