-- Define a table to hold the highest hits data.
CritlineClassicData = CritlineClassicData or {}

local function AddHighestHitsToTooltip(self, slot)
  if (not slot) then return end

  local actionType, id = GetActionInfo(slot)
  if actionType == "spell" then
    local spellName = GetSpellInfo(id)
    if CritlineClassicData[spellName] then
      local critLineLeft = "Highest Crit: "
      local critLineRight = tostring(CritlineClassicData[spellName].highestCrit)
      local normalLineLeft = "Highest Normal: "
      local normalLineRight = tostring(CritlineClassicData[spellName].highestNormal)

      -- Check if lines are already present in the tooltip.
      local critLineExists = false
      local normalLineExists = false

      for i=1, self:NumLines() do
        local gtl = _G["GameTooltipTextLeft"..i]
        local gtr = _G["GameTooltipTextRight"..i]
        if gtl and gtr then
          if gtl:GetText() == critLineLeft and gtr:GetText() == critLineRight then
            critLineExists = true
          elseif gtl:GetText() == normalLineLeft and gtr:GetText() == normalLineRight then
            normalLineExists = true
          end
        end
      end

      -- If lines don't exist, add them.
      if not critLineExists then
        self:AddDoubleLine(critLineLeft, critLineRight)
        _G["GameTooltipTextLeft"..self:NumLines()]:SetTextColor(1, 1, 1) -- left side color (white)
        _G["GameTooltipTextRight"..self:NumLines()]:SetTextColor(1, 0.82, 0) -- right side color (white)
      end

      if not normalLineExists then
        self:AddDoubleLine(normalLineLeft, normalLineRight)
        _G["GameTooltipTextLeft"..self:NumLines()]:SetTextColor(1, 1, 1) -- left side color (white)
        _G["GameTooltipTextRight"..self:NumLines()]:SetTextColor(1, 0.82, 0) -- right side color (white)
      end

      self:Show()
    end
  end
end

-- Register an event that fires when the player hits an enemy.
local f = CreateFrame("FRAME")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", function(self, event)
  -- Get information about the combat event.
  local timestamp, eventType, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID, _, _, amount, overkill, _, _, _, _, critical = CombatLogGetCurrentEventInfo()

  -- Check if the event is a player hit and update the highest hits data if needed.
  if sourceGUID == UnitGUID("player") and destGUID ~= UnitGUID("player") and (eventType == "SPELL_DAMAGE" or eventType == "SWING_DAMAGE" or eventType == "RANGE_DAMAGE") and amount > 0 then
    local spellName, _, spellIcon = GetSpellInfo(spellID)
    if spellName then
      CritlineClassicData[spellName] = CritlineClassicData[spellName] or {
        highestCrit = 0,
        highestNormal = 0,
        spellIcon = spellIcon,
      }
      if critical then
        if amount > CritlineClassicData[spellName].highestCrit then
          CritlineClassicData[spellName].highestCrit = amount
          PlaySound(5274, "SFX")
          CritlineClassic.ShowNewCritMessage(spellName , amount)
          print("New highest crit hit for " .. spellName .. ": " .. CritlineClassicData[spellName].highestCrit)
        end
      else
        if amount > CritlineClassicData[spellName].highestNormal then
          CritlineClassicData[spellName].highestNormal = amount
          PlaySound(5274, "SFX")
          CritlineClassic.ShowNewNormalMessage(spellName , amount)
          print("New highest normal hit for " .. spellName .. ": " .. CritlineClassicData[spellName].highestNormal)
        end
      end
    end
  end

  --Reset for debugging
  --CritlineClassicData = {}
end)

-- Register an event that fires when the addon is loaded.
local function OnLoad(self, event)
  print("Critline Classic Loaded!")

  CritlineClassicData = _G["CritlineClassicData"]
  
  -- Add the highest hits data to the spell button tooltip.
  --GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)
  hooksecurefunc(GameTooltip, "SetAction", AddHighestHitsToTooltip)
end
local frame = CreateFrame("FRAME")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnLoad)

-- Register an event that fires when the player logs out or exits the game.
local function OnSave(self, event)
  -- Save the highest hits data to the saved variables for the addon.
  _G["CritlineClassicData"] = CritlineClassicData
end
local frame = CreateFrame("FRAME")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", OnSave)

local function ResetData()
  CritlineClassicData = {}
  print("Critline Classic data reset.")
end

SLASH_CRITLINERESET1, SLASH_CRITLINERESET2 = '/critline reset', '/clreset'
function SlashCmdList.CRITLINERESET(msg, editBox)
    ResetData()
end