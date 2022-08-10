---@diagnostic disable: need-check-nil
local DoorManager = {}
local game = Game()

local function loadFile(loc, ...)
    local _, err = pcall(require, "")
    local modName = err:match("/mods/(.*)/%.lua")
    local path = "mods/" .. modName .. "/"
    return assert(loadfile(path .. loc .. ".lua"))(...)
end
RoomFinder = loadFile("bad_gateway_scripts/RoomFinder")
local Constants = loadFile("bad_gateway_scripts/Constants")
local Helpers = loadFile("bad_gateway_scripts/Helpers")

DoorManager.chosenRoomAndDoorSlotPerFloor = {}
local couldSpawnGlitchDoorBefore = false

local IsGoingToErrorRoom = false
local AreInErrorRoom = false


---Returns true if all boss rooms are clear
function DoorManager.AreAllBossRoomsCleared()
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


---Return true if the glitch door can be spawned
function DoorManager.CanSpawnGlitchDoor()
    local level = game:GetLevel()

    local isVoid = level:GetAbsoluteStage() == LevelStage.STAGE7
    local isHome = level:GetAbsoluteStage() == LevelStage.STAGE8

    local playersHave502 = Helpers.DoesAnyPlayerHaveItem(Constants.BAD_GATEWAY_ITEM)

    return DoorManager.AreAllBossRoomsCleared() and playersHave502 and not
    (isVoid or isHome or level:IsAscent() or level:IsPreAscent())
end


