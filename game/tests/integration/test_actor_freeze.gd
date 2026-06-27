extends GutTest
## Verifies that [signal SignalHub.actors_freeze_requested] freezes an [Enemy]:
## its [LocomotionComponent] stops and its [BeehaveTree] is disabled (so it can
## neither move nor see/kill during a cutscene), and resumes on unfreeze.

const ENEMY_SCENE: PackedScene = preload("res://entites/enemy/enemy.tscn")

var _enemy: Enemy

func before_each() -> void:
	_enemy = add_child_autofree(ENEMY_SCENE.instantiate())
	await get_tree().process_frame # let _ready wire components / connect signals
	return

func test_freeze_signal_stops_enemy_and_disables_ai() -> void:
	_enemy.velocity = Vector2(120, 0)
	_enemy.walk.direction = 1.0

	SignalHub.actors_freeze_requested.emit(true)

	assert_true(_enemy.locomotion.frozen, "enemy locomotion should be frozen")
	assert_false(_enemy.behavior_tree.enabled, "enemy AI should be disabled while frozen")
	assert_eq(_enemy.velocity, Vector2.ZERO, "enemy velocity should be zeroed")
	assert_eq(_enemy.walk.direction, 0.0, "enemy walk intent should be cleared")
	return

func test_resume_signal_re_enables_enemy() -> void:
	SignalHub.actors_freeze_requested.emit(true)
	SignalHub.actors_freeze_requested.emit(false)

	assert_false(_enemy.locomotion.frozen, "enemy locomotion should resume")
	assert_true(_enemy.behavior_tree.enabled, "enemy AI should be re-enabled")
	return
