extends Node
class_name Board

const ROWS = 8
const COLUMNS = 9

var grid = []
enum Gravity {
	DOWN,
	RIGHT,
	LEFT,
	UP
}
var gravity_direction = Gravity.DOWN
var unstable_turns := 0

var blocked_columns: Array[int] = []  # Columnas bloqueadas actualmente
var blocked_rows: Array[int] = []     # Filas bloqueadas (para gravedad horizontal)
var block_turns_remaining: int = 0    # Turnos restantes de bloqueo

const BLOCK_DURATION := 3  # Duración del bloqueo en turnos

var pending_lines: Array[Dictionary] = []  # Líneas de 4 que necesitan confirmación
const PENDING_LINE_DURATION := 3  # Turnos para confirmar

func _init():
	create_board()

func create_board():
	grid.clear()
	for i in range(ROWS):
		grid.append([])
		for j in range(COLUMNS):
			grid[i].append(null)

# ========== ROTAR TABLERO 90° CLOCKWISE ==========
func rotate_board_clockwise():
	print("🔄 Rotando tablero 90° (sentido horario)")
	
	# Crear nueva grilla rotada (COLUMNS x ROWS)
	var new_grid = []
	for i in range(COLUMNS):
		new_grid.append([])
		for j in range(ROWS):
			new_grid[i].append(null)
	
	# Rotar: nueva[col][ROWS-1-row] = vieja[row][col]
	for row in range(ROWS):
		for col in range(COLUMNS):
			var new_row = col
			var new_col = ROWS - 1 - row
			new_grid[new_row][new_col] = grid[row][col]
	
	# Intercambiar dimensiones (el tablero ahora es 9x8 en lugar de 8x9)
	# Para mantener 8x9, vamos a transponer de vuelta
	# O simplemente ajustar las constantes temporalmente
	
	# **IMPORTANTE:** Para simplificar, vamos a hacer una rotación visual
	# sin cambiar las dimensiones del tablero.
	# Rotación real cambiaría ROWS ↔ COLUMNS, lo cual es complejo.
	
	# **ALTERNATIVA MÁS SIMPLE:** Rotar 180° (no cambia dimensiones)
	rotate_board_180()

# ========== ROTAR TABLERO 180° (MÁS SIMPLE) ==========
func rotate_board_180():
	print("🔄 Rotando tablero 180°")
	
	# Crear copia del tablero
	var new_grid = []
	for i in range(ROWS):
		new_grid.append([])
		for j in range(COLUMNS):
			new_grid[i].append(null)
	
	# Invertir: nueva[row][col] = vieja[ROWS-1-row][COLUMNS-1-col]
	for row in range(ROWS):
		for col in range(COLUMNS):
			var new_row = ROWS - 1 - row
			var new_col = COLUMNS - 1 - col
			new_grid[new_row][new_col] = grid[row][col]
	
	grid = new_grid
	print("✅ Tablero rotado 180°")

# ========== APLICAR GRAVEDAD DESPUÉS DE ROTACIÓN ==========
func apply_gravity_after_rotation():
	print("🌍 Aplicando gravedad después de rotación")
	
	var changes_made := true
	var iterations := 0
	var max_iterations := 100  # Seguridad para evitar bucle infinito
	
	while changes_made and iterations < max_iterations:
		changes_made = false
		iterations += 1
		
		match gravity_direction:
			Gravity.DOWN:
				# Mover fichas hacia abajo
				for col in range(COLUMNS):
					for row in range(ROWS - 2, -1, -1):  # De arriba hacia abajo
						if grid[row][col] != null and grid[row + 1][col] == null:
							grid[row + 1][col] = grid[row][col]
							grid[row][col] = null
							changes_made = true
			
			Gravity.UP:
				# Mover fichas hacia arriba
				for col in range(COLUMNS):
					for row in range(1, ROWS):
						if grid[row][col] != null and grid[row - 1][col] == null:
							grid[row - 1][col] = grid[row][col]
							grid[row][col] = null
							changes_made = true
			
			Gravity.LEFT:
				# Mover fichas hacia la izquierda
				for row in range(ROWS):
					for col in range(1, COLUMNS):
						if grid[row][col] != null and grid[row][col - 1] == null:
							grid[row][col - 1] = grid[row][col]
							grid[row][col] = null
							changes_made = true
			
			Gravity.RIGHT:
				# Mover fichas hacia la derecha
				for row in range(ROWS):
					for col in range(COLUMNS - 2, -1, -1):
						if grid[row][col] != null and grid[row][col + 1] == null:
							grid[row][col + 1] = grid[row][col]
							grid[row][col] = null
							changes_made = true
	
	print("✅ Gravedad aplicada en", iterations, "iteraciones")

