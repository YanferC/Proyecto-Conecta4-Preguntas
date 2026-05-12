extends Node
class_name EventManager

# Configuración de probabilidades (suman 100)
var gravity_chance := 40
var block_column_chance := 30
var rotation_chance := 30
var turns_between_events := 4

var turn_counter := 0

func next_turn(board: Board, game: GameController):
	turn_counter += 1
	
	if turn_counter % turns_between_events == 0:
		trigger_event(board, game)

func trigger_event(board: Board, game: GameController):
	var roll = randi() % 100
	
	print("🎲 Roll de evento: ", roll)
	
	if roll < gravity_chance:
		trigger_gravity(board, game)
	elif roll < gravity_chance + block_column_chance:
		trigger_block_column(board, game)
	else:
		trigger_rotation(board, game)

func trigger_gravity(board: Board, game: GameController):
	print("⚠️ EVENTO: Cambio de gravedad")
	var old_direction = board.gravity_direction
	board.change_gravity()
	
	# Solo emitir si realmente cambió
	if old_direction != board.gravity_direction:
		game.on_gravity_event(board.gravity_direction)

func trigger_block_column(board: Board, game: GameController):
	print("⚠️ EVENTO: Columna bloqueada (próximamente)")
	# TODO: Implementar en la siguiente fase

func trigger_rotation(board: Board, game: GameController):
	print("⚠️ EVENTO: Rotación de tablero (próximamente)")
	# TODO: Implementar en la siguiente fase
