extends Node2D

var board
var jugador1
var jugador2
var current_player
var event_manager
var question_system
var flash_timer := 0.0
var game_font : Font
var lightning_timer := 0.0
var lightning_player = null
var shake_time := 0.0

var event_text := ""
var event_timer := 0.0
var board_flash_timer := 0.0
var vibration_timer := 0.0
var gravity_icon_direction = null

const CELL_SIZE = 80
var OFFSET_X = 0
var OFFSET_Y = 0

func _ready():
	board = Board.new()
	jugador1 = Jugador.new(1, Color(0.6, 0.2, 0.8))
	jugador2 = Jugador.new(2, Color(1.0, 0.3, 0.7))
	current_player = jugador1
	
	event_manager = EventManager.new()
	question_system = QuestionSystem.new()
	
	game_font = ThemeDB.fallback_font
	
	var screen_size = get_viewport_rect().size
	OFFSET_X = (screen_size.x - get_board_width()) / 2
	OFFSET_Y = (screen_size.y - get_board_height()) / 2
	
	randomize()
	
	print("Juego iniciado")

func get_board_width():
	return Board.COLUMNS * CELL_SIZE

func get_board_height():
	return Board.ROWS * CELL_SIZE
	
func switch_turn():
	if current_player == jugador1:
		current_player = jugador2
	else:
		current_player = jugador1

func _draw():
	
	# Fondo
	var bg_color = Color(0.08, 0.05, 0.15)

	if board_flash_timer > 0:
		bg_color = Color(0.4, 0.05, 0.1)

	draw_rect(Rect2(0, 0, get_viewport_rect().size.x, get_viewport_rect().size.y), bg_color)

	# Tablero
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var x = OFFSET_X + col * CELL_SIZE
			var y = OFFSET_Y + row * CELL_SIZE
			
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color.WHITE)
			draw_rect(Rect2(x, y, CELL_SIZE, CELL_SIZE), Color.BLACK, false, 2)
			
			var jugador = board.grid[row][col]
			if jugador != null:
				var center = Vector2(x + CELL_SIZE/2, y + CELL_SIZE/2)

				# Glow si tiene habilidad lista
				if jugador.ability_ready:
					draw_circle(center, CELL_SIZE/2 - 2, jugador.color.lightened(0.5))
					draw_circle(center, CELL_SIZE/2 - 8, jugador.color)

				else:
					draw_circle(center, CELL_SIZE/2 - 5, jugador.color)
	
	if event_timer > 0:
		draw_big_event_text()
	
	if gravity_icon_direction != null:
		draw_gravity_icon()
	
	# Energía (FUERA del for)
	if lightning_player != null:
		draw_lightning(lightning_player)	
	draw_energy_bars()
	

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position
		var column = int((mouse_pos.x - OFFSET_X) / CELL_SIZE)
		
		if column >= 0 and column < Board.COLUMNS:
			place_piece(column)

func place_piece(column):
	var pos = board.drop_piece(column, current_player)
	
	if pos.x != -1:
		var before_energy = current_player.energy
		
		board.calculate_energy(pos.x, pos.y, current_player)
		if current_player.ability_ready and before_energy < Jugador.MAX_ENERGY:
			lightning_player = current_player
			play_power_sound()
			
		if board.check_winner(current_player):
			print("Ganó jugador ", current_player.id)
			shake_camera()
			await get_tree().create_timer(1.5).timeout
			reset_game()
			return
		
		switch_turn()
		event_manager.next_turn(board, self)
		queue_redraw()

func draw_energy_bars():
	var bar_width = 200
	var bar_height = 20
	var unit_width = bar_width / Jugador.MAX_ENERGY
	
	# Jugador 1
	draw_rect(Rect2(OFFSET_X, OFFSET_Y - 60, bar_width, bar_height), Color(0.2,0.2,0.2))
	draw_rect(
		Rect2(
			OFFSET_X,
			OFFSET_Y - 60,
			jugador1.energy * unit_width,
			bar_height
		),
		jugador1.color
	)
	
	# Jugador 2
	draw_rect(Rect2(OFFSET_X + 300, OFFSET_Y - 60, bar_width, bar_height), Color(0.2,0.2,0.2))
	draw_rect(
		Rect2(
			OFFSET_X + 300,
			OFFSET_Y - 60,
			jugador2.energy * unit_width,
			bar_height
		),
		jugador2.color
	)
	
	draw_ability_text()


