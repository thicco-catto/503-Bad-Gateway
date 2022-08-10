local SaveManager = {}
local BadGateWayMod = nil
local DoorManager = {}
local json = require("json")


function SaveManager.ContinueGame()
    --if there is no data no need to worry
    if not BadGateWayMod:HasData() then return end

    local encodedData = BadGateWayMod:LoadData()
    DoorManager.chosenRoomAndDoorSlotPerFloor = json.decode(encodedData)
end


function SaveManager.NewGame()
    DoorManager.chosenRoomAndDoorSlotPerFloor = {}
end


function SaveManager:OnGameStart(isContinue)
    if isContinue then
       SaveManager.ContinueGame()
    else
        SaveManager.NewGame()
    end
end


function SaveManager:OnGameExit()
    local encodedData = json.encode(DoorManager.chosenRoomAndDoorSlotPerFloor)
    BadGateWayMod:SaveData(encodedData)
end


function SaveManager.AddCallbacks(mod)
    BadGateWayMod = mod
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, SaveManager.OnGameStart)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveManager.OnGameExit)
end


function SaveManager.AddDoorManager(doorManager)
    DoorManager = doorManager
end

return SaveManager