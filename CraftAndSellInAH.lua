-- TODO: Consider if an item can be bought for a lower price from a vendor.

CraftAndSellInAH = {}

CraftAndSellInAH.auctionHousePriceSource = "Auctionator" -- or TSM

--- @class AddOn
local AddOn = select(2, ...)
--- @class _
local _ = {}

AddOn.retrieveCraftSim = function()
  if CraftSim_DEBUG and CraftSim_DEBUG.RUN then
    return CraftSim_DEBUG:RUN()
  elseif CraftSimAPI and CraftSimAPI.GetCraftSim then
    return CraftSimAPI:GetCraftSim()
  else
    error("A reference to CraftSim could not be retrieved.")
  end
end

--- @type Array
local Array = Library.retrieve("Array", "^2.1.1")
--- @type Bags
local Bags = Library.retrieve("Bags", "^2.1.0")
--- @type Coroutine
local Coroutine = Library.retrieve("Coroutine", "^2.0.1")
--- @type Events
local Events = Library.retrieve("Events", "^2.2.0")
--- @type Mathematics
local Mathematics = Library.retrieve("Mathematics", "^2.0.1")
--- @type Object
local Object = Library.retrieve("Object", "^1.1.1")
--- @type Set
local Set = Library.retrieve("Set", "^1.1.2")
--- @type String
local String = Library.retrieve("String", "^2.0.1")
local CraftSim = AddOn.retrieveCraftSim()

--- @alias Item ItemMixin

--- @alias ItemLink string
--- @alias RecipeID number
--- @alias Amount number
--- @alias Money number

--- @class ThingToCraft
--- @field itemLink ItemLink
--- @field recipeID RecipeID
--- @field amount Amount

--- @class CraftingTask
--- @field recipeID RecipeID
--- @field amount Amount
--- @field recipeData CraftSim.RecipeData

--- @class CraftingTaskWithProgress: CraftingTask
--- @field amountCrafted Amount
AddOn.CraftingTaskWithProgress = {}

--- @return CraftingTaskWithProgress
function AddOn.CraftingTaskWithProgress:new(data)
  local craftingTaskWithProgress = data or {}
  setmetatable(craftingTaskWithProgress, self)
  self.__index = self
  return craftingTaskWithProgress
end

function AddOn.CraftingTaskWithProgress:determineAmountRemainingToCraft()
  return self.amount - self.amountCrafted
end

--- @class ThingRequired
--- @field itemLink ItemLink
--- @field amount number
--- @field maximumPurchasePrice Money|nil

--- @class ThingRequiredWithMaximumPurchasePrice: ThingRequired
--- @field maximumPurchasePrice Money

--- @class ItemToRetrieve
--- @field itemLink ItemLink
--- @field amount number
--- @field amountRetrieved number
--- @field maximumPurchasePrice Money|nil

--- @enum SourceType
AddOn.SourceType = {
  NPCVendor = 1,
  Crafting = 2,
  AuctionHouse = 3,
  GuildBank = 4,
  OtherCharacter = 5,
  Mail = 6,
  Elsewhere = 7,
  Bag = 8,
  Bank = 9,
  ReagentBank = 10,
  AuctionHouseCancelling = 11,
}

--- @class BestSourcesEntry
--- @field itemLink ItemLink
--- @field amount Amount
--- @field maximumPurchasePrice Money|nil

--- @alias BestSources { [SourceType]: BestSourcesEntry[] }

--- @class GroupEntry
--- @field itemLink ItemLink
--- @field amount number
--- @field maximumPurchasePrice Money|nil

--- @alias Groups { [SourceType]: { [ItemLink]: GroupEntry } }

--- @alias Inventory { [SourceType]: { [ItemLink]: number } }

--- @alias Retrieval { [SourceType]: number }

--- @alias ThingsToRetrieveStepsList ThingsToRetrieveStep[]

--- @class ThingsToRetrieveStep
--- @field source SourceType
--- @field thingsToRetrieveFromSource ItemToRetrieve[]

--- @enum Profession
AddOn.Profession = {
  -- TODO
}

--- @alias GroupedThingsToCraft { [Profession]: CraftingTask[] }
--- @alias GroupedThingsToCraftWithProgress { [Profession]: CraftingTaskWithProgress[] }

--- @class PurchaseTask
--- @field itemLink ItemLink
--- @field amount Amount
--- @field maximumUnitPriceToBuyFor Money

--- @class SellTask
--- @field itemLink ItemLink
--- @field amount Amount

CraftAndSellInAH._ = _

local sourceTypeToName = {
  [AddOn.SourceType.NPCVendor] = "NPC vendor",
  [AddOn.SourceType.Crafting] = "crafting",
  [AddOn.SourceType.AuctionHouse] = "auction house",
  [AddOn.SourceType.GuildBank] = "guild bank",
  [AddOn.SourceType.OtherCharacter] = "other character",
  [AddOn.SourceType.Mail] = "mail",
  [AddOn.SourceType.Elsewhere] = "elsewhere",
  [AddOn.SourceType.Bag] = "bag",
  [AddOn.SourceType.Bank] = "bank",
  [AddOn.SourceType.ReagentBank] = "reagent bank",
  [AddOn.SourceType.AuctionHouseCancelling] = "auction house (cancelling)",
}

--- @param thingsToRetrieve ThingsToRetrieveStep[]
--- @param groupedThingsToCraft GroupedThingsToCraftWithProgress
function AddOn.generatePlanText(thingsToRetrieve, groupedThingsToCraft)
  local text = ""

  for __, thingToRetrieve in ipairs(thingsToRetrieve) do
    local sourceType = thingToRetrieve.source
    local thingsToRetrieveFromSource = thingToRetrieve
      .thingsToRetrieveFromSource
    text = text ..
      AddOn.generateThingsToRetrieveFromSourceText(sourceType,
        thingsToRetrieveFromSource) .. "\n"
  end

  text = "\n" .. text .. "Craft:\n"
  Array.create(Object.entries(groupedThingsToCraft)):forEach(
    function(entry)
      if CraftingSavedVariables.professions[entry.key] then
        local professionName = CraftingSavedVariables.professions[entry.key]
          .parentProfessionName or CraftingSavedVariables.professions[entry.key]
          .professionName
        text = text .. professionName .. ":\n"
      end
      Array.forEach(entry.value, function(craftingTaskWithProgress, index)
        text = text ..
          index ..
          ". " ..
          craftingTaskWithProgress.amount ..
          " x " ..
          C_TradeSkillUI.GetRecipeLink(craftingTaskWithProgress.recipeID) ..
          " (" ..
          craftingTaskWithProgress.amountCrafted ..
          " / " .. craftingTaskWithProgress.amount .. ")\n"
      end)
    end)

  return text
end

