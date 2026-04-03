extends Node2D

@onready var power_sound: AudioStreamPlayer = $PowerSound

var controller: GameController

# FX / UI state
var flash_timer := 0.0
var lightning_timer := 0.0
var lightning_player_id: int = -1
var event_text := ""
var event_timer := 0.0
var board_flash_timer := 0.0
var vibration_timer := 0.0
var gravity_icon_direction = null

const CELL_SIZE = 80
var OFFSET_X = 0
var OFFSET_Y = 0

var game_font: Font

func _ready():
	game_font = ThemeDB.fallback_font

	controller = GameController.new()
	add_child(controller)

	controller.board_changed.connect(_on_board_changed)
	controller.energy_flash.connect(_on_energy_flash)
	controller.gravity_event.connect(_on_gravity_event)
	controller.winner.connect(_on_winner)

	_recompute_offsets()
	queue_redraw()

func _recompute_offsets():
	var screen_size = get_viewport_rect().size
	OFFSET_X = (screen_size.x - get_board_width()) / 2
	OFFSET_Y = (screen_size.y - get_board_height()) / 2

func get_board_width():
	return Board.COLUMNS * CELL_SIZE

func get_board_height():
	return Board.ROWS * CELL_SIZE

func _on_board_changed():
	queue_redraw()

func _on_energy_flash(player_id: int):
	lightning_player_id = player_id
	lightning_timer = 0.0
	power_sound.play()
	queue_redraw()

func _on_gravity_event(direction):
	event_text = "⚠ GRAVEDAD ALTERADA ⚠"
	event_timer = 2.0
	board_flash_timer = 0.5
	vibration_timer = 0.4
	gravity_icon_direction = direction
	queue_redraw()

func _on_winner(player_id: int):
	print("Ganó jugador ", player_id)
	# Aquí puedes hacer shake, esperar, y reset
	await get_tree().create_timer(1.5).timeout
	controller.reset_game()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		var column = int((mouse_pos.x - OFFSET_X) / CELL_SIZE)
		if column >= 0 and column < Board.COLUMNS:
			controller.try_place_piece(column)

func _process(delta):
	# tu lógica de timers visuales (flash/eventos/vibración)
	# si vibration_timer > 0, OFFSET_X/Y vibran, si no recalculas offsets, etc.
	pass

func _draw():
	var board := controller.board
	var jugador1 := controller.jugador1
	var jugador2 := controller.jugador2

	# aquí pegas tu dibujo del fondo/tablero/fichas/barras
	pass
