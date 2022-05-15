extends Node2D

class_name Unit


const Constants = preload("res://Scripts/Constants.gd")
const GameUtils = preload("res://Scripts/GameUtils.gd")

# position
export var unit_type : int

var actions = {}
var unit_conditions = {}
var timer_actions = {}
var facing : int = Constants.PlayerInput.RIGHT
var current_action_time_elapsed : float = 0
var just_jumped : bool = false
var unit_condition_timers = {}

var pos : Vector2
var h_speed : float = 0
var v_speed : float = 0
var ground_speed : float = 0

var current_sprite : Node2D

# Called when the node enters the scene tree for the first time
func _ready():
	for action_num in Constants.UNIT_TYPE_ACTIONS[unit_type]:
		actions[action_num] = false
	for condition_num in Constants.UNIT_TYPE_CONDITIONS[unit_type].keys():
		unit_conditions[condition_num] = Constants.UNIT_TYPE_CONDITIONS[unit_type][condition_num]

func reset_actions():
	for action_num in actions.keys():
		actions[action_num] = false
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING:
		actions[Constants.ActionType.RECOIL] = true

func process_unit(delta, scene):
	if unit_type == Constants.UnitType.PLAYER:
		advance_timers(delta)
	current_action_time_elapsed += delta
	execute_actions(delta, scene)

func advance_timers(delta):
	for timer_action_num in timer_actions.keys():
		timer_actions[timer_action_num] = max(0, timer_actions[timer_action_num] - delta)
	current_action_time_elapsed += delta
	for condition_num in unit_condition_timers.keys():
		unit_condition_timers[condition_num] = max(0, unit_condition_timers[condition_num] - delta)
		if unit_condition_timers[condition_num] == 0:
			unit_conditions[condition_num] = false

func set_current_action(current_action : int):
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != current_action:
		current_action_time_elapsed = 0
	unit_conditions[Constants.UnitCondition.CURRENT_ACTION] = current_action

func do_with_timeout(action : int, new_current_action : int = -1):
	if timer_actions[action] == 0:
		actions[action] = true
		timer_actions[action] = Constants.PLAYER_TIMERS[action]
		if new_current_action != -1:
			set_current_action(new_current_action)
		if action == Constants.ActionType.FLOAT:
			unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false

func execute_actions(delta, scene):
	for action_num in actions.keys():
		if !actions[action_num]:
			continue
		match action_num:
			Constants.ActionType.JUMP:
				jump()
			Constants.ActionType.MOVE:
				move(delta)
			Constants.ActionType.RECOIL:
				recoil()
		actions[action_num] = false
	handle_moving_status(delta, scene)
	handle_idle(delta)

func jump():
	v_speed = Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type]
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
		if unit_type == Constants.UnitType.PLAYER:
			if v_speed > 0:
				set_sprite("Jump", 0)
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.JUMPING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)
		

func move(delta):
	if (unit_conditions[Constants.UnitCondition.MOVING_STATUS] != Constants.UnitMovingStatus.IDLE
	and unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE
	and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]):
		if int(floor(current_action_time_elapsed * 4)) % 3 == 0:
			set_sprite("Walk")

func handle_moving_status(delta, scene):
	# what we have: facing, current speed, move status, grounded
	# we want: to set the new intended speed
	var magnitude : float
	if unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED] and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		magnitude = sqrt(pow(v_speed, 2) + pow(h_speed, 2))
	else:
		magnitude = abs(h_speed)
	
	# if move status is idle
	if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
		# slow down
		magnitude = max(0, magnitude - Constants.ACCELERATION * delta)
	# if move status is not idle
	else:
		# if is facing-aligned
		if (h_speed <= 0 and facing == Constants.PlayerInput.LEFT) or (h_speed >= 0 and facing == Constants.PlayerInput.RIGHT):
			# speed up
			magnitude = min(Constants.MOVE_SPEEDS[unit_type], magnitude + Constants.ACCELERATION * delta)
		# if is not facing-aligned
		else:
			# slow down
			magnitude = max(0, magnitude - Constants.ACCELERATION * delta)
	
	# if is grounded
	if unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED] and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		# make magnitude greater than quantum distance
		if magnitude > 0 and magnitude < Constants.QUANTUM_DIST:
			magnitude = Constants.QUANTUM_DIST * 2
		
		# make move vector point down
		if magnitude > 0:
			if h_speed > 0:
				h_speed = Constants.QUANTUM_DIST # preserve h direction
			elif h_speed < 0:
				h_speed = -1 * Constants.QUANTUM_DIST
			else:
				if facing == Constants.PlayerInput.RIGHT:
					h_speed = Constants.QUANTUM_DIST
				else:
					h_speed = -1 * Constants.QUANTUM_DIST
		else:
			h_speed = 0
		v_speed = -1 * magnitude
	# if is not grounded
	else:
		# set h_speed
		if magnitude > 0:
			if h_speed > 0:
				h_speed = magnitude
			elif h_speed < 0:
				h_speed = -1 * magnitude
			else:
				if facing == Constants.PlayerInput.RIGHT:
					h_speed = magnitude
				else:
					h_speed = -1 * magnitude
		else:
			h_speed = 0

func handle_idle(delta):
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
		if unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				set_sprite("Idle")
		else:
			if v_speed < 0:
				set_sprite("Jump", 1)

func recoil():
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.RECOILING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)

func set_sprite(sprite_class : String, index : int = 0):
	if not unit_type in Constants.UnitSprites or not sprite_class in Constants.UnitSprites[unit_type]:
		return
	var node_list = Constants.UnitSprites[unit_type][sprite_class][1]
	var true_index : int = index
	if true_index > len(node_list) - 1:
		true_index = 0
	var new_sprite : Node2D = get_node(node_list[true_index])
	if current_sprite == null or current_sprite != new_sprite:
		if current_sprite != null:
			current_sprite.visible = false
		current_sprite = new_sprite
		current_sprite.visible = true
		if (Constants.UnitSprites[unit_type][sprite_class][0]):
			current_sprite.play()
	if facing == Constants.PlayerInput.LEFT:
		current_sprite.scale.x = -1
	else:
		current_sprite.scale.x = 1

func react(delta):
	pos.x = pos.x + h_speed * delta
	pos.y = pos.y + v_speed * delta
	position.x = pos.x * Constants.GRID_SIZE * Constants.SCALE_FACTOR
	position.y = -1 * pos.y * Constants.GRID_SIZE * Constants.SCALE_FACTOR
