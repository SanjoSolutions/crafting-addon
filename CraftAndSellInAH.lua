CraftAndSellInAH = {}
--- @class AddOn
local AddOn = select(2, ...)
local _ = {}

-- highest quality all

--TSM_API.GetBagQuantity('i:198243::i346')
--TSM_API.GetBagQuantity('i:198243')
-- /dump C_TradeSkillUI.GetRecipeSchematic(382392, false)
-- /dump C_TradeSkillUI.GetRecipeSchematic(ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID, false)

-- /dump CraftAndSellInAH._.determineAmountInInventory('i:198186')
-- /dump TSM_API.GetGuildQuantity('i:198186')

CraftAndSellInAH._ = _

local toCraftAndSellInAH = {
  -- Engineering
  {
    id = 198243,
    name = "Draconium Delver's Helmet",
    level = 346,
    recipeID = 382392,
    amount = 10
  },
  {
    id = 194125,
    name = "Spring-Loaded Draconium Fabric Cutters",
    level = 346,
    missive = "Draconic Missive of Inspiration",
    missiveIDs = Set.create({ 198534, 198535, 198536 }),
    recipeID = 382396,
    amount = 10
  },
  {
    id = 198225,
    name = "Draconium Fisherfriend",
    level = 346,
    recipeID = 382394,
    amount = 10
  },
  {
    id = 198234,
    name = "Lapidary's Draconium Clamps",
    level = 346,
    missive = "Draconic Missive of Inspiration",
    missiveIDs = Set.create({ 198534, 198535, 198536 }),
    recipeID = 382395,
    amount = 10
  },
  {
    id = 198262,
    name = "Bottomless Stonecrust Ore Satchel",
    level = 346,
    recipeID = 382393,
    amount = 10
  },
  {
    id = 198204,
    name = "Draconium Brainwave Amplifier",
    level = 346,
    recipeID = 382398,
    amount = 10
  },
  --{
  --  id = 198255,
  --  name = "Calibrated Safety Switch",
  --  recipeID = 382350,
  --  amount = 5,
  --  quality = 3
  --},
  {
    id = 198197,
    recipeID = 382379,
    amount = 250
  },

  -- Blacksmithing
  {
    id = 194541,
    name = "Prototype Regal Barding Framework",
    recipeID = 377280,
    amount = 1
  },
  {
    id = 194542,
    name = "Prototype Explorer's Barding Framework",
    recipeID = 377281,
    amount = 1
  },
  {
    id = 193609,
    name = "Crimson Combatant's Draconium Armguards",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 376617,
    amount = 10
  },
  {
    id = 193603,
    name = "Crimson Combatant's Draconium Sabatons",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 376623,
    amount = 10
  },
  {
    id = 201952,
    name = "Explorer's Expert Spaulders",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 395880,
    amount = 10
  },
  {
    id = 193605,
    name = "Crimson Combatant's Draconium Helm",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 376621,
    amount = 10
  },
  {
    id = 191242,
    name = "Draconium Pickaxe",
    level = 346,
    missiveIDs = Set.create({ 200577, 200578, 200579 }),
    recipeID = 371309,
    amount = 10
  },
  {
    id = 190484,
    name = "Draconium Sword",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 367599,
    amount = 10
  },
  {
    id = 191236,
    name = "Draconium Leatherworker's Toolset",
    level = 346,
    recipeID = 371360,
    amount = 10
  },
  {
    id = 201322,
    name = "Draconium Defender",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 393404,
    amount = 10
  },
  {
    id = 191240,
    name = "Draconium Skinning Knife",
    level = 346,
    missive = "Draconic Missive of Perception",
    missiveIDs = Set.create({ 200577, 200578, 200579 }),
    recipeID = 371304,
    amount = 10
  },
  {
    id = 201955,
    name = "Explorer's Expert Clasp",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 367611,
    amount = 10
  },
  {
    id = 190485,
    name = "Draconium Knuckles",
    level = 343,
    missive = "Draconic Missive of Peerless",
    missiveIDs = Set.create({ 194579, 194580, 194578 }),
    recipeID = 367595,
    amount = 10
  },
  --{
  --  id = 190487,
  --  name = "Draconium Axe",
  --  level = 343,
  --  missiveIDs = Set.create({ 194567, 194568, 194566 }),
  --  recipeID = 367600
  --},
  --{
  --  id = 189538,
  --  name = "Explorer's Plate Chestguard",
  --  level = 316,
  --  missiveIDs = Set.create({ 194567, 194568, 194566 }),
  --  recipeID = 395886
  --},
  --{
  --  id = 189537,
  --  name = "Explorer's Plate Boots",
  --  level = 316,
  --  missiveIDs = Set.create({ 194567, 194568, 194566 }),
  --  recipeID = 367610
  --},
  {
    id = 193602,
    name = "Crimson Combatant's Draconium Breastplate",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 376618,
    amount = 10
  },
  --{
  --  id = 201324,
  --  name = "Draconium Great Axe",
  --  level = 343,
  --  missiveIDs = Set.create({ 194567, 194568, 194566 }),
  --  recipeID = 393416
  --},
  {
    id = 191241,
    name = "Draconium Sickle",
    level = 346,
    missive = "Draconic Missive of Perception",
    missiveIDs = Set.create({ 200577, 200578, 200579 }),
    recipeID = 371343,
    amount = 10
  },
  {
    id = 191238,
    name = "Draconium Leatherworker's Knife",
    level = 346,
    missive = "Draconic Missive of Inspiration",
    missiveIDs = Set.create({ 198534, 198535, 198536 }),
    recipeID = 371338,
    amount = 10
  },
  {
    id = 190483,
    name = "Draconium Dirk",
    level = 343,
    missive = "Draconic Missive of the Quickblade",
    missiveIDs = Set.create({ 194573, 194574, 194572 }),
    recipeID = 367596,
    amount = 10
  },
  {
    id = 190482,
    name = "Draconium Stiletto",
    level = 343,
    missive = "Draconic Missive of the Quickblade",
    missiveIDs = Set.create({ 194573, 194574, 194572 }),
    recipeID = 367597,
    amount = 10
  },
  {
    id = 201953,
    name = "Explorer's Expert Gauntlets",
    level = 343,
    missiveIDs = Set.create({ 194567, 194568, 194566 }),
    recipeID = 395879,
    amount = 10
  },
  {
    id = 191304,
    name = "Sturdy Expedition Shovel",
    recipeID = 388279,
    amount = 100,
  },
  {
    id = 191235,
    name = "Draconium Blacksmith's Toolbox",
    level = 346,
    recipeID = 371364,
    amount = 10
  },
}

