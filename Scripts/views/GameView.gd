extends Node2D
class_name GameView

@onready var controller: GameController = $GameController
@onready var power_sound: AudioStreamPlayer = $PowerSound
@onready var event_notification: EventNotification = $UI/EventNotification
@onready var game_hud: GameHUD = $UI/GameHud  
@onready var question_dialog: QuestionDialog = $UI/QuestionDialog
@onready var quick_question_button: Button = $UI/QuickQuestionButton


const CELL_SIZE := 80
var OFFSET_X := 0.0
var OFFSET_Y := 0.0

const PieceScene = preload("res://scenes/Piece/Piece.tscn")
var pieces: Array[Piece] = []
var is_piece_falling: bool = false

var hovered_cell: Vector2i = Vector2i(-1, -1)
var clickable_cells: Array[Vector2i] = []

const HOVER_COLOR := Color(0.2, 0.8, 0.4, 0.4)
const CLICKABLE_COLOR := Color(0.2, 0.8, 0.4, 0.2)

var is_rotating: bool = false

var removal_mode_active: bool = false
var line_removal_mode_active: bool = false
var waiting_for_power_selection: bool = false
var current_player_using_power: Jugador = null
var highlight_removable_pieces: Array[Vector2i] = []
var skip_opponent_turn_active: bool = false

func _ready():
	await get_tree().process_frame
	
	if controller == null:
		push_error("GameController no encontrado!")
		return
	
	if game_hud == null:
		push_error("❌ GameHUD no encontrado!")
		return
	else:
		print("✅ GameHUD encontrado correctamente")
		
	# Conectar botón de pregunta rápida
	quick_question_button.pressed.connect(_on_quick_question_button_pressed)
	
	# Conectar señales del diálogo
	question_dialog.answer_selected.connect(_on_question_answered)
	question_dialog.question_skipped.connect(_on_question_skipped)
	
	controller.board_changed.connect(_on_board_changed)
	controller.gravity_event.connect(_on_gravity_event)
	controller.energy_flash.connect(_on_energy_flash)
	
	controller.energy_changed.connect(_on_energy_changed)  # ← NUEVA CONEXIÓN
	# VERIFICAR SI SE CONECTÓ
	print("🔌 Señales conectadas:")
	print("  - board_changed:", controller.board_changed.get_connections().size())
	print("  - energy_changed:", controller.energy_changed.get_connections().size())
	
	controller.block_event.connect(_on_block_event)
	controller.rotation_event.connect(_on_rotation_event)
	controller.winner.connect(_on_winner)
	controller.piece_placed.connect(_on_piece_placed)
	controller.mandatory_question_required.connect(_on_mandatory_question_required)
	controller.jugador1.power_unlocked.connect(_on_power_unlocked)
	controller.jugador2.power_unlocked.connect(_on_power_unlocked)
	controller.reset_done.connect(_on_reset_done)
	
	# Configurar PowerManager
	if controller and controller.power_manager:
		controller.power_manager.setup(controller.board, controller, self)

	if not controller.power_used.is_connected(_on_power_used):
		controller.power_used.connect(_on_power_used)
	
	# Crear diálogo de selección de poder si no existe
	if not has_node("PowerSelectionDialog"):
		var power_dialog_scene = preload("res://scenes/PowerSlectionMenu/PowerSelectionDialog.tscn")
		var power_dialog = power_dialog_scene.instantiate()
	
		if power_dialog is PowerSelectionDialog:
			add_child(power_dialog)
			controller.power_selection_dialog = power_dialog
			power_dialog.power_selected.connect(_on_power_selected)
			power_dialog.dialog_closed.connect(_on_power_dialog_closed)
			print("✅ PowerSelectionDialog instanciado correctamente")
		else:
			push_error("❌ La escena PowerSelectionDialog no tiene el script PowerSelectionDialog.gd")
	
	_recalc_offsets()
	_update_clickable_cells()
	_update_hud()
	queue_redraw()


func _recalc_offsets():
	var screen_size = get_viewport_rect().size
	OFFSET_X = (screen_size.x - get_board_width()) / 2.0
	OFFSET_Y = (screen_size.y - get_board_height()) / 2.0 + 100  # ← Bajar el tablero para dar espacio al HUD

func get_board_width() -> float:
	return Board.COLUMNS * CELL_SIZE

func get_board_height() -> float:
	return Board.ROWS * CELL_SIZE

func _update_clickable_cells():
	clickable_cells.clear()
	var board = controller.board
	if board == null:
		return
	
	match board.gravity_direction:
		Board.Gravity.DOWN:
			for col in range(Board.COLUMNS):
				clickable_cells.append(Vector2i(col, 0))
		Board.Gravity.RIGHT:
			for row in range(Board.ROWS):
				clickable_cells.append(Vector2i(Board.COLUMNS - 1, row))
		Board.Gravity.LEFT:
			for row in range(Board.ROWS):
				clickable_cells.append(Vector2i(0, row))
		Board.Gravity.UP:
			for col in range(Board.COLUMNS):
				clickable_cells.append(Vector2i(col, Board.ROWS - 1))

