local BadGatewayMod = RegisterMod("502 Bad Gateway", 1)
local game = Game()


local function AreAllBossRoomsCleared()
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local allBossesCleared = true

    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)
        local roomData = room.Data

        --If its a boss room and it hasnt been cleared
        if roomData.Type == RoomType.ROOM_BOSS and not room.Clear then
            allBossesCleared = false
            break
        end
    end

    return allBossesCleared
end


---@return boolean
local function HasFlag(toCheck, flag)
    return toCheck & flag == flag
end


---@param index integer
---@return table
function GetAdyacentIndexes(index)
    local adyacentIndexes = {}

    adyacentIndexes.UP = index - 13
    adyacentIndexes.D_UP = index - 26

    adyacentIndexes.DOWN = index + 13
    adyacentIndexes.D_DOWN = index + 26

    --Is directly adyacent to the left
    if index % 13 == 0 then
        adyacentIndexes.LEFT = -1

        adyacentIndexes.UP_LEFT = -1
        adyacentIndexes.D_UP_LEFT = -1

        adyacentIndexes.DOWN = -1
        adyacentIndexes.D_DOWN = -1
    else
        adyacentIndexes.LEFT = index - 1

        adyacentIndexes.UP_LEFT = adyacentIndexes.UP - 1
        adyacentIndexes.D_UP_LEFT = adyacentIndexes.D_UP - 1

        adyacentIndexes.DOWN_LEFT = adyacentIndexes.DOWN - 1
        adyacentIndexes.D_DOWN_LEFT = adyacentIndexes.D_DOWN - 1
    end

    --Is indirectly adyacent to the left
    if index % 13 == 0 or index % 13 == 1 then
        adyacentIndexes.D_LEFT = -1

        adyacentIndexes.UP_D_LEFT = -1
        adyacentIndexes.D_UP_D_LEFT = -1

        adyacentIndexes.DOWN_D_LEFT = -1
        adyacentIndexes.D_DOWN_D_LEFT = -1
    else
        adyacentIndexes.D_LEFT = index - 2

        adyacentIndexes.UP_D_LEFT = adyacentIndexes.UP - 2
        adyacentIndexes.D_UP_D_LEFT = adyacentIndexes.D_UP - 2

        adyacentIndexes.DOWN_D_LEFT = adyacentIndexes.DOWN - 2
        adyacentIndexes.D_DOWN_D_LEFT = adyacentIndexes.D_DOWN - 2
    end

    --Is directly adyacent to the right
    if index % 13 == 12 then
        adyacentIndexes.RIGHT = -1

        adyacentIndexes.UP_RIGHT = -1
        adyacentIndexes.D_UP_RIGHT = -1

        adyacentIndexes.DOWN = -1
        adyacentIndexes.D_DOWN = -1
    else
        adyacentIndexes.RIGHT = index + 1

        adyacentIndexes.UP_RIGHT = adyacentIndexes.UP + 1
        adyacentIndexes.D_UP_RIGHT = adyacentIndexes.D_UP + 1

        adyacentIndexes.DOWN_RIGHT = adyacentIndexes.DOWN + 1
        adyacentIndexes.D_DOWN_RIGHT = adyacentIndexes.D_DOWN + 1
    end

    --Is indirectly adyacent to the right
    if index % 13 == 12 or index % 13 == 11 then
        adyacentIndexes.D_RIGHT = -1

        adyacentIndexes.UP_D_RIGHT = -1
        adyacentIndexes.D_UP_D_RIGHT = -1

        adyacentIndexes.DOWN_D_RIGHT = -1
        adyacentIndexes.D_DOWN_D_RIGHT = -1
    else
        adyacentIndexes.D_RIGHT = index + 2

        adyacentIndexes.UP_D_RIGHT = adyacentIndexes.UP + 2
        adyacentIndexes.D_UP_D_RIGHT = adyacentIndexes.D_UP + 2

        adyacentIndexes.DOWN_D_RIGHT = adyacentIndexes.DOWN + 2
        adyacentIndexes.D_DOWN_D_RIGHT = adyacentIndexes.D_DOWN + 2
    end

    return adyacentIndexes
