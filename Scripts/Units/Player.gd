extends Unit

# Player-specific code
class_name Player

func execute_actions(delta):
	.execute_actions(delta)
	for action_num in Constants.UNIT_TYPE_ACTIONS[Constants.UnitType.PLAYER]:
		if !actions[action_num]:
			continue
		match action_num:
			# handle custom actions
			_:
				pass

func handle_input(delta):
	scene.handle_player_input()

func reset_current_action():
	scene.reset_player_current_action()
