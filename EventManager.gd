extends Node

class_name EventManager

var turn_counter = 0

func next_turn():
	turn_counter += 1
	if turn_counter % 3 == 0:
		trigger_event()

func trigger_event():
	var event = randi() % 3
	
	match event:
		0:
			print("Cambio de gravedad")
		1:
			print("Columna bloqueada")
		2:
			print("Evento especial")
