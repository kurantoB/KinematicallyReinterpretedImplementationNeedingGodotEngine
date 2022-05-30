extends Unit

# Player-specific code
class_name Player

var jump_available = true

func handle_input_move():
	actions[Constants.ActionType.MOVE] = true
	unit_conditions[Constants.UnitCondition.MOVING_STATUS] = Constants.UnitMovingStatus.MOVING

func execute_actions(delta, scene):
	for action_num in actions.keys():
		if !actions[action_num]:
			continue
		var found_action = true
		match action_num:
			# handle custom actions
			_:
				found_action = false
		if found_action:
			actions[action_num] = false
	.execute_actions(delta, scene)
