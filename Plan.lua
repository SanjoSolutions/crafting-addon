local addOnName = select(1, ...)
--- @class AddOn
local AddOn = select(2, ...)
local _ = {}

--- @type Array
local Array = Library.retrieve("Array", "^2.1.0")
--- @type Boolean
local Boolean = Library.retrieve("Boolean", "^2.0.0")
--- @type Coroutine
local Coroutine = Library.retrieve("Coroutine", "^2.0.0")
--- @type Events
local Events = Library.retrieve("Events", "^2.1.0")
--- @type Mathematics
local Mathematics = Library.retrieve("Mathematics", "^2.0.1")
--- @type Object
local Object = Library.retrieve("Object", "^1.1.0")
--- @type Set
local Set = Library.retrieve("Set", "^1.1.1")

local craftingPage = ProfessionsFrame.CraftingPage

local inputDisplay = ChatFrame4
local planDisplay = ChatFrame5

--- @type ThingsToRetrieveStepsList
local thingsToRetrieve
--- @type GroupedThingsToCraft
local groupedThingsToCraft

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
  local planText = AddOn.generatePlanText(input, thingsToRetrieve,
    groupedThingsToCraft)
  AddOn.showText(planDisplay, planText)
end

local evaluateButton = CreateFrame("Button", nil, UIParent,
  "UIPanelButtonTemplate")
evaluateButton:SetSize(80, 22)
evaluateButton:SetTextToFit("Evaluate")
evaluateButton:SetPoint("BOTTOMRIGHT", -10, 100)
evaluateButton:SetScript("OnClick", function()
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
  end)
end)

local TOLERANCE_AMOUNT = 10000

local buyButton = CreateFrame("Button", nil,
  AuctionHouseFrame,
  "UIPanelButtonTemplate")
buyButton:SetSize(80, 22)
buyButton:SetTextToFit("Buy")
buyButton:SetPoint("BOTTOMRIGHT", -5, 3)
buyButton:SetScript("OnClick", function()
  Coroutine.runAsCoroutineImmediately(function()
    local thingsToRetrieveFromAH = Array.find(thingsToRetrieve,
      function(thingToRetrieve)
        return thingToRetrieve.source == AddOn.SourceType.AuctionHouse
      end).thingsToRetrieveFromSource
    local buyTasks = Array.map(thingsToRetrieveFromAH, function(thingToRetrieve)
      local item = AddOn.createItem(thingToRetrieve.itemLink)
      AddOn.loadItem(item)
      local maximumUnitPriceToBuyFor = AddOn.determineAuctionHouseBuyPrice(item) +
        TOLERANCE_AMOUNT
      return {
        itemLink = thingToRetrieve.itemLink,
        amount = thingToRetrieve.amount,
        maximumUnitPriceToBuyFor = maximumUnitPriceToBuyFor,
      }
    end)
    AddOn.buy(buyTasks)
  end)
end)

function _.findRecipesToCraft()
  CraftingSavedVariablesPerCharacter.plan = {}

  Array.forEach(Object.values(CraftingSavedVariablesPerCharacter.recipes),
    function(recipe)
      if recipe.recipeInfo.learned then
        local recipeData = AddOn.determineRecipeData(recipe.recipeID)

        if recipeData then
          local window = 1 -- hour
          local amountToCraft
          if recipeData.supportsQualities then
            Array.create(Object.entries(recipeData
              .resultData.chanceByQuality)):forEach(function(entry)
              local chance = entry.value
              if chance > 0 then
                local quality = entry.key
                local item = recipeData.resultData.itemsByQuality[quality]
                AddOn.loadItem(item)
                local amountSoldPerDay = TSM_API.GetCustomPriceValue(
                  "dbregionsoldperday",
                  AddOn.generateItemString(item)
                ) or 0
                local amountToCraft = Mathematics.round(amountSoldPerDay / 24 *
                  window)
                if amountToCraft > 0 then
                  local item = {
                    itemLink = item:GetItemLink(),
                    recipeID = recipe.recipeID,
                    amount = amountToCraft,
                  }
                  table.insert(CraftingSavedVariablesPerCharacter.plan, item)
                end
              end
            end)
          else
            local item = recipeData.resultData.itemsByQuality[1]
            AddOn.loadItem(item)
            local amountSoldPerDay = TSM_API.GetCustomPriceValue(
              "dbregionsoldperday",
              AddOn.generateItemString(item)
            ) or 0
            amountToCraft = Mathematics.round(amountSoldPerDay / 24 * window)
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

AddOn.retrieveProfessions = function()
  local professions = {}
  local professionIndex1, professionIndex2 = GetProfessions()
  local professionIndexes = { professionIndex1, professionIndex2, }
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
      Array.forEach(craftingTasks, function(craftingTask)
        local amountRemainingToCraft = craftingTask.amount
        while amountRemainingToCraft >= 1 do
          local _, craftableAmount = craftingTask.recipeData:CanCraft(
            amountRemainingToCraft)
          if craftableAmount >= 1 then
            craftingTask.recipeData.professionGearSet:Equip()
            Coroutine.waitFor(function()
              return CraftSim.TOPGEAR.IsEquipping == false
            end)
            local amountToCraft = min(craftableAmount, craftingTask.amount)
            craftingTask.recipeData:Craft(amountToCraft)
            amountRemainingToCraft = amountRemainingToCraft - amountToCraft
            Events.waitForEvent("UPDATE_TRADESKILL_CAST_STOPPED")
          else
            break
          end
        end
      end)
    end
  end)
end)
