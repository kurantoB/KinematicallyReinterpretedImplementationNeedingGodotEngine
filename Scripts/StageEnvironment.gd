# Handles unit-environment iteraction
extends Object

const GameUtils = preload("res://Scripts/GameUtils.gd")
const Constants = preload("res://Scripts/Constants.gd")
const GameScene = preload("res://Scripts/GameScene.gd")
const Unit = preload("res://Scripts/Unit.gd")

var scene : GameScene

var colliders = []
# if unit's move vector has at least one of these directional components,
# do the collision check
var collision_into_direction_arrays = [] # nested array

var unit_collision_bounds = {} # maps unit type to [upper, lower, left, right]

func _init(the_scene : GameScene):
	scene = the_scene
	var stage : TileMap = scene.get_node("Stage")
	init_stage_grid(stage)
	stage.scale.x = Constants.SCALE_FACTOR
	stage.scale.y = Constants.SCALE_FACTOR
	for unit in scene.units:
		unit.pos = Vector2(unit.position.x / scene.Constants.GRID_SIZE, -1 * unit.position.y / scene.Constants.GRID_SIZE)
		unit.position.x = unit.position.x * scene.Constants.SCALE_FACTOR
		unit.position.y = unit.position.y * scene.Constants.SCALE_FACTOR
		unit.scale.x = Constants.SCALE_FACTOR
		unit.scale.y = Constants.SCALE_FACTOR
	# populate unit_collision_bounds
	for unit_type in Constants.ENV_COLLIDERS.keys():
		var initial_detect_pt = Constants.ENV_COLLIDERS[unit_type][0]
		var upper : float = initial_detect_pt[0].y
		var lower : float = initial_detect_pt[0].y
		var left : float = initial_detect_pt[0].x
		var right: float = initial_detect_pt[0].x
		for detect_pt in Constants.ENV_COLLIDERS[unit_type]:
			if (detect_pt[1].find(Constants.Direction.UP) != -1
			and detect_pt[0].y > upper):
				upper = detect_pt[0].y
			if (detect_pt[1].find(Constants.Direction.DOWN) != -1
			and detect_pt[0].y < lower):
				lower = detect_pt[0].y
			if (detect_pt[1].find(Constants.Direction.LEFT) != -1
			and detect_pt[0].x < left):
				left = detect_pt[0].x
			if (detect_pt[1].find(Constants.Direction.RIGHT) != -1
			and detect_pt[0].x > right):
				right = detect_pt[0].x
		unit_collision_bounds[unit_type] = [upper, lower, left, right]

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
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + 1),
					[Constants.Direction.RIGHT, Constants.Direction.DOWN]
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
			Constants.MapElemType.SLOPE_RIGHT:
				try_insert_collider(
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y),
					[Constants.Direction.LEFT, Constants.Direction.DOWN]
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
			Constants.MapElemType.SMALL_SLOPE_LEFT_1:
				try_insert_collider(
					Vector2(stage_x, stage_y),
					Vector2(stage_x + 1, stage_y + .5),
					[Constants.Direction.RIGHT, Constants.Direction.DOWN]
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
			Constants.MapElemType.SMALL_SLOPE_LEFT_2:
				try_insert_collider(
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y + 1),
					[Constants.Direction.RIGHT, Constants.Direction.DOWN]
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
			Constants.MapElemType.SMALL_SLOPE_RIGHT_1:
				try_insert_collider(
					Vector2(stage_x, stage_y + .5),
					Vector2(stage_x + 1, stage_y),
					[Constants.Direction.LEFT, Constants.Direction.DOWN]
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
			Constants.MapElemType.SMALL_SLOPE_RIGHT_2:
				try_insert_collider(
					Vector2(stage_x, stage_y + 1),
					Vector2(stage_x + 1, stage_y + .5),
					[Constants.Direction.LEFT, Constants.Direction.DOWN]
				)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.RIGHT, 1)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.LEFT, .5)
				insert_grid_collider(stage_x, stage_y, Constants.Direction.UP, 1)
			Constants.MapElemType.LEDGE:
				insert_grid_collider(stage_x, stage_y, Constants.Direction.DOWN, 1)


