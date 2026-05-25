extends Control
class_name QuestionDialog

signal answer_selected(is_correct: bool)
signal question_skipped

@onready var question_label: Label = $Panel/VBoxContainer/QuestionLabel
@onready var options_container: VBoxContainer = $Panel/VBoxContainer/OptionsContainer
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var skip_button: Button = $Panel/VBoxContainer/HBoxContainer/SkipButton
@onready var timer_label: Label = $Panel/VBoxContainer/HBoxContainer/TimerLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_question: Dictionary = {}
var correct_index: int = -1
var is_answered: bool = false
var time_remaining: float = 15.0
var is_skippable: bool = true

var option_buttons: Array[Button] = []

func _ready():
	# Obtener botones de opciones
	for child in options_container.get_children():
		if child is Button:
			option_buttons.append(child)
			child.pressed.connect(_on_option_pressed.bind(option_buttons.find(child)))
	
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Ocultar al inicio
	visible = false
	modulate.a = 0

# ========== MOSTRAR PREGUNTA ==========
func show_question(question: Dictionary, allow_skip: bool = true):
	current_question = question
	correct_index = question.correct
	is_answered = false
	is_skippable = allow_skip
	time_remaining = 15.0
	
	# Configurar UI
	question_label.text = question.q
	
	for i in range(option_buttons.size()):
		if i < question.options.size():
			option_buttons[i].text = question.options[i]
			option_buttons[i].visible = true
			option_buttons[i].disabled = false
			option_buttons[i].modulate = Color.WHITE
		else:
			option_buttons[i].visible = false
	
	feedback_label.visible = false
	skip_button.visible = allow_skip
	timer_label.text = "⏱ Tiempo: 15s"
	
	# Mostrar con animación
	visible = true
	if not animation_player.has_animation("show"):
		create_animations()
	animation_player.play("show")
	
	# Iniciar temporizador
	set_process(true)

func _process(delta: float):
	if is_answered or not visible:
		set_process(false)
		return
	
	time_remaining -= delta
	timer_label.text = "⏱ Tiempo: %ds" % int(ceil(time_remaining))
	
	# Cambiar color del temporizador cuando queda poco tiempo
	if time_remaining <= 5:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE
	
	# Tiempo agotado
	if time_remaining <= 0:
		_on_time_out()

# ========== MANEJAR SELECCIÓN DE OPCIÓN ==========
func _on_option_pressed(index: int):
	if is_answered:
		return
	
	is_answered = true
	set_process(false)
	
	var is_correct = (index == correct_index)
	
	# Deshabilitar todos los botones
	for btn in option_buttons:
		btn.disabled = true
	
	# Colorear respuesta
	if is_correct:
		option_buttons[index].modulate = Color.GREEN
		feedback_label.text = "✅ ¡Correcto!"
		feedback_label.modulate = Color.GREEN
	else:
		option_buttons[index].modulate = Color.RED
		option_buttons[correct_index].modulate = Color.GREEN
		feedback_label.text = "❌ Incorrecto"
		feedback_label.modulate = Color.RED
	
	feedback_label.visible = true
	
	# Esperar y emitir señal
	await get_tree().create_timer(2.0).timeout
	emit_signal("answer_selected", is_correct)
	hide_dialog()

# ========== MANEJAR SALTAR PREGUNTA ==========
func _on_skip_pressed():
	if not is_skippable:
		return
	
	is_answered = true
	set_process(false)
	emit_signal("question_skipped")
	hide_dialog()

# ========== TIEMPO AGOTADO ==========
func _on_time_out():
	is_answered = true
	
	# Mostrar respuesta correcta
	option_buttons[correct_index].modulate = Color.GREEN
	feedback_label.text = "⏰ Tiempo agotado"
	feedback_label.modulate = Color.ORANGE
	feedback_label.visible = true
	
	# Deshabilitar botones
	for btn in option_buttons:
		btn.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("answer_selected", false)
	hide_dialog()

# ========== OCULTAR DIÁLOGO ==========
func hide_dialog():
	animation_player.play("hide")
	await animation_player.animation_finished
	visible = false

# ========== CREAR ANIMACIONES ==========
func create_animations():
	var anim_library = AnimationLibrary.new()
	
	# Animación de entrada
	var show_anim = Animation.new()
	show_anim.length = 0.3
	
	var track_alpha = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_alpha, ".:modulate:a")
	show_anim.track_insert_key(track_alpha, 0.0, 0.0)
	show_anim.track_insert_key(track_alpha, 0.3, 1.0)
	
	anim_library.add_animation("show", show_anim)
	
	# Animación de salida
	var hide_anim = Animation.new()
	hide_anim.length = 0.2
	
	var hide_alpha = hide_anim.add_track(Animation.TYPE_VALUE)
	hide_anim.track_set_path(hide_alpha, ".:modulate:a")
	hide_anim.track_insert_key(hide_alpha, 0.0, 1.0)
	hide_anim.track_insert_key(hide_alpha, 0.2, 0.0)
	
	anim_library.add_animation("hide", hide_anim)
	
	animation_player.add_animation_library("", anim_library)
