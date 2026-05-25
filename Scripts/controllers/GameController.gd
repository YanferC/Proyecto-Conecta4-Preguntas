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
signal power_used(power_type: int, player_id: int)
signal mandatory_question_required(player_id: int)

var board: Board
var jugador1: Jugador
var jugador2: Jugador
var current_player: Jugador

var event_manager: EventManager
var question_system: QuestionSystem

var pending_row: int = -1
var pending_col: int = -1

var power_manager: PowerManager
var power_selection_dialog: Control
var waiting_for_power_selection: bool = false


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
	
	# Inicializar PowerManager
	power_manager = PowerManager.new()
	
	# Conectar señales de energía
	jugador1.energy_updated.connect(_on_energy_updated)
	jugador2.energy_updated.connect(_on_energy_updated)
	jugador1.power_unlocked.connect(_on_power_unlocked)
	jugador2.power_unlocked.connect(_on_power_unlocked)
	
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
	
	# VERIFICAR SI SE LLENÓ LA ENERGÍA (PREGUNTA OBLIGATORIA)
	if current_player.ability_ready and before_energy < Jugador.MAX_ENERGY:
		print("⚡ Energía completa - Mostrando pregunta obligatoria")
		emit_signal("energy_flash", current_player.id)
		emit_signal("mandatory_question_required", current_player.id)
		return  # ← IMPORTANTE: detener aquí hasta que responda
	
	# Verificar si confirmó una línea pendiente
	if board.check_line_confirmation(pending_row, pending_col, current_player):
		print("🎉 ¡Línea confirmada!")
		emit_signal("winner", current_player.id)
		return
	
	# Verificar ganador normal
	if board.check_winner(current_player):
		if board.pending_lines.size() > 0:
			print("⚠️ 4 en línea detectado, pero hay líneas pendientes")
		else:
			emit_signal("winner", current_player.id)
			return
	
	switch_turn()
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

# ========== MANEJAR CUANDO SE DESBLOQUEA UN PODER ==========
func _on_power_unlocked(power_type: int):
	print("🎉 Poder desbloqueado para jugador", current_player.id)
	
	# Mostrar diálogo de selección de poder
	if power_selection_dialog:
		power_selection_dialog.show_dialog(current_player.id)
		waiting_for_power_selection = true
		

# ========== SELECCIONAR PODER ==========
func select_power(power_type: int, power_level: int):
	if not waiting_for_power_selection:
		return
	
	waiting_for_power_selection = false
	
	# Asignar el poder seleccionado al jugador
	current_player.unlocked_power = power_type
	current_player.unlocked_power_level = power_level
	
	print("✅ Jugador", current_player.id, " seleccionó:", Jugador.PowerType.keys()[power_type])

# ========== MANEJAR RESPUESTA DE PREGUNTA OBLIGATORIA ==========
func handle_mandatory_question_answer(is_correct: bool):
	if is_correct:
		# Pregunta correcta: desbloquear poder (el jugador elige cuál)
		current_player.unlock_power(Jugador.PowerType.NONE, Jugador.PowerLevel.NONE)
		# El diálogo de selección se abrirá automáticamente por la señal power_unlocked
	else:
		# Pregunta incorrecta: bloquear poder y reiniciar energía
		current_player.block_power()

# ========== REINTENTAR CON PREGUNTA RÁPIDA ==========
func try_retry_power_with_quick_question():
	if current_player.retry_with_quick_question():
		# Mostrar pregunta rápida
		var question = question_system.get_random_quick_question()
		# Necesitas referencia al QuestionDialog
		# Esto se maneja mejor desde GameView
		return true
	return false

# ========== RESPUESTA CORRECTA EN PREGUNTA RÁPIDA (reintento) ==========
func on_quick_question_retry_success():
	if current_player.can_retry_with_quick and current_player.power_blocked:
		# Desbloquear poder
		current_player.unlock_power(Jugador.PowerType.NONE, Jugador.PowerLevel.NONE)
		# No reiniciar energía (ya está en 5)
		current_player.energy = Jugador.MAX_ENERGY
		current_player.energy_updated.emit(current_player.id, current_player.energy)

# ========== RESPUESTA INCORRECTA EN PREGUNTA RÁPIDA (reintento) ==========
func on_quick_question_retry_fail():
	if current_player.can_retry_with_quick and current_player.power_blocked:
		# Bloquear permanentemente, reiniciar energía a 0
		current_player.block_power()


# ========== MANEJAR ACTUALIZACIÓN DE ENERGÍA ==========
func _on_energy_updated(player_id: int, new_energy: int):
	# Emitir la señal energy_changed para que la UI se actualice
	emit_signal("energy_changed", player_id, new_energy)
	print("⚡ Energía actualizada - Jugador", player_id, ":", new_energy, "/", Jugador.MAX_ENERGY)
