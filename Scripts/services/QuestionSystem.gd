extends Node
class_name QuestionSystem

# ========== PREGUNTAS RÁPIDAS (OPCIONALES) ==========
var quick_questions := [
	{
		"q": "¿En qué contenedor se tira el papel?",
		"options": ["Azul", "Amarillo", "Verde", "Gris"],
		"correct": 0
	},
	{
		"q": "¿Los envases de plástico van al contenedor...?",
		"options": ["Verde", "Azul", "Amarillo", "Marrón"],
		"correct": 2
	},
	{
		"q": "¿Las pilas son residuos peligrosos?",
		"options": ["Sí", "No", "Solo las grandes", "Depende"],
		"correct": 0
	},
	{
		"q": "¿El vidrio se puede reciclar infinitas veces?",
		"options": ["Sí", "No", "Solo 5 veces", "Solo 10 veces"],
		"correct": 0
	},
	{
		"q": "¿Qué color tiene el contenedor de orgánico?",
		"options": ["Verde", "Marrón", "Gris", "Amarillo"],
		"correct": 1
	},
	{
		"q": "¿Los tetrabricks van al contenedor amarillo?",
		"options": ["Sí", "No", "Solo vacíos", "Solo limpios"],
		"correct": 0
	},
	{
		"q": "¿Cuántos años tarda en degradarse una bolsa de plástico?",
		"options": ["10 años", "50 años", "150 años", "500 años"],
		"correct": 2
	},
	{
		"q": "¿El aluminio es 100% reciclable?",
		"options": ["Sí", "No", "Solo al 50%", "Solo al 80%"],
		"correct": 0
	},
	{
		"q": "¿Qué NO va en el contenedor amarillo?",
		"options": ["Latas", "Briks", "Vasos de cristal", "Plásticos"],
		"correct": 2
	},
	{
		"q": "¿El papel sucio se puede reciclar?",
		"options": ["Sí", "No", "Solo si está poco sucio", "Depende del tipo"],
		"correct": 1
	}
]

# ========== PREGUNTAS OBLIGATORIAS (MÁS DIFÍCILES) ==========
var mandatory_questions := [
	{
		"q": "¿Qué porcentaje del plástico mundial se recicla actualmente?",
		"options": ["9%", "25%", "50%", "75%"],
		"correct": 0
	},
	{
		"q": "¿Cuántas toneladas de CO2 se ahorran reciclando 1 tonelada de papel?",
		"options": ["0.5 ton", "1 ton", "2 ton", "3 ton"],
		"correct": 1
	},
	{
		"q": "¿Qué material tarda más en degradarse?",
		"options": ["Vidrio", "Plástico", "Aluminio", "Papel"],
		"correct": 0
	},
	{
		"q": "¿Cuántos litros de agua se ahorran reciclando 1kg de papel?",
		"options": ["10L", "26L", "50L", "100L"],
		"correct": 1
	},
	{
		"q": "¿Qué país recicla más del 90% de sus latas de aluminio?",
		"options": ["Brasil", "Alemania", "Japón", "Suecia"],
		"correct": 0
	},
	{
		"q": "¿Cuántas veces se puede reciclar el papel?",
		"options": ["2-3 veces", "5-7 veces", "10-15 veces", "Infinitas"],
		"correct": 1
	},
	{
		"q": "¿Qué porcentaje de energía se ahorra reciclando aluminio vs. fabricarlo de nuevo?",
		"options": ["30%", "50%", "75%", "95%"],
		"correct": 3
	},
	{
		"q": "¿Cuántos años tarda en degradarse una botella de vidrio?",
		"options": ["100 años", "500 años", "1000 años", "4000 años"],
		"correct": 3
	},
	{
		"q": "¿Qué residuo electrónico es el más generado en el mundo?",
		"options": ["Móviles", "Ordenadores", "Televisores", "Neveras"],
		"correct": 2
	},
	{
		"q": "¿Qué continente genera más residuos plásticos?",
		"options": ["Asia", "Europa", "América", "África"],
		"correct": 0
	}
]

var used_quick_questions: Array[int] = []
var used_mandatory_questions: Array[int] = []

# ========== OBTENER PREGUNTA RÁPIDA ALEATORIA ==========
func get_random_quick_question() -> Dictionary:
	# Si ya usamos todas, reiniciar
	if used_quick_questions.size() >= quick_questions.size():
		used_quick_questions.clear()
	
	# Buscar una pregunta no usada
	var available_indices := []
	for i in range(quick_questions.size()):
		if not used_quick_questions.has(i):
			available_indices.append(i)
	
	if available_indices.is_empty():
		used_quick_questions.clear()
		available_indices = range(quick_questions.size())
	
	# Seleccionar aleatoriamente
	var index = available_indices[randi() % available_indices.size()]
	used_quick_questions.append(index)
	
	return quick_questions[index]

# ========== OBTENER PREGUNTA OBLIGATORIA ALEATORIA ==========
func get_random_mandatory_question() -> Dictionary:
	# Si ya usamos todas, reiniciar
	if used_mandatory_questions.size() >= mandatory_questions.size():
		used_mandatory_questions.clear()
	
	# Buscar una pregunta no usada
	var available_indices := []
	for i in range(mandatory_questions.size()):
		if not used_mandatory_questions.has(i):
			available_indices.append(i)
	
	if available_indices.is_empty():
		used_mandatory_questions.clear()
		available_indices = range(mandatory_questions.size())
	
	# Seleccionar aleatoriamente
	var index = available_indices[randi() % available_indices.size()]
	used_mandatory_questions.append(index)
	
	return mandatory_questions[index]

# ========== VERIFICAR RESPUESTA ==========
func check_answer(question: Dictionary, selected_index: int) -> bool:
	return question.correct == selected_index
