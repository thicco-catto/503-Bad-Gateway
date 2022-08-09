local BadGatewayMod = RegisterMod("502 Bad Gateway", 1)
local game = Game()


local BAD_GATEWAY_ITEM = Isaac.GetItemIdByName("502")


local function DoesAnyPlayerHaveItem(item)
    for i = 0, game:GetNumPlayers() - 1, 1 do
        local player = game:GetPlayer(i)
        if player:HasCollectible(item) then
            return true
        end
    end

    return false
end


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


local function CanSpawnGlitchDoor()
    local level = game:GetLevel()

    local isVoid = level:GetAbsoluteStage() == LevelStage.STAGE7
    local isHome = level:GetAbsoluteStage() == LevelStage.STAGE8

    local playersHave502 = DoesAnyPlayerHaveItem(BAD_GATEWAY_ITEM)

    return AreAllBossRoomsCleared() and playersHave502 and not (isVoid or isHome or level:IsAscent() or level:IsPreAscent())
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

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
        roomData.Shape == RoomShape.ROOMSHAPE_IV then
        --1x1 rooms take their grid
        return { adyacentIndexes.UP, adyacentIndexes.RIGHT, adyacentIndexes.LEFT, adyacentIndexes.DOWN }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        --1x2 rooms take their grid and the one below
        return { adyacentIndexes.UP, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.RIGHT,
            adyacentIndexes.RIGHT_DOWN, adyacentIndexes.D_DOWN }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        --2x1 rooms take their grid and the one to the right
        return { adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.D_RIGHT,
            adyacentIndexes.DOWN, adyacentIndexes.DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
        --2x2 rooms take their grid, the one below, the one to the right and the one diagonally
        return { adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN,
            adyacentIndexes.D_RIGHT, adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.D_DOWN, adyacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTL then
        --LTL rooms dont take their own grid index
        return { room.GridIndex, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.D_RIGHT,
            adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.D_DOWN, adyacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTR then
        --LTR rooms dont take the index to the right
        return { adyacentIndexes.UP, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN, adyacentIndexes.RIGHT,
            adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.D_DOWN, adyacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBL then
        --LBL rooms dont take the index below
        return { adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.D_RIGHT,
            adyacentIndexes.D_RIGHT_DOWN, adyacentIndexes.DOWN, adyacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBR then
        --LBR rooms dont take the index diagonally
        return { adyacentIndexes.UP, adyacentIndexes.UP_RIGHT, adyacentIndexes.LEFT, adyacentIndexes.LEFT_DOWN,
            adyacentIndexes.D_RIGHT, adyacentIndexes.RIGHT_DOWN, adyacentIndexes.D_DOWN }
    end
end


---@param room RoomDescriptor
local function GetRoomIndexesThatRoomOccupies(room)
    local roomData = room.Data

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
        roomData.Shape == RoomShape.ROOMSHAPE_IV then
        --1x1 rooms only take their grid index
        return { room.GridIndex }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        --1x2 rooms take their grid and the one below
        return { room.GridIndex, room.GridIndex + 13 }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        --2x1 rooms take their grid and the one to the right
        return { room.GridIndex, room.GridIndex + 1 }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
        --2x2 rooms take their grid, the one below, the one to the right and the one diagonally
        return { room.GridIndex, room.GridIndex + 1, room.GridIndex + 13, room.GridIndex + 14 }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTL then
        --LTL rooms dont take their own grid index
        return { room.GridIndex + 1, room.GridIndex + 13, room.GridIndex + 14 }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTR then
        --LTR rooms dont take the index to the right
        return { room.GridIndex, room.GridIndex + 13, room.GridIndex + 14 }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBL then
        --LBL rooms dont take the index below
        return { room.GridIndex, room.GridIndex + 1, room.GridIndex + 14 }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBR then
        --LBR rooms dont take the index diagonally
        return { room.GridIndex, room.GridIndex + 1, room.GridIndex + 13 }
    end
end


---@param index integer
local function IsAccessibleIndexButCantBeRedRoom(index)
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

        if room.Flags & RoomDescriptor.FLAG_RED_ROOM ~= RoomDescriptor.FLAG_RED_ROOM then
            --Normal rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
                roomData.Shape == RoomShape.ROOMSHAPE_IV then
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

            --Big rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x2 or roomData.Shape == RoomShape.ROOMSHAPE_LTL or
                roomData.Shape == RoomShape.ROOMSHAPE_LTR or roomData.Shape == RoomShape.ROOMSHAPE_LBL or
                roomData.Shape == RoomShape.ROOMSHAPE_LBR then

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTL then
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
                else
                    if room.GridIndex == index then
                        if HasFlag(doors, 1 << DoorSlot.UP0 | 1 << DoorSlot.LEFT0) then

                            isAccessbileFromAtLeastOne = true
                        else

                            isNotAccessibleFromAtLeastOne = true
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTR then
                    if room.GridIndex == adyacentIndexes.D_LEFT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT0) then

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
                else
                    if room.GridIndex == adyacentIndexes.LEFT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT0 | 1 << DoorSlot.UP1) then

                            isAccessbileFromAtLeastOne = true
                        else

                            isNotAccessibleFromAtLeastOne = true
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LBL then
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
                else
                    if room.GridIndex == adyacentIndexes.UP then
                        if HasFlag(doors, 1 << DoorSlot.DOWN0 | 1 << DoorSlot.LEFT1) then

                            isAccessbileFromAtLeastOne = true
                        else

                            isNotAccessibleFromAtLeastOne = true
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LBR then
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
                else
                    if room.GridIndex == adyacentIndexes.UP_RIGHT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT1 | 1 << DoorSlot.DOWN1) then

                            isAccessbileFromAtLeastOne = true
                        else

                            isNotAccessibleFromAtLeastOne = true
                        end
                    end
                end
            end
        end
    end

    return isNotAccessibleFromAtLeastOne and isAccessbileFromAtLeastOne
end


local function IsAdjacentToForbiddenRoom(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local adyacentIndexes = GetAdyacentIndexes(index)

    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)
        local roomData = room.Data

        local isAdjacent = false

        if room.Flags & RoomDescriptor.FLAG_RED_ROOM ~= RoomDescriptor.FLAG_RED_ROOM then
            --Normal rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
                roomData.Shape == RoomShape.ROOMSHAPE_IV then
                if room.GridIndex == adyacentIndexes.UP or room.GridIndex == adyacentIndexes.LEFT or
                    room.GridIndex == adyacentIndexes.RIGHT or room.GridIndex == adyacentIndexes.DOWN then
                    isAdjacent = true
                end
            end

            --1x2 rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
                if room.GridIndex == adyacentIndexes.D_UP or room.GridIndex == adyacentIndexes.LEFT or
                    room.GridIndex == adyacentIndexes.RIGHT or room.GridIndex == adyacentIndexes.UP_LEFT or
                    room.GridIndex == adyacentIndexes.UP_RIGHT or room.GridIndex == adyacentIndexes.DOWN then
                    isAdjacent = true
                end
            end

            --2x1 rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
                if room.GridIndex == adyacentIndexes.UP or room.GridIndex == adyacentIndexes.UP_LEFT or
                    room.GridIndex == adyacentIndexes.DOWN or room.GridIndex == adyacentIndexes.DOWN_LEFT or
                    room.GridIndex == adyacentIndexes.D_LEFT or room.GridIndex == adyacentIndexes.RIGHT then
                    isAdjacent = true
                end
            end

            --Big rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x2 or roomData.Shape == RoomShape.ROOMSHAPE_LTL or
                roomData.Shape == RoomShape.ROOMSHAPE_LTR or roomData.Shape == RoomShape.ROOMSHAPE_LBL or
                roomData.Shape == RoomShape.ROOMSHAPE_LBR then

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTL then
                    if room.GridIndex == adyacentIndexes.DOWN or room.GridIndex == adyacentIndexes.RIGHT then
                        isAdjacent = true
                    end
                else
                    if room.GridIndex == index then
                        isAdjacent = true
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTR then
                    if room.GridIndex == adyacentIndexes.D_LEFT or room.GridIndex == adyacentIndexes.DOWN_LEFT then
                        isAdjacent = true
                    end
                else
                    if room.GridIndex == adyacentIndexes.LEFT then
                        isAdjacent = true
                    end
                end

                if roomData.Shape == RoomShape.ROOMSHAPE_LBL then
                    if room.GridIndex == adyacentIndexes.D_UP or room.GridIndex == adyacentIndexes.UP_RIGHT then
                        isAdjacent = true
                    end
                else
                    if room.GridIndex == adyacentIndexes.UP then
                        isAdjacent = true
                    end
                end

                if roomData.Shape == RoomShape.ROOMSHAPE_LBR then
                    if room.GridIndex == adyacentIndexes.UP_D_LEFT or room.GridIndex == adyacentIndexes.D_UP_LEFT then
                        isAdjacent = true
                    end
                else
                    if room.GridIndex == adyacentIndexes.UP_RIGHT then
                        isAdjacent = true
                    end
                end
            end

            if (roomData.Type == RoomType.ROOM_BOSS or roomData.Type == RoomType.ROOM_ULTRASECRET) and isAdjacent then
                return true
            end
        end
    end
end


local function PrintPossibleRooms(possbile)
    local str = "rooms: "
    for _, index in pairs(possbile) do
        str = str .. index .. ", "
    end
    return str
end


local function GetPossibleEmptyRoomIndexes()
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    --Initialize a table with all adyacent rooms
    local possibleRooms = {}

    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)

        if room.Flags & RoomDescriptor.FLAG_RED_ROOM ~= RoomDescriptor.FLAG_RED_ROOM then
            local adyacentRooms = GetRoomIndexesAdyacentToRoom(room)

            for _, gridIndex in ipairs(adyacentRooms) do
                if gridIndex and gridIndex >= 0 and gridIndex <= 168 then
                    possibleRooms[gridIndex] = true
                end
            end
        end
    end

    --Remove indexes that are already rooms
    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)

        if room.Flags & RoomDescriptor.FLAG_RED_ROOM ~= RoomDescriptor.FLAG_RED_ROOM then
            local occupyingRooms = GetRoomIndexesThatRoomOccupies(room)

            for _, gridIndex in pairs(occupyingRooms) do
                possibleRooms[gridIndex] = nil
            end
        end
    end

    --Remove indexes that are completely accesible
    for roomIndex, _ in pairs(possibleRooms) do
        if not IsAccessibleIndexButCantBeRedRoom(roomIndex) then
            possibleRooms[roomIndex] = nil
        end
    end

    --Remove indexes that are next to some forbidden rooms
    for roomIndex, _ in pairs(possibleRooms) do
        if IsAdjacentToForbiddenRoom(roomIndex) then
            possibleRooms[roomIndex] = nil
        end
    end

    --We change the table so the room indexes are the values and not the keys
    local possibleRoomsList = {}
    for roomIndex, _ in pairs(possibleRooms) do
        table.insert(possibleRoomsList, roomIndex)
    end

    table.sort(possibleRoomsList)

    return possibleRoomsList
