extends Node2D

@onready var enemy: Enemy = $Enemy

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
var _busy: bool = false 


func _ready() -> void:
	change_state(EnemyState.OTHER_ROOM)


func _process(delta: float) -> void:
	noise = max(0.0, noise - NOISE_DECAY * delta)
	suspicion = clamp(suspicion + noise * delta * 0.1, 0.0, SUSPICION_MAX)
	
	print("suspicion: ", suspicion)
	print("noise: ", noise, "  state: ", enemy_state)


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

	match enemy_state:
		EnemyState.OTHER_ROOM:
			change_state(EnemyState.WASHING_HANDS)
		EnemyState.WASHING_HANDS:
			change_state(EnemyState.SHARPENING_KNIFE)
		EnemyState.SHARPENING_KNIFE:
			change_state(EnemyState.CHECKING_ON_YOU)
		EnemyState.CHECKING_ON_YOU:
			change_state(EnemyState.KILLING)
		_:
			change_state(EnemyState.OTHER_ROOM)

func walk_to(loc: Location) -> void:
	var target: Vector2 = location_points[loc].global_position
	enemy.face_toward(target)
	enemy.play_walk()
	await enemy.move_to(target, WALK_SPEED)
	enemy.play_idle()


func wash_hands() -> void:
	await walk_to(Location.SINK)
	enemy.play_interact()
	enemy.start_water()
	await get_tree().create_timer(3.0).timeout
	await walk_to(Location.OFFSCREEN)


func sharpen_knife() -> void:
	await walk_to(Location.KNIFE_BLOCK)
	enemy.play_interact()
	await get_tree().create_timer(3.0).timeout
	await walk_to(Location.OFFSCREEN)


func check_on_you() -> void:
	await walk_to(Location.DOORWAY)
	enemy.play_open_door()
	await get_tree().create_timer(2.0).timeout
	suspicion = max(0.0, suspicion - 20.0)
	await walk_to(Location.OFFSCREEN)


func do_other_room() -> void:
	await get_tree().create_timer(5.0).timeout


func kill() -> void:
	await walk_to(Location.CHAIR)
	enemy.play_killing()
	await get_tree().create_timer(2.0).timeout
