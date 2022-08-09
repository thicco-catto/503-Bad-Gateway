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


-- local RoomFinder = loadFile("bad_gateway_scripts/RoomFinder")

-- function BadGatewayMod:OnRender()
--     if not MinimapAPI then return end

--     for _, room in ipairs(MinimapAPI:GetLevel()) do
--         local position = room.RenderOffset
--         Isaac.RenderScaledText(room.Descriptor.GridIndex, position.X + 10, position.Y + 10, 0.5, 0.5, 1, 1, 1, 1)
--         room.DisplayFlags = 1 << 0 | 1 << 1 | 1 << 2
--     end

--     local rooms = RoomFinder.GetPossibleEmptyRoomIndexes()

--     local str = ""

--     for _, value in ipairs(rooms) do
--         str = str .. value .. ", "
--     end

--     Isaac.RenderText(str, 100, 100, 1, 1, 1, 1)
-- end

-- BadGatewayMod:AddCallback(ModCallbacks.MC_POST_RENDER, BadGatewayMod.OnRender)