---Adds the room index and door slot tuple chosen for this floor
function DoorManager.GetRoomAndDoorSlotForGlitchDoor()
    local level = game:GetLevel()
    local possibleEmptyRooms = RoomFinder.GetPossibleEmptyRoomIndexes()

    --If there are no possible rooms for our door to appear, return nil
    if #possibleEmptyRooms == 0 then
        table.insert(DoorManager.chosenRoomAndDoorSlotPerFloor, {stage = level:GetStage(), room = nil, doorSlot = nil, hasSpawnedReward = false})
        return
    end

    --We use the rng of the first player to be always consistent
    local itemRNGSeed = game:GetPlayer(0):GetCollectibleRNG(Constants.BAD_GATEWAY_ITEM):GetSeed()
    local itemRNG = RNG()
    itemRNG:SetSeed(itemRNGSeed, 35) --35 is the recommended shift

    local chosenEmptyRoom = possibleEmptyRooms[itemRNG:RandomInt(#possibleEmptyRooms) + 1]

    local roomsAndDoorSlots = RoomFinder.GetAdyacentRoomsAndDoorSlotThatConnectsToIndex(chosenEmptyRoom)

    local chosenRoomAndDoorSlot = roomsAndDoorSlots[itemRNG:RandomInt(#roomsAndDoorSlots) + 1]

    table.insert(DoorManager.chosenRoomAndDoorSlotPerFloor, {stage = level:GetStage(), room = chosenRoomAndDoorSlot.index, doorSlot = chosenRoomAndDoorSlot.doorSlot, hasSpawnedReward = false})
end


---Return the current floor's selected room and doorSlot for the glitch door to appear in
---If it hasnt been alocated yet, return nil
function DoorManager.GetRoomAndDoorSlotForCurrentLevel()
    local level = game:GetLevel()

    for _, chosenRoomAndDoor in ipairs(DoorManager.chosenRoomAndDoorSlotPerFloor) do
        if level:GetStage() == chosenRoomAndDoor.stage then
            return chosenRoomAndDoor
        end
    end

    return nil
end


---Tries to alocate a room and a door for the glitch door if it hasnt been found already
function DoorManager.TryLocateRoomForGlitchDoor()
    --First we check if the door has already been alocated in this floor
    local HasDoorAlreadyBeenAlocated = DoorManager.GetRoomAndDoorSlotForCurrentLevel()

    --If we already calculated the door position for this floor, no need to do it again
    if not HasDoorAlreadyBeenAlocated then
        DoorManager.GetRoomAndDoorSlotForGlitchDoor()
    end
end


---This function spawns a glitch door in the specifed door slot
---@param doorSlot integer
function DoorManager.SpawnGlitchDoor(doorSlot)
    local room = game:GetRoom()

    local doorGridIndex = Constants.DOOR_SLOT_GRID_INDEXES[room:GetRoomShape()][doorSlot]
    local spawningPosition = room:GetGridPosition(doorGridIndex)

    local glitchDoor = Isaac.Spawn(EntityType.ENTITY_EFFECT, Constants.GLITCH_DOOR_VARIANT, 0, spawningPosition, Vector.Zero, nil)
    ---@type EntityEffect
    glitchDoor = glitchDoor:ToEffect()

    glitchDoor.DepthOffset = -50

    if doorSlot == DoorSlot.LEFT0 or doorSlot == DoorSlot.LEFT1 then
        glitchDoor.Position = Vector(glitchDoor.Position.X - 5, glitchDoor.Position.Y)
        glitchDoor.SpriteRotation = -90
    elseif doorSlot == DoorSlot.RIGHT0 or doorSlot == DoorSlot.RIGHT1 then
        glitchDoor.Position = Vector(glitchDoor.Position.X + 5, glitchDoor.Position.Y)
        glitchDoor.SpriteRotation = 90
    elseif doorSlot == DoorSlot.DOWN0 or doorSlot == DoorSlot.DOWN1 then
        glitchDoor.Position = Vector(glitchDoor.Position.X, glitchDoor.Position.Y + 5)
        glitchDoor.SpriteRotation = 180
    elseif doorSlot == DoorSlot.UP0 or doorSlot == DoorSlot.UP1 then
        glitchDoor.Position = Vector(glitchDoor.Position.X, glitchDoor.Position.Y - 5)
    end
end


---Checks if the glitch door should exist and spawns it if it should
function DoorManager.CheckIfGltichDoorShouldExist()
    local chosenRoomAndDoorSlot = DoorManager.GetRoomAndDoorSlotForCurrentLevel()

    --If it doesnt exist just return early
    if not chosenRoomAndDoorSlot or not chosenRoomAndDoorSlot.room then return end

    local level = game:GetLevel()
    local currentRoomIndex = level:GetCurrentRoomDesc().GridIndex

    if currentRoomIndex == chosenRoomAndDoorSlot.room and
    #Isaac.FindByType(EntityType.ENTITY_EFFECT, Constants.GLITCH_DOOR_VARIANT) == 0 then
        --Glitch door should exist but doesnt, spawn it
        for doorSlot = 0, DoorSlot.NUM_DOOR_SLOTS, 1 do
            if doorSlot == chosenRoomAndDoorSlot.doorSlot then
                DoorManager.SpawnGlitchDoor(doorSlot)
            end
        end
    end
end


---Sets up everything need to start the transition to the error room
function DoorManager.StartTransitionToErrorRoom()
    IsGoingToErrorRoom = true
    SFXManager():Play(SoundEffect.SOUND_EDEN_GLITCH)

    for i = 0, game:GetNumPlayers() - 1, 1 do
        local player = game:GetPlayer(i)

        player.Velocity = Vector.Zero
        player.ControlsEnabled = false
    end
end


---Makes everything back to normal when arriving at the error room
function DoorManager.ArriveAtErrorRoom()
    AreInErrorRoom = false

    for i = 0, game:GetNumPlayers() - 1, 1 do
        local player = game:GetPlayer(i)

        --Only the player who touched the door plays the animation
        if player:GetData().IsPlayerWhoTouchedTheDoor then
            player:QueueExtraAnimation("Glitch")
            player:GetData().IsPlayerWhoTouchedTheDoor = nil
        end

        player.ControlsEnabled = true
    end
end


function DoorManager:OnFrameUpdate()
    DoorManager.TryLocateRoomForGlitchDoor()
    local canSpawnGlitchDoorNow = DoorManager.CanSpawnGlitchDoor()

    if canSpawnGlitchDoorNow then
        DoorManager.CheckIfGltichDoorShouldExist()
    end

    --If we can spawn the glitch door now and we couldnt the frame before, play the sound and glitch animation
    if canSpawnGlitchDoorNow and not couldSpawnGlitchDoorBefore then
        local chosenRoomAndDoorSlot = DoorManager.GetRoomAndDoorSlotForCurrentLevel()

        if not chosenRoomAndDoorSlot.room and not chosenRoomAndDoorSlot.hasSpawnedReward then
            --If theres not a room, and we havent yet, spawn a trinket
            chosenRoomAndDoorSlot.hasSpawnedReward = true

            local room = game:GetRoom()

            for i = 0, game:GetNumPlayers() - 1, 1 do
                local player = game:GetPlayer(i)

                if player:HasCollectible(Constants.BAD_GATEWAY_ITEM) then
                    local itemRNGSeed = player:GetCollectibleRNG(Constants.BAD_GATEWAY_ITEM):GetSeed()
                    local itemRNG = RNG()
                    itemRNG:SetSeed(itemRNGSeed, 35) --35 is the recommended shift

                    --We advance the rng once for each stage
                    for _ = 1, chosenRoomAndDoorSlot.stage, 1 do
                        itemRNG:Next()
                    end

                    local chosenTrinket = Constants.BAD_GATEWAY_TRINKETS[itemRNG:RandomInt(#Constants.BAD_GATEWAY_TRINKETS) + 1]
                    local spawningPos = room:FindFreePickupSpawnPosition(player.Position, 1, true)

                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, chosenTrinket, spawningPos, Vector.Zero, nil)
                end
            end
        elseif chosenRoomAndDoorSlot.room then
            --If theres a room, play the sound and glitch animation
            SFXManager():Play(Constants.GATEWAY_APPEAR_SFX)

            for i = 0, game:GetNumPlayers() - 1, 1 do
                local player = game:GetPlayer(i)

                if player:HasCollectible(Constants.BAD_GATEWAY_ITEM) then
                    player:QueueExtraAnimation("Glitch")
                end
            end
        end
    end

    couldSpawnGlitchDoorBefore = canSpawnGlitchDoorNow

    --If we're going to the error room, stop everything in the room
    if IsGoingToErrorRoom then
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            entity.Velocity = Vector.Zero
        end
    end
end


function DoorManager:OnGameStart()
    DoorManager.chosenRoomAndDoorSlotPerFloor = {}
    IsGoingToErrorRoom = false
end


function DoorManager:OnGlitchDoorUpdate(glitchDoor)
    --We dont need to check for collision if we already collided
    if IsGoingToErrorRoom then return end

    --If the glitch door cannot be spawned anymore, remove the door
    if not DoorManager.CanSpawnGlitchDoor() then
        glitchDoor:Remove()
        return
    end

    local playerWhoCollided = nil

    for i = 0, game:GetNumPlayers() - 1, 1 do
        local player = game:GetPlayer(i)

        if (player.Position - glitchDoor.Position):Length() < Constants.DISTANCE_TO_GLITCH_DOOR then
            --We have a collision!
            playerWhoCollided = player
        end
    end

    --If we havent found a player who collided with the door, return early
    if not playerWhoCollided then return end

    playerWhoCollided:PlayExtraAnimation("Glitch")
    playerWhoCollided:GetData().IsPlayerWhoTouchedTheDoor = true

    DoorManager.StartTransitionToErrorRoom()
end


---@param player EntityPlayer
function DoorManager:OnPlayerUpdate(player)
    --We only care about the player who touched the door
    if not player:GetData().IsPlayerWhoTouchedTheDoor then return end

    --If we are not transitioning to the error room ignore the rest
    if not IsGoingToErrorRoom then return end

    if player:IsExtraAnimationFinished() then
        IsGoingToErrorRoom = false
        AreInErrorRoom = true

        --We need to set level.LeaveDoor to -1 for game:ChangeRoom() to work properly
        local level = game:GetLevel()
        level.LeaveDoor = -1

        --Going to room index -2 means going to the error room
        game:ChangeRoom(-2, -1)
    end
end


function DoorManager:OnNewRoom()
    local canSpawnGlitchDoorNow = DoorManager.CanSpawnGlitchDoor()

    if canSpawnGlitchDoorNow then
        DoorManager.CheckIfGltichDoorShouldExist()
    end

    if AreInErrorRoom then
        DoorManager.ArriveAtErrorRoom()
    end
end


function DoorManager.AddCallbacks(mod)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, DoorManager.OnFrameUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, DoorManager.OnGameStart)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, DoorManager.OnGlitchDoorUpdate, Constants.GLITCH_DOOR_VARIANT)
    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, DoorManager.OnPlayerUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DoorManager.OnNewRoom)
end


return DoorManager