func insert_grid_collider(stage_x, stage_y, direction : int, fractional_height : float):
	var check_colliders = []
	var insert_colliders = []
	var point_a : Vector2
	var point_b : Vector2
	match direction:
		Constants.Direction.UP:
			point_a = Vector2(stage_x, stage_y)
			point_b = Vector2(stage_x + 1, stage_y)
		Constants.Direction.DOWN:
			point_a = Vector2(stage_x, stage_y + 1)
			point_b = Vector2(stage_x + 1, stage_y + 1)
		Constants.Direction.LEFT:
			point_a = Vector2(stage_x + 1, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x + 1, stage_y)
		Constants.Direction.RIGHT:
			point_a = Vector2(stage_x, stage_y + (1 * fractional_height))
			point_b = Vector2(stage_x, stage_y)
	try_insert_collider(point_a, point_b, [direction])

func try_insert_collider(point_a : Vector2, point_b : Vector2, directions : Array):
	if directions.size() == 1:
		# aligned with grid
		for i in range(len(colliders)):
			if (colliders[i][0] == point_a
			and colliders[i][1] == point_b
			and are_inverse_directions(collision_into_direction_arrays[i][0], directions[0])):
				colliders.remove(i)
				collision_into_direction_arrays.remove(i)
				return
	colliders.append([point_a, point_b])
	collision_into_direction_arrays.append(directions)

func are_inverse_directions(d1, d2):
	return ((d1 == Constants.Direction.LEFT and d2 == Constants.Direction.RIGHT)
	or (d1 == Constants.Direction.RIGHT and d2 == Constants.Direction.LEFT)
	or (d1 == Constants.Direction.UP and d2 == Constants.Direction.DOWN)
	or (d1 == Constants.Direction.DOWN and d2 == Constants.Direction.UP))

func interact(unit : Unit, delta):
	if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
		if unit.v_speed < 0:
			# reassign the move speeds so that it reflects the true movement
			reangle_grounded_move(unit)
	else:
		# apply gravity
		unit.v_speed = max(unit.v_speed - (Constants.GRAVITY * delta), Constants.MAX_FALL_SPEED)
	if not unit.h_speed == 0 or not unit.v_speed == 0:
		# regular collision
		for i in range(colliders.size()):
			if check_collision(unit, colliders[i], collision_into_direction_arrays[i], delta):
				break
		# Do this a second time in case the unit's new move displacement needs
		# fixing
		for i in range(colliders.size()):
			if check_collision(unit, colliders[i], collision_into_direction_arrays[i], delta):
				break

func reangle_grounded_move(unit : Unit):
	var has_ground_collision : bool = false
	for i in range(colliders.size()):
		var collider = colliders[i]
		var collision_into_directions = collision_into_direction_arrays[i]
		if collider[0].x == collider[1].x:
			continue
		if collision_early_exit(unit, collider, collision_into_directions):
			continue
		if collision_into_directions.find(Constants.Direction.DOWN) == -1:
			continue
		# returns [collision?, x, y]
		var intersects_results =  GameUtils.path_intersects_border(
			Vector2(unit.pos.x, unit.pos.y),
			# Vector2(unit.pos.x, unit.pos.y - (Constants.QUANTUM_DIST * 2)),
			Vector2(unit.pos.x, unit.pos.y - .5),
			collider[0],
			collider[1])
		if intersects_results[0]:
			has_ground_collision = true
			unit.pos.y = intersects_results[1].y + Constants.QUANTUM_DIST
			unit.last_contacted_ground_collider = collider
			reangle_move(unit, collider, true)
	if !has_ground_collision:
		reangle_move(unit, unit.last_contacted_ground_collider, true)
		unit.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, false)

# nullify_h_speed should be true if we are reangling a ground movement vector
func reangle_move(unit : Unit, collider, nullify_h_speed : bool):
	var angle_helper
	if unit.h_speed > 0:
		angle_helper = collider
	else:
		angle_helper = [collider[1], collider[0]]
	if nullify_h_speed:
		unit.h_speed = 0
	GameUtils.reangle_move(unit, angle_helper)