func _process(_delta):
	if is_piece_falling:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var new_hover = get_cell_at_position(mouse_pos)
	
	if new_hover != hovered_cell:
		hovered_cell = new_hover
		queue_redraw()

func get_cell_at_position(pos: Vector2) -> Vector2i:
	var col = int((pos.x - OFFSET_X) / CELL_SIZE)
	var row = int((pos.y - OFFSET_Y) / CELL_SIZE)
	
	if col >= 0 and col < Board.COLUMNS and row >= 0 and row < Board.ROWS:
		return Vector2i(col, row)
	return Vector2i(-1, -1)

func is_cell_clickable(cell: Vector2i) -> bool:
	return clickable_cells.has(cell)

func _input(event):
	
	if is_piece_falling or is_rotating:
		return
	
	# Modo eliminar ficha
	if removal_mode_active and event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		var clicked_cell = get_cell_at_position(mouse_pos)
		var clicked_row = clicked_cell.y
		var clicked_col = clicked_cell.x
		
		if clicked_cell.x >= 0 and clicked_cell.y >= 0:
			var board = controller.board
			if board.grid[clicked_row][clicked_col] != null:
				await _highlight_selected_piece(clicked_row, clicked_col)
				controller.power_manager.remove_specific_piece(clicked_row, clicked_col)
				rebuild_pieces_from_board()
				
				removal_mode_active = false
				current_player_using_power = null
				
				if event_notification:
					event_notification.show_event(
						"🗑️ FICHA ELIMINADA",
						"en [" + str(clicked_row + 1) + "," + str(clicked_col + 1) + "]",
						"🗑️"
					)
				
				_continue_after_power()
				return
			
	# Modo eliminar línea
	if line_removal_mode_active and event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		
		# Detectar si hizo clic en el área izquierda (para filas)
		if mouse_pos.x >= OFFSET_X - 40 and mouse_pos.x <= OFFSET_X - 5:
			var row_index = int((mouse_pos.y - OFFSET_Y) / CELL_SIZE)
			if row_index >= 0 and row_index < Board.ROWS:
				await _highlight_selected_line(row_index, false)
				controller.power_manager.remove_line(row_index, false)
				rebuild_pieces_from_board()
				
				line_removal_mode_active = false
				current_player_using_power = null
				
				if event_notification:
					event_notification.show_event(
						"📏 FILA ELIMINADA",
						"Fila " + str(row_index + 1) + " eliminada",
						"🗑️"
					)
				
				_continue_after_power()
				return
		
		# Detectar si hizo clic en el área superior (para columnas)
		if mouse_pos.y >= OFFSET_Y - 40 and mouse_pos.y <= OFFSET_Y - 5:
			var col_index = int((mouse_pos.x - OFFSET_X) / CELL_SIZE)
			if col_index >= 0 and col_index < Board.COLUMNS:
				await _highlight_selected_line(col_index, true)
				controller.power_manager.remove_line(col_index, true)
				rebuild_pieces_from_board()
				
				line_removal_mode_active = false
				current_player_using_power = null
				
				if event_notification:
					event_notification.show_event(
						"📏 COLUMNA ELIMINADA",
						"Columna " + str(col_index + 1) + " eliminada",
						"🗑️"
					)
				
				_continue_after_power()
				return
			
	# Juego normal
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		var clicked_cell = get_cell_at_position(mouse_pos)
		if is_cell_clickable(clicked_cell):
			handle_cell_click(clicked_cell)

func handle_cell_click(cell: Vector2i):
	var board = controller.board
	match board.gravity_direction:
		Board.Gravity.DOWN, Board.Gravity.UP:
			controller.try_place_piece(cell.x)
		Board.Gravity.RIGHT, Board.Gravity.LEFT:
			controller.try_place_piece_row(cell.y)

func _on_piece_placed(row: int, col: int, player: Jugador):
	spawn_animated_piece(row, col, player)

func spawn_animated_piece(row: int, col: int, player: Jugador):
	is_piece_falling = true
	var piece = PieceScene.instantiate() as Piece
	add_child(piece)
	pieces.append(piece)
	
	var board = controller.board
	var start_pos: Vector2
	
	match board.gravity_direction:
		Board.Gravity.DOWN:
			start_pos = Vector2(OFFSET_X + col * CELL_SIZE + CELL_SIZE / 2, OFFSET_Y - 100)
		Board.Gravity.RIGHT:
			start_pos = Vector2(OFFSET_X + get_board_width() + 100, OFFSET_Y + row * CELL_SIZE + CELL_SIZE / 2)
		Board.Gravity.LEFT:
			start_pos = Vector2(OFFSET_X - 100, OFFSET_Y + row * CELL_SIZE + CELL_SIZE / 2)
		Board.Gravity.UP:
			start_pos = Vector2(OFFSET_X + col * CELL_SIZE + CELL_SIZE / 2, OFFSET_Y + get_board_height() + 100)
	
	piece.setup(player, row, col, start_pos, OFFSET_X, OFFSET_Y, board.gravity_direction)
	piece.piece_landed.connect(_on_piece_landed)