--- @param item Item
--- @return number
function _.determineAuctionHousePrice(item)
  local ahPrice
  if CraftAndSellInAH.auctionHousePriceSource == "TSM" then
    local itemString = AddOn.generateItemString(item)
    ahPrice = TSM_API.GetCustomPriceValue("DBRecent", itemString)
    if ahPrice == nil then
      ahPrice = TSM_API.GetCustomPriceValue("DBMarket", itemString)
    end
  elseif CraftAndSellInAH.auctionHousePriceSource == "Auctionator" then
    ahPrice = Auctionator.API.v1.GetAuctionPriceByItemLink("Crafting",
      item:GetItemLink())
  end

  return ahPrice
end

--- @param thingsToCraft ThingToCraft[]
--- @return ThingsToRetrieveStepsList, GroupedThingsToCraft
function AddOn.determineThingsToRetrieve(thingsToCraft)
  --- @type ThingToCraft[]
  thingsToCraft = Array.map(thingsToCraft, Object.copy)

  --- @type Groups
  local groups = {}
  --- @type Inventory
  local inventory = {
    [AddOn.SourceType.Bag] = {},
    [AddOn.SourceType.Bank] = {},
    [AddOn.SourceType.ReagentBank] = {},
    [AddOn.SourceType.Mail] = {},
    [AddOn.SourceType.GuildBank] = {},
    [AddOn.SourceType.OtherCharacter] = {},
    [AddOn.SourceType.AuctionHouseCancelling] = {},
  }

  Array.forEach(thingsToCraft, function(thingToCraft)
    _.addItemToInventory(inventory, AddOn.createItem(thingToCraft.itemLink))
  end)

  Array.forEach(thingsToCraft, function(thingToCraft)
    local itemLink = thingToCraft.itemLink
    local retrieval = _.retrieveFromInventory(inventory, itemLink,
      thingToCraft.amount)
    for source, amount in pairs(retrieval) do
      if not groups[source] then
        groups[source] = {}
      end
      if groups[source][itemLink] then
        groups[source][itemLink].amount = groups[source][itemLink].amount +
          amount
      else
        groups[source][itemLink] = {
          itemLink = itemLink,
          amount = amount,
        }
      end
    end
    thingToCraft.amount = thingToCraft.amount -
      Mathematics.sum(Object.values(retrieval))
  end)

  --- @type ThingToCraft[]
  thingsToCraft = Array.filter(thingsToCraft, function(thingToCraft)
    return thingToCraft.amount >= 1
  end)

  --- @type { [RecipeID]: CraftingTask }
  local craftingTasks = Object.fromEntries(Array.create(Object.values(Array
      .groupBy(
        thingsToCraft,
        function(thingToCraft)
          return thingToCraft.recipeID
        end)))
    :map(function(thingsToCraft)
      local recipeID = thingsToCraft[1].recipeID

      local recipeData = AddOn.determineRecipeData(recipeID)

      if recipeData then
        return {
          key = recipeID,
          value = {
            recipeID = recipeID,
            amount = math.ceil(Array.max(Array.map(thingsToCraft,
              function(thingToCraft)
                return thingToCraft.amount
              end)) / AddOn.determineAverageAmountProducedByRecipe(recipeData)),
            recipeData = recipeData,
          },
        }
      else
        return nil
      end
    end):selectTrue())

  local extraItemsToCraft = _.determineReagentSourcesForCrafts(
    _.convertCraftingTasksMapToArray(craftingTasks),
    groups,
    inventory)

  while Array.hasElements(extraItemsToCraft) do
    --- @type { [RecipeID]: CraftingTask }
    local furtherCrafts = Object.fromEntries(
      Array.map(Object.entries(
          Array.groupBy(
            Array.map(
              extraItemsToCraft,
              function(thingToCraft)
                return {
                  recipeID = _.retrieveRecipeIDForItem(AddOn.createItem(
                    thingToCraft.itemLink)),
                  amount = thingToCraft.amount,
                }
              end
            ),
            function(thingToCraft)
              return thingToCraft.recipeID
            end
          )
        ),
        function(entry)
          local recipeID = entry.key
          local thingsToCraft = entry.value
          local recipeData = AddOn.determineRecipeData(recipeID)
          return {
            key = recipeID,
            value = {
              recipeID = recipeID,
              amount = math.ceil(
                Mathematics.sum(
                  Array.map(
                    thingsToCraft,
                    function(thingToCraft)
                      return thingToCraft.amount
                    end
                  )
                ) / AddOn.determineAverageAmountProducedByRecipe(recipeData)
              ),
              recipeData = recipeData,
            },
          }
        end)
    )

    for recipeID, craftingTask in pairs(furtherCrafts) do
      if craftingTasks[recipeID] then
        craftingTasks[recipeID].amount = craftingTasks[recipeID].amount +
          craftingTask.amount
      else
        craftingTasks[recipeID] = craftingTask
      end
    end
    extraItemsToCraft = _.determineReagentSourcesForCrafts(
      _.convertCraftingTasksMapToArray(furtherCrafts),
      groups,
      inventory
    )
  end
  groups[AddOn.SourceType.Crafting] = nil

  --- @type ThingsToRetrieveStepsList
  local list = {}

  local order = {
    AddOn.SourceType.Mail,
    AddOn.SourceType.GuildBank,
    AddOn.SourceType.NPCVendor,
    AddOn.SourceType.AuctionHouse,
    AddOn.SourceType.AuctionHouseCancelling,
    AddOn.SourceType.OtherCharacter,
    AddOn.SourceType.Elsewhere,
    AddOn.SourceType.Crafting,
  }
  Array.forEach(order, function(source)
    if groups[source] then
      table.insert(list, {
        source = source,
        thingsToRetrieveFromSource = Array.map(Object.values(groups[source]),
          function(
            groupEntry)
            groupEntry.amountRetrieved = 0
            return groupEntry
          end),
      })
    end
  end)

  --- @type GroupedThingsToCraft
  local groupedThingsToCraft = Array.groupBy(
    _.convertCraftingTasksMapToArray(craftingTasks),
    function(thingToCraft)
      return CraftingSavedVariablesPerCharacter.recipes[thingToCraft.recipeID]
        .profession
    end)

  for source, craftingTasks in pairs(groupedThingsToCraft) do
    groupedThingsToCraft[source] = _.sortByDependencyAndProfit(craftingTasks)
  end

  return list, groupedThingsToCraft
end

