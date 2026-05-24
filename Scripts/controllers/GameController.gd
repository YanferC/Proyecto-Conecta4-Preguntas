extends Node
class_name GameController

signal board_changed
signal energy_flash(player_id: int)
signal energy_changed(player_id: int, energy: int)  # ← NUEVA SEÑAL
signal gravity_event(direction: int)
signal block_event(index: int, gravity_dir: int) 
signal winner(player_id: int)
signal reset_done
signal piece_placed(row: int, col: int, player: Jugador)
signal rotation_event(pending_lines: Array[Dictionary])

var board: Board
var jugador1: Jugador
var jugador2: Jugador
var current_player: Jugador

var event_manager: EventManager
var question_system: QuestionSystem

var pending_row: int = -1
var pending_col: int = -1

func _ready():
	randomize()
	_new_game()

func _new_game():
	board = Board.new()
	jugador1 = Jugador.new(1, Color(0.6, 0.2, 0.8))
	jugador2 = Jugador.new(2, Color(1.0, 0.3, 0.7))
	current_player = jugador1
	
	event_manager = EventManager.new()
	question_system = QuestionSystem.new()
	
	emit_signal("board_changed")

# ========== COLOCAR FICHA EN COLUMNA (gravedad vertical) ==========
func try_place_piece(column: int):
	var pos = board.drop_piece(column, current_player)
	if pos.x == -1:
		print("Columna inválida o llena")
		return
	
	pending_row = pos.x
	pending_col = pos.y
	
	emit_signal("piece_placed", pos.x, pos.y, current_player)

# ========== COLOCAR FICHA EN FILA (gravedad horizontal) ==========
func try_place_piece_row(row: int):
	var pos = board.drop_piece_horizontal(row, current_player)
	if pos.x == -1:
		print("Fila inválida o llena")
		return
	
	pending_row = pos.x
	pending_col = pos.y
	
	emit_signal("piece_placed", pos.x, pos.y, current_player)

func on_rotation_event(pending_lines: Array[Dictionary]):
	print("📡 GameController emitiendo señal de rotación")
	emit_signal("rotation_event", pending_lines)
	emit_signal("board_changed")


func continue_turn_after_animation():
	var before_energy = current_player.energy
	board.calculate_energy(pending_row, pending_col, current_player)
	
	if current_player.energy != before_energy:
		print("📊 Energía cambiada: Jugador", current_player.id, "→", current_player.energy)
		emit_signal("energy_changed", current_player.id, current_player.energy)
	
	if current_player.ability_ready and before_energy < Jugador.MAX_ENERGY:
		emit_signal("energy_flash", current_player.id)
	
	# ========== VERIFICAR SI CONFIRMÓ UNA LÍNEA PENDIENTE ==========
	if board.check_line_confirmation(pending_row, pending_col, current_player):
		print("🎉 ¡Línea confirmada!")
		emit_signal("winner", current_player.id)
		return
	
	# Verificar ganador normal
	if board.check_winner(current_player):
		# Si hay líneas pendientes, NO declarar ganador aún
		if board.pending_lines.size() > 0:
			print("⚠️ 4 en línea detectado, pero hay líneas pendientes")
		else:
			emit_signal("winner", current_player.id)
			return
	
	switch_turn()
	
	# Reducir contador de líneas pendientes
	board.reduce_pending_line_turns()
	
	event_manager.next_turn(board, self)
	emit_signal("board_changed")

func switch_turn():
	current_player = jugador2 if current_player == jugador1 else jugador1

func reset_game():
	_new_game()
	emit_signal("reset_done")

func on_gravity_event(direction):
	emit_signal("gravity_event", direction)

# ========== CALLBACK PARA EVENTO DE BLOQUEO ==========
func on_block_event(index: int, gravity_dir: int):
	emit_signal("block_event", index, gravity_dir)
	emit_signal("board_changed")  # Actualizar vista