func _on_piece_landed(piece: Piece):
	is_piece_falling = false
	controller.continue_turn_after_animation()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.08, 0.05, 0.15))
	
	var board := controller.board
	if board == null:
		return
	
	for line_data in board.pending_lines:
		var cells: Array[Vector2i] = line_data.cells
		for cell in cells:
			var x = OFFSET_X + cell.y * CELL_SIZE
			var y = OFFSET_Y + cell.x * CELL_SIZE
			
			# Dibujar brillo dorado
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color(1, 0.84, 0, 0.4), true)
			draw_rect(Rect2(x + 5, y + 5, CELL_SIZE - 10, CELL_SIZE - 10), Color(1, 1, 0, 0.6), false, 3)
	
	# ========== RESALTAR FICHAS ELIMINABLES EN MODO ELIMINACIÓN ==========
	if removal_mode_active:
		for row in range(Board.ROWS):
			for col in range(Board.COLUMNS):
				if controller.board.grid[row][col] != null:
					var x = OFFSET_X + col * CELL_SIZE
					var y = OFFSET_Y + row * CELL_SIZE
					# Dibujar borde rojo brillante alrededor de fichas eliminables
					draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color(1, 0.2, 0.2, 0.5), false, 4)
					# Dibujar icono de "X"
					var center = Vector2(x + CELL_SIZE / 2, y + CELL_SIZE / 2)
					draw_string(ThemeDB.fallback_font, center - Vector2(8, 8), "🗑️", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.RED)

	# ========== RESALTAR LÍNEAS ELIMINABLES EN MODO ELIMINACIÓN DE LÍNEA ==========
	if line_removal_mode_active:
		# Resaltar filas (lado izquierdo)
		for row in range(Board.ROWS):
			var x = OFFSET_X - 30
			var y = OFFSET_Y + row * CELL_SIZE
			draw_rect(Rect2(x, y, 25, CELL_SIZE), Color(1, 0.5, 0, 0.6), true)
			draw_string(ThemeDB.fallback_font, Vector2(x + 5, y + CELL_SIZE / 2 + 5), str(row + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.WHITE)
		
		# Resaltar columnas (lado superior)
		for col in range(Board.COLUMNS):
			var x = OFFSET_X + col * CELL_SIZE
			var y = OFFSET_Y - 30
			draw_rect(Rect2(x, y, CELL_SIZE, 25), Color(1, 0.5, 0, 0.6), true)
			draw_string(ThemeDB.fallback_font, Vector2(x + CELL_SIZE / 2 - 5, y + 18), str(col + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.WHITE)
	
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var x = OFFSET_X + col * CELL_SIZE
			var y = OFFSET_Y + row * CELL_SIZE
			var cell_color = Color(0.2, 0.2, 0.25)
			var cell = Vector2i(col, row)
			
			# ========== COLOREAR CELDAS BLOQUEADAS ==========
			var is_blocked = false
			match board.gravity_direction:
				Board.Gravity.DOWN, Board.Gravity.UP:
					is_blocked = board.is_blocked(col)
				Board.Gravity.RIGHT, Board.Gravity.LEFT:
					is_blocked = board.is_blocked(row)
			
			if is_blocked:
				cell_color = Color(0.8, 0.2, 0.2, 0.6)  # Rojo oscuro para bloqueadas
			elif is_cell_clickable(cell):
				cell_color = HOVER_COLOR if cell == hovered_cell else CLICKABLE_COLOR
			
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), cell_color)
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color.BLACK, false, 3)
			
			# ========== DIBUJAR ICONO DE CANDADO EN CELDAS BLOQUEADAS ==========
			if is_blocked:
				var center = Vector2(x + CELL_SIZE / 2, y + CELL_SIZE / 2)
				draw_string(ThemeDB.fallback_font, center - Vector2(15, -5), "🔒", HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.RED)
			
			if is_cell_clickable(cell):
				cell_color = HOVER_COLOR if cell == hovered_cell else CLICKABLE_COLOR
			
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), cell_color)
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color.BLACK, false, 3)

# ========== ACTUALIZAR HUD ==========
func _update_hud():
	if game_hud:
		game_hud.update_turn(controller.current_player.id, controller.current_player.color)
		game_hud.update_energy(1, controller.jugador1.energy, Jugador.MAX_ENERGY, controller.jugador1.ability_ready)
		game_hud.update_energy(2, controller.jugador2.energy, Jugador.MAX_ENERGY, controller.jugador2.ability_ready)
		game_hud.update_gravity(controller.board.gravity_direction)
		update_power_button_visibility()