-- TODO: Consider amount already in inventory for split.
--- @param craftingTasks CraftingTask[]
--- @return CraftingTask[]
function _.sortByDependencyAndProfit(craftingTasks)
  local craftingTaskLookUp = {}
  for index, craftingTask in ipairs(craftingTasks) do
    craftingTaskLookUp[craftingTask.recipeID] = craftingTask
  end

  local sorted = {}
  local visited = Set.create()

  local visitDependencies

  --- @param craftingTask CraftingTask
  local function visit(craftingTask)
    if not visited:contains(craftingTask) then
      visited:add(craftingTask)
      visitDependencies(craftingTask)
      table.insert(sorted, craftingTask)
    end
  end

  local a = function(craftingTask2, dependencies, amountRequired)
    local averageAmountProduced = AddOn
      .determineAverageAmountProducedByRecipe(craftingTask2.recipeData)
    local totalAmountProduced = craftingTask2.amount *
      averageAmountProduced
    if totalAmountProduced > amountRequired then
      local craftingTask3 = {
        recipeID = craftingTask2.recipeID,
        amount = math.ceil(amountRequired / averageAmountProduced),
        recipeData = craftingTask2.recipeData,
      }
      craftingTask2.amount = craftingTask2.amount - craftingTask3.amount
      craftingTask2 = craftingTask3
    end
    table.insert(dependencies, craftingTask2)
  end

  --- @param craftingTask CraftingTask
  visitDependencies = function(craftingTask)
    local dependencies = {}

    Array.forEach(craftingTask.recipeData.reagentData.requiredReagents,
      function(reagent)
        local recipeID = _.retrieveRecipeIDForItem(reagent.items[1].item)
        local craftingTask2 = craftingTaskLookUp[recipeID]
        if craftingTask2 then
          local amountRequired = craftingTask.amount * reagent.requiredQuantity
          a(craftingTask2, dependencies, amountRequired)
        end
      end)

    Array.forEach(craftingTask.recipeData.reagentData.optionalReagentSlots,
      function(reagent)
        if reagent.activeReagent then
          local recipeID = _.retrieveRecipeIDForItem(reagent.activeReagent.item)
          local craftingTask2 = craftingTaskLookUp[recipeID]
          if craftingTask2 then
            local amountRequired = craftingTask.amount
            a(craftingTask2, dependencies, amountRequired)
          end
        end
      end)

    Array.forEach(craftingTask.recipeData.reagentData.finishingReagentSlots,
      function(reagent)
        if reagent.activeReagent then
          local recipeID = _.retrieveRecipeIDForItem(reagent.activeReagent.item)
          local craftingTask2 = craftingTaskLookUp[recipeID]
          if craftingTask2 then
            local amountRequired = craftingTask.amount
            a(craftingTask2, dependencies, amountRequired)
          end
        end
      end)

    table.sort(dependencies, function(a, b)
      return a.recipeData:GetAverageProfit() > b.recipeData:GetAverageProfit()
    end)

    Array.forEach(dependencies, visit)
  end

  table.sort(craftingTasks, function(a, b)
    return a.recipeData:GetAverageProfit() > b.recipeData:GetAverageProfit()
  end)

  Array.forEach(craftingTasks, visit)

  return sorted
end

local bestStatsForClasses = {
  ["Plate"] = { "Haste", "Mastery", }, -- For most specs of the plate classes it seems to be that.
}
local bestStatsForCraftingProfessions = { "Multicraft", "Inspiration",
  "Resourcefulness", "Crafting Speed", }
local bestStatsForGatheringProfessions = { "Perception", "Finesse", "Deftness", }

--- @type Set
local draconicMissivesForCraftingProfessions = Set.create({
  200568, 200570, 200569,
  198534, 198536, 198535,
  200565, 200566, 200567,
  200571, 200573, 200572,
})

--- @type Set
local draconicMissivesForGatheringProfessions = Set.create({
  200574, 200576, 200575,
  200579, 200577, 200578,
  200580, 200581, 200582,
})

--- @type Set
local engineeringStatSetterItems = Set.create({
  198174, 198176, 198175, 198232, 198233, 198231, 198236, 198238, 198237, 198307, 198309, 198308,
})

function AddOn.determineRecipeData(recipeID)
  -- for index, slot in ipairs(recipeData.reagentData.optionalReagentSlots) do
  --   local itemID = slot.possibleReagents[1].item:GetItemID()
  --   if draconicMissivesForCraftingProfessions:contains(itemID) then
  --     local bestStat = bestStatsForCraftingProfessions[1]
  --   elseif draconicMissivesForGatheringProfessions:contains(itemID) then
  --     local bestStat = bestStatsForGatheringProfessions[1]
  --   elseif engineeringStatSetterItems:contains(itemID) then
  --     local bestStat = "Haste"
  --   end
  -- end
  -- recipeData:SetOptionalReagent()

  -- TODO: Ooey-Gooey Chocolate

  local baseRecipeData = _.determineBaseRecipeData(recipeID)

  local variants = {
    {
      recipeData = baseRecipeData,
      profit = baseRecipeData:GetAverageProfit(),
    },
  }

  local itemIDs = {
    197764,
    197765,
    -- 191526, -- TODO: Minimum profit threshold for when to craft with Lesser Illustrious Insight
    -- TODO: Retrieve Lesser Illustrious Insight from breaking Illustrious Insight or by crafting Illustrious Insight and breaking it.
  }

  for index, slot in ipairs(baseRecipeData.reagentData.finishingReagentSlots) do
    for index, itemID in ipairs(itemIDs) do
      if Array.any(slot.possibleReagents, function(reagent)
          return reagent.item:GetItemID() == itemID
        end) then
        local recipeData = _.determineBaseRecipeData(recipeID)
        recipeData:SetOptionalReagent(itemID)
        recipeData:Update()
        recipeData:OptimizeProfit()

        local profit = recipeData:GetAverageProfit()

        table.insert(variants, {
          recipeData = recipeData,
          profit = profit,
        })
      end
    end
  end

  local maxVariantRecipeData = Array.max(variants, function(variant)
    return variant.profit
  end).recipeData

  -- When the profession window for the profession is closed this might be set to false by CraftSim even though the recipe is learned.
  -- We set it here to true so that CanCraft correctly works.
  maxVariantRecipeData.learned = true

  return maxVariantRecipeData
end

function _.determineBaseRecipeData(recipeID)
  --- @type CraftSim.RecipeData
  local recipeData = CraftSim.RecipeData(recipeID, false, false)

  if not recipeData.hasQualityReagents then
    recipeData:SetNonQualityReagentsMax()
  end
  recipeData:OptimizeProfit()

  return recipeData
end

local sorts = {
  {
    sortOrder = Enum.AuctionHouseSortOrder.Price,
    reverseSort = false,
  },
}

--- @param purchaseTasks PurchaseTask[]
--- @param callback fun(purchaseTask: PurchaseTask, quantity: Amount): nil
AddOn.buy = function(purchaseTasks, callback)
  Array.forEach(purchaseTasks, function(purchaseTask)
    _.purchase(purchaseTask, callback)
  end)
  print("Have worked through the full purchase list.")
end

