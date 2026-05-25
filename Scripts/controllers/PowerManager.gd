extends Node
class_name PowerManager

# Referencias
var board: Board
var game_controller: GameController
var game_view: GameView

func setup(board_ref: Board, controller_ref: GameController, view_ref: GameView):
	board = board_ref
	game_controller = controller_ref
	game_view = view_ref

# ========== EJECUTAR PODER ==========
func execute_power(power_type: int, power_level: int, current_player: Jugador, rival: Jugador):
	print("🎯 Ejecutando poder:", Jugador.PowerType.keys()[power_type])
	
	match power_type:
		Jugador.PowerType.STEAL_ENERGY:
			execute_steal_energy(current_player, rival)
		
		Jugador.PowerType.REMOVE_PIECE:
			execute_remove_piece(current_player)
		
		Jugador.PowerType.REMOVE_LINE:
			execute_remove_line(current_player)
		
		Jugador.PowerType.SKIP_TURN:
			execute_skip_turn(current_player)

# ========== PODER MEDIO: ROBAR ENERGÍA ==========
func execute_steal_energy(current: Jugador, rival: Jugador):
	print("⚡ Robando energía del rival")
	
	# Robar 2 de energía del rival
	var stolen = min(2, rival.energy)
	rival.energy = max(0, rival.energy - stolen)
	current.energy = min(current.energy + stolen, Jugador.MAX_ENERGY)
	
	# Emitir señales de actualización
	rival.energy_updated.emit(rival.id, rival.energy)
	current.energy_updated.emit(current.id, current.energy)
	
	# Mostrar notificación
	if game_view and game_view.event_notification:
		game_view.event_notification.show_event(
			"¡ENERGÍA ROBADA!",
			"Jugador %d robó %d energía" % [current.id, stolen],
			"⚡🔫"
		)
	
	# Verificar si el rival perdió energía (podría afectar ability_ready)
	if rival.energy < Jugador.MAX_ENERGY:
		rival.ability_ready = false

# ========== PODER MEDIO: ELIMINAR FICHA ==========
func execute_remove_piece(current: Jugador):
	print("🗑️ Modo selección de ficha para eliminar")
	
	# Activar modo de selección en GameView
	if game_view:
		game_view.enter_piece_removal_mode(current)

# ========== PODER ALTO: ELIMINAR FILA O COLUMNA ==========
func execute_remove_line(current: Jugador):
	print("📏 Modo selección de fila/columna para eliminar")
	
	# Activar modo de selección de línea en GameView
	if game_view:
		game_view.enter_line_removal_mode(current)

# ========== PODER ALTO: SALTAR TURNO ==========
func execute_skip_turn(current: Jugador):
	print("⏭️ Saltando turno del rival")
	
	# Mostrar notificación
	if game_view and game_view.event_notification:
		game_view.event_notification.show_event(
			"¡TURNO SALTADO!",
			"El rival pierde su turno",
			"⏭️"
		)

# ========== ELIMINAR FICHA ESPECÍFICA ==========
func remove_specific_piece(row: int, col: int):
	if board == null:
		push_error("❌ PowerManager.remove_specific_piece: board es null")
		return false
		
		
	if row < 0 or row >= Board.ROWS or col < 0 or col >= Board.COLUMNS:
		return false
	
	# Eliminar la ficha del grid
	var removed_player = board.grid[row][col]
	if removed_player == null:
		return false
	
	board.grid[row][col] = null
	print("🗑️ Ficha eliminada en [", row, ",", col, "]")
	
	# Reacomodar fichas según gravedad actual
	board.apply_gravity_after_rotation()
	
	# Verificar si se formaron líneas de 4 después de eliminar
	var new_lines = board.detect_pending_lines()
	if new_lines.size() > 0:
		board.pending_lines = new_lines
		game_controller.rotation_event.emit(new_lines)
	
	# Emitir señal de actualización
	game_controller.board_changed.emit()
	
	# Verificar si el jugador que perdió la ficha ahora tiene 4 en raya (improbable pero posible)
	if board.check_winner(removed_player):
		game_controller.winner.emit(removed_player.id)
	
	return true

# ========== ELIMINAR FILA O COLUMNA COMPLETA ==========
func remove_line(row_or_col: int, is_column: bool):
	if board == null:
		push_error("❌ PowerManager.remove_line: board es null")
		return false
		
	var removed_any = false
	
	if is_column:
		# Eliminar columna completa
		print("🗑️ Eliminando columna", row_or_col)
		for row in range(Board.ROWS):
			if board.grid[row][row_or_col] != null:
				board.grid[row][row_or_col] = null
				removed_any = true
	else:
		# Eliminar fila completa
		print("🗑️ Eliminando fila", row_or_col)
		for col in range(Board.COLUMNS):
			if board.grid[row_or_col][col] != null:
				board.grid[row_or_col][col] = null
				removed_any = true
	
	if removed_any:
		# Reacomodar fichas
		board.apply_gravity_after_rotation()
		
		# Verificar nuevas líneas
		var new_lines = board.detect_pending_lines()
		if new_lines.size() > 0:
			board.pending_lines = new_lines
			game_controller.rotation_event.emit(new_lines)
		
		game_controller.board_changed.emit()
