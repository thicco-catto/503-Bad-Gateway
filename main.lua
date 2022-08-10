local BadGatewayMod = RegisterMod("502 Bad Gateway", 1)

local function loadFile(loc, ...)
    local _, err = pcall(require, "")
    local modName = err:match("/mods/(.*)/%.lua")
    local path = "mods/" .. modName .. "/"
    return assert(loadfile(path .. loc .. ".lua"))(...)
end

DoorManager = loadFile("bad_gateway_scripts/DoorManager")
DoorManager.AddCallbacks(BadGatewayMod)

local SaveManager = loadFile("bad_gateway_scripts/SaveManager")
SaveManager.AddCallbacks(BadGatewayMod)
SaveManager.AddDoorManager(DoorManager)

loadFile("bad_gateway_scripts/compatibility/EIDCompat")

local MinimapiCompat = loadFile("bad_gateway_scripts/compatibility/MinimAPICompat")

if MinimapiCompat then
    MinimapiCompat:AddCallbacks(BadGatewayMod)
    MinimapiCompat.AddDoorManager(DoorManager)
end

-- function BadGatewayMod:OnRender()
--     if not MinimapAPI then return end
--     for _, room in ipairs(MinimapAPI:GetLevel()) do
--         local position = room.RenderOffset
--         Isaac.RenderScaledText(room.Descriptor.GridIndex, position.X + 10, position.Y + 10, 0.5, 0.5, 1, 1, 1, 1)
--         room.DisplayFlags = 1 << 0 | 1 << 1 | 1 << 2
--     end
-- end
-- BadGatewayMod:AddCallback(ModCallbacks.MC_POST_RENDER, BadGatewayMod.OnRender)