--- @param purchaseTask PurchaseTask
--- @param callback fun(purchaseTask: PurchaseTask, quantity: Amount): nil
function _.purchase(purchaseTask, callback)
  local quantity = purchaseTask.amount
  local maximumUnitPriceToBuyFor = purchaseTask.maximumUnitPriceToBuyFor

  local item = AddOn.createItem(purchaseTask.itemLink)
  AddOn.loadItem(item)
  local itemID = item:GetItemID()
  local itemLink = item:GetItemLink()
  print("Trying to buy " ..
    quantity ..
    " x " ..
    itemLink ..
    " (for a maximum unit price of " ..
    GetMoneyString(maximumUnitPriceToBuyFor) .. ").")
  if CraftAndSellInAH.showConfirmButton() then
    local wasSuccessful, event, unitPrice, totalPrice
    while true do
      C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)
      wasSuccessful, event, unitPrice, totalPrice = Events
        .waitForOneOfEvents(
          { "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE",
            "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED", },
          3)
      if event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
        print("Request seems to have been dropped. Trying again.")
      else
        break
      end
    end
    if event == "COMMODITY_PRICE_UPDATED" then
      if unitPrice <= maximumUnitPriceToBuyFor then
        C_AuctionHouse.ConfirmCommoditiesPurchase(itemID, quantity)
        local wasSuccessful, event = Events.waitForOneOfEvents(
          { "COMMODITY_PURCHASE_SUCCEEDED", "COMMODITY_PURCHASE_FAILED", },
          3)
        if wasSuccessful and event == "COMMODITY_PURCHASE_SUCCEEDED" then
          print("Have bought " ..
            quantity ..
            " x " ..
            itemLink ..
            " (for a unit price of " .. GetMoneyString(unitPrice) .. ").")
          callback(purchaseTask, quantity)
        else
          print("Have skipped buying " ..
            quantity ..
            " x " ..
            itemLink ..
            " because there was an error.")
        end
      else
        print("Have skipped buying " ..
          quantity ..
          " x " ..
          itemLink ..
          " because the unit price was higher than the maximum unit price to buy for (" ..
          GetMoneyString(unitPrice) ..
          " > " .. GetMoneyString(maximumUnitPriceToBuyFor) .. ").")
      end
    end
  end
end

--- @param sellTasks SellTask[]
AddOn.sell = function(sellTasks)
  Array.forEach(sellTasks, _.doSellTask)
  print("Have worked through the full list.")
end

-- itemID -> maximum number of charges
local itemsWithCharges = {
  [191304] = 20,
}

--- @param sellTask SellTask
function _.doSellTask(sellTask)
  local item = AddOn.createItem(sellTask.itemLink)
  local itemID = item:GetItemID()
  local amount = sellTask.amount

  local itemKey = { itemID = itemID, }
  if item:GetCurrentItemLevel() then
    itemKey.itemLevel = item:GetCurrentItemLevel()
  end
  local wasSuccessful, event, argument1
  while true do
    C_AuctionHouse.SendSearchQuery(
      itemKey,
      sorts,
      true
    )

    wasSuccessful, event, argument1 = Events
      .waitForOneOfEventsAndCondition(
        { "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED",
          "AUCTION_HOUSE_SHOW_ERROR", },
        function(self, event, argument1)
          if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
            local itemID = argument1
            return itemID == itemKey.itemID
          elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
            local itemKey2 = argument1
            return itemKey2.itemID == itemKey.itemID
          elseif event == "AUCTION_HOUSE_SHOW_ERROR" then
            return true
          end
        end, 3)

    if event == "AUCTION_HOUSE_SHOW_ERROR" and argument1 == Enum.AuctionHouseError.DatabaseError then
      Events.waitForEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
    end

    if wasSuccessful and event ~= "AUCTION_HOUSE_SHOW_ERROR" then
      break
    end
  end

  local unitPrice
  if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
    unitPrice = _.determineUnitPriceForCommodity(itemID)
  elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
    unitPrice = _.determineUnitPriceForItem(itemKey)
  end
  -- TODO: Handle when unitPrice is nil. (When there is no item of the type in the AH?)

  local minimumPriceToSellFor = 0.5 * AddOn.determineAuctionHouseBuyPrice(item)

  if unitPrice >= minimumPriceToSellFor then
    local boundItems = {}
    while true do
      local containerIndex, slotIndex = Bags.findItem(function(containerIndex,
        slotIndex)
        local slotItemID = C_Container.GetContainerItemID(containerIndex,
          slotIndex)
        return slotItemID == itemID and
          not C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(containerIndex,
            slotIndex)) and
          (not itemsWithCharges[itemID] or _.retrieveNumberOfCharges(containerIndex, slotIndex) == itemsWithCharges[itemID]) and
          not Array.any(boundItems, function(boundItem)
            return boundItem[1] == containerIndex and boundItem[2] == slotIndex
          end)
      end)
      if containerIndex and slotIndex then
        local item = ItemLocation:CreateFromBagAndSlot(containerIndex, slotIndex)
        local duration = 1
        -- TODO: Does it work if the item is distributed over multiple slots?
        local itemLink = C_Item.GetItemLink(item)
        print("Trying to put in " ..
          amount ..
          " x " .. itemLink .. " (each for " .. GetMoneyString(unitPrice) .. ").")
        if CraftAndSellInAH.showConfirmButton() then
          local errorCode = nil
          local listener
          listener = Events.listenForEvent("AUCTION_HOUSE_SHOW_ERROR",
            function(event, code)
              errorCode = code
              listener:stopListening()
            end)
          if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
            local requiresConfirmation = C_AuctionHouse.PostCommodity(item,
              duration,
              amount, unitPrice)
            if requiresConfirmation then
              C_AuctionHouse.ConfirmPostCommodity(item, duration, amount,
                unitPrice)
            end
          elseif event == "ITEM_SEARCH_RESULTS_UPDATED" then
            local requiresConfirmation = C_AuctionHouse.PostItem(item,
              duration,
              amount, nil, unitPrice)
            if requiresConfirmation then
              C_AuctionHouse.ConfirmPostItem(item, duration, amount, nil,
                unitPrice)
            end
          end
          listener:stopListening()
          if errorCode == nil then
            local wasSuccessful = Events.waitForEvent(
              "AUCTION_HOUSE_AUCTION_CREATED", 3)
            if wasSuccessful then
              print("Have put in " ..
                amount ..
                " x " ..
                itemLink .. " (each for " .. GetMoneyString(unitPrice) .. ").")
              break
            else
              print("Error putting in " .. amount .. " x " .. itemLink .. ".")
              break
            end
          else
            if errorCode == Enum.AuctionHouseError.UsedCharges then
              table.insert(boundItems, { containerIndex, slotIndex, })
            else
              print("Error putting in " .. amount .. " x " .. itemLink .. ".")
              break
            end
          end
        end
      else
        break
      end
    end
  else
    print("Skipping to put in " ..
      amount ..
      " x " ..
      item:GetItemLink() ..
      " because the auction house price is below the break even price (" ..
      GetMoneyString(unitPrice) ..
      " < " .. GetMoneyString(minimumPriceToSellFor) .. ").")
  end
