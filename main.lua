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
local function GetAdyacentIndexes(index)
    local adyacentIndexes = {}

    adyacentIndexes.UP = index - 13
    adyacentIndexes.UP_RIGHT = adyacentIndexes.UP + 1
    adyacentIndexes.UP_LEFT = adyacentIndexes.UP - 1

    adyacentIndexes.D_UP = index - 26
    adyacentIndexes.D_UP_LEFT = adyacentIndexes.D_UP - 1

    adyacentIndexes.DOWN = index + 13
    adyacentIndexes.DOWN_RIGHT = adyacentIndexes.DOWN + 1
    adyacentIndexes.DOWN_LEFT = adyacentIndexes.DOWN - 1

    adyacentIndexes.D_DOWN = index + 26
    adyacentIndexes.D_DOWN_RIGHT = adyacentIndexes.D_DOWN + 1

    --A room is adyacent to the left "wall" if its grid index is divisible by 13
    local directlyAdyacentLeft = index % 13 == 0
    adyacentIndexes.LEFT = directlyAdyacentLeft and index - 1 or -1
    adyacentIndexes.LEFT_DOWN = directlyAdyacentLeft and index + 12 or -1

    --A room is indirectly adyacent to the left "wall" if the remainder of its grid index and 13 is 1
    local indirectlyAdyacentLeft = index % 13 == 1
    adyacentIndexes.D_LEFT = indirectlyAdyacentLeft and index - 1 or -1
    adyacentIndexes.D_LEFT_DOWN = indirectlyAdyacentLeft and index + 12 or -1

    --A room is directly adyacent to the right if the remainder of its grid index and 13 is 12
    local directlyAdyacentRight = index % 13 == 12
    adyacentIndexes.RIGHT = directlyAdyacentRight and index + 1 or -1
    adyacentIndexes.RIGHT_DOWN = directlyAdyacentRight and index + 14 or -1

    --A room is indirectly adyacent to the right if the remainder of its grid index and 13 is 11
    local indirectlyAdyacentRight = index % 13 == 11
    adyacentIndexes.D_RIGHT = directlyAdyacentRight and index + 2 or -1
    adyacentIndexes.D_RIGHT_DOWN = directlyAdyacentRight and index + 15 or -1

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
---@return boolean
local function IsRoomAccessible(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local adyacentIndexes = GetAdyacentIndexes(index)

    -- --First check for small rooms
    -- for i = 0, rooms.Size - 1, 1 do
    --     local room = rooms:Get(i)
    --     local roomData = room.Data

    --     if room.GridIndex == adyacentIndexes.UP and
    --     roomData.Shape == RoomShape.ROOMSHAPE_IH or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
    --         return false
    --     end

    --     if room.GridIndex == adyacentIndexes.DOWN and
    --     roomData.Shape == RoomShape.ROOMSHAPE_IH or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
    --         return false
    --     end

    --     if room.GridIndex == adyacentIndexes.LEFT and
    --     roomData.Shape == RoomShape.ROOMSHAPE_IV or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
    --         return false
    --     end

    --     if room.GridIndex == adyacentIndexes.RIGHT and
    --     roomData.Shape == RoomShape.ROOMSHAPE_IV or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
    --         return false
    --     end

    --     if room.GridIndex == adyacentIndexes.UP_LEFT and
    --     roomData.Shape == RoomShape.ROOMSHAPE_IIH or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
    --         return false
    --     end

    --     if room.GridIndex == adyacentIndexes.UP_RIGHT and roomData.Shape == RoomShape.ROOMSHAPE_IIV then
    --         return false
    --     end

    --     if room.GridIndex == adyacentIndexes.DOWN_LEFT and roomData.Shape == RoomShape.ROOMSHAPE_IIH then
    --         return false
    --     end
    -- end

    --Check for doors
    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)
        local roomData = room.Data
        local doors = roomData.Doors

        --Normal rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or roomData.Shape == RoomShape.ROOMSHAPE_IV then
            if room.GridIndex == adyacentIndexes.UP and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.LEFT and not HasFlag(doors, DoorSlot.RIGHT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.RIGHT and not HasFlag(doors , DoorSlot.LEFT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN and not HasFlag(doors, DoorSlot.UP0) then
                return false
            end
        end

        --1x2 rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
            if room.GridIndex == adyacentIndexes.D_UP and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.LEFT and not HasFlag(doors, DoorSlot.RIGHT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.RIGHT and not HasFlag(doors, DoorSlot.LEFT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.UP_LEFT and not HasFlag(doors, DoorSlot.RIGHT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT and not HasFlag(doors, DoorSlot.LEFT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN and not HasFlag(doors, DoorSlot.UP0) then
                return false
            end
        end

        --2x1 rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
            if room.GridIndex == adyacentIndexes.UP and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.UP_LEFT and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN and not HasFlag(doors, DoorSlot.UP0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT and not HasFlag(doors, DoorSlot.UP1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_LEFT and not HasFlag(doors, DoorSlot.RIGHT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.RIGHT and not HasFlag(doors, DoorSlot.LEFT0) then
                return false
            end
        end

        --2x2 rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
            if room.GridIndex == adyacentIndexes.D_UP_LEFT and not HasFlag(doors, DoorSlot.DOWN1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_UP and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_LEFT and not HasFlag(doors, DoorSlot.RIGHT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_LEFT_UP and not HasFlag(doors, DoorSlot.RIGHT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.RIGHT and not HasFlag(doors, DoorSlot.LEFT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN and not HasFlag(doors, DoorSlot.UP0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT and not doors | DoorSlot.UP1 then
                return false
            end
        end

        --LTL rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_LTL then
            if room.GridIndex == index and not HasFlag(doors, DoorSlot.UP0 | DoorSlot.LEFT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.DOWN_LEFT and not HasFlag(doors, DoorSlot.UP1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_LEFT and not HasFlag(doors, DoorSlot.RIGHT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_LEFT_UP and not HasFlag(doors, DoorSlot.RIGHT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT and not HasFlag(doors, DoorSlot.LEFT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_UP and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_UP_LEFT and not HasFlag(doors, DoorSlot.DOWN1) then
                return false
            end
        end

        --LTR rooms
        if roomData.Shape == RoomShape.ROOMSHAPE_LTR then
            if room.GridIndex == adyacentIndexes.DOWN and not HasFlag(doors, DoorSlot.UP0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.RIGHT and not HasFlag(doors, DoorSlot.LEFT0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.UP_RIGHT and not HasFlag(doors, DoorSlot.LEFT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.LEFT and not HasFlag(doors, DoorSlot.RIGHT0 | DoorSlot.UP1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_LEFT_UP and not HasFlag(doors, DoorSlot.RIGHT1) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_UP and not HasFlag(doors, DoorSlot.DOWN0) then
                return false
            end

            if room.GridIndex == adyacentIndexes.D_UP_LEFT and not HasFlag(doors, DoorSlot.DOWN1) then
                return false
            end
        end
    end

    return true
end


local function GetPossibleEmptyRoomIndexes()
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

        for _, gridIndex in ipairs(occupyingRooms) do
            possibleRooms[gridIndex] = nil
        end
    end
end