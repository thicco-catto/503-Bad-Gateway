local RoomFinder = {}
local game = Game()

local function loadFile(loc, ...)
    local _, err = pcall(require, "")
    local modName = err:match("/mods/(.*)/%.lua")
    local path = "mods/" .. modName .. "/"
    return assert(loadfile(path .. loc .. ".lua"))(...)
end
local Helpers = loadFile("bad_gateway_scripts/Helpers")

---Returns a table with adyacent indexes and indirectly adjacent indexes (distance of 2)
---Invalid indexes will be -1
---@param index integer
---@return table
function RoomFinder.GetAdjacentIndexes(index)
    local adjacentIndexes = {}

    adjacentIndexes.UP = index - 13
    adjacentIndexes.D_UP = index - 26

    adjacentIndexes.DOWN = index + 13
    adjacentIndexes.D_DOWN = index + 26

    --Is directly adyacent to the left
    if index % 13 == 0 then
        adjacentIndexes.LEFT = -1

        adjacentIndexes.UP_LEFT = -1
        adjacentIndexes.D_UP_LEFT = -1

        adjacentIndexes.DOWN = -1
        adjacentIndexes.D_DOWN = -1
    else
        adjacentIndexes.LEFT = index - 1

        adjacentIndexes.UP_LEFT = adjacentIndexes.UP - 1
        adjacentIndexes.D_UP_LEFT = adjacentIndexes.D_UP - 1

        adjacentIndexes.DOWN_LEFT = adjacentIndexes.DOWN - 1
        adjacentIndexes.D_DOWN_LEFT = adjacentIndexes.D_DOWN - 1
    end

    --Is indirectly adyacent to the left
    if index % 13 == 0 or index % 13 == 1 then
        adjacentIndexes.D_LEFT = -1

        adjacentIndexes.UP_D_LEFT = -1
        adjacentIndexes.D_UP_D_LEFT = -1

        adjacentIndexes.DOWN_D_LEFT = -1
        adjacentIndexes.D_DOWN_D_LEFT = -1
    else
        adjacentIndexes.D_LEFT = index - 2

        adjacentIndexes.UP_D_LEFT = adjacentIndexes.UP - 2
        adjacentIndexes.D_UP_D_LEFT = adjacentIndexes.D_UP - 2

        adjacentIndexes.DOWN_D_LEFT = adjacentIndexes.DOWN - 2
        adjacentIndexes.D_DOWN_D_LEFT = adjacentIndexes.D_DOWN - 2
    end

    --Is directly adyacent to the right
    if index % 13 == 12 then
        adjacentIndexes.RIGHT = -1

        adjacentIndexes.UP_RIGHT = -1
        adjacentIndexes.D_UP_RIGHT = -1

        adjacentIndexes.DOWN = -1
        adjacentIndexes.D_DOWN = -1
    else
        adjacentIndexes.RIGHT = index + 1

        adjacentIndexes.UP_RIGHT = adjacentIndexes.UP + 1
        adjacentIndexes.D_UP_RIGHT = adjacentIndexes.D_UP + 1

        adjacentIndexes.DOWN_RIGHT = adjacentIndexes.DOWN + 1
        adjacentIndexes.D_DOWN_RIGHT = adjacentIndexes.D_DOWN + 1
    end

    --Is indirectly adyacent to the right
    if index % 13 == 12 or index % 13 == 11 then
        adjacentIndexes.D_RIGHT = -1

        adjacentIndexes.UP_D_RIGHT = -1
        adjacentIndexes.D_UP_D_RIGHT = -1

        adjacentIndexes.DOWN_D_RIGHT = -1
        adjacentIndexes.D_DOWN_D_RIGHT = -1
    else
        adjacentIndexes.D_RIGHT = index + 2

        adjacentIndexes.UP_D_RIGHT = adjacentIndexes.UP + 2
        adjacentIndexes.D_UP_D_RIGHT = adjacentIndexes.D_UP + 2

        adjacentIndexes.DOWN_D_RIGHT = adjacentIndexes.DOWN + 2
        adjacentIndexes.D_DOWN_D_RIGHT = adjacentIndexes.D_DOWN + 2
    end

    return adjacentIndexes
end