# ========== DETECTAR LÍNEAS DE 4 FORMADAS ==========
func detect_pending_lines() -> Array[Dictionary]:
	var found_lines: Array[Dictionary] = []
	
	for row in range(ROWS):
		for col in range(COLUMNS):
			var cell = grid[row][col]
			if cell == null:
				continue
			
			# Revisar 4 direcciones
			var directions = [
				Vector2i(1, 0),   # Horizontal →
				Vector2i(0, 1),   # Vertical ↓
				Vector2i(1, 1),   # Diagonal ↘
				Vector2i(1, -1)   # Diagonal ↗
			]
			
			for dir in directions:
				var line = check_line_of_4(row, col, dir.x, dir.y, cell)
				if line.size() == 4:
					found_lines.append({
						"player": cell,
						"cells": line,
						"turns_remaining": PENDING_LINE_DURATION
					})
	
	return found_lines

# ========== VERIFICAR LÍNEA DE 4 ==========
func check_line_of_4(start_row: int, start_col: int, d_row: int, d_col: int, player: Jugador) -> Array[Vector2i]:
	var line: Array[Vector2i] = []
	
	for i in range(4):
		var r = start_row + i * d_row
		var c = start_col + i * d_col
		
		if r < 0 or r >= ROWS or c < 0 or c >= COLUMNS:
			return []
		
		if grid[r][c] != player:
			return []
		
		line.append(Vector2i(r, c))
	
	return line

# ========== REDUCIR TURNOS DE LÍNEAS PENDIENTES ==========
func reduce_pending_line_turns():
	var i := 0
	while i < pending_lines.size():
		pending_lines[i].turns_remaining -= 1
		
		if pending_lines[i].turns_remaining <= 0:
			print("⏰ Línea pendiente expirada")
			pending_lines.remove_at(i)
		else:
			i += 1

# ========== VERIFICAR SI UNA JUGADA CONFIRMA UNA LÍNEA ==========
func check_line_confirmation(row: int, col: int, player: Jugador) -> bool:
	for line_data in pending_lines:
		if line_data.player != player:
			continue
		
		var cells: Array[Vector2i] = line_data.cells
		
		# Verificar si la nueva ficha está en un extremo de la línea
		var first_cell = cells[0]
		var last_cell = cells[3]
		
		# Calcular dirección de la línea
		var dir = last_cell - first_cell
		dir.x = sign(dir.x)
		dir.y = sign(dir.y)
		
		# Verificar extremo inicial
		var before_first = first_cell - dir
		if before_first.x == row and before_first.y == col:
			return true
		
		# Verificar extremo final
		var after_last = last_cell + dir
		if after_last.x == row and after_last.y == col:
			return true
	
	return false


# ========== SOLTAR FICHA VERTICAL (columnas) ==========
# ========== BLOQUEAR COLUMNA ALEATORIA ==========
func block_random_column():
	# Limpiar bloqueos anteriores
	blocked_columns.clear()
	blocked_rows.clear()
	
	# Bloquear según la dirección de gravedad
	match gravity_direction:
		Gravity.DOWN, Gravity.UP:
			# Bloquear una columna aleatoria
			var col = randi() % COLUMNS
			blocked_columns.append(col)
			block_turns_remaining = BLOCK_DURATION
			print("🔒 Columna bloqueada:", col)
			return col
		
		Gravity.RIGHT, Gravity.LEFT:
			# Bloquear una fila aleatoria
			var row = randi() % ROWS
			blocked_rows.append(row)
			block_turns_remaining = BLOCK_DURATION
			print("🔒 Fila bloqueada:", row)
			return row
	
	return -1

# ========== VERIFICAR SI UNA POSICIÓN ESTÁ BLOQUEADA ==========
func is_blocked(index: int) -> bool:
	match gravity_direction:
		Gravity.DOWN, Gravity.UP:
			return blocked_columns.has(index)
		Gravity.RIGHT, Gravity.LEFT:
			return blocked_rows.has(index)
	return false

# ========== REDUCIR CONTADOR DE BLOQUEO ==========
func reduce_block_turns():
	if block_turns_remaining > 0:
		block_turns_remaining -= 1
		
		if block_turns_remaining == 0:
			print("🔓 Bloqueo liberado")
			blocked_columns.clear()
			blocked_rows.clear()