func _on_board_changed():
	_update_clickable_cells()
	_update_hud()  # ← ACTUALIZAR HUD
	queue_redraw()

func _on_gravity_event(direction: int):
	_update_clickable_cells()
	if game_hud:
		game_hud.update_gravity(direction)
	if event_notification:
		var direction_name := ""
		var icon := "🔄"
		match direction:
			Board.Gravity.DOWN:
				direction_name = "GRAVEDAD HACIA ABAJO"
				icon = "⬇️"
			Board.Gravity.RIGHT:
				direction_name = "GRAVEDAD HACIA DERECHA"
				icon = "➡️"
			Board.Gravity.LEFT:
				direction_name = "GRAVEDAD HACIA IZQUIERDA"
				icon = "⬅️"
			Board.Gravity.UP:
				direction_name = "GRAVEDAD HACIA ARRIBA"
				icon = "⬆️"
		event_notification.show_event("CAMBIO DE GRAVEDAD", direction_name, icon)

# ========== MANEJAR EVENTO DE BLOQUEO ==========
func _on_block_event(index: int, gravity_dir: int):
	_update_clickable_cells()  # Actualizar celdas clicables
	
	if event_notification:
		var message := ""
		match gravity_dir:
			Board.Gravity.DOWN, Board.Gravity.UP:
				message = "Columna %d bloqueada por %d turnos" % [index, Board.BLOCK_DURATION]
			Board.Gravity.RIGHT, Board.Gravity.LEFT:
				message = "Fila %d bloqueada por %d turnos" % [index, Board.BLOCK_DURATION]
		
		event_notification.show_event("COLUMNA BLOQUEADA", message, "🔒")
	
	queue_redraw()

func _on_energy_flash(player_id: int):
	if game_hud:
		var player = controller.jugador1 if player_id == 1 else controller.jugador2
		game_hud.update_energy(player_id, player.energy, Jugador.MAX_ENERGY, true)
	
	# Mostrar pregunta obligatoria
	var question = controller.question_system.get_random_mandatory_question()
	question_dialog.show_question(question, false)  # false = NO permite saltar
	
	if power_sound:
		power_sound.play()


# ========== MANEJAR EVENTO DE ROTACIÓN ==========
# ========== MANEJAR EVENTO DE ROTACIÓN CON ANIMACIÓN ==========
# ========== MANEJAR EVENTO DE ROTACIÓN CON ANIMACIÓN ==========
func _on_rotation_event(pending_lines: Array[Dictionary]):
	print("🎬 Iniciando animación de rotación")
	is_rotating = true
	
	# ========== CREAR PARTÍCULAS ==========
	var particles = CPUParticles2D.new()
	add_child(particles)
	particles.position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 300.0
	particles.color = Color(1, 0.84, 0, 1)
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 300
	
	# ========== FASE 1: ZOOM OUT + ROTACIÓN ==========
	var rotation_duration := 1.0
	
	var tween = create_tween()
	tween.set_parallel(true)  # Ejecutar todo en paralelo
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Rotar 180° (PI radianes)
	tween.tween_property(self, "rotation", PI, rotation_duration)
	
	# Hacer zoom out
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), rotation_duration * 0.5)
	
	# Esperar a que termine
	await tween.finished
	
	# ========== FASE 2: ZOOM IN DE REGRESO ==========
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_OUT)
	tween2.set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(self, "scale", Vector2(1.0, 1.0), rotation_duration * 0.5)
	
	await tween2.finished
	
	# Resetear rotación visual
	rotation = 0
	
	# ========== FASE 3: REORGANIZAR FICHAS ==========
	await regenerate_all_pieces_animated(pending_lines)
	
	# ========== FASE 4: MOSTRAR NOTIFICACIÓN ==========
	if event_notification:
		if pending_lines.size() > 0:
			var player_id = pending_lines[0].player.id
			event_notification.show_event(
				"¡ROTACIÓN!",
				"Jugador %d: ¡Conecta 1 ficha más para ganar!" % player_id,
				"🔄⚡"
			)
		else:
			event_notification.show_event("ROTACIÓN COMPLETA", "Tablero reorganizado", "🔄✨")
	
	# Limpiar partículas
	await get_tree().create_timer(0.5).timeout
	particles.queue_free()
	
	is_rotating = false
	queue_redraw()
	print("✅ Animación de rotación completada")
	
