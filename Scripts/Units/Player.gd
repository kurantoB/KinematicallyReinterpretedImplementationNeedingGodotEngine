extends Unit

# Player-specific code
class_name Player

const RECOIL_PUSHBACK = 15

func _init():
	pos = Vector2(position.x / Constants.GRID_SIZE, -1 * position.y / Constants.GRID_SIZE)
	position.x = position.x * Constants.SCALE_FACTOR
	position.y = position.y * Constants.SCALE_FACTOR

func execute_actions(delta):
	.execute_actions(delta)
	for action_num in Constants.UNIT_TYPE_ACTIONS[Constants.UnitType.PLAYER]:
		if !actions[action_num]:
			continue
		match action_num:
			# handle custom actions
			Constants.ActionType.RECOIL:
				recoil()
			_:
				pass

func recoil():
	if is_current_action_timer_done(Constants.UnitCurrentAction.RECOILING):
		set_current_action(Constants.UnitCurrentAction.IDLE)
	else:
		set_current_action(Constants.UnitCurrentAction.RECOILING)
		set_sprite(Constants.SpriteClass.RECOIL)

func handle_input(delta):
	scene.handle_player_input()

func _on_Player_area_entered(area: Area2D) -> void:
	if get_condition(Constants.UnitCondition.IS_INVINCIBLE, false):
		return
	if area is Unit:
		hit_from_area(area)

func hit_from_area(other_area : Area2D):
	var collision_dir : int
	if other_area.position > position:
		collision_dir = Constants.Direction.RIGHT
	else:
		collision_dir = Constants.Direction.LEFT
	hit(collision_dir)

func hit(dir : int):
	.hit(dir)
	set_unit_condition_with_timer(Constants.UnitCondition.IS_INVINCIBLE)
	start_flash()
	set_action(Constants.ActionType.RECOIL)
	set_current_action(Constants.UnitCurrentAction.RECOILING)
	set_unit_condition(Constants.UnitCondition.MOVING_STATUS, Constants.UnitMovingStatus.IDLE)

func invincibility_ended():
	is_flash = false
	if get_overlapping_areas().size() > 0:
		if get_overlapping_areas()[0] is Unit:
			hit_from_area(get_overlapping_areas()[0])

func handle_recoil():
	if not hit_queued:
		return
	hit_queued = false
	if get_condition(Constants.UnitCondition.IS_ON_GROUND, true):
		if h_speed > 0:
			if hit_dir == Constants.Direction.LEFT:
				v_speed += RECOIL_PUSHBACK
			else:
				v_speed -= RECOIL_PUSHBACK
		elif h_speed < 0:
			if hit_dir == Constants.Direction.LEFT:
				v_speed -= RECOIL_PUSHBACK
			else:
				v_speed += RECOIL_PUSHBACK
		else:
			v_speed = RECOIL_PUSHBACK
			if hit_dir == Constants.Direction.LEFT:
				h_speed = Constants.QUANTUM_DIST
			else:
				h_speed = -Constants.QUANTUM_DIST
		if v_speed < 0:
			h_speed *= -1
			v_speed = abs(v_speed)
	else:
		if hit_dir == Constants.Direction.LEFT:
			h_speed += RECOIL_PUSHBACK
		else:
			h_speed -= RECOIL_PUSHBACK
	facing = hit_dir
