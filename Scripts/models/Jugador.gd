extends Node

class_name Jugador

var id: int
var energy: int = 0
var color: Color

const MAX_ENERGY = 5
var ability_ready: bool = false


func _init(jugador_id: int, jugador_color: Color):
	id = jugador_id
	color = jugador_color

func add_energy(amount: int):
	energy += amount
	
	if energy >= MAX_ENERGY:
		energy = MAX_ENERGY
		ability_ready = true

func use_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		
		if energy < MAX_ENERGY:
			ability_ready = false
			
		return true
	return false