# ========== REGENERAR FICHAS CON ANIMACIÓN DE CAÍDA ==========
# ========== REGENERAR FICHAS CON ANIMACIÓN DE CAÍDA ==========
func regenerate_all_pieces_animated(pending_lines: Array[Dictionary]):
	print("🔄 Regenerando fichas con animación")
	
	var board = controller.board
	if board == null:
		return
	
	# 1. Guardar posiciones actuales de las fichas
	var old_pieces_data: Array[Dictionary] = []
	for piece in pieces:
		old_pieces_data.append({
			"piece": piece,
			"old_pos": piece.position,
			"player": piece.jugador
		})
	
	# 2. Calcular nuevas posiciones según el grid rotado
	var new_positions: Array[Dictionary] = []
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var player = board.grid[row][col]
			if player != null:
				var new_x = OFFSET_X + col * CELL_SIZE + CELL_SIZE / 2
				var new_y = OFFSET_Y + row * CELL_SIZE + CELL_SIZE / 2
				new_positions.append({
					"player": player,
					"pos": Vector2(new_x, new_y),
					"row": row,
					"col": col
				})
	
	# 3. Intentar reutilizar fichas existentes y animarlas
	var pieces_to_remove: Array[Piece] = []
	var pieces_animated: Array[Piece] = []
	
	for old_data in old_pieces_data:
		var piece: Piece = old_data.piece
		var found_match := false
		
		# Buscar si esta ficha tiene una nueva posición
		for i in range(new_positions.size()):
			var new_data = new_positions[i]
			if new_data.player == old_data.player and not pieces_animated.has(piece):
				# CREAR TWEEN CORRECTAMENTE
				if is_instance_valid(piece):
					var tween = create_tween()
					tween.set_ease(Tween.EASE_OUT)
					tween.set_trans(Tween.TRANS_BOUNCE)
					tween.tween_property(piece, "position", new_data.pos, 0.6)
					
					# Actualizar datos de la ficha
					piece.grid_row = new_data.row
					piece.grid_col = new_data.col
					
					pieces_animated.append(piece)
					new_positions.remove_at(i)
					found_match = true
				break
		
		if not found_match:
			pieces_to_remove.append(piece)
	
	# 4. Eliminar fichas que no tienen correspondencia
	for piece in pieces_to_remove:
		pieces.erase(piece)
		
		# VERIFICAR QUE LA PIEZA EXISTE ANTES DE ANIMAR
		if is_instance_valid(piece):
			var tween = create_tween()
			tween.tween_property(piece, "modulate:a", 0.0, 0.3)
			tween.tween_callback(piece.queue_free)
		else:
			piece.queue_free()
	
	# 5. Crear fichas nuevas para posiciones sin correspondencia
	for new_data in new_positions:
		spawn_piece_with_fall_animation(new_data.row, new_data.col, new_data.player, new_data.pos)
	
	# 6. Esperar a que terminen las animaciones
	await get_tree().create_timer(0.8).timeout
	
	# 7. Aplicar brillo dorado a líneas pendientes
	if pending_lines.size() > 0:
		highlight_pending_lines(pending_lines)
	
	print("✅", pieces.size(), "fichas reorganizadas con animación")


# ========== CREAR FICHA CON ANIMACIÓN DE CAÍDA DESDE ARRIBA ==========
# ========== CREAR FICHA CON ANIMACIÓN DE CAÍDA DESDE ARRIBA ==========
func spawn_piece_with_fall_animation(row: int, col: int, player: Jugador, final_pos: Vector2):
	var piece = PieceScene.instantiate() as Piece
	add_child(piece)
	pieces.append(piece)
	
	# Posición inicial: arriba del tablero
	var start_y = OFFSET_Y - 200
	piece.position = Vector2(final_pos.x, start_y)
	
	# Configurar la ficha
	piece.jugador = player
	piece.grid_row = row
	piece.grid_col = col
	piece.target_position = final_pos
	piece.is_falling = false
	
	# Aplicar color
	if piece.sprite:
		piece.sprite.modulate = player.color
	
	# ESPERAR UN FRAME ANTES DE ANIMAR
	await get_tree().process_frame
	
	# Animar caída con efecto de rebote
	if is_instance_valid(piece):
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(piece, "position", final_pos, 0.5)


# ========== RESALTAR LÍNEAS PENDIENTES CON ANIMACIÓN ==========
# ========== RESALTAR LÍNEAS PENDIENTES CON ANIMACIÓN ==========
func highlight_pending_lines(pending_lines: Array[Dictionary]):
	print("✨ Resaltando", pending_lines.size(), "líneas pendientes")
	
	for line_data in pending_lines:
		var cells: Array[Vector2i] = line_data.cells
		
		# Animar cada ficha de la línea
		for cell in cells:
			# Buscar la ficha visual en esa posición
			for piece in pieces:
				if piece.grid_row == cell.x and piece.grid_col == cell.y:
					# VERIFICAR VALIDEZ ANTES DE ANIMAR
					if is_instance_valid(piece) and is_instance_valid(piece.sprite):
						var tween = create_tween()
						tween.set_loops(3)  # Repetir 3 veces
						tween.tween_property(piece.sprite, "modulate", Color(2, 2, 0, 1), 0.3)
						tween.tween_property(piece.sprite, "modulate", piece.jugador.color, 0.3)
					break

