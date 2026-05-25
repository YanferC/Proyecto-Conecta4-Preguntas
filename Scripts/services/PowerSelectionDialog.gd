extends Control
class_name PowerSelectionDialog

signal power_selected(power_type: int, power_level: int)
signal dialog_closed

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var medium_panel: Panel = $Panel/MediumPanel
@onready var high_panel: Panel = $Panel/HighPanel
@onready var medium_steal_btn: Button = $Panel/MediumPanel/StealEnergyBtn
@onready var medium_remove_btn: Button = $Panel/MediumPanel/RemovePieceBtn
@onready var high_remove_line_btn: Button = $Panel/HighPanel/RemoveLineBtn
@onready var high_skip_turn_btn: Button = $Panel/HighPanel/SkipTurnBtn

var current_player_id: int = 0
var animation_player: AnimationPlayer
var tween: Tween

# Colores de la paleta
const COLOR_BG_DARK = Color(0.176, 0.106, 0.306)  # #2D1B4E
const COLOR_PURPLE = Color(0.49, 0.17, 0.65)      # #7D2CA5
const COLOR_PINK = Color(1.0, 0.188, 0.44)        # #FF3070
const COLOR_GOLD = Color(1.0, 0.84, 0.0)          # #FFD700
const COLOR_ORANGE = Color(1.0, 0.42, 0.21)       # #FF6B35
const COLOR_WHITE = Color.WHITE
const COLOR_DARK_TEXT = Color(0.9, 0.9, 0.95)

func _ready():
	# Configurar estilos
	setup_styles()
	
	# Crear AnimationPlayer si no existe
	if not has_node("AnimationPlayer"):
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
		create_animations()
	else:
		animation_player = $AnimationPlayer
	
	# Conectar botones
	medium_steal_btn.pressed.connect(_on_steal_energy_pressed)
	medium_remove_btn.pressed.connect(_on_remove_piece_pressed)
	high_remove_line_btn.pressed.connect(_on_remove_line_pressed)
	high_skip_turn_btn.pressed.connect(_on_skip_turn_pressed)
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Configurar efectos hover
	setup_hover_effects()
	
	# Inicialmente oculto
	visible = false
	modulate.a = 0

func setup_styles():
	# ========== ESTILO DEL PANEL PRINCIPAL ==========
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_DARK
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = COLOR_PINK
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.shadow_size = 20
	panel_style.shadow_offset = Vector2(0, 5)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# ========== ESTILO DE PANELES INTERNOS ==========
	# MediumPanel
	var medium_style = StyleBoxFlat.new()
	medium_style.bg_color = Color(0.25, 0.15, 0.4)
	medium_style.border_width_left = 2
	medium_style.border_width_right = 2
	medium_style.border_width_top = 2
	medium_style.border_width_bottom = 2
	medium_style.border_color = COLOR_PURPLE
	medium_style.corner_radius_top_left = 15
	medium_style.corner_radius_top_right = 15
	medium_style.corner_radius_bottom_left = 15
	medium_style.corner_radius_bottom_right = 15
	
	medium_panel.add_theme_stylebox_override("panel", medium_style)
	
	# HighPanel
	var high_style = StyleBoxFlat.new()
	high_style.bg_color = Color(0.25, 0.15, 0.4)
	high_style.border_width_left = 2
	high_style.border_width_right = 2
	high_style.border_width_top = 2
	high_style.border_width_bottom = 2
	high_style.border_color = COLOR_GOLD
	high_style.corner_radius_top_left = 15
	high_style.corner_radius_top_right = 15
	high_style.corner_radius_bottom_left = 15
	high_style.corner_radius_bottom_right = 15
	
	high_panel.add_theme_stylebox_override("panel", high_style)
	
	# ========== ESTILO DEL TÍTULO ==========
	title_label.add_theme_color_override("font_color", COLOR_GOLD)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# ========== ESTILO DE BOTONES ==========
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = COLOR_PURPLE
	button_style.border_width_bottom = 3
	button_style.border_color = Color(0.3, 0.1, 0.4)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	
	var button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = COLOR_PINK
	button_hover_style.border_width_bottom = 3
	button_hover_style.border_color = Color(0.8, 0.15, 0.35)
	button_hover_style.corner_radius_top_left = 10
	button_hover_style.corner_radius_top_right = 10
	button_hover_style.corner_radius_bottom_left = 10
	button_hover_style.corner_radius_bottom_right = 10
	
	var button_pressed_style = StyleBoxFlat.new()
	button_pressed_style.bg_color = Color(0.35, 0.12, 0.5)
	button_pressed_style.border_width_top = 3
	button_pressed_style.border_color = Color(0.3, 0.1, 0.4)
	button_pressed_style.corner_radius_top_left = 10
	button_pressed_style.corner_radius_top_right = 10
	button_pressed_style.corner_radius_bottom_left = 10
	button_pressed_style.corner_radius_bottom_right = 10
	
	var buttons = [medium_steal_btn, medium_remove_btn, high_remove_line_btn, high_skip_turn_btn]
	for btn in buttons:
		btn.add_theme_stylebox_override("normal", button_style)
		btn.add_theme_stylebox_override("hover", button_hover_style)
		btn.add_theme_stylebox_override("pressed", button_pressed_style)
		btn.add_theme_color_override("font_color", COLOR_WHITE)
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD)
		btn.add_theme_constant_override("outline_size", 1)
	
	# ========== ESTILO DEL BOTÓN DE CERRAR ==========
	if close_button:
		var close_style = StyleBoxFlat.new()
		close_style.bg_color = Color(0.5, 0.1, 0.1)
		close_style.corner_radius_top_left = 15
		close_style.corner_radius_top_right = 15
		close_style.corner_radius_bottom_left = 15
		close_style.corner_radius_bottom_right = 15
		
		var close_hover_style = StyleBoxFlat.new()
		close_hover_style.bg_color = Color(0.8, 0.15, 0.15)
		close_hover_style.corner_radius_top_left = 15
		close_hover_style.corner_radius_top_right = 15
		close_hover_style.corner_radius_bottom_left = 15
		close_hover_style.corner_radius_bottom_right = 15
		
		close_button.add_theme_stylebox_override("normal", close_style)
		close_button.add_theme_stylebox_override("hover", close_hover_style)
		close_button.add_theme_color_override("font_color", COLOR_WHITE)

