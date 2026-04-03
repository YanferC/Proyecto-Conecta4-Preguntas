extends Node
class_name GameController

signal board_changed
signal energy_flash(player_id: int)
signal gravity_event(direction: int)
signal winner(player_id: int)
signal reset_done

var board: Board
var jugador1: Jugador
var jugador2: Jugador
var current_player: Jugador

var event_manager: EventManager
var question_system: QuestionSystem

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

func switch_turn():
	current_player = jugador2 if current_player == jugador1 else jugador1

func try_place_piece(column: int):
	var pos = board.drop_piece(column, current_player)
	if pos.x == -1:
		return

	var before_energy = current_player.energy
	board.calculate_energy(pos.x, pos.y, current_player)

	# Si se llenó la energía ahora, avisar para FX/sonido
	if current_player.ability_ready and before_energy < Jugador.MAX_ENERGY:
		emit_signal("energy_flash", current_player.id)

	if board.check_winner(current_player):
		emit_signal("winner", current_player.id)
		return

	switch_turn()

	# Evento aleatorio (gravedad)
	event_manager.next_turn(board, self)

	emit_signal("board_changed")

func reset_game():
	board.create_board()
	jugador1.energy = 0
	jugador2.energy = 0
	jugador1.ability_ready = false
	jugador2.ability_ready = false
	current_player = jugador1

	emit_signal("reset_done")
	emit_signal("board_changed")

# Callback usado por EventManager (lo dejamos igual por simplicidad)
func on_gravity_event(direction):
	emit_signal("gravity_event", direction)
	emit_signal("board_changed")