end


local function GetAdyacentRoomsAndDoorSlotThatConnectsToIndex(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local adyacentIndexes = GetAdyacentIndexes(index)

    local roomsAndDoorSlots = {}

    --Check for doors
    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)
        local roomData = room.Data
        local doors = roomData.Doors

        if room.Flags & RoomDescriptor.FLAG_RED_ROOM ~= RoomDescriptor.FLAG_RED_ROOM then
            --Normal rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
                roomData.Shape == RoomShape.ROOMSHAPE_IV then
                if room.GridIndex == adyacentIndexes.UP then
                    if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                    end
                end

                if room.GridIndex == adyacentIndexes.LEFT then
                    if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                    end
                end

                if room.GridIndex == adyacentIndexes.RIGHT then
                    if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                    end
                end

                if room.GridIndex == adyacentIndexes.DOWN then
                    if HasFlag(doors, 1 << DoorSlot.UP0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                    end
                end
            end

            --1x2 rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
                if room.GridIndex == adyacentIndexes.D_UP then
                    if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                    end
                end

                if room.GridIndex == adyacentIndexes.LEFT then
                    if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                    end
                end

                if room.GridIndex == adyacentIndexes.RIGHT then
                    if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                    end
                end

                if room.GridIndex == adyacentIndexes.UP_LEFT then
                    if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT1})
                    end
                end

                if room.GridIndex == adyacentIndexes.UP_RIGHT then
                    if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT1})
                    end
                end

                if room.GridIndex == adyacentIndexes.DOWN then
                    if HasFlag(doors, 1 << DoorSlot.UP0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                    end
                end
            end

            --2x1 rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
                if room.GridIndex == adyacentIndexes.UP then
                    if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                    end
                end

                if room.GridIndex == adyacentIndexes.UP_LEFT then
                    if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN1})
                    end
                end

                if room.GridIndex == adyacentIndexes.DOWN then
                    if HasFlag(doors, 1 << DoorSlot.UP0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                    end
                end

                if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                    if HasFlag(doors, 1 << DoorSlot.UP1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP1})
                    end
                end

                if room.GridIndex == adyacentIndexes.D_LEFT then
                    if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                    end
                end

                if room.GridIndex == adyacentIndexes.RIGHT then
                    if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                    end
                end
            end

            --Big rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x2 or roomData.Shape == RoomShape.ROOMSHAPE_LTL or
                roomData.Shape == RoomShape.ROOMSHAPE_LTR or roomData.Shape == RoomShape.ROOMSHAPE_LBL or
                roomData.Shape == RoomShape.ROOMSHAPE_LBR then

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTL then
                    if room.GridIndex == adyacentIndexes.DOWN then
                        if HasFlag(doors, 1 << DoorSlot.UP0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                        end
                    end

                    if room.GridIndex == adyacentIndexes.RIGHT then
                        if HasFlag(doors, 1 << DoorSlot.LEFT0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                        end
                    end
                else
                    if room.GridIndex == index then
                        if HasFlag(doors, 1 << DoorSlot.UP0 | 1 << DoorSlot.LEFT0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTR then
                    if room.GridIndex == adyacentIndexes.D_LEFT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                        end
                    end

                    if room.GridIndex == adyacentIndexes.DOWN_LEFT then
                        if HasFlag(doors, 1 << DoorSlot.UP1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP1})
                        end
                    end
                else
                    if room.GridIndex == adyacentIndexes.LEFT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT0 | 1 << DoorSlot.UP1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP1})
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LBL then
                    if room.GridIndex == adyacentIndexes.D_UP then
                        if HasFlag(doors, 1 << DoorSlot.DOWN0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                        end
                    end

                    if room.GridIndex == adyacentIndexes.UP_RIGHT then
                        if HasFlag(doors, 1 << DoorSlot.LEFT1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT1})
                        end
                    end
                else
                    if room.GridIndex == adyacentIndexes.UP then
                        if HasFlag(doors, 1 << DoorSlot.DOWN0 | 1 << DoorSlot.LEFT1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT1})
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LBR then
                    if room.GridIndex == adyacentIndexes.UP_D_LEFT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT1})
                        end
                    end

                    if room.GridIndex == adyacentIndexes.D_UP_LEFT then
                        if HasFlag(doors, 1 << DoorSlot.DOWN1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN1})
                        end
                    end
                else
                    if room.GridIndex == adyacentIndexes.UP_RIGHT then
                        if HasFlag(doors, 1 << DoorSlot.RIGHT1 | 1 << DoorSlot.DOWN1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN1})
                        end
                    end
                end
            end
        end
    end

    table.sort(roomsAndDoorSlots, function(a, b)
        return a.index > b.index
    end)

    return roomsAndDoorSlots
