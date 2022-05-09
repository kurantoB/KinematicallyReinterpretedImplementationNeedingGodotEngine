extends Object

const GameUtils = preload("res://Scripts/GameUtils.gd")
const Constants = preload("res://Scripts/Constants.gd")
const GameScene = preload("res://Scripts/GameScene.gd")
const Unit = preload("res://Scripts/Unit.gd")

var scene : GameScene

var top_right_colliders = []
var bottom_right_colliders = []
var bottom_left_colliders = []
var top_left_colliders = []

func _init(the_scene : GameScene):
	scene = the_scene
	var stage = scene.get_node("Stage")
	init_stage_grid(stage.get_children())
	for stage_elem in stage.get_children():
		stage_elem.position.x = stage_elem.position.x * Constants.SCALE_FACTOR
		stage_elem.position.y = stage_elem.position.y * Constants.SCALE_FACTOR
		stage_elem.scale.x = Constants.SCALE_FACTOR
		stage_elem.scale.y = Constants.SCALE_FACTOR
	var player = scene.get_node("Player")
	init_player(player)
	player.position.x = player.position.x * Constants.SCALE_FACTOR
	player.position.y = player.position.y * Constants.SCALE_FACTOR
	player.scale.x = Constants.SCALE_FACTOR
	player.scale.y = Constants.SCALE_FACTOR
	
	if scene.has_node("Background"):
		var background = scene.get_node("Background")
		for stage_elem in background.get_children():
			stage_elem.position.x = stage_elem.position.x * Constants.SCALE_FACTOR
			stage_elem.position.y = stage_elem.position.y * Constants.SCALE_FACTOR
			stage_elem.scale.x = Constants.SCALE_FACTOR
			stage_elem.scale.y = Constants.SCALE_FACTOR

func init_player(player : Unit):
	player.pos = Vector2(player.position.x / Constants.GRID_SIZE, -1 * player.position.y / Constants.GRID_SIZE)

func interact(unit : Unit, delta):
	# gravity-affected
	if unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED]:
		# gravity-affected, grounded
		if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
			# gravity-affected, grounded, -v
			if unit.v_speed < 0:
				scene.conditional_log("interact gravity-affected, grounded, neg v-speed: reorient speed, reposition")
				ground_movement_interaction(unit, delta)
			# gravity-affected, grounded, v-speed-zero
			else:
				scene.conditional_log("interact gravity-affected, grounded, v-speed-zero: zero-out speed, reposition")
				unit.h_speed = 0
				unit.v_speed = 0
				ground_still_placement(unit)
		else:
			scene.conditional_log("interact gravity-affected, not-grounded")
			var gravity_factor = Constants.GRAVITY
			var max_fall_speed = Constants.MAX_FALL_SPEED
			if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
				scene.conditional_log("interact gravity-affected, not-grounded, flying")
				gravity_factor = Constants.GRAVITY_LITE
				max_fall_speed = Constants.MAX_FALL_LITE
			scene.conditional_log("interact change-v-speed: " + str(unit.v_speed) + " -> " + str(max(unit.v_speed - (gravity_factor * delta), max_fall_speed)))
			unit.v_speed = max(unit.v_speed - (gravity_factor * delta), max_fall_speed)

	if not (unit.h_speed == 0 and unit.v_speed == 0):
		scene.conditional_log("interact not-still")
		# regular collision
		if unit.h_speed >= 0 and unit.v_speed > 0:
			for collider in top_right_colliders:
				check_collision(unit, collider, [Constants.DIRECTION.UP, Constants.DIRECTION.RIGHT], delta)
		elif unit.h_speed > 0 and unit.v_speed <= 0:
			for collider in bottom_right_colliders:
				check_collision(unit, collider, [Constants.DIRECTION.RIGHT], delta)
			for collider in bottom_right_colliders:
				check_collision(unit, collider, [Constants.DIRECTION.DOWN], delta)
		elif unit.h_speed <= 0 and unit.v_speed < 0:
			for collider in bottom_left_colliders:
				check_collision(unit, collider, [Constants.DIRECTION.LEFT], delta)
			for collider in bottom_left_colliders:
				check_collision(unit, collider, [Constants.DIRECTION.DOWN], delta)
		elif unit.h_speed < 0 and unit.v_speed >= 0:
			for collider in top_left_colliders:
				check_collision(unit, collider, [Constants.DIRECTION.LEFT, Constants.DIRECTION.UP], delta)

