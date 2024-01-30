local _ = {}

do
  BINDING_HEADER_CRAFTING = "Crafting"
  local prefix = "Crafting: "
  BINDING_NAME_CRAFTING_CONFIRM_BUTTON = prefix .. "Confirm"
end

function CraftingTab_OnUpdate(self)
  local cursorX, cursorY = GetCursorPosition()
  cursorX = cursorX / UIParent:GetScale()
  cursorY = cursorY / UIParent:GetScale()
  local craftingFrame = _G["CraftingFrame" .. self:GetID()]
  CraftingFrame_UpdateButtonSide(craftingFrame)
  if not IsMouseButtonDown(self.dragButton) then
    CraftingFrameTab_OnDragStop(self)
    self.dragButton = nil
    self:SetScript("OnUpdate", nil)
  end
end

function CraftingFrameTab_OnDragStop(self)
  CraftingFrame_StopDragging(_G["CraftingFrame" .. self:GetID()])
end

function CraftingFrame_OnLoad(self)
  self:SetFading(false)
  self:SetMaxLines(5000)
  self:SetFontObject(ChatFontNormal)
  self:SetIndentedWordWrap(false)
  self:SetJustifyH("LEFT")

  _.SetWindowColor(self)
  _.SetWindowAlpha(self)

  local noMouseWheel = not GetCVarBool("chatMouseScroll")
  ScrollUtil.InitScrollingMessageFrameWithScrollBar(self, self.ScrollBar,
    noMouseWheel)

  CraftingFrame_SetTabPosition(self, 0)
  CraftingFrame_Update(self:GetID())

  FCFTab_UpdateColors(_G[self:GetName() .. "Tab"], false)

  FloatingChatFrame_SetupScrolling(self)
end

function CraftingFrame_StopDragging(frame)
  frame:StopMovingOrSizing()
  CraftingFrame_SetTabPosition(frame, 0)
end

function CraftingFrame_UpdateButtonSide(frame)

end

function CraftingFrame_SetTabPosition(frame, x)
  local tab = _G[frame:GetName() .. "Tab"]
  tab:ClearAllPoints()
  tab:SetPoint("BOTTOMLEFT", frame:GetName() .. "Background", "TOPLEFT", x + 2, 0)
end

function CraftingFrame_Update(id, onUpdateEvent)
  local frame = _G["CraftingFrame" .. id]
  local tab = _G["CraftingFrame" .. id .. "Tab"]

  FCF_SetWindowName(frame, frame.title, true)

  if not frame.minimized then
    frame:Show()
    CraftingFrame_SetTabPosition(frame, 0)
  end

  FCF_UpdateButtonSide(frame)
end

function CraftingFrame_MinimizeFrame(frame, side)
  local tab = _G[frame:GetName() .. "Tab"]
  if not frame.minFrame then
    frame.minFrame = FCF_CreateMinimizedFrame(frame)

    local minimizedFrame = _G[frame:GetName() .. "Minimized"]
    minimizedFrame:SetScript("OnDoubleClick", function(self)
      CraftingFrame_MaximizeFrame(self.maxFrame)
    end)

    local button = _G[frame:GetName() .. "MinimizedMaximizeButton"]
    button:SetScript("OnClick", function(self)
      CraftingFrame_MaximizeFrame(self:GetParent().maxFrame)
    end)
  end

  if frame.minFrame.resetPosition then
    frame.minFrame:ClearAllPoints()
    frame.minFrame:SetPoint("TOP" .. side, frame, "TOP" .. side, 0, 0)
    frame.minFrame.resetPosition = false
  end

  frame.minimized = true

  frame.minFrame:Show()
  frame:Hide()
  tab:Hide()
end

function CraftingFrame_MaximizeFrame(frame)
  local minFrame = frame.minFrame
  local tab = _G[frame:GetName() .. "Tab"]

  frame.minimized = false

  minFrame:Hide()
  frame:Show()
  tab:Show()

  FCF_FadeInChatFrame(frame)
end

function _.setCraftingWindowSavedPosition(id, point, xOffset, yOffset)
  _.ensureWindowObject(id)
  local window = CraftingSavedVariables.windows[id]
  window.point = point
  window.xOffset = xOffset
  window.yOffset = yOffset
end

function _.setChatWindowSavedDimensions(id, width, height)
  _.ensureWindowObject(id)
  local window = CraftingSavedVariables.windows[id]
  window.width = width
  window.height = height
end

function _.ensureWindowObject(id)
  if not CraftingSavedVariables.windows then
    CraftingSavedVariables.windows = {}
  end
  if not CraftingSavedVariables.windows[id] then
    CraftingSavedVariables.windows[id] = {}
  end
end

_.CRAFTING_FRAME_TEXTURES = {
  "Background",
  "TopLeftTexture",
  "BottomLeftTexture",
  "TopRightTexture",
  "BottomRightTexture",
  "LeftTexture",
  "RightTexture",
  "BottomTexture",
  "TopTexture",
  "ButtonFrameBackground",
  "ButtonFrameTopLeftTexture",
  "ButtonFrameBottomLeftTexture",
  "ButtonFrameTopRightTexture",
  "ButtonFrameBottomRightTexture",
  "ButtonFrameLeftTexture",
  "ButtonFrameRightTexture",
  "ButtonFrameBottomTexture",
  "ButtonFrameTopTexture",
}

function _.SetWindowColor(frame)
  local name = frame:GetName()
  for index, value in pairs(_.CRAFTING_FRAME_TEXTURES) do
    _G[name .. value]:SetVertexColor(0, 0, 0)
  end
end

function _.SetWindowAlpha(frame)
  local alpha = 1
  local name = frame:GetName()
  for index, value in pairs(_.CRAFTING_FRAME_TEXTURES) do
    _G[name .. value]:SetAlpha(alpha)
  end
  frame.oldAlpha = alpha
end
