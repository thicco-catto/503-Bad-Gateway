local Helpers = {}
local game = Game()

---Returns whether a certain bitmask has a mask
---@return boolean
function Helpers.HasFlag(toCheck, flag)
    return toCheck & flag == flag
end


---Returns whether any player has an specified item
---@param item any
---@return boolean
function Helpers.DoesAnyPlayerHaveItem(item)
    for i = 0, game:GetNumPlayers() - 1, 1 do
        local player = game:GetPlayer(i)
        if player:HasCollectible(item) then
            return true
        end
    end

    return false
end


function Helpers.GetDimension(level)
    local roomIndex = level:GetCurrentRoomIndex()

    for i = 0, 2 do
        if GetPtrHash(level:GetRoomByIdx(roomIndex, i)) == GetPtrHash(level:GetRoomByIdx(roomIndex, -1)) then
            return i
        end
    end
    
    return nil
end


return Helpers