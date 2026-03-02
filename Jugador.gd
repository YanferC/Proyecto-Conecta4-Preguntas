extends Node

class_name Jugador

var id: int
var energy: int = 0
var color: Color

func _init(jugador_id: int, jugador_color: Color):
	id = jugador_id
	color = jugador_color

func add_energy(amount: int):
	energy += amount

func use_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		return true
	return false
