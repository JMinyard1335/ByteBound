class_name HealthComponent
extends Node

signal health_changed(amt: int, new_health: int)
signal health_depleated()
signal health_full(max: int)

@export var max_health: int = 100
var health: int 

func _ready() -> void:
	health = max_health


func take_damage(amt: int) -> int:
	amt = abs(amt)
	health = max(0, health - amt)
	if health == 0:
		health_depleated.emit()
		return health
	
	health_changed.emit(amt, health)
	return health


func heal(amt: int) -> int:
	amt = abs(amt)
	health = min(max_health, health + amt)
	if health == max_health:
		health_full.emit(max_health)
		return health
	
	health_changed.emit(amt, health)
	return health
