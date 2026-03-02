extends Node2D

var board
var jugador1
var jugador2
var current_player
var event_manager
var question_system

func _ready():
	board = Board.new()
	jugador1 = Jugador.new(1, Color.RED)
	jugador2 = Jugador.new(2, Color.YELLOW)
	current_player = jugador1
	
	event_manager = EventManager.new()
	question_system = QuestionSystem.new()
	
	print("Juego iniciado")
	
func switch_turn():
	if current_player == jugador1:
		current_player = jugador2
	else:
		current_player = jugador1
