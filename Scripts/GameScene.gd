extends Node

class_name GameScene

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

var time_elapsed : float = 0
var time_elapsed_to_log : float = -1
var num_iterations = 24
var log_triggered : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	units.append(get_node("Player"))
	player = units[0]
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	player.get_node("Camera2D").make_current()
	get_node("AudioStreamPlayer").play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for unit in units:
		unit.reset_actions()
	handle_player_input()	
	# handle enemy input
	for unit in units:
		unit.process_unit(delta, self)
		set_logging_iteration(unit, delta)
		stage_env.interact(unit, delta)
			# ground_movement_interaction
			# ground_still_placement
			# check_collision
			#	check_ground_collision
		terminate_logging_iteration(unit)
		unit.react(delta)
		time_elapsed = time_elapsed + delta

func handle_player_input():
	for input_num in input_table.keys():
		if Input.is_action_pressed(Constants.INPUT_MAP[input_num]):
			input_table[input_num] = true
		else:
			input_table[input_num] = false
	
	if (player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.RECOILING
	or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING):
		return
	
	if (player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CHANNELING and !input_table[Constants.PlayerInput.GBA_B]
	or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING and !input_table[Constants.PlayerInput.DOWN]
	or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING and !input_table[Constants.PlayerInput.GBA_A] and !input_table[Constants.PlayerInput.UP]):
		player.set_current_action(Constants.UnitCurrentAction.IDLE)
		

	if input_table[Constants.PlayerInput.UP]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			if not player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
	
	if input_table[Constants.PlayerInput.DOWN]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE and player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			if player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				player.actions[Constants.ActionType.DIGEST] = true
				player.unit_conditions[Constants.UnitCondition.IS_PORTING] = false
				new_player_move_status = Constants.UnitMovingStatus.IDLE
			else:
				player.actions[Constants.ActionType.CROUCH] = true
				player.set_current_action(Constants.UnitCurrentAction.CROUCHING)
				new_player_move_status = Constants.UnitMovingStatus.IDLE
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			player.actions[Constants.ActionType.CROUCH] = true
	
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
					# if action-idle + move-idle + grounded + dash-timer-active + input-dash-facing-match
					if player.timer_actions[Constants.ActionType.DASH] > 0 and player.dash_facing == dir_input:
						# set dash
						player.actions[Constants.ActionType.DASH] = true
						new_player_move_status = Constants.UnitMovingStatus.DASHING
					# if action-idle + move-idle + grounded + (not-dash-timer-active or not-input-dash-facing-match)
					else:
						# set move
						player.actions[Constants.ActionType.MOVE] = true
						new_player_move_status = Constants.UnitMovingStatus.MOVING
					# start timer, set dash-facing
					player.timer_actions[Constants.ActionType.DASH] = Constants.PLAYER_TIMERS[Constants.ActionType.DASH]
					player.dash_facing = dir_input
				# if action-idle + move-idle + not-grounded
				else:
					# set move, kill timer
					player.actions[Constants.ActionType.MOVE] = true
					new_player_move_status = Constants.UnitMovingStatus.MOVING
					player.timer_actions[Constants.ActionType.DASH] = 0
			# if action-idle + move-moving
			elif player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] == Constants.UnitMovingStatus.MOVING:
				# set move
				player.actions[Constants.ActionType.MOVE] = true
				# if action-idle + move-moving + grounded
				if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
					# if action-idle + move-moving + grounded + facing-change
					if player.facing != dir_input:
						# start timer, set dash-facing
						player.timer_actions[Constants.ActionType.DASH] = Constants.PLAYER_TIMERS[Constants.ActionType.DASH]
						player.dash_facing = dir_input
				# if action-idle + move-moving + not-grounded
				else:
					# kill timer
					player.timer_actions[Constants.ActionType.DASH] = 0
			# if action-idle + move-dashing
			else:
				# if action-idle + move-dashing + facing-change
				if player.facing != dir_input:
					# set move
					player.actions[Constants.ActionType.MOVE] = true
					new_player_move_status = Constants.UnitMovingStatus.MOVING
				# if action-idle + move-dashing + not-facing-change
				else:
					# set dash
					player.actions[Constants.ActionType.DASH] = true
					new_player_move_status = Constants.UnitMovingStatus.DASHING
				# start timer, set dash-facing
				player.timer_actions[Constants.ActionType.DASH] = Constants.PLAYER_TIMERS[Constants.ActionType.DASH]
				player.dash_facing = dir_input
		# if action-jumping or action-flying
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			# set move, kill timer
			player.actions[Constants.ActionType.MOVE] = true
			new_player_move_status = Constants.UnitMovingStatus.MOVING
			player.timer_actions[Constants.ActionType.DASH] = 0
		# set facing
		player.facing = dir_input
	
	if not input_table[Constants.PlayerInput.LEFT] and not input_table[Constants.PlayerInput.RIGHT]:
		new_player_move_status = Constants.UnitMovingStatus.IDLE
	
	if input_table[Constants.PlayerInput.GBA_A]:
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			player.do_with_timeout(Constants.ActionType.SLIDE, Constants.UnitCurrentAction.SLIDING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
			player.actions[Constants.ActionType.JUMP] = true
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE:
			if player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] and !player.just_jumped:
				player.actions[Constants.ActionType.JUMP] = true
				player.set_current_action(Constants.UnitCurrentAction.JUMPING)
				player.just_jumped = true
				player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false
			elif not player.unit_conditions[Constants.UnitCondition.IS_PORTING] and !player.just_jumped:
				player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.do_with_timeout(Constants.ActionType.FLOAT, Constants.UnitCurrentAction.FLYING)

	if !input_table[Constants.PlayerInput.GBA_A]:
		player.just_jumped = false
	
	if input_table[Constants.PlayerInput.GBA_B]:
		# if crouching
		if player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING:
			# slide
			player.do_with_timeout(Constants.ActionType.SLIDE, Constants.UnitCurrentAction.SLIDING)
		# else if idle or channeling
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.IDLE or player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CHANNELING:
			# if porting and B is not still pressed after absorb
			if player.unit_conditions[Constants.UnitCondition.IS_PORTING]:
				if not player.just_absorbed:
					# drop porting
					player.actions[Constants.ActionType.DROP_PORTING] = true
					player.unit_conditions[Constants.UnitCondition.IS_PORTING] = false
			else:
				# channel
				player.actions[Constants.ActionType.CHANNEL] = true
				player.set_current_action(Constants.UnitCurrentAction.CHANNELING)
				new_player_move_status = Constants.UnitMovingStatus.IDLE
		# else if flying
		elif player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			player.actions[Constants.ActionType.CANCEL_FLYING] = true
			player.set_current_action(Constants.UnitCurrentAction.IDLE)
	
	if !input_table[Constants.PlayerInput.GBA_B]:
		player.just_absorbed = false
	
	if (input_table[Constants.PlayerInput.GBA_SELECT]
	and player.unit_conditions[Constants.UnitCondition.HAS_ABILITY]
	and player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.CHANNELING
	and player.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] != Constants.UnitCurrentAction.SLIDING):
		player.actions[Constants.ActionType.DISCARD] = true
		player.unit_conditions[Constants.UnitCondition.HAS_ABILITY] = false
		
	player.unit_conditions[Constants.UnitCondition.MOVING_STATUS] = new_player_move_status

func set_logging_iteration(unit : Unit, delta):
	if (log_triggered or
	(num_iterations != 0
	and unit.pos.x <= 8.1 and unit.pos.y <= 3.55 and unit.h_speed < 0)):
		time_elapsed_to_log = time_elapsed
		log_triggered = true
		print("Iteration identified: " + str(time_elapsed_to_log))
		unit.log_unit()

func terminate_logging_iteration(unit : Unit):
	if time_elapsed == time_elapsed_to_log:
		print("Iteration ended")
		num_iterations = num_iterations - 1
		unit.log_unit()
		if num_iterations == 0:
			log_triggered = false

func conditional_log(message : String):
	if is_log_condition():
		print(get_log_msg(message))

func get_log_msg(message : String):
	return str(time_elapsed) + " " + message

func is_log_condition():
	return time_elapsed == time_elapsed_to_log