AddOn.SourceType = {
  NPCVendor = 1,
  Crafting = 2,
  AuctionHouse = 3,
  GuildBank = 4,
  OtherCharacter = 5,
  Mail = 6,
  Otherwise = 7
}

local sourceTypeToName = {
  [AddOn.SourceType.NPCVendor] = 'NPC vendor',
  [AddOn.SourceType.Crafting] = 'Crafting',
  [AddOn.SourceType.AuctionHouse] = 'Auction house',
  [AddOn.SourceType.GuildBank] = 'Guild bank',
  [AddOn.SourceType.OtherCharacter] = 'Other character',
  [AddOn.SourceType.Mail] = 'Mail',
  [AddOn.SourceType.Otherwise] = 'Otherwise'
}

function AddOn.generateThingsToRetrieveText(thingsToRetrieve)
  local text = ''
  for __, thingToRetrieve in ipairs(thingsToRetrieve) do
    local sourceType = thingToRetrieve.source
    local thingsToRetrieveFromSource = thingToRetrieve.thingsToRetrieveFromSource
    if text ~= '' then
      text = text .. '\n'
    end
    text = text .. AddOn.generateThingsToRetrieveFromSourceText(sourceType, thingsToRetrieveFromSource)
  end
  return text
end

function _.determineThingsToCraft()
  local thingsToCraft = {}
  for __, item in ipairs(toCraftAndSellInAH) do
    local totalAmount = item.amount or 1
    if _.canBeCraftedForALowerPriceThanSoldInTheAuctionHouse(item) then
      local itemString = _.generateItemString(item)
      local amountToCraft = math.max(totalAmount - TSM_API.GetAuctionQuantity(itemString) - _.determineAmountInInventory(itemString),
        0)
      if amountToCraft >= 1 then
        table.insert(thingsToCraft, Object.assign({}, item, { amount = amountToCraft }))
      end
    end
  end
  return thingsToCraft
