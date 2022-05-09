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
var dash_facing : int
var current_action_time_elapsed : float = 0
var just_absorbed : bool = false
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
	for condition_num in Constants.UNIT_CONDITION_TIMERS[unit_type].keys():
		unit_condition_timers[condition_num] = 0
	if unit_type == Constants.UnitType.PLAYER:
		for timer_action_num in Constants.PLAYER_TIMERS.keys():
			timer_actions[timer_action_num] = 0

func reset_actions():
	for action_num in actions.keys():
		actions[action_num] = false
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING:
		actions[Constants.ActionType.SLIDE] = true
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
			unit_conditions[Constants.UnitCondition.CURRENT_ACTION] = new_current_action
		if action == Constants.ActionType.FLOAT:
			unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false

func execute_actions(delta, scene):
	for action_num in actions.keys():
		if !actions[action_num]:
			continue
		match action_num:
			Constants.ActionType.CANCEL_FLYING:
				cancel_flying()
			Constants.ActionType.CROUCH:
				crouch()
			Constants.ActionType.DASH:
				dash(delta)
			Constants.ActionType.DIGEST:
				digest()
			Constants.ActionType.DISCARD:
				discard()
			Constants.ActionType.DROP_PORTING:
				drop_porting()
			Constants.ActionType.FLOAT:
				flot()
			Constants.ActionType.JUMP:
				jump()
			Constants.ActionType.MOVE:
				move(delta)
			Constants.ActionType.RECOIL:
				recoil()
			Constants.ActionType.SLIDE:
				slide()
		actions[action_num] = false
	handle_moving_status(delta, scene)
	handle_idle(delta)

func cancel_flying():
	pass

func crouch():
	pass

func dash(delta):
	if (unit_conditions[Constants.UnitCondition.MOVING_STATUS] != Constants.UnitMovingStatus.IDLE
	and unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE
	and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]):
		set_sprite("Dash")

func digest():
	pass

func discard():
	pass

func drop_porting():
	pass
	
func flot():
	v_speed = Constants.UNIT_TYPE_JUMP_SPEEDS[unit_type] * .67

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
	scene.conditional_log("set magnitude: " + str(magnitude))
	
	# if move status is idle
	if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
		# slow down
		magnitude = max(0, magnitude - Constants.ACCELERATION * delta)
		scene.conditional_log("move-idle, not-near-still: slow-down: magnitude: " + str(magnitude))
	# if move status is not idle
	else:
		# if is facing-aligned
		if (h_speed <= 0 and facing == Constants.PlayerInput.LEFT) or (h_speed >= 0 and facing == Constants.PlayerInput.RIGHT):
			# speed up
			if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.DASHING:
				magnitude = min(Constants.DASH_SPEED, magnitude + Constants.ACCELERATION * delta)
			else:
				magnitude = min(Constants.MOVE_SPEEDS[unit_type], magnitude + Constants.ACCELERATION * delta)
			scene.conditional_log("not-move-idle, facing-aligned: speed-up: magnitude: " + str(magnitude))
		# if is not facing-aligned
		else:
			# slow down
			magnitude = max(0, magnitude - Constants.ACCELERATION * delta)
			scene.conditional_log("not-move-idle, not-facing-aligned: slow-down: magnitude: " + str(magnitude))
	
	# if is grounded
	if unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED] and unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		# make magnitude greater than quantum distance
		if magnitude > 0 and magnitude < Constants.QUANTUM_DIST:
			magnitude = Constants.QUANTUM_DIST * 2
			scene.conditional_log("grounded: quantum magnitude: " + str(magnitude))
		
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
			scene.conditional_log("grounded, non-zero-magnitude: preserve-h-dir: " + str(h_speed))
		else:
			h_speed = 0
		v_speed = -1 * magnitude
		scene.conditional_log("grounded: point-down: " + str(v_speed) + ", set-h-speed: " + str(h_speed))
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
		scene.conditional_log("not-grounded: set-h-speed: " + str(h_speed))

func handle_idle(delta):
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
		if unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.IDLE:
				set_sprite("Idle")
		else:
			if v_speed < 0:
				set_sprite("Jump", 1)
	elif unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
		if v_speed > 0:
			set_sprite("Fly", 0)
		else:
			set_sprite("Fly", 1)

func recoil():
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.RECOILING]:
		set_current_action(Constants.UnitCurrentAction.IDLE)
	if unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.RECOILING:
		unit_conditions[Constants.UnitCondition.IS_INVINCIBLE] = true
		unit_condition_timers[Constants.UnitCondition.IS_INVINCIBLE] = Constants.UNIT_CONDITION_TIMERS[unit_type][Constants.UnitCondition.IS_INVINCIBLE]
		set_current_action(Constants.UnitCurrentAction.RECOILING)

func slide():
	var dir_factor = 1
	if facing == Constants.PlayerInput.LEFT:
		dir_factor = -1
	h_speed = 10 * dir_factor
	if current_action_time_elapsed >= Constants.CURRENT_ACTION_TIMERS[unit_type][Constants.UnitCurrentAction.SLIDING]:
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

func log_unit():
	print("===UNIT DEBUG====")
	print("pos: " + str(pos))
	print("speeds: " + str(Vector2(h_speed, v_speed)))
	print("facing: " + Constants.PlayerInput.keys()[facing])
	print("conditions: action: " + Constants.UnitCurrentAction.keys()[unit_conditions[Constants.UnitCondition.CURRENT_ACTION]] + ", grounded: " + str(unit_conditions[Constants.UnitCondition.IS_ON_GROUND]) + ", movement: " + Constants.UnitMovingStatus.keys()[unit_conditions[Constants.UnitCondition.MOVING_STATUS]])
	print("=================")