end


---@param room RoomDescriptor
local function GetRoomIndexesAdyacentToRoom(room)
    local roomData = room.Data

    local adyacentIndexes = GetAdyacentIndexes(room.GridIndex)

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or roomData.Shape == RoomShape.ROOMSHAPE_IV then
        --1x1 rooms take their grid
        return {adyacentIndexes.UP, adyacentIndexes.RIGHT, adyacentIndexes.LEFT, adyacentIndexes.DOWN}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        --1x2 rooms take their grid and the one below
        return {adyacentIndexes.UP, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.RIGHT, adyacentIndexes.RIGHT_DOWN, adyacentIndexes.D_DOWN}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        --2x1 rooms take their grid and the one to the right
        return {adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.D_RIGHT, adyacentIndexes.DOWN, adyacentIndexes.DOWN_RIGHT}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
        --2x2 rooms take their grid, the one below, the one to the right and the one diagonally
        return {adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.D_RIGHT, adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.D_DOWN, adyacentIndexes.D_DOWN_RIGHT}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTL then
        --LTL rooms dont take their own grid index
        return {room.GridIndex, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.D_RIGHT, adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.D_DOWN, adyacentIndexes.D_DOWN_RIGHT}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTR then
        --LTR rooms dont take the index to the right 
        return {adyacentIndexes.UP, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.RIGHT, adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.D_DOWN, adyacentIndexes.D_DOWN_RIGHT}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBL then
        --LBL rooms dont take the index below
        return {adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.D_RIGHT, adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.DOWN, adyacentIndexes.D_DOWN_RIGHT}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBR then
        --LBR rooms dont take the index diagonally
        return {adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.D_RIGHT, adyacentIndexes.RIGHT_DOWN, adyacentIndexes.D_DOWN}
    end
end


---@param room RoomDescriptor
local function GetRoomIndexesThatRoomOccupies(room)
    local roomData = room.Data

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or roomData.Shape == RoomShape.ROOMSHAPE_IV then
        --1x1 rooms only take their grid index
        return {room.GridIndex}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        --1x2 rooms take their grid and the one below
        return {room.GridIndex, room.GridIndex + 13}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        --2x1 rooms take their grid and the one to the right
        return {room.GridIndex, room.GridIndex + 1}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
        --2x2 rooms take their grid, the one below, the one to the right and the one diagonally
        return {room.GridIndex, room.GridIndex + 1, room.GridIndex + 13, room.GridIndex + 14}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTL then
        --LTL rooms dont take their own grid index
        return {room.GridIndex + 1, room.GridIndex + 13, room.GridIndex + 14}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTR then
        --LTR rooms dont take the index to the right 
        return {room.GridIndex, room.GridIndex + 13, room.GridIndex + 14}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBL then
        --LBL rooms dont take the index below
        return {room.GridIndex, room.GridIndex + 1, room.GridIndex + 14}
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBR then
        --LBR rooms dont take the index diagonally
        return {room.GridIndex, room.GridIndex + 1, room.GridIndex + 13}
    end
end