end

function _.canBeCraftedForALowerPriceThanSoldInTheAuctionHouse(item, preferredReagents)
  --local recipe = _.retrieveRecipeForItem(item.id)
  --local recipeData = _.createCraftSimRecipeData(recipe)
  ---- local priceData =
  --return CraftSim.CALC:getMeanProfit(recipeData, priceData) > 0
  local itemString = _.generateItemString(item)
  return TSM_API.GetCustomPriceValue('DBRecent', itemString) * 0.95 > _.determineCraftingCost(item, preferredReagents)
end

function _.retrieveMaterialsForThingsToCraft(thingsToCraft)
  local thingsToRetrieve = AddOn.determineThingsToRetrieve(thingsToCraft)
  return thingsToRetrieve
end

function AddOn.determineThingsToRetrieve(thingsToCraft)
  local thingsToRetrieve = _.determineThingsToRetrieve(thingsToCraft)
  Array.forEach(thingsToRetrieve, function(thingToRetrieve)
    --thingToRetrieve.itemIDs = Set.create(Array.select(thingToRetrieve.itemIDs:toList(), function(itemID)
    --  return _.canBeCraftedForALowerPriceThanSoldInTheAuctionHouse(thingToRetrieve, Set.create({ itemID }))
    --end))
    thingToRetrieve.amount = math.max(thingToRetrieve.amount - Math.sum(Array.map(thingToRetrieve.itemIDs:toList(),
      function(id)
        local itemString = _.generateItemString({ id = id, level = thingToRetrieve.level })
        -- Reagents from those sources can directly be used for crafting.
        return TSM_API.GetBagQuantity(itemString) + TSM_API.GetBankQuantity(itemString) + TSM_API.GetReagentBankQuantity(itemString)
      end)), 0)
  end)
  thingsToRetrieve = Array.filter(thingsToRetrieve, function(thingToRetrieve)
    return thingToRetrieve.amount >= 1
  end)

  local inventory = {
    [AddOn.SourceType.Mail] = {},
    [AddOn.SourceType.GuildBank] = {},
    [AddOn.SourceType.OtherCharacter] = {}
  }
  Array.forEach(thingsToRetrieve, function(thingToRetrieve)
    Array.forEach(thingToRetrieve.itemIDs:toList(), function(itemID)
      if not inventory[AddOn.SourceType.Mail][itemID] then
        inventory[AddOn.SourceType.Mail][itemID] = 0
      end
      local itemString = _.generateItemString({ id = itemID })
      inventory[AddOn.SourceType.Mail][itemID] = inventory[AddOn.SourceType.Mail][itemID] + TSM_API.GetMailQuantity(itemString)

      if not inventory[AddOn.SourceType.GuildBank][itemID] then
        inventory[AddOn.SourceType.GuildBank][itemID] = 0
      end
      local itemString = _.generateItemString({ id = itemID })
      inventory[AddOn.SourceType.GuildBank][itemID] = inventory[AddOn.SourceType.GuildBank][itemID] + TSM_API.GetGuildQuantity(itemString)

      -- TODO: Other characters
    end)
  end)

  local groups = {}
  Array.forEach(thingsToRetrieve, function(thingToRetrieve)
    local bestSources = AddOn.determineBestSourcesToRetrieveThingFrom(inventory, thingToRetrieve)
    for source, object in pairs(bestSources) do
      if not groups[source] then
        groups[source] = {}
      end
      local item = Object.assign({}, thingToRetrieve, object)
      item.itemIDs = nil
      table.insert(groups[source], item)
    end
  end)

  local list = {}

  local order = {
    AddOn.SourceType.Mail,
    AddOn.SourceType.GuildBank,
    AddOn.SourceType.NPCVendor,
    AddOn.SourceType.AuctionHouse,
    AddOn.SourceType.OtherCharacter,
    AddOn.SourceType.Otherwise,
    AddOn.SourceType.Crafting
  }
  Array.forEach(order, function(source)
    if groups[source] then
      table.insert(list, {
        source = source,
        thingsToRetrieveFromSource = groups[source]
      })
    end
  end)

  return list
