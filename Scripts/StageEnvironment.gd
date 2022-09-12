# Handles unit-environment iteraction
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
	var stage : TileMap = scene.get_node("Stage")
	init_stage_grid(stage)
	stage.scale.x = Constants.SCALE_FACTOR
	stage.scale.y = Constants.SCALE_FACTOR
	var player = scene.get_node("Player")
	init_player(player)
	player.position.x = player.position.x * Constants.SCALE_FACTOR
	player.position.y = player.position.y * Constants.SCALE_FACTOR
	player.scale.x = Constants.SCALE_FACTOR
	player.scale.y = Constants.SCALE_FACTOR

func init_player(player : Unit):
	player.pos = Vector2(player.position.x / Constants.GRID_SIZE, -1 * player.position.y / Constants.GRID_SIZE)

func interact(unit : Unit, delta):
	# grounded
	if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		interact_grounded(unit, delta)
	else:
		var gravity_factor = Constants.GRAVITY
		var max_fall_speed = Constants.MAX_FALL_SPEED
		unit.v_speed = max(unit.v_speed - (gravity_factor * delta), max_fall_speed)

	if not (unit.h_speed == 0 and unit.v_speed == 0):
		# regular collision
		if unit.h_speed >= 0 and unit.v_speed > 0:
			for collider in top_right_colliders:
				check_collision(unit, collider, [Constants.Direction.UP, Constants.Direction.RIGHT], delta)
		elif unit.h_speed > 0 and unit.v_speed <= 0:
			# We have to make sure every horizontal-direction check is preceded by a down check, and vice versa...
			for collider in bottom_right_colliders:
				check_collision(unit, collider, [Constants.Direction.RIGHT], delta)
			for collider in bottom_right_colliders:
				check_collision(unit, collider, [Constants.Direction.DOWN], delta)
			for collider in bottom_right_colliders:
				check_collision(unit, collider, [Constants.Direction.RIGHT], delta)
		elif unit.h_speed <= 0 and unit.v_speed < 0:
			# We have to make sure every horizontal-direction check is preceded by a down check, and vice versa...
			for collider in bottom_left_colliders:
				check_collision(unit, collider, [Constants.Direction.LEFT], delta)
			for collider in bottom_left_colliders:
				check_collision(unit, collider, [Constants.Direction.DOWN], delta)
			for collider in bottom_left_colliders:
				check_collision(unit, collider, [Constants.Direction.LEFT], delta)
		elif unit.h_speed < 0 and unit.v_speed >= 0:
			for collider in top_left_colliders:
				check_collision(unit, collider, [Constants.Direction.LEFT, Constants.Direction.UP], delta)

func interact_grounded(unit : Unit, delta):
	# grounded, v-speed-neg
	if unit.v_speed < 0:
		ground_movement_interaction(unit, delta)
	# grounded, v-speed-zero
	else:
		unit.h_speed = 0
		unit.v_speed = 0
		ground_placement(unit)

func init_stage_grid(tilemap : TileMap):
	for map_elem in tilemap.get_used_cells():
		var stage_x = floor(tilemap.map_to_world(map_elem).x / Constants.GRID_SIZE)
		var stage_y = floor(-1 * tilemap.map_to_world(map_elem).y / Constants.GRID_SIZE) - 1
		var map_elem_type : int
		var cellv = tilemap.get_cellv(map_elem)
		var found_map_elem_type : bool = false
		for test_map_elem_type in [
			Constants.MapElemType.SQUARE,
			Constants.MapElemType.SLOPE_LEFT,
			Constants.MapElemType.SLOPE_RIGHT,
			Constants.MapElemType.SMALL_SLOPE_LEFT_1,
			Constants.MapElemType.SMALL_SLOPE_LEFT_2,
			Constants.MapElemType.SMALL_SLOPE_RIGHT_1,
			Constants.MapElemType.SMALL_SLOPE_RIGHT_2,
			Constants.MapElemType.LEDGE]:
			for test_cell_v in Constants.TILE_SET_MAP_ELEMS[scene.tile_set_name][test_map_elem_type]:
				if test_cell_v == cellv:
					map_elem_type = test_map_elem_type
					found_map_elem_type = true
					break
			if found_map_elem_type:
				break
		match map_elem_type:
			Constants.MapElemType.SQUARE:
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, 1)
			Constants.MapElemType.SLOPE_LEFT:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
			Constants.MapElemType.SLOPE_RIGHT:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
			Constants.MapElemType.SMALL_SLOPE_LEFT_1:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
			Constants.MapElemType.SMALL_SLOPE_LEFT_2:
				try_insert_collider(
					[],
					[top_right_colliders, bottom_right_colliders, bottom_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y + 1)
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
			Constants.MapElemType.SMALL_SLOPE_RIGHT_1:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y)
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
			Constants.MapElemType.SMALL_SLOPE_RIGHT_2:
				try_insert_collider(
					[],
					[bottom_right_colliders, bottom_left_colliders, top_left_colliders],
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y + .5)
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)
			Constants.MapElemType.LEDGE:
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)