func draw_ability_text():
	var flash_color = Color(1,1,1)
	
	if int(flash_timer * 5) % 2 == 0:
		flash_color = Color(1,1,0.3)	
	
	if jugador1.ability_ready:
		draw_string(
			game_font,
			Vector2(OFFSET_X, OFFSET_Y - 75),
			"⚡ Habilidad Lista ⚡",
			HORIZONTAL_ALIGNMENT_LEFT,
			200,
			16,
			flash_color
		)
		
	if jugador2.ability_ready:
		draw_string(
			game_font,
			Vector2(OFFSET_X + 300, OFFSET_Y - 75),
			"⚡ Habilidad Lista ⚡",
			HORIZONTAL_ALIGNMENT_LEFT,
			200,
			16,
			flash_color
		)
		
func _process(delta):
	if jugador1.ability_ready or jugador2.ability_ready:
		flash_timer += delta
		queue_redraw()
	if lightning_player != null:
		lightning_timer += delta
		if lightning_timer > 0.5:
			lightning_player = null
			lightning_timer = 0
		queue_redraw()	
		
	if event_timer > 0:
		event_timer -= delta
		queue_redraw()

	if board_flash_timer > 0:
		board_flash_timer -= delta

	if vibration_timer > 0:
		vibration_timer -= delta
		OFFSET_X += randf_range(-2,2)
		OFFSET_Y += randf_range(-2,2)
	else:
		# recalcular centrado normal
		var screen_size = get_viewport_rect().size
		OFFSET_X = (screen_size.x - get_board_width()) / 2
		OFFSET_Y = (screen_size.y - get_board_height()) / 2
	
		
func reset_game():
	board.create_board()
	jugador1.energy = 0
	jugador2.energy = 0
	jugador1.ability_ready = false
	jugador2.ability_ready = false
	
	current_player = jugador1
	
	queue_redraw()
	print("Tablero reiniciado")

func draw_lightning(jugador):
	var start_x = OFFSET_X if jugador == jugador1 else OFFSET_X + 300
	var start = Vector2(start_x + 100, OFFSET_Y - 40)
	var end = Vector2(start_x + 100, OFFSET_Y + 10)

	var points = []
	points.append(start)

	for i in range(5):
		var t = float(i) / 4.0
		var x = lerp(start.x, end.x, t) + randf_range(-10, 10)
		var y = lerp(start.y, end.y, t)
		points.append(Vector2(x, y))

	points.append(end)

	for i in range(points.size() - 1):
		draw_line(points[i], points[i+1], Color(1,1,0.3), 3)

func on_gravity_event(direction):
	event_text = "⚠ GRAVEDAD ALTERADA ⚠"
	event_timer = 2.0
	board_flash_timer = 0.5
	vibration_timer = 0.4
	gravity_icon_direction = direction

func draw_big_event_text():
	var screen_size = get_viewport_rect().size
	var pos = Vector2(screen_size.x / 2 - 200, screen_size.y / 2)

	draw_string(
		game_font,
		pos,
		event_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		400,
		36,
		Color(1,0.3,0.3)
	)

func draw_gravity_icon():
	var screen_size = get_viewport_rect().size
	var center = Vector2(screen_size.x/2, screen_size.y/2 + 50)

	match gravity_icon_direction:
		Board.Gravity.DOWN:
			draw_line(center, center + Vector2(0,50), Color.YELLOW, 6)
		Board.Gravity.RIGHT:
			draw_line(center, center + Vector2(50,0), Color.YELLOW, 6)
		Board.Gravity.LEFT:
			draw_line(center, center + Vector2(-50,0), Color.YELLOW, 6)

func play_power_sound():
	$PowerSound.play()

func shake_camera():
	shake_time = 0.4
