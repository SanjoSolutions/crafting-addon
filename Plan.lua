local addOnName = select(1, ...)
--- @class AddOn
local AddOn = select(2, ...)
local _ = {}

AddOn.USUAL_CRAFTING_TIME = 0.5 -- seconds
AddOn.MINIMUM_PROFIT_PER_HOUR = 5000000 / 3 * 60
AddOn.MINIMUM_PROFIT_PER_CRAFT = AddOn.MINIMUM_PROFIT_PER_HOUR /
  (AddOn
    .USUAL_CRAFTING_TIME * 60 * 60) -- TODO: Consider the different crafting times for different recipes.

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
--- @type Boolean
local Boolean = Library.retrieve("Boolean", "^2.0.0")
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
local CraftSim = AddOn.retrieveCraftSim()

local craftingPage = ProfessionsFrame.CraftingPage

local inputDisplay = CraftingFrame1
local planDisplay = CraftingFrame2
inputDisplay:SetMaxLines(5000)
planDisplay:SetMaxLines(5000)

--- @type ThingsToRetrieveStepsList
local thingsToRetrieve
--- @type GroupedThingsToCraftWithProgress
local groupedThingsToCraft

local isAuctionHouseOpen = AuctionHouseFrame:IsShown()

local onAuctionHouseShowListener = Events.listenForEvent(
  "AUCTION_HOUSE_SHOW", function()
    isAuctionHouseOpen = true
  end)

local onAuctionHouseClosedListener = Events.listenForEvent(
  "AUCTION_HOUSE_CLOSED", function()
    isAuctionHouseOpen = false
  end)

function _.update()
  local input = CraftingSavedVariablesPerCharacter.plan
  local inputText = ""
  Array.forEach(input, function(item, index)
    if index >= 2 then
      inputText = inputText .. "\n"
    end
    inputText = inputText .. item.amount .. " x " .. item.itemLink
  end)
  AddOn.showText(inputDisplay, inputText)

  thingsToRetrieve, groupedThingsToCraft = AddOn.determineThingsToRetrieve(
    input)
  for source, craftingTasks in pairs(groupedThingsToCraft) do
    for index, craftingTask in ipairs(craftingTasks) do
      local craftingTaskWithProgress = AddOn.CraftingTaskWithProgress:new(
        craftingTask)
      craftingTaskWithProgress.amountCrafted = 0
      craftingTasks[index] = craftingTaskWithProgress
    end
  end
  _.updatePlanText()
end

function _.updatePlanText()
  local planText = AddOn.generatePlanText(thingsToRetrieve,
    groupedThingsToCraft)
  AddOn.showText(planDisplay, planText)
end

local evaluateButton = CreateFrame("Button", nil, UIParent,
  "UIPanelButtonTemplate")
evaluateButton:SetSize(80, 22)
evaluateButton:SetTextToFit("Evaluate")
evaluateButton:SetPoint("BOTTOMRIGHT", -10, 100)
evaluateButton:SetScript("OnClick", function()
  print("Evaluating...")
  Coroutine.runAsCoroutineImmediately(function()
    local professions = AddOn.retrieveProfessions()
    local hasScannedAProfession = false
    Array.forEach(professions, function(profession)
      if not _.hasScannedProfession(profession) then
        _.scanProfession(profession)
        hasScannedAProfession = true
      end
    end)
    if hasScannedAProfession then
      print("Thanks. The recipes have been scanned.")
    end

    _.findRecipesToCraft()
    print("Have finished evaluating.")
  end)
end)

local TOLERANCE_AMOUNT = 10000

local buyButton = CreateFrame("Button", nil,
  AuctionHouseFrame,
  "UIPanelButtonTemplate")
