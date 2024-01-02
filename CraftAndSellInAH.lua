-- TODO: Consider if an item can be bought for a lower price from a vendor.

CraftAndSellInAH = {}

--- @class AddOn
local AddOn = select(2, ...)
--- @class _
local _ = {}

--- @type Array
local Array = Library.retrieve("Array", "^2.1.1")
--- @type Bags
local Bags = Library.retrieve("Bags", "^2.0.5")
--- @type Coroutine
local Coroutine = Library.retrieve("Coroutine", "^2.0.1")
--- @type Events
local Events = Library.retrieve("Events", "^2.1.0")
--- @type Mathematics
local Mathematics = Library.retrieve("Mathematics", "^2.0.1")
--- @type Object
local Object = Library.retrieve("Object", "^1.1.1")
--- @type Set
local Set = Library.retrieve("Set", "^1.1.2")
--- @type String
local String = Library.retrieve("String", "^2.0.1")
local CraftSim = CraftSim_DEBUG:RUN()

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

--- @class ThingRequired
--- @field itemLinks Set
--- @field amount number

--- @class ItemToRetrieve
--- @field itemLink ItemLink
--- @field amount number

--- @enum SourceType
AddOn.SourceType = {
  NPCVendor = 1,
  Crafting = 2,
  AuctionHouse = 3,
  GuildBank = 4,
  OtherCharacter = 5,
  Mail = 6,
  Otherwise = 7,
  Bag = 8,
  Bank = 9,
  ReagentBank = 10,
}

--- @class BestSourcesEntry
--- @field itemLink ItemLink
--- @field amount Amount

--- @alias BestSources { [SourceType]: BestSourcesEntry[] }

--- @class GroupEntry
--- @field itemLink ItemLink
--- @field amount number

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
  [AddOn.SourceType.Otherwise] = "otherwise",
  [AddOn.SourceType.Bag] = "bag",
  [AddOn.SourceType.Bank] = "bank",
  [AddOn.SourceType.ReagentBank] = "reagent bank",
}

function AddOn.generatePlanText(input, thingsToRetrieve, groupedThingsToCraft)
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
      Array.forEach(entry.value, function(item, index)
        text = text ..
          index ..
          ". " ..
          item.amount ..
          " x " ..
          C_TradeSkillUI.GetRecipeLink(item.recipeID) .. "\n"
      end)
    end)

  return text
end

