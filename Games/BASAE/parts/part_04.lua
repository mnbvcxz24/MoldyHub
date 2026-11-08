                    local minimumCPS = CPSFilter.amount * (scales[CPSFilter.unit] or 1)
                    cpsPriorityPickup = cps >= minimumCPS
                end
                if HighestCashEnabled and cps >= 0 then
                    local lowestPlaced = GetLowestPlacedCPS()
                    aboveLowestPriorityPickup = lowestPlaced >= 0 and cps > lowestPlaced
                end
            end
            if evaluationCancelled() or not pickup.Parent then
                SetPickupTracking(pickup, "Cancelled: automation toggled")
                return
            end
            local selectedRarityCount = 0
            for _, selected in pairs(SelectedRarities) do
                if selected then selectedRarityCount += 1 end
            end
            local anyPickupFilterEnabled = UnindexedOnlyEnabled or HighestCashEnabled
                or KGThresholdAmount > 0 or CPSFilter.amount > 0 or selectedRarityCount > 0
            local mutationPickupMatch = PickUpWithMutationEnabled and GetPickupMutation(pickup) ~= "No Mutation"
            local qualified = not anyPickupFilterEnabled or forceUnindexedPickup
                or aboveLowestPriorityPickup or kgPriorityPickup or cpsPriorityPickup or rarityPriorityPickup
                or mutationPickupMatch
            if not qualified then
                local reason = "no enabled pickup rule matched"
                if HighestCashEnabled and cps < 0 then
                    reason = "CPS unavailable for Above Lowest $/s"
                elseif CPSFilter.amount > 0 and cps < 0 then
                    reason = "CPS unavailable for minimum CPS"
                elseif not rarityPriorityPickup then
                    reason = "rarity mismatch and no CPS/KG priority matched"
                end
                SetPickupTracking(pickup, "Rejected: " .. reason, cpsText)
                RejectPickupAndRestart("Filtered out " .. pickup.Name .. " | " .. reason .. ".")
                return
            end
            if forceUnindexedPickup then
                pickupPriority = 1
            elseif aboveLowestPriorityPickup then
                pickupPriority = 2
            elseif kgPriorityPickup then
                pickupPriority = 3
            elseif cpsPriorityPickup then
                pickupPriority = 4
            else
                pickupPriority = 5
            end
            pickup:SetAttribute("MoldyHub_BASAE_Priority", pickupPriority)
            pickup:SetAttribute("MoldyHub_BASAE_Qualified", true)
            if PickupRequested then
                local activePriority = ActivePickup and ActivePickup.Parent and (ActivePickup:GetAttribute("MoldyHub_BASAE_Priority") or 5) or math.huge
                local activeWeight = ActivePickup and ActivePickup.Parent and GetPickupWeightKg(ActivePickup) or nil
                local shouldPreempt = pickupPriority < activePriority
                if pickupPriority == activePriority then
                    if pickupPriority == 2 or pickupPriority == 4 then
                        shouldPreempt = cps > ActivePickupCPS
                    elseif pickupPriority == 3 then
                        shouldPreempt = pickupWeightKg ~= nil and (activeWeight == nil or pickupWeightKg > activeWeight)
                    end
                end
                if shouldPreempt then
                    SetPickupTracking(pickup, "Replacing lower-priority pickup (priority " .. tostring(pickupPriority) .. ")", cpsText)
                    PickupGeneration += 1
                    PickupRequested = false
                    if PickupMovementConnection then
                        PickupMovementConnection:Disconnect()
                        PickupMovementConnection = nil
                    end
                    local oldPickupName = ActivePickup and ActivePickup.Name or "none"
                    SetTrackerStatus(string.format("PICKUP LOCK PREEMPT: %s (priority %d, %.2f CPS) replaces %s (priority %s, %.2f CPS) during phase %s.", pickup.Name, pickupPriority, cps, oldPickupName, tostring(activePriority), ActivePickupCPS, PickupPhase))
                    local oldCharacter = LocalPlayer.Character
                    local oldHumanoid = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
                    if oldHumanoid then oldHumanoid:Move(Vector3.zero, false) end
                    task.wait()
                else
                    SetPickupTracking(pickup, "Checked: another pickup has priority", cpsText)
                    SetTrackerStatus(string.format("Eligible pet %s ignored while %s is locked (priority %s vs %d; CPS %.2f vs %.2f).", pickup.Name, tostring(ActivePickup and ActivePickup.Name or "another pickup"), tostring(activePriority), pickupPriority, cps, ActivePickupCPS))
                    return
                end
            end
            PickupGeneration += 1
            local pickupToken = PickupGeneration
            ActivePickup = pickup
            FlingAnimalTarget = pickup
            FlingTargetAnimalName = pickup.Name
            FlingTargetWeightKg = GetAnimalWeightKg(pickup)
            if FlingTargetWeightKg ~= nil then
                SetTrackerStatus("Pickup identity captured: " .. tostring(FlingTargetAnimalName) .. " | WeightKg=" .. tostring(FlingTargetWeightKg))
            end
            task.spawn(function()
                local identityDeadline = os.clock() + 12
                local identityAttempts = 0
                local lastIdentityLog = 0
                while not Runtime.Stopped and PickupGeneration == pickupToken
                    and ActivePickup == pickup and FlingTargetWeightKg == nil
                    and os.clock() < identityDeadline do
                    identityAttempts += 1
                    local identityFolder = workspace:FindFirstChild("AnimalPickups")
                    if identityFolder then
                        for _, candidate in ipairs(identityFolder:GetChildren()) do
                            if candidate == pickup and candidate.Name == FlingTargetAnimalName then
                                local identity = GetAnimalWeightKg(candidate)
                                if identity ~= nil then
                                    FlingTargetWeightKg = identity
                                    SetTrackerStatus("Captured pickup identity: " .. tostring(FlingTargetAnimalName) .. " | WeightKg=" .. tostring(identity) .. " | attempts=" .. tostring(identityAttempts))
                                    break
                                end
                            end
                        end
                    end
                    local now = os.clock()
                    if FlingTargetWeightKg == nil and now - lastIdentityLog >= 1 then
                        lastIdentityLog = now
                        SetTrackerStatus("Searching AnimalPickups | animal=" .. tostring(FlingTargetAnimalName) .. " | WeightKg=waiting | attempts=" .. tostring(identityAttempts))
                    end
                    if FlingTargetWeightKg == nil then task.wait(0.25) end
                end
                if FlingTargetWeightKg == nil and PickupGeneration == pickupToken then
                    SetTrackerStatus("Initial identity search timed out for " .. tostring(FlingTargetAnimalName) .. "; fling recovery will retry.")
                end
            end)
            ActivePickupCPS = cps
            ActivePickup:SetAttribute("MoldyHub_BASAE_Priority", pickupPriority)
            PickupPhase = "ANIMAL_APPROACH"
            SetPickupTracking(pickup, "Selected for pickup", cpsText)
            PickupRequested = true
            task.delay(45, function()
                if Runtime.Stopped or PickupGeneration ~= pickupToken or not PickupRequested
                    or ReturningAfterPickup or ActivePickup ~= pickup then
                    return
                end
                SetTrackerStatus("PICKUP WATCHDOG: " .. pickup.Name .. " stayed locked for 45s; releasing stale lock and resuming Auto Break.")
                PickupGeneration += 1
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                PickupPhase = "IDLE"
                if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
                if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
                if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
                local watchdogCharacter = LocalPlayer.Character
                local watchdogHumanoid = watchdogCharacter and watchdogCharacter:FindFirstChildOfClass("Humanoid")
                if watchdogHumanoid then watchdogHumanoid:Move(Vector3.zero, false) end
                WaitingForPickup = false
                ArrivedAtTarget = false
                task.spawn(function()
                    EquipHotbarOne()
                    task.wait(0.2)
                    if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                        StartAutoBreak(true)
                    end
                end)
            end)
            if StopAutoBreak then StopAutoBreak("Auto Break paused while Auto Pickup handles " .. pickup.Name .. ".", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            local activeCharacter = LocalPlayer.Character
            local activeHumanoid = activeCharacter and activeCharacter:FindFirstChildOfClass("Humanoid")
            if activeHumanoid then activeHumanoid:Move(Vector3.zero, false) end
            SetPickupPhase("ANIMAL_APPROACH", string.format("%s | %.2f CPS | Auto Break paused; animal target owns movement.", pickup.Name, cps))
            local pickupPosition
            local positionOk, position = pcall(function()
                if pickup:IsA("Model") then return pickup:GetPivot().Position end
                if pickup:IsA("BasePart") then return pickup.Position end
            end)
            if positionOk then
                pickupPosition = position
                LastAnimalPickupPosition = position
            end
            local moveCharacter = LocalPlayer.Character
            local moveHumanoid = moveCharacter and moveCharacter:FindFirstChildOfClass("Humanoid")
            local moveRoot = moveCharacter and moveCharacter:FindFirstChild("HumanoidRootPart")
            if not pickupPosition or not moveHumanoid or not moveRoot then
                if PickupGeneration ~= pickupToken then return end
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: animal location or character position unavailable.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local animalMoveStarted = os.clock()
            local lastAnimalProgressAt = os.clock()
            local bestAnimalDistance = math.huge
            TouchAutomationProgress("PICKUP:ANIMAL_APPROACH")
            if PickupMovementConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            local animalMoveBindName = "MoldyHub_BASAE_PickupAnimal_" .. tostring(pickupToken)
            RunService:BindToRenderStep(animalMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                if not PickupRequested or PickupGeneration ~= pickupToken or not pickup.Parent
                    or LocalPlayer.Character ~= moveCharacter or not moveRoot.Parent
                    or moveHumanoid.Health <= 0 then
                    moveHumanoid:Move(Vector3.zero, false)
                    return
                end
                local ok, currentPosition = pcall(function()
                    if pickup:IsA("Model") then return pickup:GetPivot().Position end
                    if pickup:IsA("BasePart") then return pickup.Position end
                end)
                if ok and currentPosition then
                    local direction = Vector3.new(currentPosition.X - moveRoot.Position.X, 0, currentPosition.Z - moveRoot.Position.Z)
                    if direction.Magnitude > 4 then
                        moveHumanoid:Move(direction.Unit, false)
                    else
                        moveHumanoid:Move(Vector3.zero, false)
                    end
                end
            end)
            local animalMoveConnection = {
                Disconnect = function()
                    pcall(function() RunService:UnbindFromRenderStep(animalMoveBindName) end)
                end
            }
            PickupMovementConnection = animalMoveConnection
            while not Runtime.Stopped and PickupRequested and PickupGeneration == pickupToken and pickup.Parent and moveHumanoid.Health > 0 do
                if LocalPlayer.Character ~= moveCharacter or not moveCharacter.Parent or not moveRoot.Parent then
                    if PickupGeneration ~= pickupToken then return end
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: character changed while moving to animal.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local ok, currentPosition = pcall(function()
                    if pickup:IsA("Model") then return pickup:GetPivot().Position end
                    if pickup:IsA("BasePart") then return pickup.Position end
                end)
                if ok and currentPosition then
                    pickupPosition = currentPosition
                    LastAnimalPickupPosition = currentPosition
                end
                local animalOffset = Vector3.new(pickupPosition.X - moveRoot.Position.X, 0, pickupPosition.Z - moveRoot.Position.Z)
                local animalDistance = animalOffset.Magnitude
                if animalDistance <= 4 then break end
                local now = os.clock()
                if now - animalMoveStarted >= 25 then
                    moveHumanoid:Move(Vector3.zero, false)
                    if PickupGeneration ~= pickupToken then return end
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus(string.format("Pickup cancelled: timed out reaching animal location (%.1f studs away).", animalDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if animalDistance < bestAnimalDistance - 0.75 then
                    bestAnimalDistance = animalDistance
                    lastAnimalProgressAt = now
                    TouchAutomationProgress()
                elseif now - lastAnimalProgressAt >= 2.5 then
                    lastAnimalProgressAt = now
                    bestAnimalDistance = animalDistance
                    moveHumanoid:Move(Vector3.zero, false)
                    task.wait(0.05)
                    if PickupRequested and PickupGeneration == pickupToken and pickup.Parent
                        and LocalPlayer.Character == moveCharacter and moveRoot.Parent and moveHumanoid.Health > 0 then
                        local refreshedPosition
                        local refreshedOk, refreshed = pcall(function()
                            if pickup:IsA("Model") then return pickup:GetPivot().Position end
                            if pickup:IsA("BasePart") then return pickup.Position end
                        end)
                        if refreshedOk then refreshedPosition = refreshed end
                        if refreshedPosition then
                            local refreshedDirection = Vector3.new(
                                refreshedPosition.X - moveRoot.Position.X, 0,
                                refreshedPosition.Z - moveRoot.Position.Z
                            )
                            if refreshedDirection.Magnitude > 4 then
                                moveHumanoid:Move(refreshedDirection.Unit, false)
                            end
                        end
                    end
                    SetTrackerStatus(string.format("PICKUP MOVEMENT: reset and reinitialized movement toward %s (%.1f studs).", pickup.Name, animalDistance))
                end
                task.wait(0.05)
            end
            if PickupMovementConnection == animalMoveConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            if animalMoveConnection then animalMoveConnection:Disconnect(); animalMoveConnection = nil end
            moveHumanoid:Move(Vector3.zero, false)
            if PickupGeneration ~= pickupToken then return end
            if not PickupRequested or not pickup.Parent or not pickupPosition then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Pickup cancelled: animal disappeared before location verification.")
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            local verifiedAnimalDistance = (Vector3.new(pickupPosition.X, moveRoot.Position.Y, pickupPosition.Z) - moveRoot.Position).Magnitude
            if verifiedAnimalDistance > 5 then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus(string.format("Pickup cancelled: animal location verification failed (%.1f studs).", verifiedAnimalDistance))
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                return
            end
            SetPickupPhase("PROMPT_SEARCH", string.format("%s | animal reached (%.1f studs); finding its nearest matching StealPrompt.", pickup.Name, verifiedAnimalDistance))
            local prompt
            local promptState = "StealPrompt not found"
            local promptDeadline = os.clock() + 5
            local promptMatchRadius = 18
            local function getPromptPosition(candidate)
                local parent = candidate and candidate.Parent
                while parent and parent ~= workspace do
                    if parent:IsA("Attachment") then
                        return parent.WorldPosition
                    elseif parent:IsA("BasePart") then
                        return parent.Position
                    elseif parent:IsA("Model") then
                        local ok, pivot = pcall(function() return parent:GetPivot() end)
                        if ok and pivot then return pivot.Position end
                    end
                    parent = parent.Parent
                end
                return nil
            end
            repeat
                if PickupGeneration ~= pickupToken then return end
                prompt = nil
                local nearestDistance = math.huge
                local totalStealPrompts = 0
                local enabledStealPrompts = 0
                for _, candidate in ipairs(workspace:GetDescendants()) do
                    if candidate:IsA("ProximityPrompt") and candidate.Name == "StealPrompt" then
                        totalStealPrompts += 1
                        if candidate.Enabled then
                            enabledStealPrompts += 1
                            local candidatePosition = getPromptPosition(candidate)
                            if candidatePosition then
                                local distance = (candidatePosition - pickupPosition).Magnitude
                                if distance < nearestDistance and distance <= promptMatchRadius then
                                    nearestDistance = distance
                                    prompt = candidate
                                end
                            end
                        end
                    end
                end
                if prompt then
                    promptState = string.format("nearest enabled StealPrompt: %s (%.2f studs from animal; found %d total/%d enabled)", prompt:GetFullName(), nearestDistance, totalStealPrompts, enabledStealPrompts)
                else
                    promptState = string.format("No enabled StealPrompt within %.0f studs of animal (found %d total/%d enabled)", promptMatchRadius, totalStealPrompts, enabledStealPrompts)
                end
                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    break
                end
                task.wait(0.25)
            until os.clock() >= promptDeadline
            if PickupGeneration ~= pickupToken then return end
            if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
                PickupRequested = false
                ActivePickup = nil
                ActivePickupCPS = -1
                SetTrackerStatus("Eligible pet " .. pickup.Name
                    .. " but pickup prompt unavailable after 5s: " .. promptState .. ".")
                task.delay(2, function()
                    if pickup.Parent and AutoPickupEnabled then PickupMonitorSeen[pickup] = nil end
                end)
                if AutoBreakEnabled and StartAutoBreak then StartAutoBreak(true) end
                return
            end
            SetPickupPhase("PROMPT_APPROACH", pickup.Name .. " | moving to matching StealPrompt; target and movement remain locked.")
            task.spawn(function()
                SetPickupPhase("PROMPT_APPROACH", "Lock held by " .. pickup.Name .. "; moving to its matching prompt.")
                local character, humanoid, root = WaitForCharacterAndParts(10, function()
                    return PickupRequested and PickupGeneration == pickupToken and AutoPickupEnabled
                end)
                if not character then
                    if PickupGeneration == pickupToken then
                        PickupRequested = false
                        ActivePickup = nil
                        ActivePickupCPS = -1
                        SetTrackerStatus("Pickup cancelled: character parts unavailable while approaching prompt.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    end
                    return
                end
                local promptPosition = getPromptPosition(prompt)
                if not promptPosition then
                    PickupRequested = false
                    SetTrackerStatus("Pickup cancelled: could not read matched prompt position.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local moveStarted = os.clock()
                local lastPromptProgressAt = os.clock()
                local bestPromptDistance = math.huge
                TouchAutomationProgress("PICKUP:PROMPT_APPROACH")
                if PickupMovementConnection then
                    PickupMovementConnection:Disconnect()
                    PickupMovementConnection = nil
                end
                local promptMoveBindName = "MoldyHub_BASAE_PickupPrompt_" .. tostring(pickupToken)
                RunService:BindToRenderStep(promptMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                    if not PickupRequested or PickupGeneration ~= pickupToken or not pickup.Parent or not prompt.Parent
                        or LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                        humanoid:Move(Vector3.zero, false)
                        return
                    end
                    local livePosition = getPromptPosition(prompt)
                    if livePosition then promptPosition = livePosition end
                    local direction = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                    local verticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                    local activationRange = math.max(0, prompt.MaxActivationDistance)
                    local horizontalReach = verticalOffset < activationRange
                        and math.sqrt(math.max(0, activationRange * activationRange - verticalOffset * verticalOffset)) - 0.5
                        or 0
                    local stopDistance = math.max(1, horizontalReach)
                    if direction.Magnitude > stopDistance then
                        humanoid:Move(direction.Unit, false)
                    else
                        humanoid:Move(Vector3.zero, false)
                    end
                end)
                local promptMoveConnection = {
                    Disconnect = function()
                        pcall(function() RunService:UnbindFromRenderStep(promptMoveBindName) end)
                    end
                }
                PickupMovementConnection = promptMoveConnection
                while not Runtime.Stopped and PickupRequested and PickupGeneration == pickupToken and pickup.Parent and prompt.Parent and humanoid.Health > 0 do
                    if LocalPlayer.Character ~= character or not character.Parent or not root.Parent then
                        if PickupGeneration ~= pickupToken then return end
                        PickupRequested = false
                        ActivePickup = nil
                        ActivePickupCPS = -1
                        SetTrackerStatus("Pickup cancelled: character changed while moving to animal prompt.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        return
                    end
                    promptPosition = getPromptPosition(prompt) or promptPosition
                    local offset = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                    local promptDistance = offset.Magnitude
                    local verticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                    local activationRange = math.max(0, prompt.MaxActivationDistance)
                    local horizontalReach = verticalOffset < activationRange
                        and math.sqrt(math.max(0, activationRange * activationRange - verticalOffset * verticalOffset)) - 0.5
                        or 0
                    local stopDistance = math.max(1, horizontalReach)
                    if promptDistance <= stopDistance then break end
                    local now = os.clock()
                    if now - moveStarted >= 25 then
                        humanoid:Move(Vector3.zero, false)
                        if PickupGeneration ~= pickupToken then return end
                        PickupRequested = false
                        ActivePickup = nil
                        ActivePickupCPS = -1
                        SetTrackerStatus(string.format("Pickup cancelled: timed out reaching animal prompt (%.1f studs away).", promptDistance))
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        return
                    end
                    if promptDistance < bestPromptDistance - 0.75 then
                        bestPromptDistance = promptDistance
                        lastPromptProgressAt = now
                        TouchAutomationProgress()
                    elseif now - lastPromptProgressAt >= 2.5 then
                        lastPromptProgressAt = now
                        bestPromptDistance = promptDistance
                        humanoid:Move(Vector3.zero, false)
                        task.wait(0.05)
                        if PickupRequested and PickupGeneration == pickupToken and pickup.Parent and prompt.Parent
                            and LocalPlayer.Character == character and root.Parent and humanoid.Health > 0 then
                            local refreshedPromptPosition = getPromptPosition(prompt)
                            if refreshedPromptPosition then promptPosition = refreshedPromptPosition end
                            local refreshedOffset = Vector3.new(
                                promptPosition.X - root.Position.X, 0,
                                promptPosition.Z - root.Position.Z
                            )
                            local refreshedVerticalOffset = math.abs(promptPosition.Y - root.Position.Y)
                            local refreshedRange = math.max(0, prompt.MaxActivationDistance)
                            local refreshedReach = refreshedVerticalOffset < refreshedRange
                                and math.sqrt(math.max(0, refreshedRange * refreshedRange - refreshedVerticalOffset * refreshedVerticalOffset)) - 0.5
                                or 0
                            if refreshedOffset.Magnitude > math.max(1, refreshedReach) then
                                humanoid:Move(refreshedOffset.Unit, false)
                            end
                        end
                        SetTrackerStatus(string.format("PICKUP MOVEMENT: reset and reinitialized movement toward StealPrompt (%.1f studs).", promptDistance))
                    end
                    task.wait(0.05)
                end
                if PickupMovementConnection == promptMoveConnection then
                    PickupMovementConnection:Disconnect()
                    PickupMovementConnection = nil
                end
                if promptMoveConnection then promptMoveConnection:Disconnect(); promptMoveConnection = nil end
                humanoid:Move(Vector3.zero, false)
                if PickupGeneration ~= pickupToken then return end
                if not PickupRequested or not pickup.Parent then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: animal disappeared before reaching its prompt.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                SetPickupPhase("ACTIVATING", "Reached " .. pickup.Name .. "'s matching StealPrompt; activating immediately when the prompt is ready.")
                if PickupGeneration ~= pickupToken then return end
                if LocalPlayer.Character ~= character or not character.Parent or humanoid.Health <= 0 or not root.Parent then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: character changed or became unavailable.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if not PickupRequested or not pickup.Parent then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: animal disappeared before activation.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                if PickupGeneration ~= pickupToken then return end
                if not prompt.Parent or not prompt.Enabled then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus("Pickup cancelled: StealPrompt became unavailable before activation.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local latestPromptPosition = getPromptPosition(prompt)
                local latestPromptDistance = latestPromptPosition and (latestPromptPosition - root.Position).Magnitude or math.huge
                if not prompt.Parent or not prompt.Enabled or latestPromptDistance > math.max(4, prompt.MaxActivationDistance) then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    SetTrackerStatus(string.format("Pickup cancelled: prompt range changed before activation (%.1f studs).", latestPromptDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    return
                end
                local pickupConfirmed = false
                local activationErrors = {}
                local activationDeadline = os.clock() + 15
                local activationAttempt = 0
                while not pickupConfirmed and os.clock() < activationDeadline do
                    if PickupGeneration ~= pickupToken or not PickupRequested or not AutoPickupEnabled then return end
                    if not pickup.Parent then pickupConfirmed = true; break end
                    if not prompt.Parent or not prompt.Enabled then
                        task.wait(0.25)
                    else
                        activationAttempt += 1
                        local currentPromptPosition = getPromptPosition(prompt)
                        local currentPromptDistance = currentPromptPosition and (currentPromptPosition - root.Position).Magnitude or math.huge
                        if currentPromptDistance <= prompt.MaxActivationDistance then
                            local holdOk, holdErr = pcall(function()
                                if typeof(fireproximityprompt) == "function" then
                                    fireproximityprompt(prompt)
                                    if prompt.HoldDuration > 0 then task.wait(prompt.HoldDuration + 0.15) end
                                else
                                    prompt:InputHoldBegin()
                                    task.wait(prompt.HoldDuration + 0.1)
                                    prompt:InputHoldEnd()
                                end
                            end)
                            if not holdOk then
                                table.insert(activationErrors, tostring(holdErr))
                                pcall(function() prompt:InputHoldEnd() end)
                            end
                            local confirmDeadline = os.clock() + 0.75
                            while not Runtime.Stopped and os.clock() < confirmDeadline
                                and PickupGeneration == pickupToken and PickupRequested and pickup.Parent do
                                task.wait(0.05)
                            end
                            if not pickup.Parent then pickupConfirmed = true
                            elseif activationAttempt == 1 or activationAttempt % 3 == 0 then
                                SetTrackerStatus("StealPrompt still unchecked for " .. pickup.Name .. "; retry " .. tostring(activationAttempt) .. ".")
                            end
                        else
                            SetTrackerStatus(string.format("Waiting for StealPrompt range for %s (%.1f/%.1f studs).",
                                pickup.Name, currentPromptDistance, prompt.MaxActivationDistance))
                            task.wait(0.25)
                        end
                    end
                    if not pickupConfirmed then task.wait(0.2) end
                end
                if PickupGeneration ~= pickupToken then return end
                if not pickupConfirmed then
                    PickupRequested = false
                    ActivePickup = nil
                    ActivePickupCPS = -1
                    PickupPhase = "IDLE"
                    local detail = #activationErrors > 0 and (" Activation error: " .. table.concat(activationErrors, " | ")) or ""
                    SetPickupTracking(pickup, "Retry timeout: steal not confirmed", detail)
                    SetTrackerStatus("StealPrompt retry window expired for " .. pickup.Name .. "; released pickup lock." .. detail)
                    PickupMonitorSeen[pickup] = nil
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak(true) end
                    return
                end
                SetPickupTracking(pickup, "Collected", cpsText)
                SetPickupPhase("CONFIRMED", "Collected " .. pickup.Name .. "; releasing target lock and returning to base.")
                ActivePickup = nil
                ActivePickupCPS = -1
                ReturnToPickup("Pickup confirmed. Returning straight to base.")
            end)
        end
        function QueuePendingAnimalPickup(pickup)
            if not pickup or not pickup.Parent or PendingAnimalPickupSet[pickup] then return end
            PendingAnimalPickupSet[pickup] = true
            table.insert(PendingAnimalPickups, pickup)
            SetTrackerStatus("NEW ANIMAL queued: " .. pickup.Name .. " | current pickup/return lock is active; will evaluate when movement is released.")
            if PendingAnimalPickupWorker then return end
            PendingAnimalPickupWorker = true
            task.spawn(function()
                while not Runtime.Stopped and not ScriptShuttingDown and #PendingAnimalPickups > 0 do
                    if not AutoPickupEnabled then
                        -- Keep the queue and its de-duplication markers intact while disabled.
                        task.wait(0.25)
                    elseif not PickupRequested and not ReturningAfterPickup and not FlingRecoveryActive then
                        local nextPickup = table.remove(PendingAnimalPickups, 1)
                        if nextPickup then PendingAnimalPickupSet[nextPickup] = nil end
                        if nextPickup and nextPickup.Parent then
                            local ok, err = xpcall(function()
                                EvaluatePickup(nextPickup)
                            end, debug.traceback)
                            if not ok then
                                SetTrackerStatus("Queued pickup evaluation failed for " .. tostring(nextPickup.Name) .. ": " .. tostring(err):gsub("[%r\n]+", " "):sub(1, 180))
                            end
                            task.wait(0.25)
                        else
                            task.wait()
                        end
                    else
                        task.wait(0.5)
                    end
                end
                PendingAnimalPickupWorker = false
            end)
        end
        function BindAnimalPickups(folder)
            if not folder or not folder:IsA("Folder") and not folder:IsA("Model") then return end
            AnimalPickups = folder
            TrackPersistentConnection(folder.ChildAdded:Connect(function(pickup)
                PickupMonitorSeen[pickup] = nil
                local pickupRarity = tostring(GetPetRarity(pickup) or "Unknown")
                SetPickupTracking(pickup, "Detected")
                pickup:SetAttribute("MoldyHub_BASAE_Rarity", pickupRarity)
                if not AutoPickupEnabled then
                    SetTrackerStatus("NEW ANIMAL: " .. pickup.Name .. " | rarity=" .. pickupRarity .. " | monitoring waits until Auto Pickup is ON.")
                    return
                end
                PickupMonitorSeen[pickup] = true
                QueuePendingAnimalPickup(pickup)
            end))
            TrackPersistentConnection(folder.ChildRemoved:Connect(function(pickup)
                PickupMonitorSeen[pickup] = nil
                PendingAnimalPickupSet[pickup] = nil
            end))
            SetTrackerStatus("AnimalPickups folder detected; continuous monitoring is ready.")
        end
        if AnimalPickups then BindAnimalPickups(AnimalPickups) end
        task.spawn(function()
            while not Runtime.Stopped and not ScriptShuttingDown do
                if AutoPickupEnabled and AnimalPickups and AnimalPickups.Parent then
                    for _, pickup in ipairs(AnimalPickups:GetChildren()) do
                        if pickup.Parent == AnimalPickups and not PickupMonitorSeen[pickup] then
                            PickupMonitorSeen[pickup] = true
                            QueuePendingAnimalPickup(pickup)
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
        local CatchFlingRemote = game:GetService("ReplicatedStorage"):WaitForChild("CatchFlingRemote")
        HandleFlingRecovery = function(action, flingPosition, duration, strength, carriedAnimalLost)
            if tostring(action):lower() ~= "fling" then return end
            if AntiPaloEnabled and not carriedAnimalLost then
                local released, releaseError = pcall(function()
                    if type(firesignal) ~= "function" then
                        error("firesignal is unavailable in this executor")
                    end
                    firesignal(CatchFlingRemote.OnClientEvent, "release")
                end)
                if released then
                    AddDebugLog("[Anti Knockback] Fling release signal fired.")
                else
                    AddDebugLog("[Anti Knockback] Fling release failed: " .. tostring(releaseError))
                end
            end
            if not AutoPickupEnabled then
                SetTrackerStatus("Fling detected: recovery cancelled because Auto Pickup is OFF.")
                return
            end
            if FlingRecoveryActive then
                SetTrackerStatus("Fling recovery event received while recovery is active; ignoring duplicate trigger.")
                return
            end
            if carriedAnimalLost and not ReturningAfterPickup and not PickupRequested then return end
            if not carriedAnimalLost and not CarriedAnimalWatch.model and not ReturningAfterPickup and not PickupRequested then
                SetTrackerStatus("Fling event ignored: no active animal pickup or carried animal.")
                return
            end
            local flingAnimal = ActivePickup or FlingAnimalTarget
            local targetAnimalName = (flingAnimal and flingAnimal.Name) or FlingTargetAnimalName
            local targetWeightKg = FlingTargetWeightKg
            if not targetAnimalName then
                SetTrackerStatus("Fling recovery skipped: tracked animal name is unavailable.")
                return
            end
            local function findTrackedAnimal()
                local folder = workspace:FindFirstChild("AnimalPickups")
                if not folder or not targetAnimalName then return nil end

                local targetWeight = ParseWeightKg(targetWeightKg)
                if flingAnimal and flingAnimal.Parent == folder and flingAnimal.Name == targetAnimalName then
                    local liveWeight = ParseWeightKg(GetAnimalWeightKg(flingAnimal))
                    if targetWeight == nil or liveWeight == nil or math.abs(liveWeight - targetWeight) <= math.max(0.001, math.abs(targetWeight) * 0.000001) then
                        return flingAnimal
                    end
                end

                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local bestMatch, bestDistance
                local nearestNameMatch, nearestNameDistance
                local hasReadableWeight = false

                for _, candidate in ipairs(folder:GetChildren()) do
                    if candidate.Name == targetAnimalName then
                        local candidateWeight = ParseWeightKg(GetAnimalWeightKg(candidate))
                        local ok, position = pcall(function()
                            if candidate:IsA("Model") then return candidate:GetPivot().Position end
                            if candidate:IsA("BasePart") then return candidate.Position end
                        end)
                        if ok and position then
                            local distance = root and (position - root.Position).Magnitude or 0
                            if not nearestNameDistance or distance < nearestNameDistance then
                                nearestNameMatch, nearestNameDistance = candidate, distance
                            end
                            if candidateWeight ~= nil then
                                hasReadableWeight = true
                            end
                            if targetWeight ~= nil and candidateWeight ~= nil then
                                local tolerance = math.max(0.001, math.abs(targetWeight) * 0.000001)
                                if math.abs(candidateWeight - targetWeight) <= tolerance then
                                    if not bestDistance or distance < bestDistance then
                                        bestMatch, bestDistance = candidate, distance
                                    end
                                end
                            end
                        end
                    end
                end

                if bestMatch then
                    flingAnimal = bestMatch
                    return bestMatch
                end
                if targetWeight ~= nil and hasReadableWeight then
                    return nil
                end
                if nearestNameMatch then flingAnimal = nearestNameMatch end
                return nearestNameMatch
            end
            local function getTrackedAnimalPosition()
                local animal = findTrackedAnimal()
                if not animal then return nil end
                local ok, position = pcall(function()
                    if animal:IsA("Model") then return animal:GetPivot().Position end
                    if animal:IsA("BasePart") then return animal.Position end
                end)
                return ok and position or nil
            end

            if ReturnMovementConnection then
                ReturnMovementConnection:Disconnect()
                ReturnMovementConnection = nil
            end
            if PickupMovementConnection then
                PickupMovementConnection:Disconnect()
                PickupMovementConnection = nil
            end
            if MovementConnection then
                MovementConnection:Disconnect()
                MovementConnection = nil
            end
            ReturningAfterPickup = false
            local interruptedCharacter = LocalPlayer.Character
            local interruptedHumanoid = interruptedCharacter and interruptedCharacter:FindFirstChildOfClass("Humanoid")
            if interruptedHumanoid then interruptedHumanoid:Move(Vector3.zero, false) end

            FlingRecoveryActive = true
            local recoverySearchToken = PickupGeneration
            TouchAutomationProgress("FLING_RECOVERY:FIND_DROPPED_ANIMAL")
            if not FlingRecoveryActive or PickupGeneration ~= recoverySearchToken then
                return
            end
            if PickupMovementConnection then PickupMovementConnection:Disconnect(); PickupMovementConnection = nil end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            if ReturnMovementConnection then ReturnMovementConnection:Disconnect(); ReturnMovementConnection = nil end
            ReturningAfterPickup = false
            PickupGeneration += 1
            local flingToken = PickupGeneration
            ActivePickup = nil
            ActivePickupCPS = -1
            PickupRequested = true
            if StopAutoBreak then StopAutoBreak("Auto Break paused for fling recovery.", CurrentTarget ~= nil and IsEggAvailable(CurrentTarget)) end
            if MovementConnection then MovementConnection:Disconnect(); MovementConnection = nil end
            SetTrackerStatus("Base return paused. FLING RECOVERY locating dropped " .. tostring(targetAnimalName) .. " in AnimalPickups.")
            task.spawn(function()
                local recoveryMoveBindName
                local recoveryHumanoid
                local originalAutoRotate
                local function cleanupFlingRecovery()
                    if recoveryHumanoid and recoveryHumanoid.Parent and originalAutoRotate ~= nil then
                        recoveryHumanoid.AutoRotate = originalAutoRotate
                        originalAutoRotate = nil
                    end
                    if recoveryMoveBindName then
                        pcall(function()
                            game:GetService("RunService"):UnbindFromRenderStep(recoveryMoveBindName)
                        end)
                        recoveryMoveBindName = nil
                    end
                    FlingRecoveryActive = false
                    if CancelFlingRecovery == cleanupFlingRecovery then
                        CancelFlingRecovery = nil
                    end
                    if PendingReturnAfterFling then
                        local pendingReason = PendingReturnAfterFlingReason
                        PendingReturnAfterFling = false
                        PendingReturnAfterFlingReason = nil
                        ReturnToPickup(pendingReason or "Fling recovery finished. Returning to base.")
                    end
                end
                CancelFlingRecovery = cleanupFlingRecovery
                local function finishFlingRecovery()
                    cleanupFlingRecovery()
                    if AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup and StartAutoBreak then
                        task.delay(0.25, function()
                            if not FlingRecoveryActive and AutoBreakEnabled and not PickupRequested and not ReturningAfterPickup then
                                StartAutoBreak()
                            end
                        end)
                    end
                end
                if PickupGeneration ~= flingToken or not FlingRecoveryActive then
                    finishFlingRecovery()
                    return
                end
                local character, humanoid, root = WaitForCharacterAndParts(10, function()
                    return PickupGeneration == flingToken and PickupRequested and FlingRecoveryActive
                end)
                if not character then
                    if PickupGeneration ~= flingToken or not FlingRecoveryActive then
                        cleanupFlingRecovery()
                        return
                    end
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: character parts unavailable.")
                    finishFlingRecovery()
                    return
                end
                recoveryHumanoid = humanoid
                originalAutoRotate = humanoid.AutoRotate
                humanoid.AutoRotate = false
                if PickupGeneration ~= flingToken or not PickupRequested or not AutoPickupEnabled then
                    finishFlingRecovery()
                    return
                end
                local recoveryPosition = getTrackedAnimalPosition()
                if carriedAnimalLost and not recoveryPosition then
                    local animalWaitDeadline = os.clock() + 2.5
                    repeat
                        task.wait(0.1)
                        recoveryPosition = getTrackedAnimalPosition()
                    until recoveryPosition or os.clock() >= animalWaitDeadline
                        or Runtime.Stopped or PickupGeneration ~= flingToken or not FlingRecoveryActive
                end
                if not recoveryPosition then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: dropped animal was not found in AnimalPickups (" .. tostring(targetAnimalName) .. ").")
                    finishFlingRecovery()
                    return
                end
                local function positionOf(candidate)
                    local parent = candidate and candidate.Parent
                    while parent and parent ~= workspace do
                        if parent:IsA("Attachment") then return parent.WorldPosition end
                        if parent:IsA("BasePart") then return parent.Position end
                        if parent:IsA("Model") then return parent:GetPivot().Position end
                        parent = parent.Parent
                    end
                    return nil
                end
                local function findNearbyStealPrompt()
                    local anchor = workspace:FindFirstChild("PromptAnchor")
                    if not anchor then return nil, nil end
                    local nearest = math.huge
                    local bestPrompt, bestPosition
                    for _, candidate in ipairs(anchor:GetDescendants()) do
                        if candidate:IsA("ProximityPrompt") and candidate.Name == "StealPrompt" and candidate.Enabled then
                            local pos = positionOf(candidate)
                            if pos then
                                local distance = (pos - recoveryPosition).Magnitude
                                if distance < nearest and distance <= 12 then
                                    nearest, bestPrompt, bestPosition = distance, candidate, pos
                                end
                            end
                        end
                    end
                    return bestPrompt, bestPosition
                end
                local prompt, promptPosition = findNearbyStealPrompt()
                local promptLogged = prompt ~= nil
                if prompt then
                    SetTrackerStatus(string.format("FLING RECOVERY cached StealPrompt %.1f studs from animal; moving immediately.", (promptPosition - recoveryPosition).Magnitude))
                else
                    SetTrackerStatus("FLING RECOVERY: searching for StealPrompt while moving toward the animal.")
                end
                SetTrackerStatus(string.format(
                    "FLING RECOVERY found dropped %s in AnimalPickups at (%.3f, %.3f, %.3f).",
                    tostring(flingAnimal and flingAnimal.Name or targetAnimalName or "animal"),
                    recoveryPosition.X, recoveryPosition.Y, recoveryPosition.Z
                ))
                local RunService = game:GetService("RunService")
                recoveryMoveBindName = "MoldyHub_BASAE_FlingRecovery_" .. tostring(flingToken)
                RunService:BindToRenderStep(recoveryMoveBindName, Enum.RenderPriority.Character.Value + 1, function()
                    if Runtime.Stopped or not PickupRequested or PickupGeneration ~= flingToken
                        or LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then
                        humanoid:Move(Vector3.zero, false)
                        return
                    end
                    local livePosition = getTrackedAnimalPosition()
                    if livePosition then recoveryPosition = livePosition end
                    local moveOffset = Vector3.new(recoveryPosition.X - root.Position.X, 0, recoveryPosition.Z - root.Position.Z)
                    if moveOffset.Magnitude > 4 then
                        humanoid:Move(moveOffset.Unit, false)
                    else
                        humanoid:Move(Vector3.zero, false)
                    end
                end)
                local moveStarted = os.clock()
                local lastProgressAt = os.clock()
                local bestDistance = math.huge
                TouchAutomationProgress("FLING_RECOVERY:ANIMAL_APPROACH")
                while not Runtime.Stopped and PickupRequested and PickupGeneration == flingToken and humanoid.Health > 0 do
                    if LocalPlayer.Character ~= character or not character.Parent or not root.Parent then
                        PickupRequested = false
                        SetTrackerStatus("FLING RECOVERY cancelled: character changed or root became unavailable.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    local livePosition = getTrackedAnimalPosition()
                    if livePosition then recoveryPosition = livePosition end
                    if not prompt then
                        prompt, promptPosition = findNearbyStealPrompt()
                        if prompt and not promptLogged then
                            promptLogged = true
                            SetTrackerStatus(string.format("FLING RECOVERY found StealPrompt while moving (%.1f studs from animal).", (promptPosition - recoveryPosition).Magnitude))
                        end
                    end
                    local offset = Vector3.new(recoveryPosition.X - root.Position.X, 0, recoveryPosition.Z - root.Position.Z)
                    local distance = offset.Magnitude
                    if distance <= 4 then break end
                    local now = os.clock()
                    if now - moveStarted >= 45 then
                        humanoid:Move(Vector3.zero, false)
                        PickupRequested = false
                        SetTrackerStatus(string.format("FLING RECOVERY cancelled: timed out reaching the animal location (%.1f studs away).", distance))
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    if distance < bestDistance - 0.75 then
                        bestDistance = distance
                        lastProgressAt = now
                        TouchAutomationProgress()
                    elseif now - lastProgressAt >= 2.5 then
                        local state = humanoid:GetState()
                        if state == Enum.HumanoidStateType.FallingDown
                            or state == Enum.HumanoidStateType.Ragdoll
                            or state == Enum.HumanoidStateType.Physics
                            or state == Enum.HumanoidStateType.PlatformStanding then
                            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                        lastProgressAt = now
                        bestDistance = distance
                        if humanoid.PlatformStand then humanoid.PlatformStand = false end
                        if root.Anchored then
                            SetTrackerStatus(string.format("FLING RECOVERY blocked: HumanoidRootPart is anchored (%.1f studs away).", distance))
                        else
                            SetTrackerStatus(string.format("FLING RECOVERY: movement input refreshed every frame; no progress yet (%.1f studs away, state=%s).", distance, tostring(state)))
                        end
                    end
                    task.wait(0.1)
                end
                if recoveryMoveBindName then
                    pcall(function() RunService:UnbindFromRenderStep(recoveryMoveBindName) end)
                    recoveryMoveBindName = nil
                end
                humanoid:Move(Vector3.zero, false)
                local arrivalDistance = (Vector3.new(recoveryPosition.X, root.Position.Y, recoveryPosition.Z) - root.Position).Magnitude
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not PickupRequested or humanoid.Health <= 0 or arrivalDistance > 5 then
                    PickupRequested = false
                    SetTrackerStatus(string.format("FLING RECOVERY cancelled: arrival verification failed (%.1f studs).", arrivalDistance))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                local searchDeadline = os.clock() + 1.5
                if not prompt then
                    SetTrackerStatus(string.format("FLING RECOVERY arrived near animal (%.1f studs); brief final StealPrompt check.", arrivalDistance))
                    repeat
                        local livePosition = getTrackedAnimalPosition()
                        if livePosition then recoveryPosition = livePosition end
                        prompt, promptPosition = findNearbyStealPrompt()
                        if prompt then break end
                        task.wait(0.1)
                    until os.clock() >= searchDeadline or PickupGeneration ~= flingToken
                end
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not prompt or not prompt.Parent or not prompt.Enabled or not promptPosition then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY failed: no enabled StealPrompt within 12 studs of the current animal location.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                SetTrackerStatus(string.format("FLING RECOVERY found nearest prompt %.1f studs from the animal; verifying prompt position.", (promptPosition - recoveryPosition).Magnitude))
                local moveStarted = os.clock()
                local bestPromptDistance = math.huge
                TouchAutomationProgress("FLING_RECOVERY:PROMPT_APPROACH")
                while not Runtime.Stopped and PickupRequested and PickupGeneration == flingToken and prompt.Parent and prompt.Enabled and humanoid.Health > 0 do
                    promptPosition = positionOf(prompt) or promptPosition
                    local locationError = (promptPosition - recoveryPosition).Magnitude
                    if locationError > 14 then
                        humanoid:Move(Vector3.zero, false)
                        PickupRequested = false
                        SetTrackerStatus(string.format("FLING RECOVERY cancelled: prompt moved %.1f studs away from the animal location.", locationError))
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    local offset = Vector3.new(promptPosition.X - root.Position.X, 0, promptPosition.Z - root.Position.Z)
                    local distanceToPrompt = (promptPosition - root.Position).Magnitude
                    if distanceToPrompt < bestPromptDistance - 0.75 then
                        bestPromptDistance = distanceToPrompt
                        TouchAutomationProgress()
                    end
                    if distanceToPrompt <= math.min(prompt.MaxActivationDistance, 5) then break end
                    if os.clock() - moveStarted >= 25 then
                        humanoid:Move(Vector3.zero, false)
                        PickupRequested = false
                        SetTrackerStatus("FLING RECOVERY cancelled: timed out reaching the verified prompt.")
                        if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                        finishFlingRecovery()
                        return
                    end
                    humanoid:Move(offset.Magnitude > 0 and offset.Unit or Vector3.zero, false)
                    task.wait(0.05)
                end
                humanoid:Move(Vector3.zero, false)
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not PickupRequested or not prompt.Parent or not prompt.Enabled or humanoid.Health <= 0 then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY cancelled: prompt or character became unavailable.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                promptPosition = positionOf(prompt) or promptPosition
                local finalPlayerDistance = (promptPosition - root.Position).Magnitude
                local finalLocationError = (promptPosition - recoveryPosition).Magnitude
                if finalPlayerDistance > math.min(prompt.MaxActivationDistance, 5) or finalLocationError > 14 then
                    PickupRequested = false
                    SetTrackerStatus(string.format("FLING RECOVERY blocked by location verification: player=%.1f studs, animal mismatch=%.1f studs.", finalPlayerDistance, finalLocationError))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                task.wait(0.15)
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                promptPosition = positionOf(prompt) or promptPosition
                if LocalPlayer.Character ~= character or not character.Parent or humanoid.Health <= 0
                    or not prompt.Parent or not prompt.Enabled
                    or (promptPosition - root.Position).Magnitude > math.min(prompt.MaxActivationDistance, 5)
                    or (promptPosition - recoveryPosition).Magnitude > 14 then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY blocked: prompt moved outside the verified pickup range.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                local ok, err = pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration + 0.1)
                        prompt:InputHoldEnd()
                    end
                end)
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not ok then
                    pcall(function() prompt:InputHoldEnd() end)
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY pickup failed: " .. tostring(err))
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                SetTrackerStatus("FLING RECOVERY prompt activated; confirming animal collection.")
                local confirmed = false
                local confirmDeadline = os.clock() + 4
                while not Runtime.Stopped and os.clock() < confirmDeadline and PickupGeneration == flingToken and PickupRequested do
                    local folder = workspace:FindFirstChild("AnimalPickups")
                    local targetStillExists = false
                    if folder then
                        for _, animal in ipairs(folder:GetChildren()) do
                            if animal.Name == targetAnimalName then
                                targetStillExists = true
                                break
                            end
                        end
                        if not targetStillExists then confirmed = true; break end
                    end
                    task.wait(0.1)
                end
                if PickupGeneration ~= flingToken then
                    finishFlingRecovery()
                    return
                end
                if not confirmed then
                    PickupRequested = false
                    SetTrackerStatus("FLING RECOVERY: prompt activated but collection was not confirmed; staying in place.")
                    if AutoBreakEnabled and StartAutoBreak then StartAutoBreak() end
                    finishFlingRecovery()
                    return
                end
                SetTrackerStatus("FLING RECOVERY collection confirmed; resuming base return to the saved base position.")
                finishFlingRecovery()
                ReturnToPickup("Fling recovery pickup confirmed. Returning to saved base position.")
            end)
        end
        FlingRemoteConnection = TrackPersistentConnection(CatchFlingRemote.OnClientEvent:Connect(HandleFlingRecovery))
        CarriedAnimalWatch.Bind = function(folder)
            if not folder or not folder:IsA("Folder") or CarriedAnimalWatch.folder == folder then return end
            CarriedAnimalWatch.folder = folder
            local function observeCarriedAnimal(model)
                if model and model.Name == "CarriedAnimal" then
                    CarriedAnimalWatch.model = model
                    CarriedAnimalWatch.seen = true
                end
            end
            for _, child in ipairs(folder:GetChildren()) do observeCarriedAnimal(child) end
            CarriedAnimalWatch.childAdded = TrackPersistentConnection(folder.ChildAdded:Connect(function(child)
                observeCarriedAnimal(child)
            end))
            CarriedAnimalWatch.childRemoved = TrackPersistentConnection(folder.ChildRemoved:Connect(function(child)
                if child ~= CarriedAnimalWatch.model or not CarriedAnimalWatch.seen then return end
                local removedModel = child
                CarriedAnimalWatch.model = nil
                CarriedAnimalWatch.seen = false
                local carriedWeight = GetAnimalWeightKg(removedModel)
                if FlingTargetWeightKg == nil and carriedWeight ~= nil then
                    FlingTargetWeightKg = carriedWeight
                end
                task.defer(function()
                    if Runtime.Stopped or ScriptShuttingDown or CarriedAnimalWatch.model ~= nil
                        or not AutoPickupEnabled or not AutoBreakEnabled
                        or (not ReturningAfterPickup and not PickupRequested) then return end
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - BaseReturnPosition).Magnitude <= 10 then
                        SetTrackerStatus("CarriedAnimal disappeared near base; treating it as a normal bank instead of recovery.")
                        return
                    end
                    SetTrackerStatus("CarriedAnimal disappeared while away from base; starting fast animal-location recovery.")
                    if HandleFlingRecovery then HandleFlingRecovery("fling", nil, nil, nil, true) end
                end)
            end))
            SetTrackerStatus("CarriedAnimals folder connected; watching CarriedAnimal presence.")
        end
        local existingCarriedFolder = workspace:FindFirstChild("CarriedAnimals")
        if existingCarriedFolder then CarriedAnimalWatch.Bind(existingCarriedFolder) end
        AnimalFolderConnection = TrackPersistentConnection(workspace.ChildAdded:Connect(function(child)
            if child.Name == "AnimalPickups" and not AnimalPickups then
                BindAnimalPickups(child)
            elseif child.Name == "CarriedAnimals" then
                CarriedAnimalWatch.Bind(child)
            end
        end))
        StopAutoBreak = function(reason, preserveTargetState)
            TouchAutomationProgress(AutoBreakEnabled and "AUTO_BREAK_PAUSED" or "AUTO_BREAK_OFF")
            if MovementConnection then
                MovementConnection:Disconnect()
                MovementConnection = nil
            end
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and not PickupRequested and not ReturningAfterPickup then
                humanoid:Move(Vector3.zero, false)
            end
            ArrivedAtTarget = false
            if not preserveTargetState then
                WaitingForPickup = false
                CurrentTarget = nil
            end
            if reason then
                SetTrackerStatus(reason)
            end
        end
        StartAutoBreak = function(forceRefresh)
            if not AutoBreakEnabled or ScriptShuttingDown then return end
            local startGeneration = AutoBreakGeneration
            TouchAutomationProgress("AUTO_BREAK:SELECTING_TARGET")
            if FlingRecoveryActive then
                SetTrackerStatus("Auto Break paused: fling recovery owns movement until the animal pickup attempt finishes.")
                return
            end
            if not AutoBreakEnabled then
                SetTrackerStatus("Auto Break start ignored: toggle is OFF.")
                return
            end
            if PickupRequested or ReturningAfterPickup then
                SetTrackerStatus("Auto Break start ignored: pickup/return is in progress.")
                return
            end
            if WaitingForPickup then
                SetTrackerStatus("Auto Break start ignored: broken target is waiting for its AnimalPickups entry.")
                return
            end
            local lockedTarget = CurrentTarget
            if lockedTarget and IsEggConfirmedComplete(lockedTarget) then
                CompletedEggs[lockedTarget] = true
                lockedTarget = nil
                SetTrackerStatus("Current egg HP reached 0; releasing target lock.")
            elseif lockedTarget and not IsEggAvailable(lockedTarget) then
                lockedTarget = nil
            end
            if lockedTarget and not forceRefresh and (MovementConnection ~= nil or ArrivedAtTarget) then
                return
            end
            StopAutoBreak(nil, lockedTarget ~= nil)
            local selectedZoneNames = {}
            for zoneName, selected in pairs(SelectedZones) do
                if selected then
                    table.insert(selectedZoneNames, zoneName)
                end
            end
            table.sort(selectedZoneNames)
            local target = lockedTarget
            if not target then
                local priorityCandidates = {}
                for _, zoneName in ipairs(selectedZoneNames) do
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                                and egg.Name:lower():find("egg", 1, true)
                                and IsEggAvailable(egg) then
                                local eggName = GetEggTypeName(egg.Name)
                                if SelectedEggs[eggName] ~= false then
                                    local category = GetEggCategory(egg)
                                    local isTitanic = category ~= nil
                                        and category:lower() == "titanic"
                                    table.insert(priorityCandidates, {
                                        egg = egg,
                                        luck = GetEggLuck(egg),
                                        kg = GetEggWeightKg(egg) or 0,
                                        isTitanic = isTitanic
                                    })
                                end
                            end
                        end
                    end
                end
                table.sort(priorityCandidates, function(a, b)
                    if TitanicPriorityEnabled and a.isTitanic ~= b.isTitanic then
                        return a.isTitanic
                    end
                    if SortOrder == "Highest Kg" and a.kg ~= b.kg then
                        return a.kg > b.kg
                    elseif SortOrder == "Highest Luck" and a.luck ~= b.luck then
                        return a.luck > b.luck
                    end
                    return a.egg.Name < b.egg.Name
                end)
                if #priorityCandidates > 0 then
                    local best = priorityCandidates[1]
                    target = best.egg
                    SetTrackerStatus("AUTO BREAK PRIORITY: selected " .. target.Name
                        .. " | " .. tostring(SortOrder)
                        .. (TitanicPriorityEnabled and (best.isTitanic and " | Titanic priority matched" or " | No Titanic category match") or ""))
                    AddDebugLog("[Auto Break] Selected " .. target.Name
                        .. " | priority=" .. tostring(SortOrder)
                        .. " | luck=" .. tostring(best.luck)
                        .. " | kg=" .. tostring(best.kg)
                        .. " | categoryTitanic=" .. tostring(best.isTitanic)
                        .. " | candidates=" .. tostring(#priorityCandidates))
                end
            end
            if not target then
                local normalZoneNames = {}
                local preferredIsSelected = false
                if PreferredZoneName then
                    for _, zoneName in ipairs(selectedZoneNames) do
                        if zoneName == PreferredZoneName then
                            preferredIsSelected = true
                            break
                        end
                    end
                end
                if preferredIsSelected then
                    table.insert(normalZoneNames, PreferredZoneName)
                end
                for _, zoneName in ipairs(selectedZoneNames) do
                    if zoneName ~= PreferredZoneName then
                        table.insert(normalZoneNames, zoneName)
                    end
                end
                for _, zoneName in ipairs(normalZoneNames) do
                    if target then break end
                    local zone = ZoneBuilds:FindFirstChild(zoneName)
                    local eggsFolder = zone and zone:FindFirstChild("Eggs")
                    if eggsFolder then
                        for _, egg in ipairs(eggsFolder:GetChildren()) do
                            if (egg:IsA("Model") or egg:IsA("BasePart"))
                            and egg.Name:lower():find("egg", 1, true) then
                                local eggName = GetEggTypeName(egg.Name)
                                if SelectedEggs[eggName] ~= false and IsEggAvailable(egg) then
                                    target = egg
                                    break
                                end
                            end
                        end
                        if target then break end
                    end
                end
            end
            if not target then
                SetTrackerStatus("No target found. Select a zone and keep at least one egg type enabled.")
                TouchAutomationProgress("IDLE")
