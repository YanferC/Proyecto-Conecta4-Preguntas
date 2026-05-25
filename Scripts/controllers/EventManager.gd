extends Node
class_name EventManager

# Configuración de probabilidades (suman 100)
var gravity_chance := 45
var block_column_chance := 45
var rotation_chance := 10
var turns_between_events := 4

var turn_counter := 0

func next_turn(board: Board, game: GameController):
	turn_counter += 1
	
	# REDUCIR CONTADOR DE BLOQUEO CADA TURNO
	board.reduce_block_turns()
	
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
	
	if old_direction != board.gravity_direction:
		game.on_gravity_event(board.gravity_direction)

func trigger_block_column(board: Board, game: GameController):
	print("⚠️ EVENTO: Bloquear columna/fila")
	var blocked_index = board.block_random_column()
	
	if blocked_index != -1:
		game.on_block_event(blocked_index, board.gravity_direction)

func trigger_rotation(board: Board, game: GameController):
	print("⚠️ EVENTO: Rotación de tablero")
	
	# 1. Rotar el tablero 180°
	board.rotate_board_180()
	
	# 2. Aplicar gravedad
	board.apply_gravity_after_rotation()
	
	# 3. Detectar líneas de 4 formadas
	var new_lines = board.detect_pending_lines()
	
	if new_lines.size() > 0:
		print("🎯", new_lines.size(), "líneas de 4 detectadas")
		board.pending_lines = new_lines
		game.on_rotation_event(new_lines)
	else:
		print("✅ Rotación completa sin líneas formadas")
		game.on_rotation_event([])
