if not MinimapAPI then return end

local MinimapiCompat = {}

local Constants = require("bad_gateway_scripts/Constants")
local DoorManager = {}

local HasAddedIcon = false


--Returns whether a room at a certain room index has the glitch door icon or not
---@param room table
---@return boolean
function MinimapiCompat.DoesMinimapRoomHaveIcon(room)
    local icons = room.PermanentIcons

    for _, icon in ipairs(icons) do
        if icon == Constants.GLITCH_DOOR_ICON_ID then
            return true
        end
    end

    return false
end


function MinimapiCompat:OnFrameUpdate()
    --Dont do anything until the icon has been added
    if not HasAddedIcon then return end

    local selectedRoom = DoorManager.GetRoomAndDoorSlotForCurrentLevel()

    --If the selected room hasnt been selected yet or doesnt exist ignore the rest of the callback
    if not selectedRoom or not selectedRoom.room then return end

    local canSpawnDoor = DoorManager.CanSpawnGlitchDoor()
    local room = MinimapAPI:GetRoomByIdx(selectedRoom.room)
    local isIconInMinimap = MinimapiCompat.DoesMinimapRoomHaveIcon(room)

    if canSpawnDoor and not isIconInMinimap then
        table.insert(room.PermanentIcons, Constants.GLITCH_DOOR_ICON_ID)
    elseif not canSpawnDoor and isIconInMinimap then
        for index, icon in ipairs(room.PermanentIcons) do
            if icon == Constants.GLITCH_DOOR_ICON_ID then
                table.remove(room.PermanentIcons, index)
            end
        end
    end
end


function MinimapiCompat:OnGameStart()
    --No need to add the icon more than once
    if HasAddedIcon then return end
    HasAddedIcon = true

    local glitchDoorIconSprite = Sprite()
    glitchDoorIconSprite:Load("gfx/glitch_door_minimap_icon.anm2", true)

    MinimapAPI:AddIcon(Constants.GLITCH_DOOR_ICON_ID, glitchDoorIconSprite, "Idle", 0)
end


function MinimapiCompat:AddCallbacks(mod)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, MinimapiCompat.OnFrameUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MinimapiCompat.OnGameStart)
end


function MinimapiCompat.AddDoorManager(doorManager)
    DoorManager = doorManager
end


return MinimapiCompat