end

function _.determineThingsToRetrieve(thingsToCraft)
  return _.sum(Array.flatMap(thingsToCraft, _.determineThingsToRetrieveForThing))
end

function _.determineThingsToRetrieveForThing(thingToCraft)
  local thingsRequiredForThing = _.determineThingsRequiredForThing(thingToCraft)
  local thingsToRetrieveForThing = {}
  local recipe = _.retrieveRecipeForRecipeID(thingToCraft.recipeID)
  local item = {
    id = Array.last(recipe.craftedItemIDs), -- TODO: Determine what quality can be produced.
    recipeID = thingToCraft.recipeID
  }
  Array.forEach(thingsRequiredForThing, function(thingRequiredForThing)
    local itemIDs = Set.create(Array.select(thingRequiredForThing.itemIDs:toList(), function(itemID)
      return _.canBeCraftedForALowerPriceThanSoldInTheAuctionHouse(item, Set.create({ itemID }))
    end))
    local amount = math.max(thingRequiredForThing.amount - Math.sum(Array.map(itemIDs:toList(),
      function(id)
        local itemString = _.generateItemString({ id = id, level = thingRequiredForThing.level })
        -- Reagents from those sources can directly be used for crafting.
        return TSM_API.GetBagQuantity(itemString) + TSM_API.GetBankQuantity(itemString) + TSM_API.GetReagentBankQuantity(itemString)
      end)), 0)
    if amount >= 1 then
      local thingToRetrieveForThing = Object.assign({}, thingRequiredForThing, {
        itemIDs = itemIDs,
        amount = amount
      })
      table.insert(thingsToRetrieveForThing, thingToRetrieveForThing)
    end
  end)

  return thingsToRetrieveForThing
end

function _.determineMinimumQualityRequiredForCraft(thingToCraft)
  return 1 -- TODO: Implement
end

-- /dump CopyToClipboard(select(2, GetItemInfo(190396)))

-- [Serevite Ore |A:Professions-ChatIcon-Quality-Tier2:17:23::1|a]

function _.determineQualityOfItem(itemID)
  _.loadItem(itemID)
  local itemLink = select(2, GetItemInfo(itemID))
  print(itemLink)
  local qualityString = string.match(itemLink, 'Professions-ChatIcon-Quality-Tier(%d)')
  local quality
  if qualityString then
    quality = tonumber(qualityString, 10)
  else
    quality = nil
  end
  return quality
end

function _.determineThingsRequiredForThing(thingToCraft)
  local thingsRequiredForThing = {}
  local thingsRequiredPerThing = _.determineThingsRequiredPerThing(thingToCraft)
  Array.forEach(thingsRequiredPerThing, function(thingRequiredPerThing)
    table.insert(thingsRequiredForThing, Object.assign({}, thingRequiredPerThing, {
      amount = (thingToCraft.amount or 1) * thingRequiredPerThing.amount
    }))
  end)
  return thingsRequiredForThing
end

function _.determineThingsRequiredPerThing(thingToCraft)
  local recipeID = thingToCraft.recipeID
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
  local reagentSlotSchematics = recipeSchematic.reagentSlotSchematics
  local thingsToBuy = {}

  -- optimization goal: maximize "average profit / craft"
  -- options:
  --  * reach guaranteed
  --  * reach inspiration breakpoint
  -- _.determineOptimalWayToCraft(thingToCraft)

  --if thingToCraft.quality then
  --
  --elseif thingToCraft.level then
  --
  --else
  Array.forEach(reagentSlotSchematics, function(reagentSlotSchematic)
    if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic then
      local itemIDs = Array.map(reagentSlotSchematic.reagents, function(reagent)
        return reagent.itemID
      end)

      local recipeID
      if Array.hasElements(itemIDs) then
        recipeID = _.retrieveRecipeIDForItem(itemIDs[1])
      else
        recipeID = nil
      end
      table.insert(thingsToBuy, {
        recipeID = recipeID,
        itemIDs = Set.create(itemIDs),
        amount = reagentSlotSchematic.quantityRequired
      })
    end
  end)
  if thingToCraft.missiveIDs then
    local recipeID
    if Array.hasElements(thingToCraft.missiveIDs) then
      recipeID = _.retrieveRecipeIDForItem(thingToCraft.missiveIDs[1])
    else
      recipeID = nil
    end
    local recipeID = table.insert(thingsToBuy, {
      recipeID = recipeID,
      itemIDs = thingToCraft.missiveIDs,
      amount = 1
    })
  end
  --end

  return thingsToBuy
