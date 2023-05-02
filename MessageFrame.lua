function CritlineClassic.CreateMessageFrame()
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetPoint("CENTER", UIParent, "CENTER")
  f:SetSize(400, 50)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetScript("OnMouseDown", f.StartMoving)
  f:SetScript("OnMouseUp", f.StopMovingOrSizing)
  f:SetScript("OnHide", f.StopMovingOrSizing)

  local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  text:SetPoint("CENTER", f, "CENTER")
  text:SetText("Asdf")
  f.text = text

  return f
end

-- Define a function that shows the new crit message in the center of the screen.
function CritlineClassic.ShowNewCritMessage(spellName, amount)
  if not CritlineClassicMessageFrame then
    CritlineClassicMessageFrame = CritlineClassic.CreateMessageFrame()
  end
  CritlineClassicMessageFrame.text:SetText(string.format("New %s crit: %d!", spellName, amount))
  CritlineClassicMessageFrame:Show()
  C_Timer.After(5, function() CritlineClassicMessageFrame:Hide() end)
end

function CritlineClassic.ShowNewNormalMessage(spellName, amount)
  if not CritlineClassicMessageFrame then
    CritlineClassicMessageFrame = CritlineClassic.CreateMessageFrame()
  end
  CritlineClassicMessageFrame.text:SetText(string.format("New %s normal record: %d!", spellName, amount))
  CritlineClassicMessageFrame:Show()
  C_Timer.After(5, function() CritlineClassicMessageFrame:Hide() end)
end