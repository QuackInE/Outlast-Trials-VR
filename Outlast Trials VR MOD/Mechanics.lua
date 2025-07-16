-- Player movement, running, jumping, crouching, hiding, and stamina system for UEVR

-- ====== Player State ======
local player = {
    position = Vector3.new(0,0,0),
    velocity = Vector3.new(0,0,0),
    isGrounded = true,
    isCrouching = false,
    isSprinting = false,
    stamina = 100,         -- max stamina
    staminaDrainRate = 15, -- stamina drained per second while sprinting
    staminaRegenRate = 10, -- stamina regenerated per second when not sprinting
    staminaCooldown = false,
    staminaCooldownTime = 3,
    staminaCooldownTimer = 0,
    hideSpots = {},        -- list of nearby hide spots
    isHiding = false
}

-- ====== Constants ======
local WALK_SPEED = 2.5
local SPRINT_SPEED = 5.0
local CROUCH_SPEED = 1.2
local JUMP_FORCE = 5.0
local GRAVITY = -9.8

-- ====== Input Helpers (change to match your input system) ======
function GetAxis(name)
    -- Example: "MoveX", "MoveY"
    return GetInputAxis(name) or 0
end

function GetButton(name)
    -- Example: "Jump", "Sprint", "Crouch", "Hide"
    return GetInput(name) > 0.5
end

-- ====== Movement Logic ======
function UpdateMovement(deltaTime)
    -- Get input axes
    local inputX = GetAxis("MoveX")
    local inputZ = GetAxis("MoveY")

    -- Determine speed
    local speed = WALK_SPEED
    if player.isCrouching then
        speed = CROUCH_SPEED
    elseif player.isSprinting and player.stamina > 0 and not player.staminaCooldown then
        speed = SPRINT_SPEED
        player.stamina = math.max(0, player.stamina - player.staminaDrainRate * deltaTime)
        if player.stamina == 0 then
            player.staminaCooldown = true
            player.staminaCooldownTimer = player.staminaCooldownTime
            player.isSprinting = false
        end
    else
        -- Regenerate stamina
        if player.stamina < 100 then
            player.stamina = math.min(100, player.stamina + player.staminaRegenRate * deltaTime)
        end
        if player.staminaCooldown then
            player.staminaCooldownTimer = player.staminaCooldownTimer - deltaTime
            if player.staminaCooldownTimer <= 0 then
                player.staminaCooldown = false
            end
        end
    end

    -- Calculate movement vector relative to player forward
    local forward = GetPlayerForwardVector()
    local right = GetPlayerRightVector()

    local moveDir = (forward * inputZ) + (right * inputX)
    if moveDir:Length() > 1 then
        moveDir = moveDir:Normalized()
    end

    -- Apply horizontal movement
    local horizontalVelocity = moveDir * speed

    -- Apply gravity & jumping
    if player.isGrounded then
        player.velocity.y = 0
        if GetButton("Jump") and not player.isCrouching then
            player.velocity.y = JUMP_FORCE
            player.isGrounded = false
        end
    else
        player.velocity.y = player.velocity.y + GRAVITY * deltaTime
    end

    -- Combine horizontal and vertical velocity
    player.velocity.x = horizontalVelocity.x
    player.velocity.z = horizontalVelocity.z

    -- Update position
    player.position = player.position + player.velocity * deltaTime

    -- Check for ground contact (simplified)
    if player.position.y <= 0 then
        player.position.y = 0
        player.isGrounded = true
        player.velocity.y = 0
    end

    -- Update player position in the game (replace with actual movement call)
    SetPlayerPosition(player.position)
end

-- ====== Crouch / Hide Logic ======
function UpdateCrouchAndHide()
    if GetButton("Crouch") then
        player.isCrouching = true
    else
        player.isCrouching = false
    end

    -- Detect nearby hide spots
    player.isHiding = false
    for _, spot in ipairs(player.hideSpots) do
        if spot:IsNearby(player.position, 1.5) and player.isCrouching then
            player.isHiding = true
            -- Trigger hide logic here (e.g. disable enemy detection)
            -- Possibly play animation or sound
            break
        end
    end
end

-- ====== Update Loop ======
function OnUpdate(deltaTime)
    UpdateMovement(deltaTime)
    UpdateCrouchAndHide()
    -- Add more game mechanic updates here (e.g. stamina UI)
end

-- ====== Example: Adding hide spots ======
function AddHideSpot(spot)
    table.insert(player.hideSpots, spot)
end

-- ====== Initialization ======
function InitMechanics()
    print("Mechanics.lua initialized")
    -- Initialize hide spots or other data if needed
end

-- ====== Hook Update ======
function OnGameTick(deltaTime)
    OnUpdate(deltaTime)
end

-- Register OnGameTick with the game loop
RegisterTickCallback(OnGameTick)

-- Initialize mechanics on script load
InitMechanics()

-- NIGHT VISION TOGGLE
local nightVisionOn = false
local nightVisionCooldown = 0

function ToggleNightVision()
    if GetTime() < nightVisionCooldown then return end
    nightVisionCooldown = GetTime() + 0.5  -- prevent rapid toggling

    nightVisionOn = not nightVisionOn
    PressKey("R") -- triggers night vision like keyboard
    Log("Night Vision: " .. (nightVisionOn and "ON" or "OFF"))
end

-- Check for VR button press (adjust for your VR setup)
function Update()
    if IsButtonPressed("RightGrip") and IsButtonDown("RightTrigger") then
        ToggleNightVision()
    end
end