# ========== MANEJAR CAMBIO DE ENERGÍA ==========
func _on_energy_changed(player_id: int, new_energy: int):
	if game_hud:
		var player = controller.jugador1 if player_id == 1 else controller.jugador2
		var is_full = player.ability_ready
		
		print("🔋 Actualizando HUD - Jugador", player_id, "→ Energía:", new_energy, "Full:", is_full)
		
		# Actualizar solo la barra del jugador que cambió
		game_hud.update_energy(player_id, new_energy, Jugador.MAX_ENERGY, false)

# ========== MANEJAR PREGUNTA RÁPIDA ==========
func _on_quick_question_button_pressed():
	if is_piece_falling or is_rotating:
		return
	
	var player = controller.current_player
	
	# VERIFICAR SI ES UN REINTENTO DE PODER BLOQUEADO
	if player.ability_ready and player.power_blocked and player.can_retry_with_quick:
		print("🔄 Usando pregunta rápida para reintentar poder")
		player.can_retry_with_quick = false  # Solo un reintento
		
		var question = controller.question_system.get_random_mandatory_question()
		question_dialog.show_question(question, false)
	else:
		# Pregunta rápida normal
		var question = controller.question_system.get_random_quick_question()
		question_dialog.show_question(question, true)

# ========== MANEJAR RESPUESTA DE PREGUNTA ==========
func _on_question_answered(is_correct: bool):
	var player = controller.current_player
	
	# CASO 1: Pregunta obligatoria (primera vez con energía llena)
	if player.ability_ready and player.power_blocked and player.can_retry_with_quick:
		if is_correct:
			print("✅ Pregunta obligatoria correcta - Abriendo selección de poder")
			player.power_blocked = false  # Desbloquear temporalmente
			
			# Mostrar diálogo de selección de poder
			if controller.power_selection_dialog:
				controller.power_selection_dialog.show_dialog(player.id)
			else:
				push_error("❌ PowerSelectionDialog no encontrado")
			
			if event_notification:
				event_notification.show_event(
					"¡RESPUESTA CORRECTA!",
					"Elige tu poder",
					"✅"
				)
		else:
			print("❌ Pregunta obligatoria incorrecta - Poder bloqueado")
			player.block_power()
			
			if event_notification:
				event_notification.show_event(
					"RESPUESTA INCORRECTA",
					"Poder bloqueado. Usa pregunta rápida para reintentar",
					"❌"
				)
			
			# Continuar turno después de fallar
			_continue_turn_after_question()
	
	# CASO 2: Reintento con pregunta rápida
	elif player.ability_ready and player.power_blocked and not player.can_retry_with_quick:
		if is_correct:
			print("🔓 Reintento exitoso - Abriendo selección de poder")
			player.power_blocked = false
			
			if controller.power_selection_dialog:
				controller.power_selection_dialog.show_dialog(player.id)
			
			if event_notification:
				event_notification.show_event(
					"¡PODER DESBLOQUEADO!",
					"Elige tu poder",
					"🔓"
				)
		else:
			print("❌ Reintento fallido - Poder perdido definitivamente")
			player.block_power()
			
			if event_notification:
				event_notification.show_event(
					"¡PODER PERDIDO!",
					"Energía reiniciada a 0",
					"❌"
				)
			
			_continue_turn_after_question()
	
	# CASO 3: Pregunta rápida normal (+1 energía)
	else:
		if is_correct:
			player.add_energy(1)
			
			if event_notification:
				event_notification.show_event(
					"¡RESPUESTA CORRECTA!",
					"+1 Energía",
					"✅"
				)
		else:
			if event_notification:
				event_notification.show_event(
					"RESPUESTA INCORRECTA",
					"Sin recompensa",
					"❌"
				)
	
	_update_hud()


func _on_question_skipped():
	print("⏭ Pregunta saltada")

# ========== ENTRAR EN MODO ELIMINACIÓN DE FICHA ==========
func enter_piece_removal_mode(player: Jugador):
	removal_mode_active = true
	current_player_using_power = player
	
	if event_notification:
		event_notification.show_event(
			"🔪 MODO ELIMINACIÓN",
			"Haz clic en una ficha para eliminarla",
			"🗑️"
		)

# ========== ENTRAR EN MODO ELIMINACIÓN DE FILA/COLUMNA ==========
func enter_line_removal_mode(player: Jugador):
	line_removal_mode_active = true
	current_player_using_power = player
	
	if event_notification:
		event_notification.show_event(
			"📏 MODO ELIMINAR LÍNEA",
			"Haz clic en una fila (izquierda) o columna (arriba) para eliminarla",
			"🗑️"
		)

