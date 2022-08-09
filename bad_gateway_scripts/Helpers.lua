local Helpers = {}
local game = Game()

---Returns whether a certain bitmask has a mask
---@return boolean
function Helpers.HasFlag(toCheck, flag)
    return toCheck & flag == flag
end


---Returns whether any player has an specified mask
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

return Helpers