func init_stage_grid(map_elems):
	for map_elem in map_elems:
		var stage_x = floor(map_elem.position.x / Constants.GRID_SIZE)
		var stage_y = floor(-1 * map_elem.position.y / Constants.GRID_SIZE)
		match map_elem.map_elem_type:
			Constants.MAP_ELEM_TYPES.SQUARE:
				if stage_x == 39 and stage_y == 2:
					print("Found stage_x == 39 and stage_y == 2 square")
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.UP, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, 1)
			Constants.MAP_ELEM_TYPES.SLOPE_LEFT:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SLOPE_RIGHT:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_LEFT_1:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_LEFT_2:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_RIGHT_1:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.SMALL_SLOPE_RIGHT_2:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.DOWN, 1)
			Constants.MAP_ELEM_TYPES.LEDGE:
				insert_grid_collider(stage_x, stage_y, Constants.DIRECTION.UP, 1)


func insert_grid_collider(stage_x, stage_y, direction : int, fractional_height : float):
	var check_colliders = []
	var insert_colliders = []
	var point_a : Vector2
	var point_b : Vector2
	match direction:
		Constants.DIRECTION.UP:
			check_colliders = [top_right_colliders, top_left_colliders]
			insert_colliders = [bottom_right_colliders, bottom_left_colliders]
			point_a = Vector2(stage_x, stage_y + 1)
			point_b = Vector2(stage_x + 1, stage_y + 1)
		Constants.DIRECTION.DOWN:
			check_colliders = [bottom_right_colliders, bottom_left_colliders]
			insert_colliders = [top_right_colliders, top_left_colliders]
			point_a = Vector2(stage_x, stage_y)
			point_b = Vector2(stage_x + 1, stage_y)
		Constants.DIRECTION.LEFT:
			check_colliders = [bottom_left_colliders, top_left_colliders]
			insert_colliders = [top_right_colliders, bottom_right_colliders]
			point_a = Vector2(stage_x, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x, stage_y)
		Constants.DIRECTION.RIGHT:
			check_colliders = [top_right_colliders, bottom_right_colliders]
			insert_colliders = [bottom_left_colliders, top_left_colliders]
			point_a = Vector2(stage_x + 1, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x + 1, stage_y)
	try_insert_collider(check_colliders, insert_colliders, point_a, point_b)

func try_insert_collider(check_colliders, insert_colliders, point_a : Vector2, point_b : Vector2):
	var found_existing : bool = false
	for i in range(len(check_colliders)):
		for j in range(len(check_colliders[i])):
			if check_colliders[i][j][0] == point_a and check_colliders[i][j][1] == point_b:
				found_existing = true
				check_colliders[i].remove(j)
				break
	if not found_existing:
		for i in range(len(insert_colliders)):
			insert_colliders[i].append([point_a, point_b])