# ========== MANEJAR CUANDO SE USA UN PODER ==========
func _on_power_used(power_type: int, player_id: int):
	if event_notification:
		var power_name = ""
		match power_type:
			Jugador.PowerType.STEAL_ENERGY:
				power_name = "ROBO DE ENERGÍA"
			Jugador.PowerType.REMOVE_PIECE:
				power_name = "ELIMINAR FICHA"
			Jugador.PowerType.REMOVE_LINE:
				power_name = "ELIMINAR LÍNEA"
			Jugador.PowerType.SKIP_TURN:
				power_name = "SALTAR TURNO"
		
		event_notification.show_event(
			"¡PODER USADO!",
			"Jugador %d usó %s" % [player_id, power_name],
			"💥"
		)

# ========== MANEJAR SELECCIÓN DE PODER ==========
func _on_power_selected(power_type: int, power_level: int):
	print("⚡ Poder seleccionado - EJECUTANDO INMEDIATAMENTE:", Jugador.PowerType.keys()[power_type])
	
	var player = controller.current_player
	var rival = controller.jugador1 if player == controller.jugador2 else controller.jugador2
	
	# Guardar el poder seleccionado
	player.unlocked_power = power_type
	player.unlocked_power_level = power_level
	
	# EJECUTAR EL PODER INMEDIATAMENTE
	match power_type:
		Jugador.PowerType.STEAL_ENERGY:
			var stolen = min(2, rival.energy)
			
			# El rival pierde energía
			rival.energy = max(0, rival.energy - stolen)
			rival.ability_ready = rival.energy >= Jugador.MAX_ENERGY
			
			# El usuario "gasta" su energía, pero conserva lo robado
			player.energy = stolen
			player.ability_ready = false
			player.power_blocked = false
			player.can_retry_with_quick = true
			
			rival.energy_updated.emit(rival.id, rival.energy)
			player.energy_updated.emit(player.id, player.energy)
			
			if event_notification:
				event_notification.show_event(
					"¡ENERGÍA ROBADA!",
					"Jugador %d robó %d energía a Jugador %d" % [player.id, stolen, rival.id],
					"⚡🔫"
				)
			
			_continue_after_power()
		
		Jugador.PowerType.REMOVE_PIECE:
			player.energy = 0
			player.energy_updated.emit(player.id, player.energy)
			player.ability_ready = false
			player.power_blocked = false
			player.can_retry_with_quick = true
			
			if event_notification:
				event_notification.show_event(
					"🔪 ELIMINAR FICHA",
					"Haz clic en una ficha para eliminarla",
					"🗑️"
				)
			
			removal_mode_active = true
			current_player_using_power = player
		
		Jugador.PowerType.REMOVE_LINE:
			player.energy = 0
			player.energy_updated.emit(player.id, player.energy)
			player.ability_ready = false
			player.power_blocked = false
			player.can_retry_with_quick = true
			
			if event_notification:
				event_notification.show_event(
					"📏 ELIMINAR LÍNEA",
					"Haz clic en una fila (izquierda) o columna (arriba) para eliminarla",
					"🗑️"
				)
			
			line_removal_mode_active = true
			current_player_using_power = player
		
		Jugador.PowerType.SKIP_TURN:
			skip_opponent_turn_active = true
			
			player.energy = 0
			player.energy_updated.emit(player.id, player.energy)
			player.ability_ready = false
			player.power_blocked = false
			player.can_retry_with_quick = true
			
			if event_notification:
				event_notification.show_event(
					"⏭️ TURNO SALTADO",
					"El rival pierde su turno. Juegas otra vez.",
					"⏭️"
				)
			
			_continue_after_power()
	
	# Resetear estado del poder (ya se usó)
	player.unlocked_power = Jugador.PowerType.NONE
	player.unlocked_power_level = Jugador.PowerLevel.NONE
	player.ability_ready = false
	player.power_blocked = false
	player.can_retry_with_quick = true
	
	# Actualizar UI
	_update_hud()


# ========== MOSTRAR/OCULTAR BOTÓN DE USAR PODER ==========
func update_power_button_visibility():
	if not has_node("UI/UsePowerButton"):
		return
	
	var btn = $UI/UsePowerButton
	var player = controller.current_player
	
	if player.unlocked_power != Jugador.PowerType.NONE and not player.power_blocked:
		btn.visible = true
		
		var power_name = ""
		match player.unlocked_power:
			Jugador.PowerType.STEAL_ENERGY:
				power_name = "⚡ Robar Energía"
			Jugador.PowerType.REMOVE_PIECE:
				power_name = "🗑️ Eliminar Ficha"
			Jugador.PowerType.REMOVE_LINE:
				power_name = "📏 Eliminar Línea"
			Jugador.PowerType.SKIP_TURN:
				power_name = "⏭️ Saltar Turno"
		
		btn.text = "💥 " + power_name
	else:
		btn.visible = false



# ========== BOTÓN PARA USAR PODER (agregar en GameHUD) ==========
func _on_use_power_button_pressed():
	if controller and not is_piece_falling and not is_rotating:
		var result = controller.use_current_player_power()
		
		if result:
			update_power_button_visibility()
			_update_hud()