end

function _.determineOptimalWayToCraft(thingToCraft)
  local isCooking = recipeData.professionID == Enum.Profession.Cooking
  local gearCombos = CraftSim.TOPGEAR:GetProfessionGearCombinations(isCooking)
  if gearCombos then
    local exportMode = CraftSim.CONST.EXPORT_MODE.NON_WORK_ORDER
    local recipeData = CraftSim.DATAEXPORT:exportRecipeData(thingToCraft.recipeID, exportMode)
    if recipeData then
      local recipeType = recipeData.recipeType
      local priceData = CraftSim.PRICEDATA:GetPriceData(recipeData, recipeType)
      local noItemsRecipeData = CraftSim.TOPGEAR:DeductCurrentItemStats(recipeData, recipeType)
      local simulationResults = _.simulateProfessionGearCombinations(gearCombos, noItemsRecipeData,
        recipeType, priceData)

    end
  end
end

function _.simulateProfessionGearCombinations(gearCombos, recipeData, recipeType, priceData)
  local results = {}

  for __, gearCombination in pairs(gearCombos) do
    local statChanges = CraftSim.TOPGEAR:GetStatChangesFromGearCombination(gearCombination)
    local modifiedRecipeData = CraftSim.TOPGEAR:GetModifiedRecipeDataByStatChanges(recipeData, recipeType, statChanges)
    -- TODO: Optimize material choices to maximize profit. Seem only relevant if the inspiration stat changes.
    local meanProfit = CraftSim.CALC:getMeanProfit(modifiedRecipeData, priceData)
    table.insert(results, {
      meanProfit = meanProfit,
      combo = gearCombination,
      modifiedRecipeData = modifiedRecipeData
    })
  end

  return results
end

-- /dump C_TradeSkillUI.GetRecipeInfo(ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID)

-- /dump C_TradeSkillUI.GetRecipeSchematic(ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID, false)

-- /dump C_TradeSkillUI.GetRecipeInfo(382379)

function AddOn.scanRecipes()
  C_TradeSkillUI.GetChildProfessionInfo()
  local professionInfo = C_TradeSkillUI.GetChildProfessionInfo()
  for __, recipeID in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
    local craftedItemIDs = _.retrieveCraftedItemIDs(recipeID)

    CraftingSavedVariables.recipes[recipeID] = {
      recipeID = recipeID,
      categoryID = recipeInfo.categoryID,
      profession = professionInfo.profession,
      skillLineAbilityID = recipeInfo.skillLineAbilityID,
      craftedItemIDs = craftedItemIDs,
      recipeInfo = recipeInfo
    }

    Array.forEach(craftedItemIDs, function(itemID)
      CraftingSavedVariables.itemIDToRecipeID[itemID] = recipeID
    end)
  end
end

function _.retrieveCachedRecipeInfo(recipeID)
	local recipe = _.retrieveRecipeForRecipeID(recipeID)
  if recipe then
    return recipe.recipeInfo
  else
    return nil
  end
end

local retrieveRecipeInfo = C_TradeSkillUI.GetRecipeInfo
C_TradeSkillUI.GetRecipeInfo = function (recipeID, recipeLevel)
  return retrieveRecipeInfo(recipeID, recipeLevel) or _.retrieveCachedRecipeInfo(recipeID)
end