func insert_grid_collider(stage_x, stage_y, direction : int, fractional_height : float):
	var check_colliders = []
	var insert_colliders = []
	var point_a : Vector2
	var point_b : Vector2
	match direction:
		Constants.Direction.UP:
			check_colliders = [top_right_colliders, top_left_colliders]
			insert_colliders = [bottom_right_colliders, bottom_left_colliders]
			point_a = Vector2(stage_x, stage_y + 1)
			point_b = Vector2(stage_x + 1, stage_y + 1)
		Constants.Direction.DOWN:
			check_colliders = [bottom_right_colliders, bottom_left_colliders]
			insert_colliders = [top_right_colliders, top_left_colliders]
			point_a = Vector2(stage_x, stage_y)
			point_b = Vector2(stage_x + 1, stage_y)
		Constants.Direction.LEFT:
			check_colliders = [bottom_left_colliders, top_left_colliders]
			insert_colliders = [top_right_colliders, bottom_right_colliders]
			point_a = Vector2(stage_x, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x, stage_y)
		Constants.Direction.RIGHT:
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
	var angle_helper_collider
	for collider in bottom_left_colliders:
		# true/false, collision direction, collision point, and unit env collider
		var env_collision = unit_is_colliding_w_env(unit, collider, [Constants.Direction.DOWN], delta, true)
		if env_collision[0]:
			# collided with ground
			has_ground_collision = true
			var collision_point = env_collision[2]
			var unit_env_collider = env_collision[3]
			var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			unit.pos.y = unit.pos.y + y_dist_to_translate
			var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
			unit.pos.x = unit.pos.x + x_dist_to_translate
			angle_helper_collider = collider
			break
	if not has_ground_collision:
		unit.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)
	var angle_helper
	if unit.h_speed > 0:
		if has_ground_collision:
			angle_helper = angle_helper_collider
		else:
			angle_helper = [Vector2(0, 0), Vector2(1, 0)]
	else:
		if has_ground_collision:
			angle_helper = [angle_helper_collider[1], angle_helper_collider[0]]
		else:
			angle_helper = [Vector2(1, 0), Vector2(0, 0)]
	unit.h_speed = 0
	GameUtils.reangle_move(unit, angle_helper)

func ground_placement(unit : Unit):
	for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
		if unit_env_collider[0] != Vector2(0, 0):
			continue
		for collider in bottom_left_colliders:
			if collider[0].x == collider[1].x:
				continue
			var collision_check : Vector2 = unit.pos + unit_env_collider[0]
			var altered_collision_check: Vector2 = collision_check
			altered_collision_check.y = altered_collision_check.y + .9
			var intersects_results = GameUtils.path_intersects_border(
				altered_collision_check,
				collision_check + Vector2(0, -.3),
				collider[0],
				collider[1])
			if intersects_results[0]:
				var collision_point = intersects_results[1]
				var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
				var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
				unit.pos.y = unit.pos.y + y_dist_to_translate
				var collider_set_pos_x = collision_point.x
				var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
				unit.pos.x = unit.pos.x + x_dist_to_translate
				return
	