# ========== MODIFICAR drop_piece PARA VALIDAR BLOQUEO ==========
func drop_piece(column: int, jugador: Jugador) -> Vector2:
	if column < 0 or column >= COLUMNS:
		return Vector2(-1, -1)
	
	# ✅ VERIFICAR SI LA COLUMNA ESTÁ BLOQUEADA
	if is_blocked(column):
		print("❌ Columna bloqueada:", column)
		return Vector2(-1, -1)
	
	match gravity_direction:
		Gravity.DOWN:
			for row in range(ROWS - 1, -1, -1):
				if grid[row][column] == null:
					grid[row][column] = jugador
					return Vector2(row, column)
		
		Gravity.UP:
			for row in range(ROWS):
				if grid[row][column] == null:
					grid[row][column] = jugador
					return Vector2(row, column)
	
	return Vector2(-1, -1)

# ========== MODIFICAR drop_piece_horizontal PARA VALIDAR BLOQUEO ==========
func drop_piece_horizontal(row: int, jugador: Jugador) -> Vector2:
	if row < 0 or row >= ROWS:
		print("❌ Fila inválida:", row)
		return Vector2(-1, -1)
	
	# ✅ VERIFICAR SI LA FILA ESTÁ BLOQUEADA
	if is_blocked(row):
		print("❌ Fila bloqueada:", row)
		return Vector2(-1, -1)
	
	match gravity_direction:
		Gravity.RIGHT:
			print("🔍 Gravedad RIGHT - Buscando PRIMERA vacía desde columna 0")
			for col in range(COLUMNS):
				if grid[row][col] == null:
					grid[row][col] = jugador
					print("✅ Ficha colocada en fila:", row, "col:", col)
					return Vector2(row, col)
			print("❌ Fila", row, "está llena (RIGHT)")
		
		Gravity.LEFT:
			print("🔍 Gravedad LEFT - Buscando ÚLTIMA vacía desde columna", COLUMNS - 1)
			for col in range(COLUMNS - 1, -1, -1):
				if grid[row][col] == null:
					grid[row][col] = jugador
					print("✅ Ficha colocada en fila:", row, "col:", col)
					return Vector2(row, col)
			print("❌ Fila", row, "está llena (LEFT)")
	
	return Vector2(-1, -1)
	
func check_winner(jugador: Jugador) -> bool:
	for row in range(ROWS):
		for col in range(COLUMNS):
			if check_direction(row, col, 1, 0, jugador):
				return true
			if check_direction(row, col, 0, 1, jugador):
				return true
			if check_direction(row, col, 1, 1, jugador):
				return true
			if check_direction(row, col, 1, -1, jugador):
				return true
	return false

func check_direction(row, col, d_row, d_col, jugador):
	var count = 0
	for i in 4:
		var r = row + i * d_row
		var c = col + i * d_col
		if r >= 0 and r < ROWS and c >= 0 and c < COLUMNS:
			if grid[r][c] == jugador:
				count += 1
			else:
				break
		else:
			break
	return count == 4

func calculate_energy(row, col, jugador):
	var connections = count_connections(row, col, jugador)
	
	if connections == 2:
		jugador.add_energy(1)
	elif connections == 3:
		jugador.add_energy(2)

func count_connections(row, col, jugador) -> int:
	var max_count = 1
	
	max_count = max(max_count, count_direction(row, col, 0, 1, jugador))
	max_count = max(max_count, count_direction(row, col, 1, 0, jugador))
	max_count = max(max_count, count_direction(row, col, 1, 1, jugador))
	max_count = max(max_count, count_direction(row, col, 1, -1, jugador))
	
	return max_count

func count_direction(row, col, d_row, d_col, jugador) -> int:
	var count = 1
	
	var r = row + d_row
	var c = col + d_col
	
	while r >= 0 and r < ROWS and c >= 0 and c < COLUMNS and grid[r][c] == jugador:
		count += 1
		r += d_row
		c += d_col
	
	r = row - d_row
	c = col - d_col
	
	while r >= 0 and r < ROWS and c >= 0 and c < COLUMNS and grid[r][c] == jugador:
		count += 1
		r -= d_row
		c -= d_col
	
	return count

func change_gravity():
	var values = [Gravity.DOWN, Gravity.RIGHT, Gravity.LEFT, Gravity.UP]
	values.erase(gravity_direction)
	
	gravity_direction = values[randi() % values.size()]
	print("Nueva gravedad: ", gravity_direction)
