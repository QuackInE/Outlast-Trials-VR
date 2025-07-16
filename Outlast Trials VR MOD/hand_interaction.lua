
-- ==============================
--       HAND INTERACTION
--     Lua Script for UEVR
-- ==============================

-- ==============================
-- == GLOBAL TABLES & STATE ==
-- ==============================

local heldItems = { left = nil, right = nil }
local holsters = { back = nil, beltLeft = nil, beltRight = nil }
local playerInLocker = false
local lockerRef = nil
local cooldownTimers = {}

-- ==============================
-- == HELPER FUNCTIONS ==
-- ==============================

function GetTime()
    return os.clock()
end

function SetCooldown(name, duration)
    cooldownTimers[name] = GetTime() + duration
end

function IsOnCooldown(name)
    return cooldownTimers[name] and GetTime() < cooldownTimers[name]
end

function Debug(msg)
    print("[HAND INTERACTION] " .. msg)
end

-- ==============================
-- == GRABBING & RELEASING ==
-- ==============================

function grabItem(hand)
    if heldItems[hand] then return end

    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.5)

    if hit and hit.actor then
        AttachToHand(hand, hit.actor)
        heldItems[hand] = hit.actor
        Debug("Grabbed item with " .. hand)
    end
end

function releaseItem(hand)
    local item = heldItems[hand]
    if item then
        local velocity = GetHandVelocity(hand)
        DetachFromHand(hand, item)
        ApplyImpulse(item, velocity)
        heldItems[hand] = nil
        Debug("Released item from " .. hand)
    end
end

-- ==============================
-- == USE ITEM LOGIC ==
-- ==============================

function useHeldItem(hand)
    local item = heldItems[hand]
    if item and item:HasFunction("Use") then
        item:CallFunction("Use")
        Debug("Used item with " .. hand)
    end
end

function consumeItem(hand)
    local item = heldItems[hand]
    if not item then return end

    if item:HasTag("Medicine") then
        item:CallFunction("Drink")
        Debug("Consumed medicine with " .. hand)
    elseif item:HasTag("Syringe") or item:HasTag("Adrenaline") then
        item:CallFunction("Inject")
        Debug("Injected item with " .. hand)
    end
end

-- ==============================
-- == FLASHLIGHT ==
-- ==============================

function toggleFlashlight(hand)
    local item = heldItems[hand]
    if item and item:HasTag("Flashlight") then
        item:CallFunction("Toggle")
        Debug("Toggled flashlight with " .. hand)
    end
end

-- ==============================
-- == HOLSTER / DRAW ==
-- ==============================

function holsterItem(hand)
    local item = heldItems[hand]
    if not item then return end

    if hand == "left" then
        holsters.beltLeft = item
    elseif hand == "right" then
        holsters.beltRight = item
    end

    DetachFromHand(hand, item)
    heldItems[hand] = nil
    Debug("Holstered item from " .. hand)
end

function drawFromHolster(hand)
    if hand == "left" and holsters.beltLeft then
        AttachToHand(hand, holsters.beltLeft)
        heldItems.left = holsters.beltLeft
        holsters.beltLeft = nil
    elseif hand == "right" and holsters.beltRight then
        AttachToHand(hand, holsters.beltRight)
        heldItems.right = holsters.beltRight
        holsters.beltRight = nil
    end
    Debug("Drew item to " .. hand)
end

-- ==============================
-- == INTERACTABLES ==
-- ==============================

function interactWithButton(hand)
    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 0.5)

    if hit and hit.actor and hit.actor:HasTag("Button") then
        hit.actor:CallFunction("Activate")
        Debug("Pressed button with " .. hand)
    end
end

function doorInteraction(hand)
    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.0)

    if hit and hit.actor and hit.actor:IsA("Door") then
        AttachToHand(hand, hit.actor)
        heldItems[hand] = hit.actor
        Debug("Interacted with door using " .. hand)
    end
end

