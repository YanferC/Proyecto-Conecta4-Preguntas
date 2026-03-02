extends Node

class_name QuestionSystem

var questions = [
	{"q": "¿Qué estructura es LIFO?", "a": "Pila"},
	{"q": "¿2^3?", "a": "8"}
]

func get_random_question():
	return questions[randi() % questions.size()]