func check_collision(unit : Unit, collider, collision_into_directions, delta):
	if collision_early_exit(unit, collider, collision_into_directions):
		return false
	var is_ground_collision : bool = collision_into_directions.find(Constants.Direction.DOWN) != -1
	for unit_env_collider in Constants.ENV_COLLIDERS[unit.unit_type]:
		if unit_env_collider_early_exit(unit_env_collider[1], collision_into_directions):
			continue
		var collision_check_location : Vector2 = unit.pos + unit_env_collider[0]
		var collision_check_try_location : Vector2 = collision_check_location + Vector2(unit.h_speed * delta, unit.v_speed * delta)
		# returns [collision?, (x, y)]
		var intersects_results =  GameUtils.path_intersects_border(
			collision_check_location,
			collision_check_try_location,
			collider[0],
			collider[1])
		if intersects_results[0]:
			if is_ground_collision:
				if unit_env_collider[0] == Vector2(0, 0):
					unit.pos.y = intersects_results[1].y + Constants.QUANTUM_DIST
					unit.pos.x = intersects_results[1].x
					if unit.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]:
						# preserve magnitude
						reangle_move(unit, collider, false)
					else:
						if unit.get_current_action() != Constants.UnitCurrentAction.JUMPING:
							unit.set_unit_condition(Constants.UnitCondition.IS_ON_GROUND, true)
							# landed on ground, horizontal component to become magnitude
							unit.v_speed = 0
						reangle_move(unit, collider, false)
			else:
				if collider[0].x == collider[1].x:
					# vertical wall collision
					var new_cc_x : float
					if unit.h_speed < 0:
						new_cc_x = intersects_results[1].x + Constants.QUANTUM_DIST
					else:
						new_cc_x = intersects_results[1].x - Constants.QUANTUM_DIST
					var target_h_speed : float = (new_cc_x - collision_check_location.x) / delta
					var factor : float = target_h_speed / unit.h_speed
					unit.h_speed *= factor
					if unit.get_condition(Constants.UnitCondition.IS_ON_GROUND, false):
						# also shorten vertical component to preserve move vector direction
						unit.v_speed *= factor
				else:
					# ceiling collision (horizontal only for now)
					var new_cc_y : float = intersects_results[1].y - Constants.QUANTUM_DIST
					unit.v_speed = (new_cc_y - collision_check_location.y) / delta
					if unit.get_current_action() == Constants.UnitCurrentAction.JUMPING:
						unit.set_current_action(Constants.UnitCurrentAction.IDLE)
			if !is_ground_collision or unit_env_collider[0] == Vector2(0, 0):
				# return true if there's a collision
				# don't return true if it's a ground collision but the unit environment collider is not the (0, 0) collider
				return true
	return false

func collision_early_exit(unit : Unit, collider, collision_into_directions):
	if (collider[0].y > unit.pos.y + unit_collision_bounds[unit.unit_type][0] + 1
	and collider[1].y > unit.pos.y + unit_collision_bounds[unit.unit_type][0] + 1):
		return true
	if (collider[0].y < unit.pos.y + unit_collision_bounds[unit.unit_type][1] - 1
	and collider[1].y < unit.pos.y + unit_collision_bounds[unit.unit_type][1] - 1):
		return true
	if collider[1].x < unit.pos.x + unit_collision_bounds[unit.unit_type][2] - 1:
		return true
	if collider[0].x > unit.pos.x + unit_collision_bounds[unit.unit_type][3] + 1:
		return true
	for collision_into_direction in collision_into_directions:
		if collision_into_direction == Constants.Direction.UP and unit.v_speed > 0:
			return false
		if collision_into_direction == Constants.Direction.DOWN and unit.v_speed < 0:
			return false
		if collision_into_direction == Constants.Direction.LEFT and unit.h_speed < 0:
			return false
		if collision_into_direction == Constants.Direction.RIGHT and unit.h_speed > 0:
			return false
	return true

func unit_env_collider_early_exit(env_collider_directions, collision_into_directions):
	var found_matching_direction : bool = false
	for env_collider_direction in env_collider_directions:
		for collision_into_direction in collision_into_directions:
			if env_collider_direction == collision_into_direction:
				return false
	return true