func ground_movement_interaction(unit : Unit, delta):
	var has_ground_collision = false
	var collider_group = []
	var angle_helper
	for collider in bottom_left_colliders:
		# true/false, collision direction, collision point, and unit env collider
		var env_collision = unit_is_colliding_w_env(unit, collider, [Constants.DIRECTION.DOWN], delta, true)
		if env_collision[0]:
			# collided with ground
			has_ground_collision = true
			scene.conditional_log("ground_movement_interaction ground-collided: " + str(collider) + " at " + str(env_collision[2]))
			if unit.h_speed > 0:
				angle_helper = collider
			else:
				angle_helper = [collider[1], collider[0]]
			scene.conditional_log("ground_movement_interaction angle_helper: " + str(angle_helper))
			scene.conditional_log("ground_movement_interaction zero-out h-speed")
			unit.h_speed = 0
			var collision_point = env_collision[2]
			var unit_env_collider = env_collision[3]
			var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			scene.conditional_log("ground_movement_interaction change-pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
			unit.pos.y = unit.pos.y + y_dist_to_translate
			var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
			scene.conditional_log("ground_movement_interaction change-pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
			unit.pos.x = unit.pos.x + x_dist_to_translate
			break
	if not has_ground_collision:
		scene.conditional_log("ground_movement_interaction not-ground-collided - is-on-ground-false")
		unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = false
		if unit.h_speed > 0:
			angle_helper = [Vector2(0, 0), Vector2(1, 0)]
		else:
			angle_helper = [Vector2(1, 0), Vector2(0, 0)]
		scene.conditional_log("ground_movement_interaction angle_helper: " + str(angle_helper))
		scene.conditional_log("ground_movement_interaction zero-out h-speed")
		unit.h_speed = 0
	scene.conditional_log("ground_movement_interaction reangling: " + str(Vector2(unit.h_speed, unit.v_speed)) + " ->")
	GameUtils.reangle_move(unit, angle_helper)
	scene.conditional_log("ground_movement_interaction reangling:     " + str(Vector2(unit.h_speed, unit.v_speed)))

func ground_still_placement(unit : Unit):
	for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
		if unit_env_collider[1].has(Constants.DIRECTION.DOWN):
			for collider in bottom_left_colliders:
				if collider[0].x == collider[1].x:
					continue
				var collision_check : Vector2 = unit.pos + unit_env_collider[0]
				var altered_collision_check: Vector2 = collision_check
				altered_collision_check.y = altered_collision_check.y + .3
				var intersects_results = GameUtils.path_intersects_border(
					altered_collision_check,
					collision_check + Vector2(0, -.3),
					collider[0],
					collider[1])
				if intersects_results[0]:
					var collision_point = intersects_results[1]
					var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
					var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
					scene.conditional_log("ground_still_placement change pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
					unit.pos.y = unit.pos.y + y_dist_to_translate
					var collider_set_pos_x = collision_point.x
					var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
					scene.conditional_log("ground_still_placement change pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
					unit.pos.x = unit.pos.x + x_dist_to_translate
					return
	
func check_collision(unit : Unit, collider, collision_directions, delta):
	# true/false, collision direction, collision point, and unit env collider
	var env_collision = unit_is_colliding_w_env(unit, collider, collision_directions, delta)
	if env_collision[0]:
		var collision_dir = env_collision[1]
		var collision_point = env_collision[2]
		var unit_env_collider = env_collision[3]
		scene.conditional_log("check_collision collided: " + str(collider) + " check-directions: " + str(collision_directions) + " direction: " + Constants.DIRECTION.keys()[env_collision[1]] + ", at " + str(collision_point) + " w/ env-collider: " + str(unit_env_collider[0]))
		check_ground_collision(unit, collider, collision_point, unit_env_collider)
		if collision_dir == Constants.DIRECTION.UP:
			scene.conditional_log("check_collision up collision zero-out v-speed")
			unit.v_speed = 0
			var collider_set_pos_y = collision_point.y - Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			scene.conditional_log("check_collision up collision change-pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
			unit.pos.y = unit.pos.y + y_dist_to_translate
		elif collision_dir == Constants.DIRECTION.LEFT or collision_dir == Constants.DIRECTION.RIGHT:
			if (collider[0].x == collider[1].x
			or (not unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED] or not unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND])):
				scene.conditional_log("check_collision left/right non-slope-collision or not-grounded zero-out h-speed")
				unit.h_speed = 0
			var collider_set_pos_x = collision_point.x
			if collision_dir == Constants.DIRECTION.LEFT:
				scene.conditional_log("check_collision left collision")
				collider_set_pos_x = collider_set_pos_x + Constants.QUANTUM_DIST
			else:
				scene.conditional_log("check_collision right collision")
				collider_set_pos_x = collider_set_pos_x - Constants.QUANTUM_DIST
			var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
			scene.conditional_log("check_collision change-pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
			unit.pos.x = unit.pos.x + x_dist_to_translate

# handle collision with ground if any
func check_ground_collision(unit : Unit, collider, collision_point : Vector2, unit_env_collider):
	if not unit_env_collider[1].has(Constants.DIRECTION.DOWN):
		scene.conditional_log("check_ground_collision " + str(unit_env_collider[0]) + " not ground collider")
		return
	if (unit.unit_conditions[Constants.UnitCondition.IS_GRAVITY_AFFECTED]
		and not unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]
		and (collider[0].y == collider[1].y or (collider[0].x != collider[1].x and collider[0].y != collider[1].y))):
		scene.conditional_log("check_ground_collision airborne ground collision on: " + str(collider) + " with " + str(unit_env_collider[0]))
		scene.conditional_log("check_ground_collision make v-speed's h-component the h-speed")
#		unit.v_speed = 0
#		unit.h_speed = 0
		if collider[0].y == collider[1].y:
			unit.v_speed = 0
		else:
			var angle_helper
			if unit.h_speed > 0:
				angle_helper = collider
			else:
				angle_helper = [collider[1], collider[0]]
				unit.v_speed = abs(unit.h_speed)
				GameUtils.reangle_move(unit, angle_helper)
		var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
		var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
		scene.conditional_log("check_ground_collision change pos-y: " + str(unit.pos.y) + " -> " + str(unit.pos.y + y_dist_to_translate))
		unit.pos.y = unit.pos.y + y_dist_to_translate
		var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
		scene.conditional_log("check_ground_collision change pos-x: " + str(unit.pos.x) + " -> " + str(unit.pos.x + x_dist_to_translate))
		unit.pos.x = unit.pos.x + x_dist_to_translate
		scene.conditional_log("check_ground_collision set grounded")
		unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND] = true
		if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING:
			scene.conditional_log("check_ground_collision set current action flying -> idle")
			unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] = Constants.UnitCurrentAction.IDLE
	

# returns true/false, collision direction, collision point, and unit env collider
func unit_is_colliding_w_env(unit : Unit, collider, directions, delta, is_ground_check = false):
	var found_env_collider : bool = false
	var found_condition : bool = false;
	for direction_to_check in directions:
		if (((direction_to_check == Constants.DIRECTION.LEFT or direction_to_check == Constants.DIRECTION.RIGHT)
		and collider[0].y == collider[1].y)
		or ((direction_to_check == Constants.DIRECTION.UP or direction_to_check == Constants.DIRECTION.DOWN)
		and collider[0].x == collider[1].x)):
			continue
		for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
			if unit_env_collider[1].has(direction_to_check):
				if ((direction_to_check == Constants.DIRECTION.LEFT or direction_to_check == Constants.DIRECTION.RIGHT)
				and (collider[0].x != collider[1].x and collider[0].y != collider[1].y)
				and unit_env_collider[0] != Vector2(0, 0)):
					continue;
				found_env_collider = true
				if found_condition:
					scene.conditional_log("unit_is_colliding_w_env checking unit_env_collider " + str(unit_env_collider) + " against collider: " + str(collider) + " with direction " + Constants.DIRECTION.keys()[direction_to_check] + " while unit at " + str(unit.pos))
				var intersects_results = intersect_check_w_collider_uec_dir(unit, collider, direction_to_check, unit_env_collider, is_ground_check, delta, found_condition)
				if intersects_results[0]:
					if found_condition:
						scene.conditional_log("unit_is_colliding_w_env checking unit_env_collider collection detected")
					return [intersects_results[0], direction_to_check, intersects_results[1], unit_env_collider]
	if found_condition:
		scene.conditional_log("unit_is_colliding_w_env no collision for unit pos " + str(unit.pos) + ", collider " + str(collider) + ", check-dirs " + str(directions))
	return [false, -1, Vector2(), {}]

func intersect_check_w_collider_uec_dir(unit : Unit, collider, direction_to_check : int, unit_env_collider, is_ground_check : bool, delta, found_condition : bool):
	var new_is_ground_check = (is_ground_check
	or (direction_to_check == Constants.DIRECTION.DOWN and collider[0].y == collider[1].y)
	or (collider[0].x != collider[1].x and collider[0].y != collider[1].y))
	if found_condition:
		scene.conditional_log("unit_is_colliding_w_env is-ground-check " + str(is_ground_check) + " for check-dir " + Constants.DIRECTION.keys()[direction_to_check] + " and collider " + str(collider))
	var unit_env_collider_vector = unit_env_collider[0]
	if (unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.CROUCHING
	or unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.SLIDING
	or unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.FLYING):
		unit_env_collider_vector.y = unit_env_collider_vector.y * Constants.CROUCH_FACTOR
	var collision_check : Vector2 = unit.pos + unit_env_collider_vector
	var altered_collision_check: Vector2 = collision_check
	if is_ground_check:
		altered_collision_check.y = altered_collision_check.y + .3
	if found_condition:
		scene.conditional_log("unit_is_colliding_w_env altered_collision_check " + str(altered_collision_check))
	return GameUtils.path_intersects_border(
		altered_collision_check,
		collision_check + Vector2(unit.h_speed * delta, unit.v_speed * delta),
		collider[0],
		collider[1])