func setup_hover_effects():
	# Efecto de escala al pasar mouse sobre paneles
	var panels = [medium_panel, high_panel]
	for p in panels:
		p.mouse_entered.connect(_on_panel_hover_enter.bind(p))
		p.mouse_exited.connect(_on_panel_hover_exit.bind(p))
	
	# Efecto en botones individuales
	var buttons = [
		{"btn": medium_steal_btn, "desc": "Roba 2 energía al rival"},
		{"btn": medium_remove_btn, "desc": "Elimina una ficha del tablero"},
		{"btn": high_remove_line_btn, "desc": "Elimina fila o columna completa"},
		{"btn": high_skip_turn_btn, "desc": "El rival pierde su próximo turno"}
	]
	
	for b in buttons:
		b.btn.mouse_entered.connect(_show_tooltip.bind(b.desc))
		b.btn.mouse_exited.connect(_hide_tooltip)

func _show_tooltip(text: String):
	# Crear o mostrar tooltip
	if not has_node("Tooltip"):
		var tooltip = Label.new()
		tooltip.name = "Tooltip"
		tooltip.add_theme_color_override("font_color", COLOR_GOLD)
		tooltip.add_theme_color_override("font_shadow_color", Color.BLACK)
		tooltip.add_theme_constant_override("shadow_offset_x", 1)
		tooltip.add_theme_constant_override("shadow_offset_y", 1)
		add_child(tooltip)
	
	var tooltip_label = $Tooltip
	tooltip_label.text = "✨ " + text
	tooltip_label.position = get_viewport().get_mouse_position() + Vector2(15, -30)
	tooltip_label.visible = true
	
	# Animación fade in
	var t = create_tween()
	t.tween_property(tooltip_label, "modulate:a", 1.0, 0.2)

func _hide_tooltip():
	if has_node("Tooltip"):
		$Tooltip.visible = false

func _on_panel_hover_enter(panel_node: Panel):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel_node, "scale", Vector2(1.02, 1.02), 0.2)

func _on_panel_hover_exit(panel_node: Panel):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel_node, "scale", Vector2(1.0, 1.0), 0.2)