end


local function GetRoomAndDoorSlotForGlitchDoor()
    local possibleEmptyRooms = GetPossibleEmptyRoomIndexes()

    --We use the rng of the first player to be always consistent
    local itemRNGSeed = game:GetPlayer(0):GetCollectibleRNG(BAD_GATEWAY_ITEM):GetSeed()
    local itemRNG = RNG()
    itemRNG:SetSeed(itemRNGSeed, 35) --35 is the recommended shift

    local chosenEmptyRoom = possibleEmptyRooms[itemRNG:RandomInt(#possibleEmptyRooms) + 1]

    local roomsAndDoorSlots = GetAdyacentRoomsAndDoorSlotThatConnectsToIndex(chosenEmptyRoom)

    local chosenRoomAndDoorSlot = roomsAndDoorSlots[itemRNG:RandomInt(#roomsAndDoorSlots) + 1]

    print(chosenRoomAndDoorSlot.index .. ", " .. chosenRoomAndDoorSlot.doorSlot)
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

    GetRoomAndDoorSlotForGlitchDoor()
end

BadGatewayMod:AddCallback(ModCallbacks.MC_POST_UPDATE, BadGatewayMod.OnUpdate)


function BadGatewayMod:OnRender()
    if not MinimapAPI then return end

    for _, room in ipairs(MinimapAPI:GetLevel()) do
        local position = room.RenderOffset
        Isaac.RenderScaledText(room.Descriptor.GridIndex, position.X + 10, position.Y + 10, 0.5, 0.5, 1, 1, 1, 1)
        room.DisplayFlags = 1 << 0 | 1 << 1 | 1 << 2
    end

    if CanSpawnGlitchDoor() then
        Isaac.RenderText(PrintPossibleRooms(RoomsToPutDoor), 100, 100, 1, 1, 1, 1)
    end
end

BadGatewayMod:AddCallback(ModCallbacks.MC_POST_RENDER, BadGatewayMod.OnRender)