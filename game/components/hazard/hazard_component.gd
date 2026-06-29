class_name HazardComponent
extends Node
## Damages the player while its owning [Area2D] is armed.
##
## A single, reusable hazard brain. The owner holds the [HazardStats] (so it stays
## editable on the instanced top-level node) and passes it down via [method init].
## The owner also supplies an [member area] (the damage zone) and — for proximity
## hazards — a [member proximity_area]. This component decides [i]when[/i] it is
## dangerous and applies damage to any overlapping body in the [code]"Player"[/code]
## group. It never reaches into the player beyond the [method Player.hurt] /
## [method Player.kill] contract, and reports its state through [signal phase_changed]
## / [signal struck] so the owning entity can drive visuals and audio.

## Emitted whenever the danger state changes. Owners swap sprite/light to match.
signal phase_changed(phase: Phase)
## Emitted each time the hazard deals damage to [param body]. For sfx / fx.
signal struck(body: Node2D)

## Danger state. [constant Phase.ARMED] is the only one that deals damage.
enum Phase {
	## Safe.
	IDLE,
	## Safe, but warning that arming is imminent (periodic / proximity charge).
	TELEGRAPH,
	## Dangerous: damages overlapping players.
	ARMED,
}

## The damage zone. Players overlapping it while armed take damage.
@export var area: Area2D
## Detection zone that arms the hazard. Required when the stats mode is PROXIMITY.
@export var proximity_area: Area2D

## Master enable. While false the hazard is forced safe (lasers toggle this).
var active: bool = true
## True while the hazard is currently dealing damage. Read-only.
var armed: bool = false

var _stats: HazardStats
var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _charge_t: float = 0.0
var _bodies: Array[Node2D] = []        # players overlapping the damage area
var _prox: Array[Node2D] = []          # players overlapping the proximity area
var _hit: Dictionary = {}              # body -> already hit this arming (interval 0)
var _tick: Dictionary = {}             # body -> seconds until next DOT tick


#region Engine Methods
func _physics_process(delta: float) -> void:
	if not active:
		_set_phase(Phase.IDLE)
		return

	match _stats.mode:
		HazardStats.Mode.CONTACT:
			_set_phase(Phase.ARMED)
		HazardStats.Mode.PERIODIC:
			_tick_periodic(delta)
		HazardStats.Mode.PROXIMITY:
			_tick_proximity(delta)

	if armed:
		_damage_bodies(delta)
#endregion


#region Public API
## Wires the hazard with its behaviour [param stats]. Call from the owner's
## [method Node._ready] so the stats can live on the editable top-level node.
func init(stats: HazardStats) -> void:
	assert(stats, "HazardComponent: stats (HazardStats) not provided to init()")
	assert(area, "HazardComponent: area (Area2D) not set")
	_stats = stats
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	if _stats.mode == HazardStats.Mode.PROXIMITY:
		assert(proximity_area, "HazardComponent: proximity_area required for PROXIMITY mode")
		proximity_area.body_entered.connect(_on_prox_entered)
		proximity_area.body_exited.connect(_on_prox_exited)
	_phase_t = _stats.idle_time
	if _stats.mode == HazardStats.Mode.CONTACT:
		_phase = Phase.ARMED
		armed = true


## Returns the current danger [enum Phase] (owners sync visuals on ready).
func get_phase() -> Phase:
	return _phase
#endregion


#region Signal Handlers
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player") or body in _bodies:
		return
	_bodies.append(body)
	_tick[body] = 0.0


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)
	_hit.erase(body)
	_tick.erase(body)


func _on_prox_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if _prox.is_empty():
		_charge_t = _stats.proximity_charge
	if body not in _prox:
		_prox.append(body)


func _on_prox_exited(body: Node2D) -> void:
	_prox.erase(body)
#endregion


#region Private Helpers
## Advances the periodic IDLE -> (TELEGRAPH) -> ARMED -> IDLE cycle.
func _tick_periodic(delta: float) -> void:
	_phase_t -= delta
	if _phase_t > 0.0:
		return
	match _phase:
		Phase.IDLE:
			if _stats.telegraph_time > 0.0:
				_phase_t = _stats.telegraph_time
				_set_phase(Phase.TELEGRAPH)
			else:
				_phase_t = _stats.active_time
				_set_phase(Phase.ARMED)
		Phase.TELEGRAPH:
			_phase_t = _stats.active_time
			_set_phase(Phase.ARMED)
		Phase.ARMED:
			_phase_t = _stats.idle_time
			_set_phase(Phase.IDLE)


## Arms while the player lingers in the proximity zone (after any charge delay).
func _tick_proximity(delta: float) -> void:
	if _prox.is_empty():
		_set_phase(Phase.IDLE)
		return
	if armed:
		return
	if _stats.proximity_charge > 0.0:
		_charge_t -= delta
		if _charge_t > 0.0:
			_set_phase(Phase.TELEGRAPH)
			return
	_set_phase(Phase.ARMED)


## Applies damage to overlapping players according to the stats' damage interval.
func _damage_bodies(delta: float) -> void:
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		if _stats.damage_interval <= 0.0:
			if not _hit.get(body, false):
				_hit[body] = true
				_strike(body)
		else:
			_tick[body] = _tick.get(body, 0.0) - delta
			if _tick[body] <= 0.0:
				_tick[body] = _stats.damage_interval
				_strike(body)


## Deals one hit to [param body] through the player damage contract.
func _strike(body: Node2D) -> void:
	if _stats.lethal and body.has_method("kill"):
		body.kill()
		struck.emit(body)
		return
	if not _stats.lethal and body.has_method("hurt"):
		body.hurt(_stats.damage)
		struck.emit(body)


## Updates the danger phase, syncing [member armed] and emitting on change.
func _set_phase(phase: Phase) -> void:
	if phase == _phase:
		return
	_phase = phase
	armed = phase == Phase.ARMED
	if not armed:
		_hit.clear()
	phase_changed.emit(phase)
#endregion
