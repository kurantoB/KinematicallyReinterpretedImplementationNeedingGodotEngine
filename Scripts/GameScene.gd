extends Node

# _process(delta) is called by this class
# player input is handled here
# unit declares its intention in process_unit()
# stage environment interacts with the unit in interact()
# unit executes its resulting state in react()
# stage environment interacts with the unit once more in interact_post()
class_name GameScene

export var tile_set_name: String
const Constants = preload("res://Scripts/Constants.gd")
const Unit = preload("res://Scripts/Unit.gd")
const UNIT_DIRECTORY = {
	Constants.UnitType.NPC: preload("res://Units/NPC.tscn"),
}

# positions to unit string
export var spawning : Dictionary
var spawning_map = {} # keeps track of what's alive

var paused : bool = false

var units = []
var player : Player
var player_cam : Camera2D

# [pressed?, just pressed?, just released?]
var input_table = {
	Constants.PlayerInput.UP: [false, false, false],
	Constants.PlayerInput.DOWN: [false, false, false],
	Constants.PlayerInput.LEFT: [false, false, false],
	Constants.PlayerInput.RIGHT: [false, false, false],
	Constants.PlayerInput.GBA_A: [false, false, false],
	Constants.PlayerInput.GBA_B: [false, false, false],
	Constants.PlayerInput.GBA_SELECT: [false, false, false],
}
const I_T_PRESSED : int = 0
const I_T_JUST_PRESSED : int = 1
const I_T_JUST_RELEASED : int = 2

var stage_env

var time_elapsed : float = 0

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	units.append(get_node("Player"))
	player = units[0]
	player.init_unit_w_scene(self)
	player_cam = player.get_node("Camera2D")
	player_cam.make_current()
	
	stage_env = load("res://Scripts/StageEnvironment.gd").new(self)
	player.get_node("Camera2D").make_current()
	for spawning_key in spawning:
		spawning_map[spawning_key] = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# visual effects
	if (player.facing == Constants.Direction.RIGHT):
		player_cam.offset_h = 1
	else:
		player_cam.offset_h = -1
	
	read_paused()
	if not paused:
		# game logic
		process_spawning()
		for unit in units:
			unit.reset_actions()
			unit.handle_input(delta)
			unit.process_unit(delta, time_elapsed)
			stage_env.interact(unit, delta)
			unit.react(delta)
		time_elapsed += delta

func read_paused():
	if Input.is_action_just_pressed(Constants.INPUT_MAP[Constants.PlayerInput.GBA_START]):
		paused = !paused

func process_spawning():
	for one_spawn in spawning.keys():
		if spawning_map[one_spawn] != null:
			continue
		if abs(one_spawn[0] - player.pos.x) >= Constants.SPAWN_DISTANCE + 1 or abs(one_spawn[1] - player.pos.y) >= Constants.SPAWN_DISTANCE + 1:
			continue
		if abs(one_spawn[0] - player.pos.x) <= Constants.SPAWN_DISTANCE:
			continue
		# NPCUnit
		var npc_scene = UNIT_DIRECTORY[Constants.UnitType.get(spawning[one_spawn])]
		var npc_instance = npc_scene.instance()
		add_child(npc_instance)
		units.append(npc_instance)
		npc_instance.spawn_point = one_spawn
		spawning_map[one_spawn] = npc_instance
		npc_instance.pos.x = one_spawn[0]
		npc_instance.pos.y = one_spawn[1]
		npc_instance.position.x = npc_instance.pos.x * Constants.GRID_SIZE
		npc_instance.position.y = -1 * npc_instance.pos.y * Constants.GRID_SIZE
		npc_instance.init_unit_w_scene(self)

func handle_player_input():
	# early exit
	
	if player.get_current_action() == Constants.UnitCurrentAction.RECOILING:
		player.set_action(Constants.ActionType.RECOIL)
		return
	
	for input_num in input_table.keys():
		if Input.is_action_pressed(Constants.INPUT_MAP[input_num]):
			input_table[input_num][I_T_PRESSED] = true
			input_table[input_num][I_T_JUST_RELEASED] = false
			if Input.is_action_just_pressed(Constants.INPUT_MAP[input_num]):
				input_table[input_num][I_T_JUST_PRESSED] = true
			else:
				input_table[input_num][I_T_JUST_PRESSED] = false
		else:
			input_table[input_num][I_T_PRESSED] = false
			input_table[input_num][I_T_JUST_PRESSED] = false
			if Input.is_action_just_released(Constants.INPUT_MAP[input_num]):
				input_table[input_num][I_T_JUST_RELEASED] = true
			else:
				input_table[input_num][I_T_JUST_RELEASED] = false
	
	# process input_table
	
	if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] or input_table[Constants.PlayerInput.RIGHT][I_T_PRESSED]:
		if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] and input_table[Constants.PlayerInput.RIGHT][I_T_PRESSED]:
			input_table[Constants.PlayerInput.LEFT][I_T_PRESSED] = false
			input_table[Constants.PlayerInput.LEFT][I_T_JUST_PRESSED] = false
		var input_dir
		if input_table[Constants.PlayerInput.LEFT][I_T_PRESSED]:
			input_dir = Constants.Direction.LEFT
		else:
			input_dir = Constants.Direction.RIGHT
		# if action-idle or action-jumping
		if (player.get_current_action() == Constants.UnitCurrentAction.IDLE
		or player.get_current_action() == Constants.UnitCurrentAction.JUMPING):
			# set move
			player.set_action(Constants.ActionType.MOVE)
			# set facing
			player.facing = input_dir
	
	if input_table[Constants.PlayerInput.GBA_A][I_T_PRESSED]:
		if (player.get_current_action() == Constants.UnitCurrentAction.JUMPING
		or (player.get_current_action() == Constants.UnitCurrentAction.IDLE
		and player.unit_conditions[Constants.UnitCondition.IS_ON_GROUND]
		and input_table[Constants.PlayerInput.GBA_A][I_T_JUST_PRESSED])):
			player.set_action(Constants.ActionType.JUMP)
