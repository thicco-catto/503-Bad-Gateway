local BadGatewayMod = RegisterMod("502 Bad Gateway", 1)
local game = Game()

local function loadFile(loc, ...)
    local _, err = pcall(require, "")
    local modName = err:match("/mods/(.*)/%.lua")
    local path = "mods/" .. modName .. "/"
    return assert(loadfile(path .. loc .. ".lua"))(...)
end

local DoorManager = loadFile("bad_gateway_scripts/DoorManager")
DoorManager.AddCallbacks(BadGatewayMod)

loadFile("bad_gateway_scripts/compatibility/EIDCompat")

local MinimapiCompat = loadFile("bad_gateway_scripts/compatibility/MinimAPICompat")

if MinimapiCompat then
    MinimapiCompat:AddCallbacks(BadGatewayMod)
    MinimapiCompat.AddDoorManager(DoorManager)
end