--- @param item Item
--- @return number
function _.determineAuctionHousePrice(item)
  local itemString = AddOn.generateItemString(item)
  local ahPrice = TSM_API.GetCustomPriceValue("DBRecent", itemString)
  if ahPrice == nil then
    ahPrice = TSM_API.GetCustomPriceValue("DBMarket", itemString)
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

  _.determineReagentSourcesForCrafts(
    _.convertCraftingTasksMapToArray(craftingTasks),
    groups,
    inventory)

  while groups[AddOn.SourceType.Crafting] and Array.hasElements(groups[AddOn.SourceType.Crafting]) do
    --- @type { [RecipeID]: CraftingTask }
    local furtherCrafts = Object.fromEntries(
      Object.entries(
        Array.groupBy(
          Array.map(
            groups[AddOn.SourceType.Crafting],
            function(thingToCraft)
              local recipeID = CraftingSavedVariables.itemIDToRecipeID
                [thingToCraft.itemID]
              return {
                recipeID = recipeID,
                amount = thingToCraft.amount,
              }
            end
          ),
          function(thingToCraft)
            return thingToCraft.recipeID
          end
        )
      )
      :map(function(entry)
        local recipeID = entry.key
        local thingsToCraft = entry.value
        local recipeData = AddOn.determineRecipeData(recipeID)
        return {
          key = recipeID,
          value = {
            recipeID = recipeID,
            amount = math.ceil(
              Array.max(
                Array.map(
                  thingsToCraft,
                  function(thingToCraft)
                    return thingToCraft.amount
                  end
                )
              ) / AddOn.determineAverageAmountProducedByRecipe(recipeData)
            ),
          },
        }
      end)
    )

    for recipeID, craft in pairs(furtherCrafts) do
      if craftingTasks[recipeID] then
        craftingTasks[recipeID].amount = craftingTasks[recipeID].amount +
          craft.amount
      else
        craftingTasks[recipeID] = craft
      end
    end
    groups[AddOn.SourceType.Crafting] = nil
    _.determineReagentSourcesForCrafts(
      _.convertCraftingTasksMapToArray(furtherCrafts),
      groups,
      inventory
    )
  end

  --- @type ThingsToRetrieveStepsList
  local list = {}

  local order = {
    AddOn.SourceType.Mail,
    AddOn.SourceType.GuildBank,
    AddOn.SourceType.NPCVendor,
    AddOn.SourceType.AuctionHouse,
    AddOn.SourceType.OtherCharacter,
    AddOn.SourceType.Otherwise,
    AddOn.SourceType.Crafting,
  }
  Array.forEach(order, function(source)
    if groups[source] then
      table.insert(list, {
        source = source,
        thingsToRetrieveFromSource = Object.values(groups[source]),
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

  Array.create(Object.values(groupedThingsToCraft)):forEach(function(
    craftingTasks)
    table.sort(craftingTasks, function(a, b)
      return Array.any(
        b.recipeData.reagentData.requiredReagents, function(reagent)
          return _.retrieveRecipeIDForItem(reagent.items[1].item:GetItemID()) ==
            a.recipeID
        end)
    end)
  end)

  return list, groupedThingsToCraft
end

function AddOn.determineRecipeData(recipeID)
  local recipeData = CraftSim.RecipeData(recipeID, false, false)
  -- FIXME: With CraftSim freshly installed, this seems to throw an error. It seems required to open the profession window once to fix the error.
  recipeData:SetEquippedProfessionGearSet()
  if not recipeData.hasQualityReagents then
    for index, reagent in ipairs(recipeData.reagentData.requiredReagents) do
      reagent.items[1].quantity = reagent.requiredQuantity
    end
  end
  recipeData:OptimizeProfit()
  -- When the profession window for the profession is closed this might be set to false by CraftSim even though the recipe is learned.
  -- We set it here to true so that CanCraft correctly works.
  recipeData.learned = true

  return recipeData
end

local sorts = {
  {
    sortOrder = Enum.AuctionHouseSortOrder.Price,
    reverseSort = false,
  },
}

--- @param purchaseTasks PurchaseTask[]
AddOn.buy = function(purchaseTasks)
  Array.forEach(purchaseTasks, _.purchase)
  print("Have worked through the full purchase list.")
end

--- @param buyTask PurchaseTask
function _.purchase(purchaseTask)
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
    C_AuctionHouse.StartCommoditiesPurchase(itemID, quantity)
    local wasSuccessful, event, unitPrice, totalPrice = Events
      .waitForOneOfEvents(
        { "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE", },
        3)
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

--- @param sellTask SellTask
function _.doSellTask(sellTask)
  local item = AddOn.createItem(sellTask.itemLink)
  local itemID = item:GetItemID()
  local amount = sellTask.amount

  local itemKey = { itemID = itemID, }
  local wasSuccessful, event, argument1
  while true do
    C_AuctionHouse.SendSearchQuery(
      itemKey,
      sorts,
      true
    )

    wasSuccessful, event, argument1 = Events
      .waitForOneOfEventsAndCondition(
        { "COMMODITY_SEARCH_RESULTS_UPDATED", "AUCTION_HOUSE_SHOW_ERROR", },
        function(self, event, argument1)
          if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
            local itemID = argument1
            return itemID == itemKey.itemID
          elseif event == "AUCTION_HOUSE_SHOW_ERROR" then
            return true
          end
        end, 3)

    if event == "AUCTION_HOUSE_SHOW_ERROR" and argument1 == 10 then
      Events.waitForEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
    end

    if event ~= "AUCTION_HOUSE_SHOW_ERROR" then
      break
    end
  end

  local unitPrice
  if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
    unitPrice = _.determineUnitPrice(itemID)
    -- TODO: Handle when unitPrice is nil. (When there is no item of the type in the AH?)

    -- TODO: Make sure that the unit price is high enough so that selling the item for the price is profitable.

    local containerIndex, slotIndex = Bags.findItem(itemID)
    if containerIndex and slotIndex then
      local item = ItemLocation:CreateFromBagAndSlot(containerIndex, slotIndex)
      local duration = 1
      -- TODO: Does it work if the item is distributed over multiple slots?
      local itemLink = C_Item.GetItemLink(item)
      print("Trying to put in " ..
        amount ..
        " x " .. itemLink .. " (each for " .. GetMoneyString(unitPrice) .. ").")
      if MoneyMakingAssistant.showConfirmButton() then
        local requiresConfirmation = C_AuctionHouse.PostCommodity(item, duration,
          amount, unitPrice)
        if requiresConfirmation then
          C_AuctionHouse.ConfirmPostCommodity(item, duration, amount, unitPrice)
        end
        -- TODO: Events for error?
        local wasSuccessful = Events.waitForEvent(
          "AUCTION_HOUSE_AUCTION_CREATED", 3)
        if wasSuccessful then
          print("Have put in " ..
            amount ..
            " x " ..
            itemLink .. " (each for " .. GetMoneyString(unitPrice) .. ").")
        else
          print("Error putting in " .. amount .. " x " .. itemLink .. ".")
        end
      end
    end
  end
end

function _.determineUnitPrice(itemID)
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

do
  -- FIXME
  BINDING_HEADER_MONEY_MAKING = "Money Making"
  local prefix = "Money Making: "
  BINDING_NAME_MONEY_MAKING_CONFIRM_BUTTON = prefix .. "Confirm"
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
    local itemString = AddOn.generateItemString(item)
    inventory[AddOn.SourceType.Bag][itemLink] = TSM_API.GetBagQuantity(
      itemString)
  end

  if not inventory[AddOn.SourceType.Bank][itemLink] then
    local itemString = AddOn.generateItemString(item)
    inventory[AddOn.SourceType.Bank][itemLink] = TSM_API.GetBankQuantity(
      itemString)
  end

  if not inventory[AddOn.SourceType.ReagentBank][itemLink] then
    local itemString = AddOn.generateItemString(item)
    inventory[AddOn.SourceType.ReagentBank][itemLink] = TSM_API
      .GetReagentBankQuantity(
        itemString)
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

  -- TODO: Other characters
end

function _.convertCraftingTasksMapToArray(crafts)
  return Object.values(crafts)
end

--- @param craftingTasks CraftingTask[]
--- @param groups Groups
--- @param inventory Inventory
function _.determineReagentSourcesForCrafts(craftingTasks, groups, inventory)
  local thingsRequired = _.determineThingsRequiredForCraftingTasks(
    craftingTasks)

  Array.forEach(thingsRequired, function(thingRequired)
    Array.forEach(thingRequired.itemLinks:toList(), function(itemLink)
      _.addItemToInventory(inventory, AddOn.createItem(itemLink))
    end)
  end)


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
        else
          groups[source][itemLink] = Object.copy(entry)
        end
      end)
    end
  end)
end

--- @param craftingTasks CraftingTask[]
--- @return ThingRequired[]
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

--- @class ThingRequired
--- @field amount number
local ThingRequired = {}

--- @return ThingRequired
function ThingRequired.create(data)
  local thingRequired
  if data then
    thingRequired = Object.copy(data)
  else
    thingRequired = {}
  end
  setmetatable(thingRequired, { __index = ThingRequired, })
  return thingRequired
end

--- @param craftingTask CraftingTask
--- @return ThingRequired[]
function _.determineThingsRequiredForCraftingTask(craftingTask)
  local thingsRequiredForThing = {}
  local thingsRequiredPerThing = _.determineThingsRequiredPerCraftingTask(
    craftingTask)

  Array.forEach(thingsRequiredPerThing, function(thingRequiredPerThing)
    table.insert(thingsRequiredForThing,
      Object.assign({}, thingRequiredPerThing, {
        amount = (craftingTask.amount or 1) * thingRequiredPerThing.amount,
      }))
  end)

  return thingsRequiredForThing
end

--- @param craftingTask CraftingTask
--- @return ThingRequired[]
function _.determineThingsRequiredPerCraftingTask(craftingTask)
  local recipeID = craftingTask.recipeID
  local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
  local reagentSlotSchematics = recipeSchematic.reagentSlotSchematics
  --- @type ThingRequired[]
  local thingsToRetrieve = {}

  Array.forEach(reagentSlotSchematics, function(reagentSlotSchematic)
    if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic then
      local itemIDs = Array.map(reagentSlotSchematic.reagents, function(reagent)
        return reagent.itemID
      end)

      if #itemIDs == 1 then
        local item = AddOn.createItem(itemIDs[1])
        AddOn.loadItem(item)
        local itemLink = item:GetItemLink()
        table.insert(thingsToRetrieve, {
          itemLinks = Set.create({ itemLink, }),
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
            local itemLink = item.item:GetItemLink()
            table.insert(thingsToRetrieve, {
              itemLinks = Set.create({ itemLink, }),
              amount = quantity,
            })
          end
        end)
      end
    end
  end)
  if craftingTask.missiveIDs then
    local recipeID
    if Array.hasElements(craftingTask.missiveIDs) then
      recipeID = _.retrieveRecipeIDForItem(craftingTask.missiveIDs[1])
    else
      recipeID = nil
    end
    table.insert(thingsToRetrieve, {
      itemLinks = Array.map(craftingTask.missiveIDs, _.convertItemIDToItemLink),
      amount = 1,
    })
  end

  return thingsToRetrieve
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
  return retrieveRecipeInfo(recipeID, recipeLevel) or
    _.retrieveCachedRecipeInfo(recipeID)
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

function _.retrieveRecipeForItem(itemID)
  local recipeID = _.retrieveRecipeIDForItem(itemID)
  if recipeID then
    return _.retrieveRecipeForRecipeID(recipeID)
  else
    return nil
  end
end

function _.retrieveRecipeForRecipeID(recipeID)
  return CraftingSavedVariablesPerCharacter.recipes[recipeID]
end

function _.retrieveRecipeIDForItem(itemID)
  return CraftingSavedVariables.itemIDToRecipeID[itemID]
end

--- @param thingsToRetrieve ThingRequired[]
--- @return ThingRequired[]
function _.sum(thingsToRetrieve)
  local totalThingsToRetrieve = {}
  local lookup = {}
  Array.forEach(thingsToRetrieve, function(thingToBuy)
    local firstItemLink = thingToBuy.itemLinks:toList()[1]
    local entry = lookup[firstItemLink]
    if entry then
      entry.amount = entry.amount + thingToBuy.amount
    else
      local entry = Object.copy(thingToBuy)
      table.insert(totalThingsToRetrieve, entry)
      lookup[firstItemLink] = entry
    end
  end)
  return totalThingsToRetrieve
end

function _.craftThings(thingsToCraft)

end

function AddOn.generateThingsToRetrieveFromSourceText(sourceType,
  thingsToRetrieve)
  local text = ""
  if sourceTypeToName[sourceType] then
    text = text .. "Retrieve from " .. sourceTypeToName[sourceType] .. ":"
    Array.forEach(thingsToRetrieve, function(thingToRetrieve)
      local itemLink = thingToRetrieve.itemLink
      local line = "  " .. thingToRetrieve.amount .. " x " .. itemLink
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

function _.determineAmountInInventory(itemString)
  return TSM_API.GetBagQuantity(itemString) + TSM_API.GetBankQuantity(itemString) +
    TSM_API.GetReagentBankQuantity(itemString) +
    TSM_API.GetMailQuantity(itemString) + TSM_API.GetGuildQuantity(itemString)
end

--- @param item Item
function AddOn.generateItemString(item)
  local itemString = "i:" .. item:GetItemID()
  if not AddOn.isCommodityItem(item) then
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
  chatFrame:Clear()

  local lines = String.split("\n", text)
  Array.forEach(lines, function(line)
    chatFrame:AddMessage(line)
  end)
end

-- TODO: Sagacious Incense buff (+20 inspiration) when it makes a difference
function _.determineCraftingCost(item)
  if item.recipeID then
    local recipeData = AddOn.determineRecipeData(item.recipeID)
    local quality = Array.findIndex(recipeData.resultData.itemsByQuality,
      function(item2)
        return item2:GetItemLink() == item:GetItemLink()
      end)
    if quality and recipeData.resultData.chanceByQuality[quality] > 0 then
      return recipeData.priceData.craftingCosts *
        (1 / recipeData.resultData.chanceByQuality[quality])
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
    local recipeData = CraftSim.RecipeData(recipe.recipeID, false, false)
    return CraftSim.CALC:GetExpectedItemAmountMulticraft(recipeData)
  else
    return nil
  end
end

--- @param recipeData RecipeData
function AddOn.determineAverageAmountProducedByRecipe(recipeData)
  return CraftSim.CALC:GetExpectedItemAmountMulticraft(recipeData)
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

  local itemLinks = thing.itemLinks:toList()
  Array.map(itemLinks, function(itemLink)
    AddOn.loadItem(AddOn.createItem(itemLink))
  end)
  table.sort(itemLinks, _.compareQuality)

  local amountLeft = thing.amount

  for __, itemLink in ipairs(itemLinks) do
    local retrieval = _.retrieveFromInventory(inventory, itemLink, amountLeft)

    for source, amount in pairs(retrieval) do
      if not bestSources[source] then
        bestSources[source] = {}
      end
      table.insert(bestSources[source], {
        itemLink = itemLink,
        amount = amount,
      })
    end

    local amountLeft = amountLeft -
      Mathematics.sum(Object.values(retrieval))

    -- other sources
    if amountLeft >= 1 then
      local item = {
        itemLink = itemLink,
        recipeID = _.retrieveRecipeIDForItem(itemLink),
      }
      local npcBuyPrice = _.determineNPCBuyPrice(itemLink)
      local craftingPrice = _.determineCraftingCost(item)
      local auctionHouseBuyPrice = AddOn.determineAuctionHouseBuyPrice(AddOn
        .createItem(item.itemLink))
      local sources = {}
      if npcBuyPrice then
        table.insert(sources, {
          type = AddOn.SourceType.NPCVendor,
          price = npcBuyPrice,
        })
      end
      if craftingPrice then
        table.insert(sources, {
          type = AddOn.SourceType.Crafting,
          price = craftingPrice,
        })
      end
      if auctionHouseBuyPrice then
        table.insert(sources, {
          type = AddOn.SourceType.AuctionHouse,
          price = auctionHouseBuyPrice,
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
      if not bestSources[source] then
        bestSources[source] = {}
      end
      table.insert(bestSources[source], {
        itemLink = itemLink,
        amount = amountLeft,
      })
    end
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

function _.determineNPCBuyPrice(itemID)
  return nil -- TODO: Implement
end

function _.determineCraftingPrice(itemID)
  local recipeID = _.retrieveRecipeIDForItem(itemID)

  if recipeID then
    local exportMode = CraftSim.CONST.EXPORT_MODE.NON_WORK_ORDER
    local recipeData = CraftSim.DATAEXPORT:exportRecipeData(recipeID, exportMode)
    if recipeData then
      local recipeType = recipeData.recipeType
      local priceData = CraftSim.PRICEDATA:GetPriceData(recipeData, recipeType)
      local statWeights = CraftSim.AVERAGEPROFIT
        :getProfessionStatWeightsForCurrentRecipe(recipeData, priceData,
          exportMode)
      local averageAmountProducedPerCraft = statWeights.craftedItems.baseQuality +
        statWeights.craftedItems.nextQuality
      local averageCraftingCostPerCraftedItem = priceData.craftingCostPerCraft /
        averageAmountProducedPerCraft
      return averageCraftingCostPerCraftedItem
    end
  end

  return nil
end

--- @param item Item
function AddOn.determineAuctionHouseBuyPrice(item)
  local itemString = AddOn.generateItemString(item)
  return TSM_API.GetCustomPriceValue("DBRecent", itemString)
end

function _.findRecipesToCraft()
  local allRecipes = _.retrieveAllRecipes()
  local potentialCandidates = Array.filter(allRecipes, function(recipe)
    return _.isCraftable(recipe) and
      _.canProducedItemBeSoldInTheAuctionHouse(recipe)
  end)
  local recipesToCraft = {}
  Array.forEach(potentialCandidates, function(potentialCandidate)
    local bestConfiguration = _.selectBestConfiguration(potentialCandidate)
    if _.averageProfitPerCraft(bestConfiguration) > 0 then
      table.insert(recipesToCraft, {
        recipe = potentialCandidate,
        amount = _.retrieveAverageDailySold(item),
      })
    end
  end)
  return recipesToCraft
end

function _.isCraftable(recipe)

end

function _.canProducedItemBeSoldInTheAuctionHouse(recipe)

end
