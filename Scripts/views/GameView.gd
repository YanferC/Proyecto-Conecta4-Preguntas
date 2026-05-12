extends Node2D
class_name GameView

@onready var controller: GameController = $GameController
@onready var power_sound: AudioStreamPlayer = $PowerSound
@onready var event_notification: EventNotification = $UI/EventNotification
@onready var game_hud: GameHUD = $UI/GameHUD  # ← NUEVO

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

func _ready():
	await get_tree().process_frame
	
	if controller == null:
		push_error("GameController no encontrado!")
		return
	
	controller.board_changed.connect(_on_board_changed)
	controller.gravity_event.connect(_on_gravity_event)
	controller.energy_flash.connect(_on_energy_flash)
	controller.winner.connect(_on_winner)
	controller.piece_placed.connect(_on_piece_placed)
	
	_recalc_offsets()
	_update_clickable_cells()
	_update_hud()  # ← NUEVO
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
	if is_piece_falling:
		return
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
	
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var x = OFFSET_X + col * CELL_SIZE
			var y = OFFSET_Y + row * CELL_SIZE
			var cell_color = Color(0.2, 0.2, 0.25)
			var cell = Vector2i(col, row)
			
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

func _on_energy_flash(player_id: int):
	if game_hud:
		var player = controller.jugador1 if player_id == 1 else controller.jugador2
		game_hud.update_energy(player_id, player.energy, Jugador.MAX_ENERGY, true)
	if power_sound:
		power_sound.play()
	if event_notification:
		event_notification.show_event("ENERGÍA COMPLETA", "Jugador %d puede responder pregunta" % player_id, "⚡")

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
