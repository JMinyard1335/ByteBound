class_name Laser extends Area2D
## A hazard beam toggled by buttons on its channel.
##
## Thin coordinator: wires a [ChannelReceiverComponent] to a [HazardComponent] and
## the visuals. A pedestal opens it permanently; a pressure plate opens it while held.

const LASER_FIELD: AudioPoolStream = preload("res://Assets/Audio/pool-streams/laserField.tres")
const LASER_COLLISION: AudioPoolStream = preload("res://Assets/Audio/pool-streams/laserCollision.tres")

## Behaviour preset for the beam hazard, handed to [member hazard] on ready.
@export var stats: HazardStats
@export var hazard: HazardComponent
@export var receiver: ChannelReceiverComponent
@export var sprite: AnimatedSprite2D
@export var light: PointLight2D
## When true, the first time this laser deactivates it plays a focus cutscene
## (camera pans here, all actors frozen). Set false to disable the pan for this laser.
@export var play_cutscene: bool = true
## How long the cutscene holds on this laser after panning in.
@export var cutscene_hold: float = 1.0

var perma_open: bool = false
# Set when reactivated so _process replays "Active" after the "Activate" anim.
var just_activated: bool = false
# True once this laser has played its deactivation cutscene (de-dup per level).
var _cutscene_played: bool = false
var _laser_field_handle: AudioHandle

func _ready() -> void:
	assert(stats, "Laser: stats (HazardStats) not set")
	hazard.init(stats)
	receiver.activated.connect(_on_activated)
	receiver.deactivated.connect(_on_deactivated)
	hazard.struck.connect(_on_struck)
	sprite.play("Active")
	light.enabled = true
	_update_sound()

func _process(_delta: float) -> void:
	if not sprite.is_playing() and just_activated:
		sprite.play("Active")
		just_activated = false
	_update_sound()

func _exit_tree() -> void:
	_stop_laser_sound()
	return

func _on_activated(by_pedestal: bool) -> void:
	if by_pedestal:
		perma_open = true
		if hazard.active:
			_deactivate()
	elif hazard.active and not perma_open:
		_deactivate()

func _on_deactivated() -> void:
	if not hazard.active and not perma_open:
		_activate()

func _on_struck(_body: Node2D) -> void:
	AudioPool.play(LASER_COLLISION, global_position)

func _deactivate() -> void:
	hazard.active = false
	sprite.play("Disabled")
	light.enabled = false
	if play_cutscene and not _cutscene_played:
		_cutscene_played = true
		CutsceneManager.play(self, cutscene_hold)

func _activate() -> void:
	hazard.active = true
	sprite.play("Activate")
	light.enabled = true
	just_activated = true

func _update_sound() -> void:
	if hazard.active:
		if _laser_field_handle == null or not _laser_field_handle.is_playing():
			_laser_field_handle = AudioPool.play(LASER_FIELD, global_position)
		else:
			_laser_field_handle.move_to(global_position)
		return
	_stop_laser_sound()
	return

func _stop_laser_sound() -> void:
	if _laser_field_handle and _laser_field_handle.is_valid():
		_laser_field_handle.stop()
	_laser_field_handle = null
	return
