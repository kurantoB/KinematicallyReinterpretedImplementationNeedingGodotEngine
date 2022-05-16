enum UnitType {
	PLAYER,
}

enum ActionType {
	JUMP,
	MOVE,
}

enum UnitCondition {
	CURRENT_ACTION,
	IS_ON_GROUND,
	MOVING_STATUS,
}

enum UnitCurrentAction {
	IDLE,
	JUMPING,
}

enum UnitMovingStatus {
	IDLE,
	MOVING,
}

enum PlayerInput {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	GBA_A,
	GBA_B,
	GBA_START,
	GBA_SELECT,
}

const UNIT_TYPE_ACTIONS = {
	UnitType.PLAYER: [
		ActionType.JUMP,
		ActionType.MOVE,
	],
}

enum DIRECTION {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

const UNIT_TYPE_CURRENT_ACTIONS = {
	UnitType.PLAYER: [
		UnitCurrentAction.IDLE,
		UnitCurrentAction.JUMPING,
	],
}

const UNIT_TYPE_MOVING_STATUS = {
	UnitType.PLAYER: [
		UnitMovingStatus.IDLE,
		UnitMovingStatus.MOVING,
	],
}

const UNIT_TYPE_CONDITIONS = {
	UnitType.PLAYER: {
		UnitCondition.CURRENT_ACTION: UNIT_TYPE_CURRENT_ACTIONS[UnitType.PLAYER][UnitCurrentAction.IDLE],
		UnitCondition.IS_ON_GROUND: false,
		UnitCondition.MOVING_STATUS: UNIT_TYPE_MOVING_STATUS[UnitType.PLAYER][UnitMovingStatus.IDLE],
	},
}

const CURRENT_ACTION_TIMERS = {
	UnitType.PLAYER: {
		UnitCurrentAction.JUMPING: 0.4,
	}
}

const ENV_COLLIDERS = {
	UnitType.PLAYER: [
		[Vector2(0, 1.5), [DIRECTION.LEFT, DIRECTION.UP, DIRECTION.RIGHT]],
		[Vector2(0, .75), [DIRECTION.LEFT, DIRECTION.RIGHT]],
		[Vector2(0, 0), [DIRECTION.LEFT, DIRECTION.DOWN, DIRECTION.RIGHT]],
	],
}

const INPUT_MAP = {
	PlayerInput.UP: "ui_up",
	PlayerInput.DOWN: "ui_down",
	PlayerInput.LEFT: "ui_left",
	PlayerInput.RIGHT: "ui_right",
	PlayerInput.GBA_A: "gba_a",
	PlayerInput.GBA_B: "gba_b",
	PlayerInput.GBA_START: "gba_start",
	PlayerInput.GBA_SELECT: "gba_select",
}

enum MAP_ELEM_TYPES {
	SQUARE,
	SLOPE_LEFT,
	SLOPE_RIGHT,
	SMALL_SLOPE_LEFT_1,
	SMALL_SLOPE_LEFT_2,
	SMALL_SLOPE_RIGHT_1,
	SMALL_SLOPE_RIGHT_2,
	LEDGE,
}

const TileSetMapElems = {
	"TestTileSet": {
		MAP_ELEM_TYPES.SQUARE: [0, 1, 2, 3, 4, 5, 6, 7, 8],
		MAP_ELEM_TYPES.SLOPE_LEFT: [15, 16],
		MAP_ELEM_TYPES.SLOPE_RIGHT: [17, 18],
		MAP_ELEM_TYPES.SMALL_SLOPE_LEFT_1: [9],
		MAP_ELEM_TYPES.SMALL_SLOPE_LEFT_2: [10, 11],
		MAP_ELEM_TYPES.SMALL_SLOPE_RIGHT_1: [12],
		MAP_ELEM_TYPES.SMALL_SLOPE_RIGHT_2: [13, 14],
		MAP_ELEM_TYPES.LEDGE: [19, 20, 21, 22],
	}
}

const UnitSprites = {
	UnitType.PLAYER: {
		# "Sprite class": [is animation?, [Node list]]
		"Idle": [false, ["Idle"]],
		"Walk": [true, ["Walk"]],
		"Jump": [false, ["Jump1", "Jump2"]],
	}
}

const UNIT_TYPE_MOVE_SPEEDS = {
	UnitType.PLAYER: 6
}

const UNIT_TYPE_JUMP_SPEEDS = {
	UnitType.PLAYER: 5
}

const SCALE_FACTOR = 3
const GRID_SIZE = 20 # pixels
const GRAVITY = 30
const MAX_FALL_SPEED = -12
const ACCELERATION = 35
const QUANTUM_DIST = 0.001
