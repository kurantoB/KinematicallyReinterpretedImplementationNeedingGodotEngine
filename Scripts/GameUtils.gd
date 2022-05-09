extends Node

# also returns x, y of intersection
static func path_intersects_border(path_from : Vector2, path_to : Vector2, border_pt_a : Vector2, border_pt_b : Vector2):
	# y = mx + b
	
	# if path is vertical
	if path_from.x == path_to.x:
		# if border is vertical
		if border_pt_a.x == border_pt_b.x:
			return [false, Vector2()]
		# if border is not vertical
		else:
			# if path x is not within range
			if path_from.x < min(border_pt_a.x, border_pt_b.x) or path_from.x > max(border_pt_a.x, border_pt_b.x):
				return [false, Vector2()]
			# find m and b and solve for where border intersects with vertical line
			var m = get_m(border_pt_b, border_pt_a)
			var b = get_b(border_pt_a, m)
			var intersect_y = m * path_from.x + b
			var intersects : bool = intersect_y >= min(path_from.y, path_to.y) and intersect_y <= max(path_from.y, path_to.y)
			return [intersects, Vector2(path_from.x, intersect_y)]
	# else if border is vertical
	elif border_pt_a.x == border_pt_b.x:
		# if border x is not within range
		if border_pt_a.x < min(path_from.x, path_to.x) or border_pt_a.x > max(path_from.x, path_to.x):
				return [false, Vector2()]
		# find m and b and solve for where border intersects with vertical line
		var m = get_m(path_to, path_from)
		var b = get_b(path_from, m)
		var intersect_y = m * border_pt_a.x + b
		return [intersect_y >= min(border_pt_a.y, border_pt_b.y) and intersect_y <= max(border_pt_a.y, border_pt_b.y), Vector2(border_pt_a.x, intersect_y)]
	# else if path and border are parallel
	elif get_m(path_to, path_from) == get_m(border_pt_b, border_pt_a):
		return [false, Vector2()]
	else:
		var path_m = get_m(path_to, path_from)
		var path_b = get_b(path_from, path_m)
		var border_m = get_m(border_pt_b, border_pt_a)
		var border_b = get_b(border_pt_a, border_m)
		# m1x + b1 = m2x + b2
		# m1x - m2x = b2 - b1
		# x = (b2 - b1) / (m1 - m2)
		var intersect_x = (border_b - path_b) / (path_m - border_m)
		return [(intersect_x >= min(border_pt_a.x, border_pt_b.x) and intersect_x <= max(border_pt_a.x, border_pt_b.x)
		and intersect_x >= min(path_from.x, path_to.x) and intersect_x <= max(path_from.x, path_to.x)), Vector2(intersect_x, path_m * intersect_x + path_b)]

static func get_m(pt_a : Vector2, pt_b : Vector2):
	return (pt_b.y - pt_a.y) / (pt_b.x - pt_a.x)

static func get_b(pt : Vector2, m : float):
	return pt.y - (m * pt.x)

static func reangle_move(unit, angle_helper):
	# pythagoras
	var unit_magnitude = sqrt(pow(unit.h_speed, 2) +  pow(unit.v_speed, 2))
	var helper_magnitude = sqrt(pow(angle_helper[1].x - angle_helper[0].x, 2) +  pow(angle_helper[1].y - angle_helper[0].y, 2))
	if helper_magnitude == 0:
		unit.h_speed = 0
		unit.v_speed = 0
		return
	var factor = unit_magnitude / helper_magnitude
	unit.h_speed = (angle_helper[1].x - angle_helper[0].x) * factor
	unit.v_speed = (angle_helper[1].y - angle_helper[0].y) * factor
