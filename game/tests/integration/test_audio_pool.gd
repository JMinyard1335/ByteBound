extends GutTest
## Covers AudioPool's AudioHandle contract: a handle stays valid only while it
## controls its original sound, and is invalidated by stop() and by player reuse
## (the ABA case the generation token defends against).
##
## Note: whether a sound is *audible* (is_playing() == true) needs a real audio
## driver, so that direction is left to manual verification; everything here is
## driver-independent.

const ONE_SHOT: AudioPoolStream = preload("res://Assets/Audio/pool-streams/playerJump.tres")

var _handles: Array[AudioHandle] = []


func after_each() -> void:
	# Stop anything a test left playing so sounds don't leak across tests.
	for handle in _handles:
		handle.stop()
	_handles.clear()


func _play(stream: AudioPoolStream) -> AudioHandle:
	var handle: AudioHandle = AudioPool.play(stream)
	_handles.append(handle)
	return handle


func test_play_returns_valid_handle_for_its_stream() -> void:
	var handle: AudioHandle = _play(ONE_SHOT)
	assert_true(handle.is_valid(), "fresh handle should be valid")
	assert_eq(handle.stream, ONE_SHOT, "handle reports the stream it started")


func test_stop_invalidates_handle() -> void:
	var handle: AudioHandle = _play(ONE_SHOT)
	handle.stop()
	assert_false(handle.is_valid(), "stopped handle is invalid")
	assert_false(handle.is_playing(), "stopped handle is not playing")
	assert_null(handle.stream, "invalid handle reports a null stream")


func test_reused_player_invalidates_stale_handle() -> void:
	# stop() frees the player back to the pool; the next play reuses it with a new
	# generation token, so the stale handle must report invalid.
	var stale: AudioHandle = _play(ONE_SHOT)
	stale.stop()
	var fresh: AudioHandle = _play(ONE_SHOT)
	assert_false(stale.is_valid(), "stale handle invalid after its player is reused")
	assert_true(fresh.is_valid(), "the new handle is valid")


func test_invalid_handle_is_inert() -> void:
	var handle: AudioHandle = AudioHandle.new()
	assert_false(handle.is_valid())
	assert_false(handle.is_playing())
	assert_null(handle.stream)
	handle.stop()                # must not crash
	handle.move_to(Vector2.ZERO) # must not crash