buyButton:SetSize(80, 22)
buyButton:SetTextToFit("Buy")
buyButton:SetScript("OnClick", function()
  Coroutine.runAsCoroutineImmediately(function()
    local thingsToRetrieveFromAH = Array.find(thingsToRetrieve,
      function(thingToRetrieve)
        return thingToRetrieve.source == AddOn.SourceType.AuctionHouse
      end).thingsToRetrieveFromSource
    local purchaseTaskToThingToRetrieve = {}
    local purchaseTasks = Array.map(thingsToRetrieveFromAH,
      function(thingToRetrieve)
        local item = AddOn.createItem(thingToRetrieve.itemLink)
        AddOn.loadItem(item)
        local amount = thingToRetrieve.amount - thingToRetrieve.amountRetrieved
        local purchaseTask = {
          itemLink = thingToRetrieve.itemLink,
          amount = amount,
          maximumUnitPriceToBuyFor = thingToRetrieve.maximumPurchasePrice,
        }
        purchaseTaskToThingToRetrieve[purchaseTask] = thingToRetrieve
        return purchaseTask
      end):filter(function(task) return task.amount >= 1 end)
    AddOn.buy(purchaseTasks, function(purchaseTask, amount)
      local thingToRetrieve = purchaseTaskToThingToRetrieve[purchaseTask]
      thingToRetrieve.amountRetrieved = thingToRetrieve.amountRetrieved + amount
      _.updatePlanText()
    end)
  end)
end)

local sellButton = CreateFrame("Button", nil,
  AuctionHouseFrame,
  "UIPanelButtonTemplate")
sellButton:SetSize(80, 22)
sellButton:SetTextToFit("Sell")
sellButton:SetPoint("BOTTOMRIGHT", -5, 3)
sellButton:SetScript("OnClick", function()
  Coroutine.runAsCoroutineImmediately(function()
    local sellTasks = Array.map(CraftingSavedVariablesPerCharacter.plan,
        function(thingToCraft)
          local item = AddOn.createItem(thingToCraft.itemLink)
          AddOn.loadItem(item)
          local bagQuantity = AddOn.determineBagQuantity(item)
          local itemString = AddOn.generateItemString(item)
          local amount = min(
            thingToCraft.amount - (TSM_API.GetAuctionQuantity(itemString) or 0),
            bagQuantity)
          return {
            itemLink = thingToCraft.itemLink,
            amount = amount,
          }
        end)
      :filter(function(sellTask)
        return sellTask.amount >= 1
      end)
    AddOn.sell(sellTasks)
  end)
end)

buyButton:SetPoint("RIGHT", sellButton, "LEFT", -2, 0)

function _.findRecipesToCraft()
  CraftingSavedVariablesPerCharacter.plan = {}

  Array.forEach(Object.values(CraftingSavedVariablesPerCharacter.recipes),
    function(recipe)
      if recipe.recipeInfo.learned and recipe.recipeID ~= 381417 and not AddOn.isTransmuteRecipe(recipe) then
        local recipeData = AddOn.determineRecipeData(recipe.recipeID)

        if recipeData and not Array.any(C_TradeSkillUI.GetRecipeRequirements(recipeData.recipeID), function(
            requirement)
            return requirement.name == "Earth-Warder's Forge"
          end) and recipeData:GetAverageProfit() >= AddOn.MINIMUM_PROFIT_PER_CRAFT then
          local window = 1 -- hour
          local averageSoldPerDayMultiplier = 1 -- to account for that the stat has been derived from TSM users and that some players might not use TSM.
          if recipeData.supportsQualities then
            Array.create(Object.entries(recipeData
              .resultData.chanceByQuality)):forEach(function(entry)
              local chance = entry.value
              if chance > 0 then
                local quality = entry.key
                --- @type Item
                local item = recipeData.resultData.itemsByQuality[quality]
                AddOn.loadItem(item)
                local amountSoldPerDay = (TSM_API.GetCustomPriceValue(
                  "dbregionsoldperday*10000",
                  AddOn.generateItemString(item, false)
                ) or 0) / 10000
                local amountInAuctionHouse = AddOn
                  .determineTotalAmountInAuctionHouse(item)
                local amountToPutIntoAuctionHouse = amountSoldPerDay *
                  averageSoldPerDayMultiplier *
                  window / 24
                if amountToPutIntoAuctionHouse < 1 then
                  amountToPutIntoAuctionHouse = 0
                else
                  amountToPutIntoAuctionHouse = Mathematics.round(
                    amountToPutIntoAuctionHouse)
                end
                local amountToCraft = max(
                  amountToPutIntoAuctionHouse - amountInAuctionHouse, 0)
                if amountToCraft > 0 then
                  --- @type ThingToCraft
                  local item = {
                    itemLink = item:GetItemLink(),
                    recipeID = recipe.recipeID,
                    amount = amountToCraft,
                  }
                  table.insert(CraftingSavedVariablesPerCharacter.plan, item)
                end
              end
            end)
          elseif recipeData.resultData.itemsByQuality[1] then -- skips recrafting
            --- @type Item
            local item = recipeData.resultData.itemsByQuality[1]
            AddOn.loadItem(item)
            local amountSoldPerDay = (TSM_API.GetCustomPriceValue(
              "dbregionsoldperday*10000",
              AddOn.generateItemString(item)
            ) or 0) / 10000
            local amountInAuctionHouse = AddOn
              .determineTotalAmountInAuctionHouse(item)
            local amountToPutIntoAuctionHouse = amountSoldPerDay *
              averageSoldPerDayMultiplier *
              window / 24
            if amountToPutIntoAuctionHouse < 1 then
              amountToPutIntoAuctionHouse = 0
            else
              amountToPutIntoAuctionHouse = Mathematics.round(
                amountToPutIntoAuctionHouse)
            end
            local amountToCraft = max(
              amountToPutIntoAuctionHouse - amountInAuctionHouse, 0)
            if amountToCraft > 0 then
              local item = {
                itemLink = item:GetItemLink(),
                recipeID = recipe.recipeID,
                amount = amountToCraft,
              }
              table.insert(CraftingSavedVariablesPerCharacter.plan, item)
            end
          end

          Coroutine.yieldAndResume()
        end
      end
    end)
  _.update()
