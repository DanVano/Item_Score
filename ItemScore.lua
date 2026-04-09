local function istable(t)
  return type(t) == 'table'
end

-- Ceiling to nearest whole number
local function VRBCeilScore(num)
  return math.ceil(num)
end


local function VRBGetValidRatings()
  local class = UnitClass("player")
  local ratings = VRB_LABELS[class]
  if ratings then
    return ratings
  end
  return {}
end


local function VRBCalculateRating(weightTable, bonuses)
  local baseScore = 0
  local weightTypes = VRB_WEIGHTS[weightTable]
  local currentBonus = 0

  for t, w in pairs(weightTypes) do
    if BonusScanner.bonuses[t] then
      currentBonus = BonusScanner.bonuses[t]
    end

    if bonuses[t] then
      if istable(w) then
        local threshold    = w[1]
        local beforeWeight = w[2]
        local afterWeight  = w[3]
        if tonumber(currentBonus) < tonumber(threshold) then
          baseScore = baseScore + (bonuses[t] * beforeWeight)
        else
          baseScore = baseScore + (bonuses[t] * afterWeight)
        end
      else
        baseScore = baseScore + (bonuses[t] * w)
      end
    end
  end

  return VRBCeilScore(baseScore)
end


local VRBItemScoreTooltip = CreateFrame("Frame", "VRBItemScoreTooltip", GameTooltip)

VRBItemScoreTooltip:SetScript("OnShow", function(self)
    local bonuses = nil
    local lines = GameTooltip:NumLines()
    local hasScoreToShow = false

    BonusScanner.temp.sets = {}
    BonusScanner.temp.set = ""
    BonusScanner.temp.bonuses = {}
    BonusScanner.temp.details = {}
    BonusScanner.temp.slot = ""

    local className, classFileName = UnitClass("player")
    local color = RAID_CLASS_COLORS[classFileName]

    local lbl = getglobal("GameTooltipTextLeft1")
    if lbl then
        for i = 2, lines, 1 do
            local tmpText = getglobal("GameTooltipTextLeft" .. i)
            if tmpText and tmpText:GetText() then
                BonusScanner:ScanLine(tmpText:GetText())
            end
        end

        bonuses = BonusScanner.temp.bonuses

        if bonuses then
            local ratings = VRBGetValidRatings()

            local bearScore    = 0
            local bearDpsScore = 0
            local totalBearScore = 0

            for i, r in ipairs(ratings) do
                if r == "Bear" then
                    bearScore    = VRBCalculateRating("Bear", bonuses)
                    bearDpsScore = VRBCalculateRating("BearDps", bonuses)
                    totalBearScore = bearScore + bearDpsScore

                    if bearScore > 0 or bearDpsScore > 0 then
                        GameTooltip:AddDoubleLine("Bear:", bearScore .. " // " .. totalBearScore,
                            color.r, color.g, color.b,
                            color.r, color.g, color.b)
                        hasScoreToShow = true
                    end
                elseif r ~= "BearDps" then
                    local vrbscore = VRBCalculateRating(r, bonuses)
                    if vrbscore > 0 then
                        local normalizedLabel = string.gsub(r, className, "")
                        GameTooltip:AddDoubleLine(normalizedLabel .. ":", vrbscore,
                            color.r, color.g, color.b,
                            color.r, color.g, color.b)
                        hasScoreToShow = true
                    end
                end
            end

            if hasScoreToShow then
                GameTooltip:Show()
            end
        end
    end
end)