# ========== MANEJAR CIERRE DEL DIÁLOGO DE PODER ==========
func _on_power_dialog_closed():
	print("🔒 Diálogo de poder cerrado")
	# Aquí puedes reanudar el juego si es necesario
	waiting_for_power_selection = false

func _on_mandatory_question_required(player_id: int):
	print("❗ Pregunta obligatoria para jugador", player_id)
	
	# Mostrar pregunta obligatoria (NO permite saltar)
	var question = controller.question_system.get_random_mandatory_question()
	question_dialog.show_question(question, false)

# ========== CONTINUAR TURNO DESPUÉS DE RESPONDER PREGUNTA ==========
func _continue_turn_after_question():
	var board = controller.board
	
	# Verificar ganador
	if board.check_winner(controller.current_player):
		if board.pending_lines.size() > 0:
			print("⚠️ 4 en línea detectado, pero hay líneas pendientes")
		else:
			controller.winner.emit(controller.current_player.id)
			return
	
	# Cambiar turno
	controller.switch_turn()
	board.reduce_pending_line_turns()
	controller.event_manager.next_turn(board, controller)
	controller.board_changed.emit()
	_update_hud()

# ========== MANEJAR CUANDO SE DESBLOQUEA PODER ==========
func _on_power_unlocked(power_type: int):
	# Este método ya no es necesario porque abrimos el diálogo directamente
	# después de responder correctamente la pregunta obligatoria
	pass


# ========== CONTINUAR TURNO DESPUÉS DE USAR PODER ==========
func _continue_after_power():
	print("➡️ Continuando turno después de poder")
	
	var board = controller.board
	
	if board.check_winner(controller.current_player):
		if board.pending_lines.size() > 0:
			print("⚠️ 4 en línea detectado, pero hay líneas pendientes")
		else:
			controller.winner.emit(controller.current_player.id)
			return
	
	if not line_removal_mode_active and not removal_mode_active:
		if skip_opponent_turn_active:
			print("⏭️ El rival pierde el turno; juega de nuevo el mismo jugador")
			skip_opponent_turn_active = false
		else:
			controller.switch_turn()
		
		board.reduce_pending_line_turns()
		controller.event_manager.next_turn(board, controller)
	
	controller.board_changed.emit()
	_update_hud()
	
	removal_mode_active = false
	line_removal_mode_active = false
	current_player_using_power = null

func rebuild_pieces_from_board():
	clear_pieces()
	
	var board = controller.board
	if board == null:
		return
	
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var player = board.grid[row][col]
			if player != null:
				var piece = PieceScene.instantiate() as Piece
				add_child(piece)
				pieces.append(piece)
				
				piece.jugador = player
				piece.grid_row = row
				piece.grid_col = col
				piece.is_falling = false
				piece.fall_direction = board.gravity_direction
				piece.position = Vector2(
					OFFSET_X + col * CELL_SIZE + CELL_SIZE / 2,
					OFFSET_Y + row * CELL_SIZE + CELL_SIZE / 2
				)
				piece.target_position = piece.position
				
				if piece.sprite:
					piece.sprite.modulate = player.color

func _highlight_selected_piece(row: int, col: int):
	for piece in pieces:
		if piece.grid_row == row and piece.grid_col == col and is_instance_valid(piece):
			var tween = create_tween()
			tween.tween_property(piece, "scale", Vector2(1.25, 1.25), 0.12)
			tween.tween_property(piece, "scale", Vector2(0.0, 0.0), 0.18)
			await tween.finished
			return

func _highlight_selected_line(index: int, is_column: bool):
	var tweens := []
	
	for piece in pieces:
		if not is_instance_valid(piece):
			continue
		
		var match_line = false
		if is_column:
			match_line = piece.grid_col == index
		else:
			match_line = piece.grid_row == index
		
		if match_line:
			var tween = create_tween()
			tween.tween_property(piece, "modulate", Color(1, 0.2, 0.2, 1), 0.12)
			tween.tween_property(piece, "scale", Vector2(0.0, 0.0), 0.18)
			tweens.append(tween)
	
	await get_tree().create_timer(0.22).timeout

func _on_reset_done():
	if controller and controller.power_manager:
		controller.power_manager.setup(controller.board, controller, self)
	
	rebuild_pieces_from_board()
	_update_clickable_cells()
	_update_hud()
	queue_redraw()


func _on_winner(player_id: int):
	is_piece_falling = false
	if event_notification:
		event_notification.show_event("¡VICTORIA!", "Jugador %d ha ganado la partida" % player_id, "🏆")
	await get_tree().create_timer(3.0).timeout
	clear_pieces()
	controller.reset_game()

func clear_pieces():
	for piece in pieces:
		piece.queue_free()
	pieces.clear()
