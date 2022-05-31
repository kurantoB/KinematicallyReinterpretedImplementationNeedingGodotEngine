extends Unit

# Player-specific code
class_name Player

var jump_available = true

func execute_actions(delta):
	for action_num in Constants.UNIT_TYPE_ACTIONS[Constants.UnitType.PLAYER]:
		if !actions[action_num]:
			continue
		match action_num:
			# handle custom actions
			_:
				pass
	.execute_actions(delta)
