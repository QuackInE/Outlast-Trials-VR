-- combat.lua - VR Melee Combat for The Outlast Trials (UEVR)

-- Table to hold combat functions
Combat = {}

-- Required libraries
require("input")
require("haptics")
require("raycast")
require("actors")
require("audio")

-- Thresholds
local PUNCH_VELOCITY_THRESHOLD = 2.5
local SWING_VELOCITY_THRESHOLD = 3.0
local PUSH_VELOCITY_THRESHOLD = 2.2

-- Utility: Get velocity of a hand
function Combat.GetHandVelocity(hand)
    return GetVelocityForHand(hand) or Vector3(0, 0, 0)
end

-- Utility: Get position of a hand
function Combat.GetHandPosition(hand)
    return GetWorldPositionForHand(hand) or Vector3(0, 0, 0)
end

-- Utility: Get forward vector of a hand
function Combat.GetHandForwardVector(hand)
    return GetForwardVectorForHand(hand) or Vector3(0, 0, 1)
end

-- Detect a punch with bare hands
function Combat.DetectPunch(hand)
    local velocity = Combat.GetHandVelocity(hand)
    if velocity:Length() > PUNCH_VELOCITY_THRESHOLD then
        local origin = Combat.GetHandPosition(hand)
        local dir = Combat.GetHandForwardVector(hand)
        local hit = Raycast(origin, dir, 0.5)

        if hit and hit.actor and hit.actor:HasTag("Enemy") then
            hit.actor:CallFunction("TakeDamage", { amount = 10 })
            PlayHapticFeedback(hand, 0.3)
            PlaySound("punch_impact")
        end
    end
end

-- Detect a melee swing with held item
function Combat.SwingWeapon(hand, heldItems)
    local item = heldItems[hand]
    if item and item:HasTag("MeleeWeapon") then
        local velocity = Combat.GetHandVelocity(hand)
        if velocity:Length() > SWING_VELOCITY_THRESHOLD then
            local origin = Combat.GetHandPosition(hand)
            local dir = Combat.GetHandForwardVector(hand)
            local hit = Raycast(origin, dir, 1.0)

            if hit and hit.actor and hit.actor:HasTag("Enemy") then
                local damage = velocity:Length() * 5
                hit.actor:CallFunction("TakeDamage", { amount = damage })
                PlayHapticFeedback(hand, 0.4)
                PlaySound("melee_hit")
            end
        end
    end
end

-- Push enemies with palm strike
function Combat.PushEnemy(hand)
    local velocity = Combat.GetHandVelocity(hand)
    local origin = Combat.GetHandPosition(hand)
    local dir = Combat.GetHandForwardVector(hand)
    local hit = Raycast(origin, dir, 0.75)

    if hit and hit.actor and hit.actor:HasTag("Enemy") and velocity:Length() > PUSH_VELOCITY_THRESHOLD then
        local force = velocity * 50
        hit.actor:ApplyImpulse(force)
        PlayHapticFeedback(hand, 0.5)
        PlaySound("push")
    end
end

-- Combat tick: runs every frame
function Combat.CombatTick(heldItems)
    for _, hand in ipairs({"Left", "Right"}) do
        Combat.DetectPunch(hand)
        Combat.SwingWeapon(hand, heldItems)
        Combat.PushEnemy(hand)
    end
end

-- Return the combat module
return Combat