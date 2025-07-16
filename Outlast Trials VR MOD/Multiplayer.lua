-- ====== Multiplayer Mechanics (Outlast Trials VR Mod) ======

-- Table to track connected players
local players = {}

-- Sync interval (in seconds)
local syncInterval = 0.1
local lastSyncTime = 0

-- Player state info to sync
local playerState = {
    position = Vector3.new(0, 0, 0),
    rotation = Quaternion.identity(),
    leftHand = {
        position = Vector3.new(0, 0, 0),
        rotation = Quaternion.identity(),
        heldItem = nil
    },
    rightHand = {
        position = Vector3.new(0, 0, 0),
        rotation = Quaternion.identity(),
        heldItem = nil
    },
    isDowned = false,
    isReviving = false
}

-- === Player Join ===
function OnPlayerJoin(player)
    players[player.id] = {
        id = player.id,
        name = player.name,
        state = deepcopy(playerState)
    }
    print("[Multiplayer] Player joined: " .. player.name)
end

-- === Player Leave ===
function OnPlayerLeave(player)
    players[player.id] = nil
    print("[Multiplayer] Player left: " .. player.name)
end

-- === Sync Player State ===
function SyncPlayerState(localPlayer)
    if Time() - lastSyncTime < syncInterval then return end
    lastSyncTime = Time()

    localPlayerState = {
        position = GetPlayerPosition(),
        rotation = GetPlayerRotation(),
        leftHand = {
            position = GetHandPosition("left"),
            rotation = GetHandRotation("left"),
            heldItem = GetHeldItem("left")
        },
        rightHand = {
            position = GetHandPosition("right"),
            rotation = GetHandRotation("right"),
            heldItem = GetHeldItem("right")
        },
        isDowned = IsPlayerDowned(),
        isReviving = IsPlayerReviving()
    }

    -- Send to all connected players
    for _, player in pairs(players) do
        SendNetworkEvent("UpdatePlayerState", player.id, localPlayerState)
    end
end

-- === Handle Incoming Network Events ===
function OnNetworkEvent(event, fromId, data)
    if event == "UpdatePlayerState" and players[fromId] then
        players[fromId].state = data
    elseif event == "RevivePlayer" and players[fromId] then
        SetPlayerDownedState(false)
        print("[Multiplayer] You were revived by " .. players[fromId].name)
    end
end

-- === Render Other Players ===
function RenderOtherPlayers()
    for _, player in pairs(players) do
        if player.id ~= GetLocalPlayerId() then
            DrawNetworkPlayer(player.state)
        end
    end
end

function DrawNetworkPlayer(state)
    -- Placeholder: Draw avatar, hands, held items, etc.
    SetAvatarPosition(state.position)
    SetAvatarRotation(state.rotation)

    SetHandPosition("left", state.leftHand.position)
    SetHandRotation("left", state.leftHand.rotation)

    SetHandPosition("right", state.rightHand.position)
    SetHandRotation("right", state.rightHand.rotation)

    if state.leftHand.heldItem then AttachGhostItem("left", state.leftHand.heldItem) end
    if state.rightHand.heldItem then AttachGhostItem("right", state.rightHand.heldItem) end
end

-- === Revive Mechanic ===
function AttemptRevive(targetPlayer)
    if GetDistanceTo(targetPlayer.state.position) < 1.5 then
        print("[Multiplayer] Reviving " .. targetPlayer.name)
        StartReviveAnimation()
        Wait(3.0)
        SendNetworkEvent("RevivePlayer", targetPlayer.id, {})
    end
end

-- === Main Update ===
function OnUpdate()
    SyncPlayerState(GetLocalPlayer())
    RenderOtherPlayers()
end

-- Register events
RegisterNetworkEvent("UpdatePlayerState", OnNetworkEvent)
RegisterNetworkEvent("RevivePlayer", OnNetworkEvent)
RegisterPlayerJoinCallback(OnPlayerJoin)
RegisterPlayerLeaveCallback(OnPlayerLeave)

print("[MultiplayerMechanics.lua] Multiplayer VR logic loaded")