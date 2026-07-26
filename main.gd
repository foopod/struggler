extends Node2D

@onready var enemy: Enemy = $Enemy
@onready var door: Door = $Door
@onready var player: Player = $Player
@onready var blackRect: ColorRect = $Black

var suspicion: float = 0.0
var noise: float = 0.0
var freedom: float = 0.0

const SUSPICION_MAX: float = 100.0
const NOISE_DECAY: float = 5.0
const NOISE_MULTIPLIER: float = 5.0

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
const STRUGGLE_COOLDOWN: float = 1.5
const STRUGGLE_BUFFER: float = 1.5

enum EnemyState {
	WASHING_HANDS,
	CHECKING_ON_YOU,
	SHARPENING_KNIFE,
	OTHER_ROOM,
	KILLING,
	TIED_UP
}

var enemy_state: EnemyState = EnemyState.OTHER_ROOM
var is_player_dead: bool = false
var is_player_free: bool = false
var _busy: bool = false
var kill_marker = false
var _struggle_ready_at: float = 0.0
var _struggle_buffered: bool = false

func _ready() -> void:
	change_state(EnemyState.OTHER_ROOM)

	var serial : Serial = %Serial
	serial.imu_data_received.connect(_on_imu_data)


func _process(delta: float) -> void:
	noise = max(0.0, noise - NOISE_DECAY * delta)
	suspicion = clamp(suspicion + noise * delta * 0.1, 0.0, SUSPICION_MAX)

func _on_imu_data(linear_acceleration: Vector3) -> void:
	player.speed_scale = 0.3 * linear_acceleration.length()
	print(linear_acceleration.length())
	if (linear_acceleration.length() > 0.3):
		add_noise(NOISE_MULTIPLIER * linear_acceleration.length())
		player.struggle()
		player.play_struggle_sound()
		freedom += 1.2
		await get_tree().create_timer(2).timeout
		
		if freedom > 100:
			is_player_free = true
			player.free_player()


func _input(event):
	if (is_player_dead or is_player_free) && event.is_action_pressed("struggle") and blackRect.color.a == 1:
		get_tree().change_scene_to_file("res://main.tscn")
	if !is_player_dead && !is_player_free && event.is_action_pressed("struggle"):
		var now: float = Time.get_ticks_msec() / 1000.0
		if now >= _struggle_ready_at:
			do_struggle()
		elif now >= _struggle_ready_at - STRUGGLE_BUFFER:
			_struggle_buffered = true


func do_struggle() -> void:
	if is_player_free:
		return
	_struggle_ready_at = Time.get_ticks_msec() / 1000.0 + STRUGGLE_COOLDOWN
	player.struggle()
	player.play_struggle_sound()
	add_noise(10)
	freedom += 5
	await get_tree().create_timer(STRUGGLE_COOLDOWN).timeout

	if freedom > 100:
		is_player_free = true
		player.free_player()
	elif _struggle_buffered:
		_struggle_buffered = false
		if !is_player_dead && !is_player_free:
			do_struggle()

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
		EnemyState.TIED_UP:
			await get_tree().create_timer(60*10).timeout

	_busy = false
	_pick_next_state()


func _pick_next_state() -> void:
	if is_player_free or is_player_dead:
		change_state(EnemyState.TIED_UP)
		return
	if suspicion >= SUSPICION_MAX:
		change_state(EnemyState.KILLING)
		return
	if suspicion > 60.0 and randf() > 0.4 and enemy_state != EnemyState.CHECKING_ON_YOU:
		change_state(EnemyState.CHECKING_ON_YOU)
		return

	match enemy_state:
		EnemyState.OTHER_ROOM:
			var r = randf()
			if r < 0.25:
				change_state(EnemyState.SHARPENING_KNIFE)
			elif r < 0.5:
				change_state(EnemyState.CHECKING_ON_YOU)
			elif r < 0.75:
				change_state(EnemyState.WASHING_HANDS)
			else:
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


func watch_for_struggle(duration: float) -> bool:
	var end_time: int = Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end_time:
		if player.is_struggling():
			return true
		await get_tree().process_frame
	return player.is_struggling()


func check_on_you() -> void:
	await walk_to(Location.DOORWAY)
	enemy.play_open_door()
	door.play_open()
	var caught: bool = await watch_for_struggle(2.5)
	if caught:
		await walk_to(Location.CHAIR)
		enemy.play_killing()
		await get_tree().create_timer(0.5).timeout
		player.kill()
		is_player_dead = true
		enemy.play_kill_sound()
		await get_tree().create_timer(2.2).timeout
		await walk_to(Location.DOORWAY)
		await walk_to(Location.OFFSCREEN)
		blackRect.color.a = 1
	else:
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
	blackRect.color.a = 1