end

function AddOn.isTransmuteRecipe(recipe)
  return recipe.profession == 3 and recipe.categoryID == 1604
end

AddOn.retrieveProfessions = function()
  local professionIndex1, professionIndex2, __, __, cookingIndex = GetProfessions()
  local professionIndexes = {}
  if professionIndex1 then
    table.insert(professionIndexes, professionIndex1)
  end
  if professionIndex2 then
    table.insert(professionIndexes, professionIndex2)
  end
  if cookingIndex then
    table.insert(professionIndexes, cookingIndex)
  end
  local professions = Array.map(professionIndexes, function(professionIndex)
    local name = GetProfessionInfo(professionIndex)
    return { index = professionIndex, name = name, }
  end)
  return professions
end

_.hasScannedProfession = function(profession)
  return Set.contains(
    CraftingSavedVariablesPerCharacter.hasProfessionBeenScanned,
    profession.index)
end

_.scanProfession = function(profession)
  if not ProfessionFrame or not ProfessionFrame:IsShown() then
    print('Please open the profession window for the profession "' ..
      profession.name .. '" so that the recipes can be scanned.')
    _.waitForProfessionsFrameCraftingPageInit()
  end

  local professionInfo = C_TradeSkillUI.GetChildProfessionInfo()
  CraftingSavedVariables.professions[professionInfo.profession] =
    professionInfo

  AddOn.scanRecipes()
  Set.add(
    CraftingSavedVariablesPerCharacter.hasProfessionBeenScanned,
    profession.index)
end

local lastCallTimeOfProfessionsFrameCraftingPageInit = nil

hooksecurefunc(ProfessionsFrame.CraftingPage, "Init", function()
  lastCallTimeOfProfessionsFrameCraftingPageInit = GetTime()
end)

function _.waitForProfessionsFrameCraftingPageInit()
  local previousLastCallTimeOfProfessionsFrameCraftingPageInit =
    lastCallTimeOfProfessionsFrameCraftingPageInit
  Coroutine.waitFor(function()
    return lastCallTimeOfProfessionsFrameCraftingPageInit ~=
      previousLastCallTimeOfProfessionsFrameCraftingPageInit
  end)
end

local amountInput

local toggleConsiderButton = CreateFrame("Button", nil, craftingPage,
  "UIPanelButtonTemplate")
toggleConsiderButton:SetSize(80, 22)
toggleConsiderButton:SetTextToFit("Consider")
toggleConsiderButton:SetPoint("BOTTOMRIGHT", -20, 7)
toggleConsiderButton:SetScript("OnClick", function()
  local recipeID = craftingPage.SchematicForm.currentRecipeInfo.recipeID
  if Set.contains(CraftingSavedVariablesPerCharacter.considered, recipeID) then
    Set.remove(CraftingSavedVariablesPerCharacter.considered, recipeID)
  else
    Set.add(CraftingSavedVariablesPerCharacter.considered, recipeID)
  end
  _.updateToggleConsiderButton(recipeID)
  _.update()
end)

