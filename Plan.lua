local addOnName = select(1, ...)
--- @class AddOn
local AddOn = select(2, ...)
local _ = {}

local craftingPage = ProfessionsFrame.CraftingPage

local craftingPlanDisplay = ChatFrame4
local materialsToRetrievePlanDisplay = ChatFrame5

function _.render()
  local craftingPlanText = ''
  Array.forEach(CraftingSavedVariablesPerCharacter.plan, function(item, index)
    if index >= 2 then
      craftingPlanText = craftingPlanText .. '\n'
    end
    local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(item.recipeID, false)
    craftingPlanText = craftingPlanText .. item.amount .. ' x ' .. recipeSchematic.name
  end)
  AddOn.showText(craftingPlanDisplay, craftingPlanText)

  local thingsToRetrieve = AddOn.determineThingsToRetrieve(CraftingSavedVariablesPerCharacter.plan)
  local thingsToRetrieveText = AddOn.generateThingsToRetrieveText(thingsToRetrieve)
  AddOn.showText(materialsToRetrievePlanDisplay, thingsToRetrieveText)
end

local planButton = CreateFrame('Button', nil, craftingPage, 'UIPanelButtonTemplate')
planButton:SetSize(80, 22)
planButton:SetTextToFit('Plan')
planButton:SetPoint('BOTTOMRIGHT', -20, 7)
planButton:SetScript('OnClick', function()
  local item = {
    recipeID = craftingPage.SchematicForm.currentRecipeInfo.recipeID,
    amount = craftingPage.CreateMultipleInputBox:GetValue()
  }
  table.insert(CraftingSavedVariablesPerCharacter.plan, item)
  _.render()
end)

craftingPage.CreateButton:SetPoint('RIGHT', planButton, 'LEFT', -30)

craftingPage.CreateMultipleInputBox:SetPoint('RIGHT', ProfessionsFrame.CraftingPage.CreateButton, 'LEFT', -30)

craftingPage.CreateAllButton:SetPoint('RIGHT', ProfessionsFrame.CraftingPage.CreateMultipleInputBox, 'LEFT', -30)

function _.keepEnabled()
  local currentRecipeInfo = craftingPage.SchematicForm:GetRecipeInfo()
  local canCreateMultiple = Boolean.toBoolean(currentRecipeInfo and currentRecipeInfo.canCreateMultiple)
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
  if event == 'ADDON_LOADED' then
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
  ticker = C_Timer.NewTicker(1, function ()
    -- Render after the price data from TSM has been loaded.
    local isPriceDataLoaded = Boolean.toBoolean(TSM_API.GetCustomPriceValue('DBMarket', 'i:190396'))
    if isPriceDataLoaded then
      ticker:Cancel()
      _.render()
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
  if not CraftingSavedVariables.recipes then
    CraftingSavedVariables.recipes = {}
  end

  if not CraftingSavedVariablesPerCharacter then
    CraftingSavedVariablesPerCharacter = {}
  end
  if not CraftingSavedVariablesPerCharacter.plan then
    CraftingSavedVariablesPerCharacter.plan = {}
  end
end

local frame = CreateFrame('Frame')
frame:SetScript('OnEvent', function(self, event, ...)
  _.onEvent(event, ...)
end)
frame:RegisterEvent('ADDON_LOADED')

local scanRecipesButton = CreateFrame('Button', nil, craftingPage, 'UIPanelButtonTemplate')
scanRecipesButton:SetSize(80, 22)
scanRecipesButton:SetTextToFit('Scan recipes')
scanRecipesButton:SetPoint('TOPLEFT', 100, -40)
scanRecipesButton:SetScript('OnClick', function()
  AddOn.scanRecipes()
  print('Recipes have been scanned.')
end)
