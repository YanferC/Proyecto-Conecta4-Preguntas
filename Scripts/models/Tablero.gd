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

func _init():
	create_board()

func create_board():
	grid.clear()
	for i in range(ROWS):
		grid.append([])
		for j in range(COLUMNS):
			grid[i].append(null)
			

func drop_piece(column: int, jugador: Jugador) -> Vector2:
	
	match gravity_direction:
		
		Gravity.DOWN:
			for row in range(ROWS - 1, -1, -1):
				if grid[row][column] == null:
					grid[row][column] = jugador
					return Vector2(row, column)
					
		Gravity.RIGHT:
			for col in range(COLUMNS - 1, -1, -1):
				if grid[column][col] == null:
					grid[column][col] = jugador
					return Vector2(column, col)
					
		Gravity.LEFT:
			for col in range(COLUMNS):
				if grid[column][col] == null:
					grid[column][col] = jugador
					return Vector2(column, col)

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
	
	# Revisar horizontal
	max_count = max(max_count, count_direction(row, col, 0, 1, jugador))
	
	# Revisar vertical
	max_count = max(max_count, count_direction(row, col, 1, 0, jugador))
	
	# Diagonal \
	max_count = max(max_count, count_direction(row, col, 1, 1, jugador))
	
	# Diagonal /
	max_count = max(max_count, count_direction(row, col, 1, -1, jugador))
	
	return max_count

func count_direction(row, col, d_row, d_col, jugador) -> int:
	var count = 1
	
	# Hacia adelante
	var r = row + d_row
	var c = col + d_col
	
	while r >= 0 and r < ROWS and c >= 0 and c < COLUMNS and grid[r][c] == jugador:
		count += 1
		r += d_row
		c += d_col
	
	# Hacia atrás
	r = row - d_row
	c = col - d_col
	
	while r >= 0 and r < ROWS and c >= 0 and c < COLUMNS and grid[r][c] == jugador:
		count += 1
		r -= d_row
		c -= d_col
	
	return count
	
func change_gravity():
	var values = [Gravity.DOWN, Gravity.RIGHT, Gravity.LEFT]
	
	# Evitar que repita la misma
	values.erase(gravity_direction)
	
	gravity_direction = values[randi() % values.size()]
	
	print("Nueva gravedad: ", gravity_direction)