end

function _.retrieveNumberOfCharges(containerIndex, slotIndex)
  local tooltipData = C_TooltipInfo.GetBagItem(containerIndex, slotIndex)
  TooltipUtil.SurfaceArgs(tooltipData)
  local numberOfChargesAsString = string.match(tooltipData.lines[3].leftText,
    "(%d+) |4Charge:Charges;")
  if numberOfChargesAsString then
    return tonumber(numberOfChargesAsString)
  else
    return nil
  end
end

function _.determineUnitPriceForCommodity(itemID)
  local numberOfCommoditySearchResults = C_AuctionHouse
    .GetNumCommoditySearchResults(itemID)
  if numberOfCommoditySearchResults >= 1 then
    local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, 1)
    if result then
      return result.unitPrice
    end
  end

  return nil
end

--- @param itemKey ItemKey
--- @return Money|nil
function _.determineUnitPriceForItem(itemKey)
  local result = _.retrieveLowestBuyoutAmountResult(itemKey)
  if result then
    local unitPrice = result.buyoutAmount
    if result.owners[1] ~= UnitName("player") then
      unitPrice = math.max(unitPrice - 100, 100)
    end
    return unitPrice
  else
    return nil
  end
end

--- @param itemKey ItemKey
--- @return ItemSearchResultInfo|nil
function _.retrieveLowestBuyoutAmountResult(itemKey)
  local numberOfSearchResults = C_AuctionHouse.GetNumItemSearchResults(itemKey)
  for index = 1, numberOfSearchResults do
    local result = C_AuctionHouse.GetItemSearchResultInfo(itemKey, index)
    if result and result.buyoutAmount then
      return result
    end
  end
  return nil
end

CraftAndSellInAH.thread = nil

local confirmButton = CreateFrame("Button", nil, UIParent,
  "UIPanelButtonTemplate")
CraftAndSellInAH.confirmButton = confirmButton
confirmButton:SetSize(144, 48)
confirmButton:SetText("Confirm")
confirmButton:SetPoint("CENTER", 0, 0)
confirmButton:SetScript("OnClick", function()
  CraftAndSellInAH.confirm()
end)
confirmButton:SetFrameStrata("HIGH")
confirmButton:Hide()

function CraftAndSellInAH.showConfirmButton()
  confirmButton:Show()
  CraftAndSellInAH.thread = coroutine.running()
  local continue = coroutine.yield()
  return continue
end

--- Confirms the action.
--- Can be done via button click or key press.
function CraftAndSellInAH.confirm()
  confirmButton:Hide()
  if CraftAndSellInAH.thread then
    local thread = CraftAndSellInAH.thread
    CraftAndSellInAH.thread = nil
    Coroutine.resumeWithShowingError(thread, true)
  end
end

function CraftAndSellInAH.cancel()
  confirmButton:Hide()
  if CraftAndSellInAH.thread then
    local thread = CraftAndSellInAH.thread
    CraftAndSellInAH.thread = nil
    Coroutine.resumeWithShowingError(thread, false)
  end
end

--- @param item Item
function _.addItemToInventory(inventory, item)
  local itemLink = item:GetItemLink()

  if not inventory[AddOn.SourceType.Bag][itemLink] then
    inventory[AddOn.SourceType.Bag][itemLink] = AddOn.determineBagQuantity(item)
  end

  if not inventory[AddOn.SourceType.Bank][itemLink] then
    inventory[AddOn.SourceType.Bank][itemLink] = AddOn.determineBankQuantity(
      item)
  end

  if not inventory[AddOn.SourceType.ReagentBank][itemLink] then
    inventory[AddOn.SourceType.ReagentBank][itemLink] = AddOn
      .determineReagentBankQuantity(item)
  end

  if not inventory[AddOn.SourceType.Mail][itemLink] then
    local itemString = AddOn.generateItemString(item)
    inventory[AddOn.SourceType.Mail][itemLink] = TSM_API.GetMailQuantity(
      itemString)
  end

  if not inventory[AddOn.SourceType.GuildBank][itemLink] then
    local itemString = AddOn.generateItemString(item)
    inventory[AddOn.SourceType.GuildBank][itemLink] = TSM_API.GetGuildQuantity(
      itemString)
  end

  -- TODO: Maybe only consider the items for cancelling which are estimated to run out.
  -- if not inventory[AddOn.SourceType.AuctionHouseCancelling][itemLink] then
  --   local itemString = AddOn.generateItemString(item)
  --   inventory[AddOn.SourceType.AuctionHouseCancelling][itemLink] = AddOn.determineTotalAmountInAuctionHouse(item)
  -- end

  -- TODO: Other characters
end

function _.convertCraftingTasksMapToArray(crafts)
  return Object.values(crafts)
end

--- @param craftingTasks CraftingTask[]
--- @param groups Groups
--- @param inventory Inventory
--- @return GroupEntry[]
function _.determineReagentSourcesForCrafts(craftingTasks, groups, inventory)
  local thingsRequired = _.determineThingsRequiredForCraftingTasks(
    craftingTasks)

  Array.forEach(thingsRequired, function(thingRequired)
    _.addItemToInventory(inventory, AddOn.createItem(thingRequired.itemLink))
  end)

  local extraCraftingTasks = {}

  Array.forEach(thingsRequired, function(thingRequired)
    local bestSources = AddOn.determineBestSourcesForThing(inventory,
      thingRequired)
    for source, entries in pairs(bestSources) do
      if not groups[source] then
        groups[source] = {}
      end
      Array.forEach(entries, function(entry)
        local itemLink = entry.itemLink
        if groups[source][itemLink] then
          groups[source][itemLink].amount = groups[source][itemLink].amount +
            entry.amount
          if source == AddOn.SourceType.AuctionHouse then
            groups[source][itemLink].maximumPurchasePrice = math.max(
              groups[source][itemLink].maximumPurchasePrice,
              entry.maximumPurchasePrice)
          end
        else
          groups[source][itemLink] = Object.copy(entry)
        end
        if source == AddOn.SourceType.Crafting then
          table.insert(extraCraftingTasks, Object.copy(entry))
        end
      end)
    end
  end)

  return extraCraftingTasks
end

--- @param craftingTasks CraftingTask[]
--- @return ThingRequiredWithMaximumPurchasePrice[]
function _.determineThingsRequiredForCraftingTasks(craftingTasks)
  return _.sum(Array.flat(Array.selectTrue(Array.map(
    craftingTasks,
    _.determineThingsRequiredForCraftingTask))))
end

