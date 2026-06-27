extends GutTest
## Unit tests for the centralized "freeze player movement" mechanism:
## [LocomotionComponent.frozen], [InputComponent.enabled], and the [Player]
## coordinator reacting to [signal SignalHub.actors_freeze_requested].

const INPUT_SCENE: PackedScene = preload("res://components/input/input_component.tscn")
const PLAYER_SCENE: PackedScene = preload("res://entites/player/player.tscn")

# LocomotionComponent.frozen ---------------------------------------------------

func test_frozen_locomotion_zeroes_velocity_and_does_not_move() -> void:
	var body: CharacterBody2D = add_child_autofree(CharacterBody2D.new())
	body.collision_layer = 0
	body.collision_mask = 0
	var loco: LocomotionComponent = LocomotionComponent.new()
	loco.body = body
	body.add_child(loco)
	loco._ready()

	body.global_position = Vector2(100, 100)
	body.velocity = Vector2(250, -120)
	loco.frozen = true
	loco._physics_process(1.0 / 60.0)

	assert_eq(body.velocity, Vector2.ZERO, "frozen body velocity should be zeroed")
	assert_eq(body.global_position, Vector2(100, 100), "frozen body should not move")

# InputComponent.enabled -------------------------------------------------------

func test_disabled_input_reports_no_movement() -> void:
	var input: InputComponent = add_child_autofree(INPUT_SCENE.instantiate())
	input.enabled = false
	input._process(1.0 / 60.0)

	assert_eq(input.input_horizontal, 0.0, "disabled input_horizontal should be 0")
	assert_false(input.get_move(), "disabled get_move should be false")
	assert_false(input.get_jump(), "disabled get_jump should be false")
	assert_false(input.get_dash(), "disabled get_dash should be false")

# Player.set_movement_frozen ---------------------------------------------------

func test_set_movement_frozen_toggles_components() -> void:
	var player: Player = add_child_autofree(PLAYER_SCENE.instantiate())
	await get_tree().process_frame

	player.velocity = Vector2(200, 50)
	player.walk.direction = 1.0
	player.set_movement_frozen(true)

	assert_true(player.movement_frozen, "player should report frozen")
	assert_false(player.input.enabled, "input should be disabled while frozen")
	assert_true(player.locomotion.frozen, "locomotion should be frozen")
	assert_eq(player.velocity, Vector2.ZERO, "velocity should be zeroed on freeze")
	assert_eq(player.walk.direction, 0.0, "walk intent should be cleared on freeze")

	player.set_movement_frozen(false)
	assert_false(player.movement_frozen, "player should report unfrozen")
	assert_true(player.input.enabled, "input should be re-enabled on resume")
	assert_false(player.locomotion.frozen, "locomotion should resume")

# SignalHub trigger ------------------------------------------------------------

func test_freeze_signal_drives_the_player() -> void:
	var player: Player = add_child_autofree(PLAYER_SCENE.instantiate())
	await get_tree().process_frame

	SignalHub.actors_freeze_requested.emit(true)
	assert_true(player.movement_frozen, "freeze signal should freeze the player")

	SignalHub.actors_freeze_requested.emit(false)
	assert_false(player.movement_frozen, "resume signal should unfreeze the player")