---@param index integer
function IsAccessibleIndexButCantBeRedRoom(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local adyacentIndexes = GetAdyacentIndexes(index)

    local isNotAccessibleFromAtLeastOne = false
    local isAccessbileFromAtLeastOne = false

    --Check for doors
    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)
        local roomData = room.Data
        local doors = roomData.Doors

        --Normal rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or roomData.Shape == RoomShape.ROOMSHAPE_IV then
            if room.GridIndex == adyacentIndexes.UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --1x2 rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
            if room.GridIndex == adyacentIndexes.D_UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --2x1 rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
            if room.GridIndex == adyacentIndexes.UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_LEFT then
                if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                if HasFlag(doors, 1 << DoorSlot.UP1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --2x2 rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
            if room.GridIndex == adyacentIndexes.D_UP_LEFT then
                if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                if HasFlag(doors, 1 << DoorSlot.UP1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --LTL rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_LTL then
            if room.GridIndex == index then
                if HasFlag(doors, 1 << DoorSlot.UP0 | 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                if HasFlag(doors, 1 << DoorSlot.UP1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP_LEFT then
                if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --LTR rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_LTR then
            if room.GridIndex == adyacentIndexes.LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0 | 1 << DoorSlot.UP1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP_LEFT then
                if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --LBL rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_LBL then
            if room.GridIndex == adyacentIndexes.UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0 | 1 << DoorSlot.LEFT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                if HasFlag(doors, 1 << DoorSlot.UP1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP_LEFT then
                if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end

        --LBR
        if roomData.Shape == RoomShape.ROOMSHAPE_LBR then
            if room.GridIndex == adyacentIndexes.UP_RIGHT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT1 | 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_UP then
                if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.RIGHT then
                if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN then
                if HasFlag(doors, 1 << DoorSlot.UP0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                if HasFlag(doors, 1 << DoorSlot.UP1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end

            if room.GridIndex == adyacentIndexes.D_LEFT then
                if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end
    end

    return isNotAccessibleFromAtLeastOne and isAccessbileFromAtLeastOne
end


local function PrintPossibleRooms(possbile)
    local str = ""
    for index, _ in pairs(possbile) do
        str = str .. index .. ", "
    end
    return str
end


function GetPossibleEmptyRoomIndexes()
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    --Initialize a table with all adyacent rooms
    local possibleRooms = {}

    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)

        local adyacentRooms = GetRoomIndexesAdyacentToRoom(room)

        for _, gridIndex in ipairs(adyacentRooms) do
            if gridIndex and gridIndex >= 0 and gridIndex <= 168 then
                possibleRooms[gridIndex] = true
            end
        end
    end

    --Remove indexes that are already rooms
    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)

        local occupyingRooms = GetRoomIndexesThatRoomOccupies(room)

        for _, gridIndex in pairs(occupyingRooms) do
            possibleRooms[gridIndex] = nil
        end
    end

    --Remove indexes that are completely accesible
    for roomIndex, _ in pairs(possibleRooms) do
        if not IsAccessibleIndexButCantBeRedRoom(roomIndex) then
            possibleRooms[roomIndex] = nil
        end
    end

    return possibleRooms
end


local RoomsToPutDoor = {}


function BadGatewayMod:OnUpdate()
    if game:GetFrameCount() == 1 then
        local player = game:GetPlayer(0)
        Isaac.ExecuteCommand("debug 10")
        player:AddCollectible(CollectibleType.COLLECTIBLE_XRAY_VISION)
        player:AddCollectible(CollectibleType.COLLECTIBLE_WOODEN_SPOON)
        player:AddCollectible(CollectibleType.COLLECTIBLE_WOODEN_SPOON)
        player:AddCollectible(CollectibleType.COLLECTIBLE_WOODEN_SPOON)
        player:AddCollectible(CollectibleType.COLLECTIBLE_RED_KEY)

        player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_XRAY_VISION))
        player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_WOODEN_SPOON))
    end

    RoomsToPutDoor = GetPossibleEmptyRoomIndexes()
end
BadGatewayMod:AddCallback(ModCallbacks.MC_POST_UPDATE, BadGatewayMod.OnUpdate)


function BadGatewayMod:OnRender()
    if not MinimapAPI then return end

    for _, room in ipairs(MinimapAPI:GetLevel()) do
        local position = room.RenderOffset
        Isaac.RenderScaledText(room.Descriptor.GridIndex, position.X + 10, position.Y + 10, 0.5, 0.5, 1, 1, 1, 1)
        room.DisplayFlags = 1<<0 | 1<<1 | 1<<2
    end

    Isaac.RenderText(PrintPossibleRooms(RoomsToPutDoor), 100, 100, 1, 1, 1, 1)
end
BadGatewayMod:AddCallback(ModCallbacks.MC_POST_RENDER, BadGatewayMod.OnRender)