extends Node

# _process(delta) is called by this class
# player input is handled here
# unit declares its intention in process_unit()
# stage environment interacts with the unit in interact()
# unit executes its resulting state in react()
class_name GameScene

export var tile_set_name: String
const Constants = preload("res://Scripts/Constants.gd")
const Unit = preload("res://Scripts/Unit.gd")

var units = []
var player : Unit
var input_table = {
	Constants.PlayerInput.UP: false,
	Constants.PlayerInput.DOWN: false,
	Constants.PlayerInput.LEFT: false,
	Constants.PlayerInput.RIGHT: false,
	Constants.PlayerInput.GBA_A: false,
	Constants.PlayerInput.GBA_B: false,
	Constants.PlayerInput.GBA_SELECT: false,
}
var new_player_move_status
var stage_env

# Called when the node enters the scene tree for the first time.
func _ready():
	units.append(get_node("Player"))
	player = units[0]
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	player.get_node("Camera2D").make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for unit in units:
		unit.reset_actions()
	handle_player_input()
	# handle other units' input
	for unit in units:
		unit.process_unit(delta, self)
		stage_env.interact(unit, delta)
		unit.react(delta)

func handle_player_input():
	for input_num in input_table.keys():
		if Input.is_action_pressed(Constants.INPUT_MAP[input_num]):
			input_table[input_num] = true
		else:
			input_table[input_num] = false
	
	if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING and !input_table[Constants.PlayerInput.GBA_A]:
		player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	if input_table[Constants.PlayerInput.LEFT] or input_table[Constants.PlayerInput.RIGHT]:
		if input_table[Constants.PlayerInput.LEFT] and input_table[Constants.PlayerInput.RIGHT]:
			input_table[Constants.PlayerInput.LEFT] = false
		var dir_input
		if input_table[Constants.PlayerInput.LEFT]:
			dir_input = Constants.PlayerInput.LEFT
		else:
			dir_input = Constants.PlayerInput.RIGHT
		# if action-idle
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			# if action-idle + move-idle
			if player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				# if action-idle + move-idle + grounded
				if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
					# set move
					player.actions[Constants.ActionType.MOVE] = true
					new_player_move_status = Constants.UnitMovingStatus.MOVING
				# if action-idle + move-idle + not-grounded
				else:
					# set move
					player.actions[Constants.ActionType.MOVE] = true
					new_player_move_status = Constants.UnitMovingStatus.MOVING
			# if action-idle + move-moving
			else:
				# set move
				player.actions[Constants.ActionType.MOVE] = true
		# if action-jumping or action-flying
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
			# set move
			player.actions[Constants.ActionType.MOVE] = true
			new_player_move_status = Constants.UnitMovingStatus.MOVING
		# set facing
		if dir_input == Constants.PlayerInput.LEFT:
			player.facing = Constants.DIRECTION.LEFT
		elif dir_input == Constants.PlayerInput.RIGHT:
			player.facing = Constants.DIRECTION.RIGHT
	
	if not input_table[Constants.PlayerInput.LEFT] and not input_table[Constants.PlayerInput.RIGHT]:
		new_player_move_status = Constants.UnitMovingStatus.IDLE
	
	if input_table[Constants.PlayerInput.GBA_A]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
			player.actions[Constants.ActionType.JUMP] = true
		elif (player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE
		and player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]
		and !player.just_jumped):
			player.actions[Constants.ActionType.JUMP] = true
			player.set_current_action(Constants.UnitCurrentAction.JUMPING)
			player.just_jumped = true
			player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false

	if !input_table[Constants.PlayerInput.GBA_A]:
		player.just_jumped = false
		
	player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] = new_player_move_status