function _.determineMinimumQualityRequiredForCraft(thingToCraft)
  return 1 -- TODO: Implement
end

-- /dump CopyToClipboard(select(2, GetItemInfo(190396)))

-- [Serevite Ore |A:Professions-ChatIcon-Quality-Tier2:17:23::1|a]

function _.determineQualityOfItem(itemID)
  local itemLink = _.convertItemIDToItemLink(itemID)
  local qualityString = string.match(itemLink,
    "Professions-ChatIcon-Quality-Tier(%d)")
  local quality
  if qualityString then
    quality = tonumber(qualityString, 10)
  else
    quality = nil
  end
  return quality
end

--- @param craftingTask CraftingTask
--- @return ThingRequiredWithMaximumPurchasePrice[]
function _.determineThingsRequiredForCraftingTask(craftingTask)
  local thingsRequiredForThing = {}
  local thingsRequiredPerThing = _.determineThingsRequiredPerCraftingTask(
    craftingTask)

  Array.forEach(thingsRequiredPerThing, function(thingRequiredPerThing)
    table.insert(thingsRequiredForThing,
      Object.assign({}, thingRequiredPerThing, {
        amount = (craftingTask.amount or 1) * thingRequiredPerThing.amount,
        maximumPurchasePrice = _.determineMaximumPurchasePrice(
          AddOn.createItem(
            thingRequiredPerThing.itemLink), craftingTask),
      }))
  end)

  return thingsRequiredForThing
end

--- @param item Item
--- @param craftingTask CraftingTask
--- @return Money|nil
function _.determineMaximumPurchasePrice(item, craftingTask)
  local priceOfItem = AddOn.determineAuctionHouseBuyPrice(item)
  if priceOfItem then
    local totalCraftingCost = craftingTask.recipeData.priceData.craftingCosts
    local averageProfit = craftingTask.recipeData:GetAverageProfit()
    return priceOfItem +
      (priceOfItem / totalCraftingCost) * averageProfit
  else
    return nil
  end
end

--- @param craftingTask CraftingTask
--- @return ThingRequired[]
function _.determineThingsRequiredPerCraftingTask(craftingTask)
  local recipeID = craftingTask.recipeID
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
  local reagentSlotSchematics = recipeSchematic.reagentSlotSchematics
  --- @type ThingRequired[]
  local thingsRequired = {}

  Array.forEach(reagentSlotSchematics, function(reagentSlotSchematic)
    if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic then
      local itemIDs = Array.map(reagentSlotSchematic.reagents, function(reagent)
        return reagent.itemID
      end)

      if #itemIDs == 1 then
        local item = AddOn.createItem(itemIDs[1])
        AddOn.loadItem(item)
        table.insert(thingsRequired, {
          itemLink = item:GetItemLink(),
          amount = reagentSlotSchematic.quantityRequired,
        })
      elseif #itemIDs >= 2 then
        local reagent = Array.find(
          craftingTask.recipeData.reagentData.requiredReagents,
          function(reagent)
            -- CraftSim Reagent had only dataSlotIndex (and slotIndex was absent).
            -- So instead we check if the first item ID matches.
            return reagent.items[1].item:GetItemID() ==
              reagentSlotSchematic.reagents[1].itemID
          end)

        Array.forEach(reagent.items, function(item)
          local quantity = item.quantity
          if quantity > 0 then
            AddOn.loadItem(item.item)
            table.insert(thingsRequired, {
              itemLink = item.item:GetItemLink(),
              amount = quantity,
            })
          end
        end)
      end
    end
  end)

  for index, slot in ipairs(craftingTask.recipeData.reagentData.finishingReagentSlots) do
    if slot.activeReagent then
      local thingRequired = {
        itemLink = slot.activeReagent.item:GetItemLink(),
        amount = 1,
      }
      table.insert(thingsRequired, thingRequired)
    end
  end

  return thingsRequired
end

-- /dump C_TradeSkillUI.GetRecipeInfo(ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID)

-- /dump C_TradeSkillUI.GetRecipeSchematic(ProfessionsFrame.CraftingPage.SchematicForm.currentRecipeInfo.recipeID, false)

-- /dump C_TradeSkillUI.GetRecipeInfo(382379)

function AddOn.scanRecipes()
  C_TradeSkillUI.GetChildProfessionInfo()
  local professionInfo = C_TradeSkillUI.GetChildProfessionInfo()
  local dragonFlightProfessionInfo = Array.find(
    C_TradeSkillUI.GetChildProfessionInfos(), function(professionInfo)
      return professionInfo.expansionName == "Dragon Isles"
    end)
  local professionID = dragonFlightProfessionInfo.professionID
  for __, recipeID in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
    if C_TradeSkillUI.IsRecipeInSkillLine(recipeID, professionID) then
      local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
      local craftedItemIDs = _.retrieveCraftedItemIDs(recipeID)

      CraftingSavedVariablesPerCharacter.recipes[recipeID] = {
        recipeID = recipeID,
        categoryID = recipeInfo.categoryID,
        profession = professionInfo.profession,
        skillLineAbilityID = recipeInfo.skillLineAbilityID,
        craftedItemIDs = craftedItemIDs,
        recipeInfo = recipeInfo,
      }

      Array.forEach(craftedItemIDs, function(itemID)
        CraftingSavedVariables.itemIDToRecipeID[itemID] = recipeID
      end)
    end
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
C_TradeSkillUI.GetRecipeInfo = function(recipeID, recipeLevel)
  local recipeInfo1 = retrieveRecipeInfo(recipeID, recipeLevel)
  local recipeInfo2 = _.retrieveCachedRecipeInfo(recipeID)
  local recipeInfo
  if recipeInfo1 and recipeInfo1.categoryID ~= 0 then
    recipeInfo = recipeInfo1
  else
    recipeInfo = recipeInfo2
  end
  return recipeInfo
end

function _.retrieveCraftedItemIDs(recipeID)
  local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
  if recipeInfo.qualityItemIDs then
    return recipeInfo.qualityItemIDs
  else
    local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    local outputItemID = recipeSchematic.outputItemID
    if outputItemID then
      return { outputItemID, }
    else
      return {}
    end
  end
end

--- @param item Item
function AddOn.retrieveRecipeForItem(item)
  local recipeID = _.retrieveRecipeIDForItem(item)
  if recipeID then
    return _.retrieveRecipeForRecipeID(recipeID)
  else
    return nil
  end
end

function _.retrieveRecipeForRecipeID(recipeID)
  return CraftingSavedVariablesPerCharacter.recipes[recipeID]
end

--- @param item Item
function _.retrieveRecipeIDForItem(item)
  return CraftingSavedVariables.itemIDToRecipeID[item:GetItemID()]
end