---Returns a list of all the room indexes directly adyacent to rooms
---@param room RoomDescriptor
---@return table
function RoomFinder.GetRoomIndexesAdjacentToRoom(room)
    local roomData = room.Data

    local adjacentIndexes = RoomFinder.GetAdjacentIndexes(room.GridIndex)

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
        roomData.Shape == RoomShape.ROOMSHAPE_IV then
        --1x1 rooms take their grid
        return { adjacentIndexes.UP, adjacentIndexes.RIGHT, adjacentIndexes.LEFT, adjacentIndexes.DOWN }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        --1x2 rooms take their grid and the one below
        return { adjacentIndexes.UP, adjacentIndexes.LEFT, adjacentIndexes.LEFT_DOWN, adjacentIndexes.RIGHT,
            adjacentIndexes.RIGHT_DOWN, adjacentIndexes.D_DOWN }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        --2x1 rooms take their grid and the one to the right
        return { adjacentIndexes.UP, adjacentIndexes.UP_RIGHT, adjacentIndexes.LEFT, adjacentIndexes.D_RIGHT,
            adjacentIndexes.DOWN, adjacentIndexes.DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
        --2x2 rooms take their grid, the one below, the one to the right and the one diagonally
        return { adjacentIndexes.UP, adjacentIndexes.UP_RIGHT, adjacentIndexes.LEFT, adjacentIndexes.LEFT_DOWN,
            adjacentIndexes.D_RIGHT, adjacentIndexes.D_RIGHT_DOWN, adjacentIndexes.D_DOWN, adjacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTL then
        --LTL rooms dont take their own grid index
        return { room.GridIndex, adjacentIndexes.UP_RIGHT, adjacentIndexes.LEFT_DOWN, adjacentIndexes.D_RIGHT,
            adjacentIndexes.D_RIGHT_DOWN, adjacentIndexes.D_DOWN, adjacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTR then
        --LTR rooms dont take the index to the right
        return { adjacentIndexes.UP, adjacentIndexes.LEFT, adjacentIndexes.LEFT_DOWN, adjacentIndexes.RIGHT,
            adjacentIndexes.D_RIGHT_DOWN, adjacentIndexes.D_DOWN, adjacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBL then
        --LBL rooms dont take the index below
        return { adjacentIndexes.UP, adjacentIndexes.UP_RIGHT, adjacentIndexes.LEFT, adjacentIndexes.D_RIGHT,
            adjacentIndexes.D_RIGHT_DOWN, adjacentIndexes.DOWN, adjacentIndexes.D_DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBR then
        --LBR rooms dont take the index diagonally
        return { adjacentIndexes.UP, adjacentIndexes.UP_RIGHT, adjacentIndexes.LEFT, adjacentIndexes.LEFT_DOWN,
            adjacentIndexes.D_RIGHT, adjacentIndexes.RIGHT_DOWN, adjacentIndexes.D_DOWN }
    end

    return {}
end


---Returns a list of all the room indexes that a room occupies
---@param room RoomDescriptor
---@return table
function RoomFinder.GetRoomIndexesThatRoomOccupies(room)
    local roomData = room.Data
    local adjacentIndexes = RoomFinder.GetAdjacentIndexes(room.GridIndex)

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
        roomData.Shape == RoomShape.ROOMSHAPE_IV then
        --1x1 rooms only take their grid index
        return { room.GridIndex }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        --1x2 rooms take their grid and the one below
        return { room.GridIndex, adjacentIndexes.DOWN }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        --2x1 rooms take their grid and the one to the right
        return { room.GridIndex, adjacentIndexes.RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_2x2 then
        --2x2 rooms take their grid, the one below, the one to the right and the one diagonally
        return { room.GridIndex, adjacentIndexes.RIGHT, adjacentIndexes.DOWN, adjacentIndexes.DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTL then
        --LTL rooms dont take their own grid index
        return { adjacentIndexes.RIGHT, adjacentIndexes.DOWN, adjacentIndexes.DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LTR then
        --LTR rooms dont take the index to the right
        return { room.GridIndex, adjacentIndexes.DOWN, adjacentIndexes.DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBL then
        --LBL rooms dont take the index below
        return { room.GridIndex, adjacentIndexes.RIGHT, adjacentIndexes.DOWN_RIGHT }
    elseif roomData.Shape == RoomShape.ROOMSHAPE_LBR then
        --LBR rooms dont take the index diagonally
        return { room.GridIndex, adjacentIndexes.RIGHT, adjacentIndexes.DOWN }
    end

    return {}
end


---Returns true if a room is adyacent to a given room index. Ignores accesibility.
---@param room RoomDescriptor
---@param index integer
function RoomFinder.IsRoomAdjacentToIndex(room, index)
    local roomData = room.Data
    local adjacentIndexes = RoomFinder.GetAdjacentIndexes(index)

    --1x1 rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
        roomData.Shape == RoomShape.ROOMSHAPE_IV then
        if room.GridIndex == adjacentIndexes.UP or room.GridIndex == adjacentIndexes.LEFT or
            room.GridIndex == adjacentIndexes.RIGHT or room.GridIndex == adjacentIndexes.DOWN then
            return true
        end
    end

    --1x2 rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        if room.GridIndex == adjacentIndexes.D_UP or room.GridIndex == adjacentIndexes.LEFT or
            room.GridIndex == adjacentIndexes.RIGHT or room.GridIndex == adjacentIndexes.UP_LEFT or
            room.GridIndex == adjacentIndexes.UP_RIGHT or room.GridIndex == adjacentIndexes.DOWN then
            return true
        end
    end

    --2x1 rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        if room.GridIndex == adjacentIndexes.UP or room.GridIndex == adjacentIndexes.UP_LEFT or
            room.GridIndex == adjacentIndexes.DOWN or room.GridIndex == adjacentIndexes.DOWN_LEFT or
            room.GridIndex == adjacentIndexes.D_LEFT or room.GridIndex == adjacentIndexes.RIGHT then
            return true
        end
    end

    --Big rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_2x2 or roomData.Shape == RoomShape.ROOMSHAPE_LTL or
        roomData.Shape == RoomShape.ROOMSHAPE_LTR or roomData.Shape == RoomShape.ROOMSHAPE_LBL or
        roomData.Shape == RoomShape.ROOMSHAPE_LBR then

        if roomData.Shape ~= RoomShape.ROOMSHAPE_LTL then
            if room.GridIndex == adjacentIndexes.DOWN or room.GridIndex == adjacentIndexes.RIGHT then
                return true
            end
        else
            if room.GridIndex == index then
                return true
            end
        end

        if roomData.Shape ~= RoomShape.ROOMSHAPE_LTR then
            if room.GridIndex == adjacentIndexes.D_LEFT or room.GridIndex == adjacentIndexes.DOWN_LEFT then
                return true
            end
        else
            if room.GridIndex == adjacentIndexes.LEFT then
                return true
            end
        end

        if roomData.Shape == RoomShape.ROOMSHAPE_LBL then
            if room.GridIndex == adjacentIndexes.D_UP or room.GridIndex == adjacentIndexes.UP_RIGHT then
                return true
            end
        else
            if room.GridIndex == adjacentIndexes.UP then
                return true
            end
        end

        if roomData.Shape == RoomShape.ROOMSHAPE_LBR then
            if room.GridIndex == adjacentIndexes.UP_D_LEFT or room.GridIndex == adjacentIndexes.D_UP_LEFT then
                return true
            end
        else
            if room.GridIndex == adjacentIndexes.UP_RIGHT then
                return true
            end
        end
    end

    return false
end


---Returns true if a room is adyacent to a given room index and if it has a door pointing to that index.
---@param room RoomDescriptor
---@param index integer
function RoomFinder.IsRoomAccesibleFromIndex(room, index)
    local adjacentIndexes = RoomFinder.GetAdjacentIndexes(index)
    local roomData = room.Data
    local doors = roomData.Doors

    if roomData.Shape == RoomShape.ROOMSHAPE_1x1 or roomData.Shape == RoomShape.ROOMSHAPE_IH or
        roomData.Shape == RoomShape.ROOMSHAPE_IV then
        if room.GridIndex == adjacentIndexes.UP then
            if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.LEFT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.RIGHT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.DOWN then
            if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                return true
            end
        end
    end

    --1x2 rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
        if room.GridIndex == adjacentIndexes.D_UP then
            if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.LEFT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.RIGHT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.UP_LEFT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.UP_RIGHT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT1) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.DOWN then
            if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                return true
            end
        end
    end

    --2x1 rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
        if room.GridIndex == adjacentIndexes.UP then
            if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.UP_LEFT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN1) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.DOWN then
            if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.DOWN_LEFT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.UP1) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.D_LEFT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                return true
            end
        end

        if room.GridIndex == adjacentIndexes.RIGHT then
            if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                return true
            end
        end
    end

    --Big rooms
    if roomData.Shape == RoomShape.ROOMSHAPE_2x2 or roomData.Shape == RoomShape.ROOMSHAPE_LTL or
        roomData.Shape == RoomShape.ROOMSHAPE_LTR or roomData.Shape == RoomShape.ROOMSHAPE_LBL or
        roomData.Shape == RoomShape.ROOMSHAPE_LBR then

        if roomData.Shape ~= RoomShape.ROOMSHAPE_LTL then
            if room.GridIndex == adjacentIndexes.DOWN then
                if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                    return true
                end
            end

            if room.GridIndex == adjacentIndexes.RIGHT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                    return true
                end
            end
        else
            if room.GridIndex == index then
                if Helpers.HasFlag(doors, 1 << DoorSlot.UP0 | 1 << DoorSlot.LEFT0) then
                    return true
                end
            end
        end

        if roomData.Shape ~= RoomShape.ROOMSHAPE_LTR then
            if room.GridIndex == adjacentIndexes.D_LEFT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                    return true
                end
            end

            if room.GridIndex == adjacentIndexes.DOWN_LEFT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.UP1) then
                    return true
                end
            end
        else
            if room.GridIndex == adjacentIndexes.LEFT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0 | 1 << DoorSlot.UP1) then
                    return true
                end
            end
        end

        if roomData.Shape ~= RoomShape.ROOMSHAPE_LBL then
            if room.GridIndex == adjacentIndexes.D_UP then
                if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                    return true
                end
            end

            if room.GridIndex == adjacentIndexes.UP_RIGHT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT1) then
                    return true
                end
            end
        else
            if room.GridIndex == adjacentIndexes.UP then
                if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0 | 1 << DoorSlot.LEFT1) then
                    return true
                end
            end
        end

        if roomData.Shape ~= RoomShape.ROOMSHAPE_LBR then
            if room.GridIndex == adjacentIndexes.UP_D_LEFT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                    return true
                end
            end

            if room.GridIndex == adjacentIndexes.D_UP_LEFT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        else
            if room.GridIndex == adjacentIndexes.UP_RIGHT then
                if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT1 | 1 << DoorSlot.DOWN1) then
                    isAccessbileFromAtLeastOne = true
                else
                    isNotAccessibleFromAtLeastOne = true
                end
            end
        end
    end

    return false
end


---Returns true if a room is accesible from at least one room and inaccesible from at least other room.
---@param index integer
---@return boolean
function RoomFinder.IsAccessibleIndexButCantBeRedRoom(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local isNotAccessibleFromAtLeastOne = false
    local isAccessbileFromAtLeastOne = false

    --Check for doors
    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)

        if not Helpers.HasFlag(room.Flags, RoomDescriptor.FLAG_RED_ROOM) then
            if RoomFinder.IsRoomAccesibleFromIndex(room, index) then
                isAccessbileFromAtLeastOne = true
            end

            if RoomFinder.IsRoomAdjacentToIndex(room, index) and not RoomFinder.IsRoomAccesibleFromIndex(room, index) then
                isNotAccessibleFromAtLeastOne = true
            end
        end
    end

    return isNotAccessibleFromAtLeastOne and isAccessbileFromAtLeastOne
end


---Returns true if a room is adyacent to a boss room or an ultra secret room.
---@param index integer
---@return boolean
function RoomFinder.IsIndexAdjacentToForbiddenRoom(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)
        local roomData = room.Data

        if not Helpers.HasFlag(room.Flags, RoomDescriptor.FLAG_RED_ROOM) then
            if (roomData.Type == RoomType.ROOM_BOSS or roomData.Type == RoomType.ROOM_ULTRASECRET) and
            RoomFinder.IsRoomAdjacentToIndex(room, index) then
                return true
            end
        end
    end

    return false
end


---Returns a list of all the possible room indexes that cant be red rooms and arent adyacent to forbidden rooms
---@return table
function RoomFinder.GetPossibleEmptyRoomIndexes()
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    --Initialize a table with all adyacent rooms
    local possibleRooms = {}

    for i = 0, rooms.Size - 1, 1 do
        local room = rooms:Get(i)

        if not Helpers.HasFlag(room.Flags, RoomDescriptor.FLAG_RED_ROOM) then
            local adyacentRooms = RoomFinder.GetRoomIndexesAdjacentToRoom(room)

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

        if not Helpers.HasFlag(room.Flags, RoomDescriptor.FLAG_RED_ROOM) then
            local occupyingRooms = RoomFinder.GetRoomIndexesThatRoomOccupies(room)

            for _, gridIndex in pairs(occupyingRooms) do
                possibleRooms[gridIndex] = nil
            end
        end
    end

    --Remove indexes that are completely accesible
    for roomIndex, _ in pairs(possibleRooms) do
        if not RoomFinder.IsAccessibleIndexButCantBeRedRoom(roomIndex) then
            possibleRooms[roomIndex] = nil
        end
    end

    --Remove indexes that are next to some forbidden rooms
    for roomIndex, _ in pairs(possibleRooms) do
        if RoomFinder.IsIndexAdjacentToForbiddenRoom(roomIndex) then
            possibleRooms[roomIndex] = nil
        end
    end

    --We change the table so the room indexes are the values and not the keys
    local possibleRoomsList = {}
    for roomIndex, _ in pairs(possibleRooms) do
        table.insert(possibleRoomsList, roomIndex)
    end

    --Sort the list so we always end up choosing the same spot
    table.sort(possibleRoomsList)

    return possibleRoomsList
end


---Returns a list of tuples of each adyacent room and what DoorSlot is accesible to a respective index
---@return table
function RoomFinder.GetAdyacentRoomsAndDoorSlotThatConnectsToIndex(index)
    local level = game:GetLevel()
    local rooms = level:GetRooms()

    local adjacentIndexes = RoomFinder.GetAdjacentIndexes(index)

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
                if room.GridIndex == adjacentIndexes.UP then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                    end
                end

                if room.GridIndex == adjacentIndexes.LEFT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                    end
                end

                if room.GridIndex == adjacentIndexes.RIGHT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                    end
                end

                if room.GridIndex == adjacentIndexes.DOWN then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                    end
                end
            end

            --1x2 rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_1x2 or roomData.Shape == RoomShape.ROOMSHAPE_IIV then
                if room.GridIndex == adjacentIndexes.D_UP then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                    end
                end

                if room.GridIndex == adjacentIndexes.LEFT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                    end
                end

                if room.GridIndex == adjacentIndexes.RIGHT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                    end
                end

                if room.GridIndex == adjacentIndexes.UP_LEFT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT1})
                    end
                end

                if room.GridIndex == adjacentIndexes.UP_RIGHT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT1})
                    end
                end

                if room.GridIndex == adjacentIndexes.DOWN then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                    end
                end
            end

            --2x1 rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x1 or roomData.Shape == RoomShape.ROOMSHAPE_IIH then
                if room.GridIndex == adjacentIndexes.UP then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                    end
                end

                if room.GridIndex == adjacentIndexes.UP_LEFT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN1})
                    end
                end

                if room.GridIndex == adjacentIndexes.DOWN then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                    end
                end

                if room.GridIndex == adjacentIndexes.DOWN_LEFT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.UP1) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP1})
                    end
                end

                if room.GridIndex == adjacentIndexes.D_LEFT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                    end
                end

                if room.GridIndex == adjacentIndexes.RIGHT then
                    if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                        table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                    end
                end
            end

            --Big rooms
            if roomData.Shape == RoomShape.ROOMSHAPE_2x2 or roomData.Shape == RoomShape.ROOMSHAPE_LTL or
                roomData.Shape == RoomShape.ROOMSHAPE_LTR or roomData.Shape == RoomShape.ROOMSHAPE_LBL or
                roomData.Shape == RoomShape.ROOMSHAPE_LBR then

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTL then
                    if room.GridIndex == adjacentIndexes.DOWN then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.UP0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP0})
                        end
                    end

                    if room.GridIndex == adjacentIndexes.RIGHT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                        end
                    end
                else
                    if room.GridIndex == index then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.UP0 | 1 << DoorSlot.LEFT0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT0})
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LTR then
                    if room.GridIndex == adjacentIndexes.D_LEFT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT0})
                        end
                    end

                    if room.GridIndex == adjacentIndexes.DOWN_LEFT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.UP1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP1})
                        end
                    end
                else
                    if room.GridIndex == adjacentIndexes.LEFT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT0 | 1 << DoorSlot.UP1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.UP1})
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LBL then
                    if room.GridIndex == adjacentIndexes.D_UP then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN0})
                        end
                    end

                    if room.GridIndex == adjacentIndexes.UP_RIGHT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.LEFT1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT1})
                        end
                    end
                else
                    if room.GridIndex == adjacentIndexes.UP then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN0 | 1 << DoorSlot.LEFT1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.LEFT1})
                        end
                    end
                end

                if roomData.Shape ~= RoomShape.ROOMSHAPE_LBR then
                    if room.GridIndex == adjacentIndexes.UP_D_LEFT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.RIGHT1})
                        end
                    end

                    if room.GridIndex == adjacentIndexes.D_UP_LEFT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.DOWN1) then
                            table.insert(roomsAndDoorSlots, {index = room.GridIndex, doorSlot = DoorSlot.DOWN1})
                        end
                    end
                else
                    if room.GridIndex == adjacentIndexes.UP_RIGHT then
                        if Helpers.HasFlag(doors, 1 << DoorSlot.RIGHT1 | 1 << DoorSlot.DOWN1) then
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


return RoomFinder
