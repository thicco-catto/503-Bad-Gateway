local Constants = {}

Constants.BAD_GATEWAY_ITEM = Isaac.GetItemIdByName("502")
Constants.GATEWAY_APPEAR_SFX = Isaac.GetSoundIdByName("502 appear")

Constants.BAD_GATEWAY_TRINKETS = {
    TrinketType.TRINKET_ERROR,
    TrinketType.TRINKET_M
}

Constants.GLITCH_DOOR_VARIANT = Isaac.GetEntityVariantByName("glitch door")

Constants.DISTANCE_TO_GLITCH_DOOR = 38

local doorSlotsGridIndexes1x1 = {
    [DoorSlot.LEFT0] = 60,
    [DoorSlot.UP0] = 7,
    [DoorSlot.RIGHT0] = 74,
    [DoorSlot.DOWN0] = 127,
}

local doorSlotsGridIndexes1x2 = {
    [DoorSlot.LEFT0] = 60,
    [DoorSlot.UP0] = 7,
    [DoorSlot.RIGHT0] = 74,
    [DoorSlot.DOWN0] = 232,
    [DoorSlot.LEFT1] = 165,
    [DoorSlot.RIGHT1] = 179,
}

local doorSlotsGridIndexes2x1 = {
    [DoorSlot.LEFT0] = 112,
    [DoorSlot.UP0] = 7,
    [DoorSlot.RIGHT0] = 139,
    [DoorSlot.DOWN0] = 231,
    [DoorSlot.UP1] = 20,
    [DoorSlot.DOWN1] = 244,
}

Constants.DOOR_SLOT_GRID_INDEXES = {
    [RoomShape.ROOMSHAPE_1x1] = doorSlotsGridIndexes1x1,
    [RoomShape.ROOMSHAPE_IH] = doorSlotsGridIndexes1x1,
    [RoomShape.ROOMSHAPE_IV] = doorSlotsGridIndexes1x1,

    [RoomShape.ROOMSHAPE_1x2] = doorSlotsGridIndexes1x2,
    [RoomShape.ROOMSHAPE_IIV] = doorSlotsGridIndexes1x2,

    [RoomShape.ROOMSHAPE_1x2] = doorSlotsGridIndexes2x1,
    [RoomShape.ROOMSHAPE_IIV] = doorSlotsGridIndexes2x1,

    [RoomShape.ROOMSHAPE_2x2] = {
        [DoorSlot.LEFT0] = 112,
        [DoorSlot.UP0] = 7,
        [DoorSlot.RIGHT0] = 139,
        [DoorSlot.DOWN0] = 427,
        [DoorSlot.LEFT1] = 308,
        [DoorSlot.UP1] = 20,
        [DoorSlot.RIGHT1] = 335,
        [DoorSlot.DOWN1] = 440,
    },

    [RoomShape.ROOMSHAPE_LTL] = {
        [DoorSlot.LEFT0] = 125,
        [DoorSlot.UP0] = 203,
        [DoorSlot.RIGHT0] = 139,
        [DoorSlot.DOWN0] = 427,
        [DoorSlot.LEFT1] = 308,
        [DoorSlot.UP1] = 20,
        [DoorSlot.RIGHT1] = 335,
        [DoorSlot.DOWN1] = 440,
    },

    [RoomShape.ROOMSHAPE_LTR] = {
        [DoorSlot.LEFT0] = 112,
        [DoorSlot.UP0] = 7,
        [DoorSlot.RIGHT0] = 126,
        [DoorSlot.DOWN0] = 427,
        [DoorSlot.LEFT1] = 308,
        [DoorSlot.UP1] = 216,
        [DoorSlot.RIGHT1] = 335,
        [DoorSlot.DOWN1] = 440,
    },

    [RoomShape.ROOMSHAPE_LBL] = {
        [DoorSlot.LEFT0] = 112,
        [DoorSlot.UP0] = 7,
        [DoorSlot.RIGHT0] = 139,
        [DoorSlot.DOWN0] = 231,
        [DoorSlot.LEFT1] = 321,
        [DoorSlot.UP1] = 20,
        [DoorSlot.RIGHT1] = 335,
        [DoorSlot.DOWN1] = 440,
    },

    [RoomShape.ROOMSHAPE_LBR] = {
        [DoorSlot.LEFT0] = 112,
        [DoorSlot.UP0] = 7,
        [DoorSlot.RIGHT0] = 139,
        [DoorSlot.DOWN0] = 427,
        [DoorSlot.LEFT1] = 308,
        [DoorSlot.UP1] = 20,
        [DoorSlot.RIGHT1] = 322,
        [DoorSlot.DOWN1] = 244,
    }
}

--For minimapi
Constants.GLITCH_DOOR_ICON_ID = "GlitchDoorMinimapIcon"

return Constants