--- @param thingsRequired ThingRequiredWithMaximumPurchasePrice[]
--- @return ThingRequiredWithMaximumPurchasePrice[]
function _.sum(thingsRequired)
  local totalThingsToRetrieve = {}
  local lookup = {}
  Array.forEach(thingsRequired, function(thingRequired)
    local itemLink = thingRequired.itemLink
    local entry = lookup[itemLink]
    if entry then
      entry.amount = entry.amount + thingRequired.amount
      entry.maximumPurchasePrice = math.max(entry.maximumPurchasePrice,
        thingRequired.maximumPurchasePrice)
    else
      local entry = Object.copy(thingRequired)
      table.insert(totalThingsToRetrieve, entry)
      lookup[itemLink] = entry
    end
  end)
  return totalThingsToRetrieve
end

function AddOn.generateThingsToRetrieveFromSourceText(sourceType,
  thingsToRetrieve)
  local text = ""
  if sourceTypeToName[sourceType] then
    text = text .. "Retrieve from " .. sourceTypeToName[sourceType] .. ":"
    Array.forEach(thingsToRetrieve, function(thingToRetrieve)
      local itemLink = thingToRetrieve.itemLink
      local line = "  " .. thingToRetrieve.amount .. " x " .. itemLink
      if sourceType == AddOn.SourceType.AuctionHouse then
        line = line .. " (" ..
          thingToRetrieve.amountRetrieved ..
          " / " .. thingToRetrieve.amount .. ")"
      end
      text = text .. "\n" .. line
    end)
  end
  return text
end

function _.join(itemLinks)
  local string = ""
  local length = Array.length(itemLinks)
  for index, itemLink in ipairs(itemLinks) do
    if index >= 2 then
      local isLastItem = index == length
      if isLastItem then
        string = string .. " or "
      else
        string = string .. ", "
      end
    end

    string = string .. itemLink
  end
  return string
end

--- @param item Item
--- @return Amount
function AddOn.determineTotalInventoryAmount(item)
  local itemString = AddOn.generateItemString(item)
  return GetItemCount(item:GetItemLink(), true, nil, true) +
    TSM_API.GetMailQuantity(
      itemString) + TSM_API.GetGuildQuantity(
      itemString) + AddOn.determineTotalAmountInAuctionHouse(item)
end

--- @param item Item
--- @return Amount
function AddOn.determineBagQuantity(item)
  return GetItemCount(item:GetItemLink())
end

--- @param item Item
--- @return Amount
function AddOn.determineBankQuantity(item)
  local itemLink = item:GetItemLink()
  return GetItemCount(itemLink, true) -
    GetItemCount(itemLink)
end

--- @param item Item
--- @return Amount
function AddOn.determineReagentBankQuantity(item)
  local itemLink = item:GetItemLink()
  return GetItemCount(itemLink,
    nil, nil, true) - GetItemCount(itemLink)
end

--- @param item Item
function AddOn.generateItemString(item, withItemLevel)
  if withItemLevel == nil then
    withItemLevel = true
  end
  local itemString = "i:" .. item:GetItemID()
  if withItemLevel and not AddOn.isCommodityItem(item) then
    local itemLevel = item:GetCurrentItemLevel()
    if itemLevel then
      itemString = itemString .. "::i" .. itemLevel
    end
  end
  return itemString
end

--- @param item Item
function AddOn.isCommodityItem(item)
  local classID, subclassID = select(6, GetItemInfoInstant(item:GetItemLink()))
  return (
    classID == Enum.ItemClass.Consumable or
    classID == Enum.ItemClass.Gem or
    classID == Enum.ItemClass.Tradegoods or
    classID == Enum.ItemClass.ItemEnhancement or
    classID == Enum.ItemClass.Questitem or
    (classID == Enum.ItemClass.Miscellaneous and subclassID ~= Enum.ItemMiscellaneousSubclass.Mount) or
    classID == Enum.ItemClass.Glyph or
    classID == Enum.ItemClass.Key
  )
end

function _.generateThingsToCraftText(thingsToCraft)
  local text = "To craft:\n"
  Array.forEach(thingsToCraft, function(thingToCraft)
    AddOn.loadItem(AddOn.createItem(id))
    local line = thingToCraft.amount ..
      " x " .. _.retrieveRecipeOutputItemLink(thingToCraft.recipeID,
        thingToCraft.quality)
    if thingToCraft.missiveIDs then
      local missiveID = thingToCraft.missiveIDs:toList()[1]
      if missiveID then
        local itemLink = _.convertItemIDToItemLink(missiveID)
        line = line .. " (with " .. itemLink .. ")"
      end
    end
    text = text .. line .. "\n"
  end)
  return text
end

function _.retrieveRecipeOutputItemLink(recipeID, quality)
  return _.retrieveRecipeOutputItemData(recipeID, quality).hyperlink
end

function _.retrieveRecipeOutputItemData(recipeID, quality)
  return C_TradeSkillUI.GetRecipeOutputItemData(recipeID, nil, nil, 3 + quality)
end

--- @param item Item
function AddOn.loadItem(item)
  if not item:IsItemDataCached() then
    local thread = coroutine.running()

    item:ContinueOnItemLoad(function()
      Coroutine.resumeWithShowingError(thread)
    end)

    coroutine.yield()
  end
end

--- @param itemReference number|string|Item Item ID, item link or item object.
--- @return Item
function AddOn.createItem(itemReference)
  local item
  local itemReferenceType = type(itemReference)
  if itemReferenceType == "number" then
    item = Item:CreateFromItemID(itemReference)
  elseif itemReferenceType == "string" then
    item = Item:CreateFromItemLink(itemReference)
  elseif itemReferenceType == "table" then
    item = itemReference
  else
    error("Unsupported type: " .. itemReferenceType)
  end
  return item
end

function _.showText(text)
  AddOn.showText(ChatFrame4, text)
end

function AddOn.showText(chatFrame, text)
  local scrollOffset = chatFrame:GetScrollOffset()
  chatFrame:Clear()

  local lines = String.split("\n", text)
  Array.forEach(lines, function(line)
    chatFrame:AddMessage(line)
  end)
  chatFrame:SetScrollOffset(scrollOffset)
end

--- @param item Item
function _.determineCraftingCost(item)
  local recipeID = _.retrieveRecipeIDForItem(item)
  if recipeID then
    local recipeData = AddOn.determineRecipeData(recipeID)
    return _.determineCraftingCostForRecipe(recipeData, item)
  else
    return nil
  end
end

-- TODO: Sagacious Incense buff (+20 inspiration) when it makes a difference
--- @param recipeData CraftSim.RecipeData
--- @param item Item
--- @return Money|nil
function _.determineCraftingCostForRecipe(recipeData, item)
  if recipeData.supportsQualities then
    local quality = Array.findIndex(recipeData.resultData.itemsByQuality,
      function(item2)
        return item2:GetItemLink() == item:GetItemLink()
      end)
    if quality and recipeData.resultData.chanceByQuality[quality] == 1 then
      return recipeData.priceData.craftingCosts /
        AddOn.determineAverageAmountProducedByRecipe(recipeData)
    else
      return nil
    end
  else
    return recipeData.priceData.craftingCosts /
      AddOn.determineAverageAmountProducedByRecipe(recipeData)
  end
