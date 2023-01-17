extends NPCUnit


func before_tick():
	if scene.rng.randf() < 0.5:
		facing = Constants.Direction.RIGHT
	else:
		facing = Constants.Direction.LEFT