function _.updateToggleConsiderButton(recipeID)
  if Set.contains(CraftingSavedVariablesPerCharacter.considered, recipeID) then
    toggleConsiderButton:SetTextToFit("Remove from considerations")
  else
    toggleConsiderButton:SetTextToFit("Consider")
  end
end

EventRegistry:RegisterCallback(
  "ProfessionsRecipeListMixin.Event.OnRecipeSelected",
  function(self, recipeInfo, recipeList)
    _.updateToggleConsiderButton(recipeInfo.recipeID)
  end)

local planButton = CreateFrame("Button", nil, craftingPage,
  "UIPanelButtonTemplate")
planButton:SetSize(80, 22)
planButton:SetTextToFit("Plan")
planButton:SetPoint("RIGHT", toggleConsiderButton, "LEFT", -8, 0)
planButton:SetScript("OnClick", function()
  local item = {
    recipeID = craftingPage.SchematicForm.currentRecipeInfo.recipeID,
    amount = amountInput:GetValue(),
  }
  table.insert(CraftingSavedVariablesPerCharacter.plan, item)
  Coroutine.runAsCoroutineImmediately(_.update)
end)

amountInput = CreateFrame("EditBox", nil, craftingPage,
  "NumericInputSpinnerTemplate")
amountInput:SetMaxLetters(5)
amountInput:SetMinMaxValues(1, 99999)
amountInput:SetPoint("RIGHT", planButton, "LEFT", -30, 0)

craftingPage.CreateButton:SetPoint("RIGHT", amountInput, "LEFT", -100, 0)

function _.keepEnabled()
  local currentRecipeInfo = craftingPage.SchematicForm:GetRecipeInfo()
  local canCreateMultiple = Boolean.toBoolean(currentRecipeInfo and
    currentRecipeInfo.canCreateMultiple)
  return canCreateMultiple
end

local setEnabled = craftingPage.CreateMultipleInputBox.SetEnabled
craftingPage.CreateMultipleInputBox.SetEnabled = function(self, enabled)
  if _.keepEnabled() then
    if not craftingPage.CreateMultipleInputBox:IsEnabled() then
      setEnabled(self, true)
    end
  else
    return setEnabled(self, enabled)
  end
end

function _.onEvent(event, ...)
  if event == "ADDON_LOADED" then
    _.onAddonLoaded(...)
  end
end

function _.onAddonLoaded(loadedAddOnName)
  if loadedAddOnName == addOnName then
    _.main()
  end
end

function _.main()
  _.initializeSavedVariables()

  if CraftAndSellInAH.auctionHousePriceSource == "TSM" then
    local ticker
    ticker = C_Timer.NewTicker(1, function()
      -- Render after the price data from TSM has been loaded.
      local isPriceDataLoaded = Boolean.toBoolean(TSM_API.GetCustomPriceValue(
        "DBMarket", "i:190396"))
      if isPriceDataLoaded then
        ticker:Cancel()
        Coroutine.runAsCoroutine(_.update)
      end
    end)
  else
    Coroutine.runAsCoroutine(_.update)
  end
end

function _.initializeSavedVariables()
  if not CraftingSavedVariables then
    CraftingSavedVariables = {}
  end
  if not CraftingSavedVariables.itemIDToRecipeID then
    CraftingSavedVariables.itemIDToRecipeID = {}
  end
  if not CraftingSavedVariables.professions then
    CraftingSavedVariables.professions = {}
  end
  if not CraftingSavedVariablesPerCharacter.recipes then
    CraftingSavedVariablesPerCharacter.recipes = {}
  end

  if not CraftingSavedVariablesPerCharacter then
    CraftingSavedVariablesPerCharacter = {}
  end
  if not CraftingSavedVariablesPerCharacter.plan then
    --- @type ThingToCraft[]
    CraftingSavedVariablesPerCharacter.plan = {}
  end
  if not CraftingSavedVariablesPerCharacter.considered then
    CraftingSavedVariablesPerCharacter.considered = Set.create()
  end
  if not CraftingSavedVariablesPerCharacter.hasProfessionBeenScanned then
    CraftingSavedVariablesPerCharacter.hasProfessionBeenScanned = Set.create()
  end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
  _.onEvent(event, ...)
end)
frame:RegisterEvent("ADDON_LOADED")

local scanRecipesButton = CreateFrame("Button", nil, craftingPage,
  "UIPanelButtonTemplate")