end

--- @param item Item
--- @return Amount|nil
function _.determineAverageAmountProduced(item)
  local recipe = AddOn.retrieveRecipeForItem(item)
  if recipe then
    local recipeData = AddOn.determineRecipeData(recipe.recipeID)
    return AddOn.determineAverageAmountProducedByRecipe(recipeData)
  else
    return nil
  end
end

--- @param recipeData CraftSim.RecipeData
--- @return Amount
function AddOn.determineAverageAmountProducedByRecipe(recipeData)
  local averageAmountOfExtraItemsFromMulticraft = select(2,
    CraftSim.CALC:GetExpectedItemAmountMulticraft(recipeData))
  local amount = recipeData.baseItemAmount
  if recipeData.supportsMulticraft then
    amount = amount + recipeData.professionStats.multicraft:GetPercent(true) *
      averageAmountOfExtraItemsFromMulticraft
  end
  return amount
end

--- @param inventory Inventory
--- @param itemLink ItemLink
--- @param amount Amount
--- @return Retrieval
function _.retrieveFromInventory(inventory, itemLink, amount)
  local amountLeft = amount

  local inventorySources = {
    AddOn.SourceType.Bag,
    AddOn.SourceType.Bank,
    AddOn.SourceType.ReagentBank,
    AddOn.SourceType.Mail,
    AddOn.SourceType.GuildBank,
    AddOn.SourceType.OtherCharacter,
    -- AddOn.SourceType.AuctionHouseCancelling,
  }

  --- @type Retrieval
  local retrieval = {}

  for __, source in ipairs(inventorySources) do
    local amountFromSource = _.retrieveFromInventoryFromSource(inventory,
      itemLink,
      source, amountLeft)
    if amountFromSource >= 1 then
      retrieval[source] = amountFromSource
      amountLeft = amountLeft - amountFromSource
    end
  end

  return retrieval
end

--- @param inventory Inventory
--- @param itemLink ItemLink
--- @param source SourceType
--- @param amount Amount
--- @return Amount
function _.retrieveFromInventoryFromSource(inventory, itemLink, source, amount)
  local amountFromSource = math.min(inventory[source][itemLink] or 0, amount)
  if amountFromSource >= 1 then
    inventory[source][itemLink] = inventory[source][itemLink] - amountFromSource
  end
  return amountFromSource
end

--- @param inventory Inventory
--- @param thing ThingRequired
--- @return BestSources
function AddOn.determineBestSourcesForThing(inventory, thing)
  --- @type BestSources
  local bestSources = {}

  local itemLink = thing.itemLink
  local item = AddOn.createItem(itemLink)
  AddOn.loadItem(item)

  local amountLeft = thing.amount

  local retrieval = _.retrieveFromInventory(inventory, itemLink, amountLeft)

  for source, amount in pairs(retrieval) do
    if not bestSources[source] then
      bestSources[source] = {}
    end
    local bestSourceEntry = {
      itemLink = itemLink,
      amount = amount,
    }
    table.insert(bestSources[source], bestSourceEntry)
  end

  local amountLeft = amountLeft -
    Mathematics.sum(Object.values(retrieval))

  -- other sources
  if amountLeft >= 1 then
    local npcBuyPrice = _.determineNPCBuyPrice(item)
    -- TODO: Craft if crafting results in a higher quality for a lower price than buying the specified quality from AH.
    local recipe = AddOn.retrieveRecipeForItem(item)
    local recipeData
    if recipe and not AddOn.isTransmuteRecipe(recipe) then
      recipeData = AddOn.determineRecipeData(recipe.recipeID)
    else
      recipeData = nil
    end
    local craftingPrice
    if recipeData then
      craftingPrice = _.determineCraftingCostForRecipe(recipeData, item)
    else
      craftingPrice = nil
    end
    local auctionHouseBuyPrice = AddOn.determineAuctionHouseBuyPrice(item)
    local sources = {}
    if npcBuyPrice then
      table.insert(sources, {
        type = AddOn.SourceType.NPCVendor,
        price = npcBuyPrice,
      })
    end
    if craftingPrice and recipeData and recipeData:GetAverageProfit() >= AddOn.MINIMUM_PROFIT_PER_CRAFT then
      table.insert(sources, {
        type = AddOn.SourceType.Crafting,
        price = craftingPrice,
      })
    end
    if auctionHouseBuyPrice then
      table.insert(sources, {
        type = AddOn.SourceType.AuctionHouse,
        price = auctionHouseBuyPrice,
        maximumPurchasePrice = thing.maximumPurchasePrice,
      })
    end
    local lowestPriceSource = Array.min(sources, function(source)
      return source.price
    end)
    local source
    if lowestPriceSource then
      source = lowestPriceSource.type
    else
      source = AddOn.SourceType.Elsewhere
    end
    if not bestSources[source] then
      bestSources[source] = {}
    end
    local bestSourceEntry = {
      itemLink = itemLink,
      amount = amountLeft,
    }
    if lowestPriceSource and source == AddOn.SourceType.AuctionHouse then
      bestSourceEntry.maximumPurchasePrice = lowestPriceSource
        .maximumPurchasePrice
    end
    table.insert(bestSources[source], bestSourceEntry)
  end

  return bestSources
end

function _.convertItemIDToItemLink(itemID)
  local item = AddOn.createItem(itemID)
  AddOn.loadItem(item)
  return item:GetItemLink()
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

local npcPrices = {
  -- Cooking
  [197749] = 1000,
  [197750] = 3000,
  [197751] = 5000,
  [197752] = 12500,
  [197753] = 30000,
  [194683] = 25000 / 5,
  [194691] = 25000 / 5,
  -- Other
  [190452] = 150000,
  [191474] = 10000,
}

function _.determineNPCBuyPrice(item)
  local price = npcPrices[item:GetItemID()]
  if price and IsSpellKnown(69044) then
    price = price * (1 - 0.2)
  end
  return price
end

--- @param item Item
function AddOn.determineAuctionHouseBuyPrice(item)
  return _.determineAuctionHousePrice(item)
end

--- @player item Item
--- @return integer
function AddOn.determineTotalAmountInAuctionHouse(item)
  local amountInAuctionHouseByCurrentCharacter, amountInAuctionHouseByOtherCharacters =
    select(3, TSM_API.GetPlayerTotals(AddOn
      .generateItemString(item)))
  return amountInAuctionHouseByCurrentCharacter +
    amountInAuctionHouseByOtherCharacters
end
