-- Define a table to hold the highest hits data.
CritlineClassicData = CritlineClassicData or {}

local function GetGCD()
  local _, gcdDuration = GetSpellCooldown(78) -- 78 is the spell ID for Warrior's Heroic Strike
  if gcdDuration == 0 then
    return 1.5 -- Default GCD duration if not available (you may adjust this value if needed)
  else
    return gcdDuration
  end
end

local function AddHighestHitsToTooltip(self, slot)
  if (not slot) then return end

  local actionType, id = GetActionInfo(slot)
  if actionType == "spell" then
    local spellName, _, _, castTime = GetSpellInfo(id)
    if CritlineClassicData[spellName] then
      local cooldown = (GetSpellBaseCooldown(id) or 0) / 1000
      local effectiveCastTime = castTime > 0 and (castTime / 1000) or GetGCD()
      local effectiveTime = max(effectiveCastTime, cooldown)

      local critDPS = CritlineClassicData[spellName].highestCrit / effectiveTime
      local normalDPS = CritlineClassicData[spellName].highestNormal / effectiveTime

      local critLineLeft = "Highest Crit: "
      local critLineRight = tostring(CritlineClassicData[spellName].highestCrit) .. " (" .. format("%.1f", critDPS) .. " DPS)"
      local normalLineLeft = "Highest Normal: "
      local normalLineRight = tostring(CritlineClassicData[spellName].highestNormal) .. " (" .. format("%.1f", normalDPS) .. " DPS)"

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

  if eventType == "SWING_DAMAGE" then
    amount = spellID
    spellName = "Auto Attack"
    spellIcon = 6603 -- or specify the path to a melee icon, if you have one
  else
    spellName, _, spellIcon = GetSpellInfo(spellID)
  end

  -- Check if the event is a player hit or a player heal and update the highest hits/heals data if needed.
  if sourceGUID == UnitGUID("player") and destGUID ~= UnitGUID("player") and 
    (eventType == "SPELL_DAMAGE" or eventType == "SWING_DAMAGE" or eventType == "RANGE_DAMAGE" or eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL") 
    and amount > 0 then

    if spellName then
      CritlineClassicData[spellName] = CritlineClassicData[spellName] or {
        highestCrit = 0,
        highestNormal = 0,
        highestHeal = 0,
        highestHealCrit = 0,
        spellIcon = spellIcon,
      }
      if critical then
        if eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL" then
          if amount > CritlineClassicData[spellName].highestHealCrit then
            CritlineClassicData[spellName].highestHealCrit = amount
            PlaySound(5274, "SFX")
            CritlineClassic.ShowNewHealCritMessage(spellName , amount)
            print("New highest crit heal for " .. spellName .. ": " .. CritlineClassicData[spellName].highestHealCrit)
          end
        else
          if amount > CritlineClassicData[spellName].highestCrit then
            CritlineClassicData[spellName].highestCrit = amount
            PlaySound(5274, "SFX")
            CritlineClassic.ShowNewCritMessage(spellName , amount)
            print("New highest crit hit for " .. spellName .. ": " .. CritlineClassicData[spellName].highestCrit)
          end
        end
      else
        if eventType == "SPELL_HEAL" or eventType == "SPELL_PERIODIC_HEAL" then
          if amount > CritlineClassicData[spellName].highestHeal then
            CritlineClassicData[spellName].highestHeal = amount
            PlaySound(5274, "SFX")
            CritlineClassic.ShowNewHealMessage(spellName , amount)
            print("New highest normal heal for " .. spellName .. ": " .. CritlineClassicData[spellName].highestHeal)
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
  end
end)

-- Register an event that fires when the addon is loaded.
local function OnLoad(self, event)
  print("Critline Classic Loaded!")

  CritlineClassicData = _G["CritlineClassicData"]
  
  -- Add the highest hits data to the spell button tooltip.
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

SLASH_CRITLINERESET1 = '/clreset'
function SlashCmdList.CRITLINERESET(msg, editBox)
    ResetData()
end