scanRecipesButton:SetSize(80, 22)
scanRecipesButton:SetTextToFit("Scan recipes")
scanRecipesButton:SetPoint("TOPLEFT", 100, -26)
scanRecipesButton:SetScript("OnClick", function()
  AddOn.scanRecipes()
  print("Recipes have been scanned.")
end)

local craftPlannedButton = CreateFrame("Button", nil, craftingPage,
  "UIPanelButtonTemplate")
craftPlannedButton:SetSize(80, 22)
craftPlannedButton:SetTextToFit("Craft planned")
craftPlannedButton:SetPoint("TOPLEFT", 100, -50)
craftPlannedButton:SetScript("OnClick", function()
  Coroutine.runAsCoroutineImmediately(function()
    local professionInfo = C_TradeSkillUI.GetChildProfessionInfo()
    local craftingTasks = groupedThingsToCraft[professionInfo.profession]
    if craftingTasks then
      for index, craftingTask in ipairs(craftingTasks) do
        if craftingTask:determineAmountRemainingToCraft() >= 1 then
          local craftableAmount = select(2, craftingTask.recipeData:CanCraft(
            craftingTask:determineAmountRemainingToCraft()))
          if craftableAmount >= 1 then
            local listener
            listener = Events.listenForEvent("TRADE_SKILL_CLOSE", function()
              CraftAndSellInAH.cancel()
              listener:stopListening()
            end)
            Professions.SetDefaultFilters()
            SearchBoxTemplate_ClearText(ProfessionsFrame.CraftingPage.RecipeList
              .SearchBox)
            C_TradeSkillUI.OpenRecipe(craftingTask.recipeData.recipeID)
            craftingTask.recipeData.professionGearSet:Equip()
            Coroutine.waitFor(function()
              return CraftSim.TOPGEAR.IsEquipping == false
            end)
            local event
            while craftingTask:determineAmountRemainingToCraft() >= 1 do
              if event == "UPDATE_TRADESKILL_CAST_STOPPED" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" then
                -- Wait a bit so that item counts are up to date.
                Coroutine.waitForDuration(1)
              end
              local craftableAmount = select(2, craftingTask.recipeData:CanCraft(
                craftingTask:determineAmountRemainingToCraft()))
              if craftableAmount >= 1 then
                local amountToCraft = min(craftableAmount,
                  craftingTask:determineAmountRemainingToCraft())
                print("Going to craft " ..
                  amountToCraft ..
                  " x " ..
                  C_TradeSkillUI.GetRecipeLink(craftingTask.recipeID) .. ".")
                if CraftAndSellInAH.showConfirmButton() then
                  local hasSpellCastFailed = false
                  local listener2 = Events.listenForEvent(
                    "UNIT_SPELLCAST_FAILED",
                    function(event, unitTarget)
                      if unitTarget == "player" then
                        hasSpellCastFailed = true
                      end
                    end)
                  local listener3 = Events.listenForEvent(
                    "UNIT_SPELLCAST_SUCCEEDED",
                    function(event, unitTarget, castGUID, spellID)
                      if unitTarget == "player" and spellID == craftingTask.recipeID then
                        craftingTask.amountCrafted = craftingTask.amountCrafted +
                          1
                        _.updatePlanText()
                      end
                    end)
                  craftingTask.recipeData:Craft(amountToCraft)
                  if not hasSpellCastFailed then
                    local events = {
                      "UPDATE_TRADESKILL_CAST_STOPPED",
                      "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED",
                      "TRADE_SKILL_CLOSE",
                    }
                    if amountToCraft == 1 then
                      Array.append(events, { "UNIT_SPELLCAST_SUCCEEDED",
                        "UNIT_SPELLCAST_STOP", })
                    end
                    event = select(2,
                      Events.waitForOneOfEventsAndCondition(events,
                        function(self, event, unitTarget)
                          if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_STOP" then
                            return unitTarget == "player"
                          else
                            return true
                          end
                        end))
                    if event == "TRADE_SKILL_CLOSE" then
                      listener2:stopListening()
                      listener3:stopListening()
                      return
                    end
                  end
                  listener2:stopListening()
                  listener3:stopListening()
                else
                  return
                end
              else
                break
              end
            end
          end
        end
      end
      print("Through the list.")
    end
  end)
end)
