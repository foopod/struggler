extends Node2D

@onready var enemy: Enemy = $Enemy
@onready var door: Door = $Door
@onready var player: Player = $Player

var suspicion: float = 0.0
var noise: float = 0.0

const SUSPICION_MAX: float = 100.0
const NOISE_DECAY: float = 5.0

enum Location { OFFSCREEN, SINK, KNIFE_BLOCK, DOORWAY, CHAIR }

@export var offscreen_point: Node2D
@export var sink_point: Node2D
@export var knife_block_point: Node2D
@export var doorway_point: Node2D
@export var chair_point: Node2D

@onready var location_points: Dictionary = {
	Location.OFFSCREEN: offscreen_point,
	Location.SINK: sink_point,
	Location.KNIFE_BLOCK: knife_block_point,
	Location.DOORWAY: doorway_point,
	Location.CHAIR: chair_point,
}

const WALK_SPEED: float = 20.0

enum EnemyState {
	WASHING_HANDS,
	CHECKING_ON_YOU,
	SHARPENING_KNIFE,
	OTHER_ROOM,
	KILLING,
}

var enemy_state: EnemyState = EnemyState.OTHER_ROOM
var is_player_dead: bool = false
var is_player_free: bool = false
var _busy: bool = false 

func _ready() -> void:
	change_state(EnemyState.OTHER_ROOM)


func _process(delta: float) -> void:
	noise = max(0.0, noise - NOISE_DECAY * delta)
	suspicion = clamp(suspicion + noise * delta * 0.1, 0.0, SUSPICION_MAX)
	
	print("suspicion: ", suspicion)
	print("noise: ", noise, "  state: ", enemy_state)

func _input(event):
	if !is_player_dead && !is_player_free && event.is_action_pressed("struggle"):
		player.struggle()
		player.play_struggle_sound()
		add_noise(10)
		await get_tree().create_timer(2).timeout
		player.free_player()

func add_noise(amount: float) -> void:
	noise += amount


func change_state(new_state: EnemyState) -> void:
	enemy_state = new_state
	_run_state(new_state)


func _run_state(state: EnemyState) -> void:
	if _busy:
		return
	_busy = true

	match state:
		EnemyState.OTHER_ROOM:
			await do_other_room()
		EnemyState.WASHING_HANDS:
			await wash_hands()
		EnemyState.SHARPENING_KNIFE:
			await sharpen_knife()
		EnemyState.CHECKING_ON_YOU:
			await check_on_you()
		EnemyState.KILLING:
			await kill()

	_busy = false

	_pick_next_state()


func _pick_next_state() -> void:
	if suspicion >= SUSPICION_MAX:
		change_state(EnemyState.KILLING)
		return
	if suspicion > 60.0 and enemy_state != EnemyState.CHECKING_ON_YOU:
		change_state(EnemyState.CHECKING_ON_YOU)
		return
	if suspicion > 100.0 and enemy_state != EnemyState.CHECKING_ON_YOU:
		change_state(EnemyState.KILLING)
		return

	match enemy_state:
		EnemyState.OTHER_ROOM:
			change_state(EnemyState.SHARPENING_KNIFE)
		EnemyState.WASHING_HANDS:
			change_state(EnemyState.SHARPENING_KNIFE)
		EnemyState.SHARPENING_KNIFE:
			change_state(EnemyState.CHECKING_ON_YOU)
		EnemyState.CHECKING_ON_YOU:
			change_state(EnemyState.OTHER_ROOM)
		_:
			change_state(EnemyState.OTHER_ROOM)

func walk_to(loc: Location) -> void:
	var target: Vector2 = location_points[loc].global_position
	enemy.face_toward(target)
	enemy.play_walk()
	enemy.start_footsteps_sound()
	await enemy.move_to(target, WALK_SPEED)
	enemy.stop_footsteps_sound()
	enemy.play_idle()


func wash_hands() -> void:
	await walk_to(Location.SINK)
	enemy.play_interact()
	enemy.play_water_sound()
	await get_tree().create_timer(6.1).timeout
	await walk_to(Location.OFFSCREEN)


func sharpen_knife() -> void:
	var sharpen_count = 1
	if randf() < 0.5:
		sharpen_count = 2
	await walk_to(Location.KNIFE_BLOCK)
	enemy.play_interact()
	enemy.play_sharpen_sound()
	await get_tree().create_timer(4).timeout
	if sharpen_count == 2:
		enemy.play_interact()
		enemy.play_sharpen_sound()
		await get_tree().create_timer(4).timeout
	await walk_to(Location.OFFSCREEN)


func check_on_you() -> void:
	await walk_to(Location.DOORWAY)
	enemy.play_open_door()
	door.play_open()
	await get_tree().create_timer(2.5).timeout
	enemy.play_close_door()
	door.play_close()
	await get_tree().create_timer(2.0).timeout
	suspicion = max(0.0, suspicion - 20.0)
	await walk_to(Location.OFFSCREEN)


func do_other_room() -> void:
	await get_tree().create_timer(2.0).timeout


func kill() -> void:
	await walk_to(Location.DOORWAY)
	enemy.play_open_door()
	door.play_open()
	await get_tree().create_timer(2.0).timeout
	await walk_to(Location.CHAIR)
	enemy.play_killing()
	await get_tree().create_timer(0.5).timeout
	player.kill()
	is_player_dead = true
	enemy.play_kill_sound()
	await get_tree().create_timer(2.2).timeout
	await walk_to(Location.DOORWAY)
	await walk_to(Location.OFFSCREEN)
	# TODO FADE TO BLACK