function _.retrieveCraftedItemIDs(recipeID)
  local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
  if recipeInfo.qualityItemIDs then
    return recipeInfo.qualityItemIDs
  else
    local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    local outputItemID = recipeSchematic.outputItemID
    if outputItemID then
      return { outputItemID }
    else
      return {}
    end
  end
end

function _.retrieveRecipeForItem(itemID)
  local recipeID = _.retrieveRecipeIDForItem(itemID)
  if recipeID then
    return _.retrieveRecipeForRecipeID(recipeID)
  else
    return nil
  end
end

function _.retrieveRecipeForRecipeID(recipeID)
	return CraftingSavedVariables.recipes[recipeID]
end

function _.retrieveRecipeIDForItem(itemID)
  return CraftingSavedVariables.itemIDToRecipeID[itemID]
end

function _.sum(thingsToBuy)
  local totalThingsToBuy = {}
  local lookup = {}
  Array.forEach(thingsToBuy, function(thingToBuy)
    local firstItemID = thingToBuy.itemIDs:toList()[1]
    local entry = lookup[firstItemID]
    if entry then
      entry.amount = entry.amount + thingToBuy.amount
    else
      local entry = Object.copy(thingToBuy)
      table.insert(totalThingsToBuy, entry)
      lookup[firstItemID] = entry
    end
  end)
  return totalThingsToBuy
end

function _.craftThings(thingsToCraft)

end

function AddOn.generateThingsToRetrieveFromSourceText(sourceType, thingsToRetrieve)
  local text = ''
  if sourceTypeToName[sourceType] then
    text = text .. sourceTypeToName[sourceType] .. ':'
    Array.forEach(thingsToRetrieve, function(thingToRetrieve)
      local itemID = thingToRetrieve.itemID
      _.loadItem(itemID)
      local itemLink = select(2, GetItemInfo(itemID))
      local line = '  ' .. thingToRetrieve.amount .. ' x ' .. itemLink
      text = text .. '\n' .. line
    end)
  end
  return text
end

function _.join(itemLinks)
  local string = ''
  local length = Array.length(itemLinks)
  for index, itemLink in ipairs(itemLinks) do
    if index >= 2 then
      local isLastItem = index == length
      if isLastItem then
        string = string .. ' or '
      else
        string = string .. ', '
      end
    end

    string = string .. itemLink
  end
  return string
end

function _.determineAmountInInventory(itemString)
  return TSM_API.GetBagQuantity(itemString) + TSM_API.GetBankQuantity(itemString) + TSM_API.GetReagentBankQuantity(itemString) + TSM_API.GetMailQuantity(itemString) + TSM_API.GetGuildQuantity(itemString)
end

function _.generateItemString(item)
  local itemString = 'i:' .. item.id
  if item.level then
    itemString = itemString .. '::i' .. item.level
  end
  return itemString
end

function _.generateThingsToCraftText(thingsToCraft)
  local text = 'To craft:\n'
  Array.forEach(thingsToCraft, function(thingToCraft)
    _.loadItem(thingToCraft.id)
    local line = thingToCraft.amount .. ' x ' .. _.retrieveRecipeOutputItemLink(thingToCraft.recipeID,
      thingToCraft.quality)
    if thingToCraft.missiveIDs then
      local missiveID = thingToCraft.missiveIDs:toList()[1]
      if missiveID then
        _.loadItem(missiveID)
        local itemLink = select(2, GetItemInfo(missiveID))
        line = line .. ' (with ' .. itemLink .. ')'
      end
    end
    text = text .. line .. '\n'
  end)
  return text
end

function _.retrieveRecipeOutputItemLink(recipeID, quality)
  return _.retrieveRecipeOutputItemData(recipeID, quality).hyperlink
end

function _.retrieveRecipeOutputItemData(recipeID, quality)
  return C_TradeSkillUI.GetRecipeOutputItemData(recipeID, nil, nil, 3 + quality)
end

function _.loadItem(itemID)
  local item = Item:CreateFromItemID(itemID)
  if not item:IsItemDataCached() then
    local thread = coroutine.running()

    item:ContinueOnItemLoad(function()
      Coroutine.resumeWithShowingError(thread)
    end)

    coroutine.yield()
  end
