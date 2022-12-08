local BadGatewayMod = RegisterMod("502 Bad Gateway", 1)


DoorManager = require("bad_gateway_scripts/DoorManager")
DoorManager.AddCallbacks(BadGatewayMod)

local SaveManager = require("bad_gateway_scripts/SaveManager")
SaveManager.AddCallbacks(BadGatewayMod)
SaveManager.AddDoorManager(DoorManager)

require("bad_gateway_scripts/compatibility/EIDCompat")

local MinimapiCompat = require("bad_gateway_scripts/compatibility/MinimAPICompat")

if MinimapiCompat ~= true then
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