func show_dialog(player_id: int):
	current_player_id = player_id
	title_label.text = "🎮 JUGADOR " + str(player_id) + " - ¡ELIGE TU PODER! 🎮"
	
	# Efecto de brillo en los botones según el jugador
	var player_color = COLOR_PINK if player_id == 1 else COLOR_ORANGE
	medium_panel.add_theme_stylebox_override("panel", create_border_style(player_color, 0.25, 0.15, 0.4))
	high_panel.add_theme_stylebox_override("panel", create_border_style(COLOR_GOLD, 0.25, 0.15, 0.4))
	
	if panel:
		var viewport_size = get_viewport_rect().size
		panel.position = Vector2(
			(viewport_size.x - panel.size.x) / 2.0,
			(viewport_size.y - panel.size.y) / 2.0
		)
	
	visible = true
	
	# Animación de entrada
	if animation_player and animation_player.has_animation("show"):
		animation_player.play("show")
	elif animation_player:
		# Animación por defecto si no existe
		var t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_BACK)
		t.tween_property(self, "modulate:a", 1.0, 0.3)
		t.parallel().tween_property(panel, "scale", Vector2(1, 1), 0.3)
		panel.scale = Vector2(0.8, 0.8)
		modulate.a = 0

func create_border_style(border_color: Color, r: float, g: float, b: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(r, g, b)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	return style

func hide_dialog():
	# Animación de salida
	if animation_player and animation_player.has_animation("hide"):
		animation_player.play("hide")
		await animation_player.animation_finished
	else:
		var t = create_tween()
		t.set_ease(Tween.EASE_IN)
		t.tween_property(self, "modulate:a", 0.0, 0.2)
		await t.finished
	
	visible = false
	emit_signal("dialog_closed")

func create_animations():
	var anim_library = AnimationLibrary.new()
	
	# ========== ANIMACIÓN DE ENTRADA ==========
	var show_anim = Animation.new()
	show_anim.length = 0.4
	
	# Fade in
	var track_alpha = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_alpha, ".:modulate:a")
	show_anim.track_insert_key(track_alpha, 0.0, 0.0)
	show_anim.track_insert_key(track_alpha, 0.4, 1.0)
	
	# Escala (zoom con rebote)
	var track_scale = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_scale, "Panel:scale")
	show_anim.track_insert_key(track_scale, 0.0, Vector2(0.7, 0.7))
	show_anim.track_insert_key(track_scale, 0.2, Vector2(1.05, 1.05))
	show_anim.track_insert_key(track_scale, 0.4, Vector2(1.0, 1.0))
	
	# Rotación de entrada
	var track_rotation = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_rotation, "Panel:rotation")
	show_anim.track_insert_key(track_rotation, 0.0, deg_to_rad(-5))
	show_anim.track_insert_key(track_rotation, 0.4, 0.0)
	
	anim_library.add_animation("show", show_anim)
	
	# ========== ANIMACIÓN DE SALIDA ==========
	var hide_anim = Animation.new()
	hide_anim.length = 0.25
	
	var hide_alpha = hide_anim.add_track(Animation.TYPE_VALUE)
	hide_anim.track_set_path(hide_alpha, ".:modulate:a")
	hide_anim.track_insert_key(hide_alpha, 0.0, 1.0)
	hide_anim.track_insert_key(hide_alpha, 0.25, 0.0)
	
	var hide_scale = hide_anim.add_track(Animation.TYPE_VALUE)
	hide_anim.track_set_path(hide_scale, "Panel:scale")
	hide_anim.track_insert_key(hide_scale, 0.0, Vector2(1.0, 1.0))
	hide_anim.track_insert_key(hide_scale, 0.25, Vector2(0.5, 0.5))
	
	anim_library.add_animation("hide", hide_anim)
	
	animation_player.add_animation_library("", anim_library)

# ========== BOTONES DE PODER ==========
func _on_steal_energy_pressed():
	play_button_press_effect(medium_steal_btn)
	emit_signal("power_selected", Jugador.PowerType.STEAL_ENERGY, Jugador.PowerLevel.MEDIUM)
	hide_dialog()

func _on_remove_piece_pressed():
	play_button_press_effect(medium_remove_btn)
	emit_signal("power_selected", Jugador.PowerType.REMOVE_PIECE, Jugador.PowerLevel.MEDIUM)
	hide_dialog()

func _on_remove_line_pressed():
	play_button_press_effect(high_remove_line_btn)
	emit_signal("power_selected", Jugador.PowerType.REMOVE_LINE, Jugador.PowerLevel.HIGH)
	hide_dialog()

func _on_skip_turn_pressed():
	play_button_press_effect(high_skip_turn_btn)
	emit_signal("power_selected", Jugador.PowerType.SKIP_TURN, Jugador.PowerLevel.HIGH)
	hide_dialog()

func _on_close_pressed():
	play_button_press_effect(close_button)
	emit_signal("dialog_closed")
	hide_dialog()

func play_button_press_effect(button: Button):
	# Efecto visual al presionar
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
	t.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Efecto de sonido (si tienes AudioStreamPlayer)
	if has_node("ButtonSound"):
		$ButtonSound.play()
