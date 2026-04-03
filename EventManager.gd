extends Node

class_name EventManager

# CONFIGURACIÓN GLOBAL EDITABLE
var gravity_chance := 40
var block_column_chance := 40
var rotation_chance := 20
var turns_between_events := 4

var turn_counter = 0

func next_turn(board, game):
	turn_counter += 1
	if turn_counter % turns_between_events == 0:
		trigger_event(board, game)

func trigger_event(board, game):
	var roll = randi() % 100
	
	if roll < gravity_chance:
		trigger_gravity(board, game)
		
	elif roll < gravity_chance + block_column_chance:
		trigger_block_column(board)
		
	else:
		trigger_rotation(board)
		
func trigger_gravity(board, game):
	print("⚠ Cambio de gravedad")
	board.change_gravity()
	game.on_gravity_event(board.gravity_direction)


func trigger_block_column(board):
	print("⚠ Columna bloqueada (aún no implementada)")


func trigger_rotation(board):
	print("⚠ Rotación (aún no implementada)")