func check_collision(unit : Unit, collider, collision_directions, delta):
	# true/false, collision direction, collision point, and unit env collider
	var env_collision = unit_is_colliding_w_env(unit, collider, collision_directions, delta)
	if env_collision[0]:
		var collision_dir = env_collision[1]
		var collision_point = env_collision[2]
		var unit_env_collider = env_collision[3]
		check_ground_collision(unit, collider, collision_point, unit_env_collider, delta)
		if collision_dir == Constants.Direction.UP:
			unit.v_speed = 0
			var collider_set_pos_y = collision_point.y - Constants.QUANTUM_DIST
			var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
			unit.pos.y = unit.pos.y + y_dist_to_translate
			if unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION] == Constants.UnitCurrentAction.JUMPING:
				unit.set_current_action(Constants.UnitCurrentAction.IDLE)
		elif collision_dir == Constants.Direction.LEFT or collision_dir == Constants.Direction.RIGHT:
			if (collider[0].x == collider[1].x
			or not unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]):
				unit.h_speed = 0
			var collider_set_pos_x = collision_point.x
			if collision_dir == Constants.Direction.LEFT:
				collider_set_pos_x = collider_set_pos_x + Constants.QUANTUM_DIST
			else:
				collider_set_pos_x = collider_set_pos_x - Constants.QUANTUM_DIST
			var x_dist_to_translate = collider_set_pos_x - (unit.pos.x + unit_env_collider[0].x)
			unit.pos.x = unit.pos.x + x_dist_to_translate

# handle collision with ground if any
func check_ground_collision(unit : Unit, collider, collision_point : Vector2, unit_env_collider, delta):
	if not unit_env_collider[1].has(Constants.Direction.DOWN):
		return
	if (not unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]
		and (collider[0].y == collider[1].y or (collider[0].x != collider[1].x and collider[0].y != collider[1].y))):
		unit.v_speed = -1 * abs(unit.h_speed)
		if unit.h_speed > 0:
			unit.h_speed = Constants.QUANTUM_DIST
		else:
			unit.h_speed = -1 * Constants.QUANTUM_DIST
		var collider_set_pos_y = collision_point.y + Constants.QUANTUM_DIST
		var y_dist_to_translate = collider_set_pos_y - (unit.pos.y + unit_env_collider[0].y)
		unit.pos.y = unit.pos.y + y_dist_to_translate
		var x_dist_to_translate = collision_point.x - (unit.pos.x + unit_env_collider[0].x)
		unit.pos.x = unit.pos.x + x_dist_to_translate
		unit.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, true)
		interact_grounded(unit, delta)
		if (unit.unit_conditions[Constants.UnitCondition.CURRENT_ACTION]) == Constants.UnitCurrentAction.JUMPING:
			unit.set_current_action(Constants.UnitCurrentAction.IDLE)

# returns true/false, collision direction, collision point, and unit env collider
func unit_is_colliding_w_env(unit : Unit, collider, directions, delta, grounded_check = false):
	for direction_to_check in directions:
		if (((direction_to_check == Constants.Direction.LEFT or direction_to_check == Constants.Direction.RIGHT)
		and collider[0].y == collider[1].y)
		or ((direction_to_check == Constants.Direction.UP or direction_to_check == Constants.Direction.DOWN)
		and collider[0].x == collider[1].x)):
			continue
		for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
			if not unit_env_collider[1].has(direction_to_check):
				continue
			if ((direction_to_check == Constants.Direction.LEFT or direction_to_check == Constants.Direction.RIGHT)
			and (collider[0].x != collider[1].x and collider[0].y != collider[1].y)
			and unit_env_collider[0] != Vector2(0, 0)):
				continue;
			var intersects_results = intersect_check_w_collider_uec_dir(unit, collider, direction_to_check, unit_env_collider, grounded_check, delta)
			if intersects_results[0]:
				return [intersects_results[0], direction_to_check, intersects_results[1], unit_env_collider]
	return [false, -1, Vector2(), {}]

func intersect_check_w_collider_uec_dir(unit : Unit, collider, direction_to_check : int, unit_env_collider, grounded_check : bool, delta):
	var unit_env_collider_vector = unit_env_collider[0]
	var collision_check : Vector2 = unit.pos + unit_env_collider_vector
	var altered_collision_check: Vector2 = collision_check
	if grounded_check:
		altered_collision_check.y = altered_collision_check.y + .9
	return GameUtils.path_intersects_border(
		altered_collision_check,
		collision_check + Vector2(unit.h_speed * delta, unit.v_speed * delta),
		collider[0],
		collider[1])

func interact_post(unit : Unit):
	# need to reground unit in case it ended up somewhere underneath ground level
	if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		ground_placement(unit)