function toggleDoorLock(hand)
    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.0)

    if hit and hit.actor and hit.actor:HasFunction("ToggleLock") then
        hit.actor:CallFunction("ToggleLock")
        Debug("Toggled lock with " .. hand)
    end
end

-- ==============================
-- == LOCKER SYSTEM ==
-- ==============================

function toggleLocker(hand)
    if playerInLocker then
        playerInLocker = false
        DetachFromActor(lockerRef)
        lockerRef = nil
        Debug("Exited locker")
        return
    end

    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.2)

    if hit and hit.actor and hit.actor:HasTag("Locker") then
        AttachToActor(hit.actor)
        playerInLocker = true
        lockerRef = hit.actor
        Debug("Entered locker")
    end
end

-- ==============================
-- == GENERATOR CRANK ==
-- ==============================

function crankGenerator(hand)
    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.5)

    if hit and hit.actor and hit.actor:HasTag("Crank") then
        local crankSpeed = GetHandVelocity(hand).magnitude
        hit.actor:CallFunction("Crank", crankSpeed)
        Debug("Cranked generator with " .. hand)
    end
end

function tinkerGenerator(hand)
    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.0)

    if hit and hit.actor and hit.actor:HasTag("Generator") then
        hit.actor:CallFunction("Tinker")
        Debug("Tinkered generator with " .. hand)
    end
end

-- ==============================
-- == PLAYER REVIVAL ==
-- ==============================

function revivePlayer(hand)
    if IsOnCooldown("revive") then return end

    local origin = GetHandPosition(hand)
    local direction = GetHandForwardVector(hand)
    local hit = Raycast(origin, direction, 1.5)

    if hit and hit.actor and hit.actor:HasTag("DownedPlayer") then
        hit.actor:CallFunction("Revive")
        SetCooldown("revive", 5)
        Debug("Revived player using " .. hand)
    end
end

-- ==============================
-- == INPUT HANDLER ==
-- ==============================

function OnInput()
    -- Grabbing & Releasing
    if GetInput("LeftGrip") > 0.5 then if not heldItems.left then grabItem("left") end else if heldItems.left then releaseItem("left") end end
    if GetInput("RightGrip") > 0.5 then if not heldItems.right then grabItem("right") end else if heldItems.right then releaseItem("right") end end

    -- Use / Consume
    if GetInputDown("LeftTrigger") then useHeldItem("left") end
    if GetInputDown("RightTrigger") then useHeldItem("right") end
    if GetInputDown("LeftSecondary") then consumeItem("left") end
    if GetInputDown("RightSecondary") then consumeItem("right") end

    -- Flashlight
    if GetInputDown("LeftThumb") then toggleFlashlight("left") end
    if GetInputDown("RightThumb") then toggleFlashlight("right") end

    -- Inventory
    if GetInputDown("X") then drawFromHolster("left") end
    if GetInputDown("Y") then drawFromHolster("right") end
    if GetInputDown("LeftHolster") then holsterItem("left") end
    if GetInputDown("RightHolster") then holsterItem("right") end

    -- Interactions
    if GetInputDown("A") then interactWithButton("right") end
    if GetInputDown("B") then interactWithButton("left") end
    if GetInputDown("LeftTrigger") then doorInteraction("left") end
    if GetInputDown("RightTrigger") then doorInteraction("right") end
    if GetInputDown("LeftGrip") then toggleDoorLock("left") end
    if GetInputDown("RightGrip") then toggleDoorLock("right") end

    -- Locker
    if GetInputDown("Start") then toggleLocker("left") end

    -- Generator
    if GetInput("LeftThumb") > 0.8 then crankGenerator("left") end
    if GetInput("RightThumb") > 0.8 then crankGenerator("right") end
    if GetInputDown("LeftTrigger") then tinkerGenerator("left") end
    if GetInputDown("RightTrigger") then tinkerGenerator("right") end

    -- Revive
    if GetInputDown("LeftTrigger") then revivePlayer("left") end
    if GetInputDown("RightTrigger") then revivePlayer("right") end
end