end

function _.showText(text)
  AddOn.showText(ChatFrame4, text)
end

function AddOn.showText(chatFrame, text)
  chatFrame:Clear()

  local lines = String.splitLines(text)
  Array.forEach(lines, function(line)
    chatFrame:AddMessage(line)
  end)
end

function _.determineCraftingCost(item, preferredReagents)
  if item.recipeID then
    local thingsRequired = _.determineThingsRequiredPerThing(item)
    local averageAmountProduced = _.determineAverageAmountProduced(item)
    if averageAmountProduced then
      return Math.sum(Array.map(thingsRequired, function(thing)
        local itemID
        if preferredReagents then
          itemID = Array.find(thing.itemIDs:toList(), function(itemID)
            return preferredReagents:contains(itemID)
          end)
        end
        if not itemID then
          itemID = Array.min(thing.itemIDs:toList(), function(itemID)
            local item = {
              id = itemID
            }
            local itemString = _.generateItemString(item)
            return TSM_API.GetCustomPriceValue('DBRecent', itemString)
          end)
        end
        local itemString = _.generateItemString({ id = itemID })
        local price = TSM_API.GetCustomPriceValue('DBRecent', itemString)
        return thing.amount * price
      end)) / averageAmountProduced
    else
      return nil
    end
  else
    return nil
  end
end

function _.determineAverageAmountProduced(item)
  local recipe = _.retrieveRecipeForItem(item.id)
  if recipe then
    local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipe.recipeID, false)
    local baseAmount = (recipeSchematic.quantityMin + recipeSchematic.quantityMax) / 2
    local multicraftExtraItemsFactor = _.determineMulticraftExtraItemsFactor(recipe)
    local averageExtraAmountFromMulticraftProc = (1 + (2.5 * baseAmount) * multicraftExtraItemsFactor) / 2
    local averageAmount = baseAmount + averageExtraAmountFromMulticraftProc

    return averageAmount
  else
    return nil
  end
end

function _.determineMulticraftExtraItemsFactor(recipe)
  local recipeData = _.createCraftSimRecipeData(recipe)
  if recipeData then
    if CraftSim.UTIL:IsSpecImplemented(recipeData.professionID) then
      recipeData.specNodeData = CraftSim.DATAEXPORT:exportSpecNodeData(recipeData)
      local rulesNodes = CraftSim.SPEC_DATA.RULE_NODES()[recipeData.professionID]
      local stats = CraftSim.SPEC_DATA:GetStatsFromSpecNodeData(recipeData, rulesNodes)
      return stats.multicraft.bonusItemsFactor
    else
      local extraItemFactors = CraftSim.SPEC_DATA:GetSpecExtraItemFactorsByRecipeData(recipeData)
      return extraItemFactors.multicraftExtraItemsFactor
    end
  else
    return nil
  end
end

function _.createCraftSimRecipeData(recipe)
  local craftedItemIDs = recipe.craftedItemIDs
  local itemID = craftedItemIDs[1]
  if itemID then
    local subclassID = select(7, GetItemInfoInstant(itemID))
    local recipeData = {
      professionID = recipe.profession,
      professionInfo = {
        skillLineID = recipe.skillLineAbilityID
      },
      recipeID = recipe.recipeID,
      categoryID = recipe.categoryID,
      subtypeID = subclassID,
    }
    return recipeData
  else
    return nil
  end
end

