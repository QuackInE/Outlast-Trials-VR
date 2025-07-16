-- ====== INIT SCRIPT FOR UEVR - AUTO LOAD ALL GAME MECHANICS ======

-- Hand interaction (grabbing, using, holstering, interacting)
require("hand_interaction")

-- Core movement mechanics (walking, running, crouching, jumping, hiding)
require("mechanics")

-- Multiplayer VR mechanics (reviving, syncing actions, emotes)
require("multiplayer_mechanics")

require("combat.lua")

-- [Optional: Add future scripts below]
-- require("combat")             -- if you make melee or weapon support
-- require("environment_fx")     -- if you add lighting, particles, weather

print("[UEVR INIT] All core game scripts successfully loaded.")