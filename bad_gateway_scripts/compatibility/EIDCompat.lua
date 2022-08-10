if not EID then return end

local function loadFile(loc, ...)
    local _, err = pcall(require, "")
    local modName = err:match("/mods/(.*)/%.lua")
    local path = "mods/" .. modName .. "/"
    return assert(loadfile(path .. loc .. ".lua"))(...)
end
local Constants = loadFile("bad_gateway_scripts/Constants")

EID:addCollectible(Constants.BAD_GATEWAY_ITEM,
    "#Opens a door to the error room somewhere on the floor after it's cleared" ..
    "#If it can't, drops {{Trinket75}}{{ColorObjName}}Error {{CR}}or {{Trinket138}}{{ColorObjName}}'M",
    "502 Bad Gateway",
    "en_us"
)

EID:addCollectible(Constants.BAD_GATEWAY_ITEM,
    "#Abre una puerta a la habitación de I Am Error en algun lugar de la planta cuando se ha derrotado al jefe" ..
    "#Si no puede, genera {{Trinket75}}{{ColorObjName}}Error {{CR}}o {{Trinket138}}{{ColorObjName}}'M",
    "502 Bad Gateway",
    "spa"
)