function AddOn.determineBestSourcesToRetrieveThingFrom(inventory, thingToRetrieve)
  local bestSources = {}

  -- inventory
  --   mail
  --   guild bank
  --   other characters
  local itemIDs = thingToRetrieve.itemIDs:toList()
  local amountLeft = thingToRetrieve.amount
  table.sort(itemIDs, _.compareQuality)

  local function retrieveFromSource(itemID, source)
    local amountFromSource = math.min(inventory[source][itemID] or 0, amountLeft)
    if amountFromSource >= 1 then
      inventory[source][itemID] = inventory[source][itemID] - amountFromSource
      bestSources[source] = {
        itemID = itemID,
        amount = amountFromSource
      }
      amountLeft = amountLeft - amountFromSource
    end
  end

  local inventorySources = {
    AddOn.SourceType.Mail,
    AddOn.SourceType.GuildBank,
    AddOn.SourceType.OtherCharacter
  }

  for __, itemID in ipairs(itemIDs) do
    for __, source in ipairs(inventorySources) do
      retrieveFromSource(itemID, source)
    end

    -- other sources
    if amountLeft >= 1 then
      local item = {
        id = itemID,
        recipeID = _.retrieveRecipeIDForItem(itemID)
      }
      local npcBuyPrice = _.determineNPCBuyPrice(itemID)
      local craftingPrice = _.determineCraftingCost(item)
      local auctionHouseBuyPrice = _.determineAuctionHouseBuyPrice(item)
      local sources = {}
      if npcBuyPrice then
        table.insert(sources, {
          type = AddOn.SourceType.NPCVendor,
          price = npcBuyPrice
        })
      end
      if craftingPrice then
        table.insert(sources, {
          type = AddOn.SourceType.Crafting,
          price = craftingPrice
        })
      end
      if auctionHouseBuyPrice then
        table.insert(sources, {
          type = AddOn.SourceType.AuctionHouse,
          price = auctionHouseBuyPrice
        })
      end
      local lowestPriceSource = Array.min(sources, function(source)
        return source.price
      end)
      local source
      if lowestPriceSource then
        source = lowestPriceSource.type
      else
        source = AddOn.SourceType.Otherwise
      end
      bestSources[source] = {
        itemID = itemID,
        amount = amountLeft
      }
    end
  end

  return bestSources
end

function _.compareQuality(a, b)
  local qualityA = _.determineQualityOfItem(a)
  local qualityB = _.determineQualityOfItem(b)
  if qualityA == nil and qualityB == nil then
    return true
  elseif qualityA and not qualityB then
    return true
  elseif not qualityA and qualityB then
    return false
  else
    return qualityA < qualityB
  end
end

function _.determineNPCBuyPrice(itemID)
  return nil -- TODO: Implement
end

function _.determineCraftingPrice(itemID)
  print('itemID', itemID)
  local recipeID = _.retrieveRecipeIDForItem(itemID)

  print('recipeID', recipeID)

  if recipeID then
    local exportMode = CraftSim.CONST.EXPORT_MODE.NON_WORK_ORDER
    local recipeData = CraftSim.DATAEXPORT:exportRecipeData(recipeID, exportMode)
    print('recipeData', recipeData)
    if recipeData then
      local recipeType = recipeData.recipeType
      local priceData = CraftSim.PRICEDATA:GetPriceData(recipeData, recipeType)
      local statWeights = CraftSim.AVERAGEPROFIT:getProfessionStatWeightsForCurrentRecipe(recipeData, priceData,
        exportMode)
      local averageAmountProducedPerCraft = statWeights.craftedItems.baseQuality + statWeights.craftedItems.nextQuality
      local averageCraftingCostPerCraftedItem = priceData.craftingCostPerCraft / averageAmountProducedPerCraft
      return averageCraftingCostPerCraftedItem
    end
  end

  return nil
end

function _.determineAuctionHouseBuyPrice(item)
  local itemString = _.generateItemString(item)
  return TSM_API.GetCustomPriceValue('DBRecent', itemString)
end

function _.findRecipesToCraft()
  local allRecipes = _.retrieveAllRecipes()
  local potentialCandidates = Array.filter(allRecipes, function(recipe)
    return _.isCraftable(recipe) and _.canProducedItemBeSoldInTheAuctionHouse(recipe)
  end)
  local recipesToCraft = {}
  Array.forEach(potentialCandidates, function(potentialCandidate)
    local bestConfiguration = _.selectBestConfiguration(potentialCandidate)
    if _.averageProfitPerCraft(bestConfiguration) > 0 then
      table.insert(recipesToCraft, {
        recipe = potentialCandidate,
        amount = _.retrieveAverageDailySold(item)
      })
    end
  end)
  return recipesToCraft
end

function _.isCraftable(recipe)

end

function _.canProducedItemBeSoldInTheAuctionHouse(recipe)

end
