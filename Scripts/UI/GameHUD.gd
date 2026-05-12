extends Control
class_name GameHUD

@onready var turn_label: Label = $TurnLabel
@onready var p1_name: Label = $Player1Panel/P1NameLabel
@onready var p1_energy_bar: ProgressBar = $Player1Panel/P1EnergyBar
@onready var p1_energy_text: Label = $Player1Panel/P1EnergyText
@onready var p2_name: Label = $Player2Panel/P2NameLabel
@onready var p2_energy_bar: ProgressBar = $Player2Panel/P2EnergyBar
@onready var p2_energy_text: Label = $Player2Panel/P2EnergyText
@onready var gravity_label: Label = $GravityLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player1_color := Color(0.6, 0.2, 0.8)
var player2_color := Color(1.0, 0.3, 0.7)

func _ready():
	# Crear animaciones
	if not animation_player.has_animation("energy_full_p1"):
		create_energy_full_animations()

# ========== ACTUALIZAR TURNO ==========
func update_turn(player_id: int, player_color: Color):
	turn_label.text = "Turno: Jugador " + str(player_id)
	turn_label.modulate = player_color
	
	# Animación de pulso
	var tween = create_tween()
	tween.tween_property(turn_label, "scale", Vector2(1.15, 1.15), 0.2)
	tween.tween_property(turn_label, "scale", Vector2(1.0, 1.0), 0.2)

# ========== ACTUALIZAR ENERGÍA ==========
func update_energy(player_id: int, energy: int, max_energy: int, is_full: bool):
	print("🎮 [HUD] update_energy llamado:")
	print("  Jugador:", player_id)
	print("  Energía:", energy)
	print("  Max:", max_energy)
	print("  Full:", is_full)
	
	if player_id == 1:
		# Animación suave de la barra
		var tween = create_tween()
		tween.tween_property(p1_energy_bar, "value", float(energy), 0.3)
		p1_energy_text.text = "⚡ %d/%d" % [energy, max_energy]
		
		if is_full:
			play_energy_full_animation(1)
	else:
		var tween = create_tween()
		tween.tween_property(p2_energy_bar, "value", float(energy), 0.3)
		p2_energy_text.text = "⚡ %d/%d" % [energy, max_energy]
		
		if is_full:
			play_energy_full_animation(2)

# ========== ACTUALIZAR GRAVEDAD ==========
func update_gravity(direction: int):
	var text := ""
	var icon := ""
	var color := Color.WHITE
	
	match direction:
		0:  # DOWN
			text = "Gravedad: Abajo"
			icon = "⬇️"
			color = Color(0.2, 0.8, 0.4)  # Verde
		1:  # RIGHT
			text = "Gravedad: Derecha"
			icon = "➡️"
			color = Color(1.0, 0.5, 0.0)  # Naranja
		2:  # LEFT
			text = "Gravedad: Izquierda"
			icon = "⬅️"
			color = Color(0.3, 0.5, 1.0)  # Azul
		3:  # UP
			text = "Gravedad: Arriba"
			icon = "⬆️"
			color = Color(1.0, 0.3, 0.3)  # Rojo
	
	gravity_label.text = icon + " " + text
	gravity_label.modulate = color
	
	# Animación de cambio
	var tween = create_tween()
	tween.tween_property(gravity_label, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(gravity_label, "scale", Vector2(1.0, 1.0), 0.15)
	

# ========== ANIMACIÓN DE ENERGÍA COMPLETA ==========
func play_energy_full_animation(player_id: int):
	if player_id == 1:
		animation_player.play("energy_full_p1")
	else:
		animation_player.play("energy_full_p2")

func create_energy_full_animations():
	var anim_library = AnimationLibrary.new()
	
	# ========== ANIMACIÓN JUGADOR 1 ==========
	var anim_p1 = Animation.new()
	anim_p1.length = 1.0
	anim_p1.loop_mode = Animation.LOOP_NONE
	
	# Track 1: Parpadeo de color de la barra
	var track_color = anim_p1.add_track(Animation.TYPE_VALUE)
	anim_p1.track_set_path(track_color, "Player1Panel/P1EnergyBar:modulate")
	anim_p1.track_insert_key(track_color, 0.0, Color(1, 1, 1, 1))
	anim_p1.track_insert_key(track_color, 0.1, Color(2, 2, 0, 1))  # Amarillo brillante
	anim_p1.track_insert_key(track_color, 0.2, Color(1, 1, 1, 1))
	anim_p1.track_insert_key(track_color, 0.3, Color(2, 2, 0, 1))
	anim_p1.track_insert_key(track_color, 0.4, Color(1, 1, 1, 1))
	anim_p1.track_insert_key(track_color, 1.0, Color(1, 1, 1, 1))
	
	# Track 2: Escala del panel
	var track_scale = anim_p1.add_track(Animation.TYPE_VALUE)
	anim_p1.track_set_path(track_scale, "Player1Panel:scale")
	anim_p1.track_insert_key(track_scale, 0.0, Vector2(1, 1))
	anim_p1.track_insert_key(track_scale, 0.2, Vector2(1.1, 1.1))
	anim_p1.track_insert_key(track_scale, 0.4, Vector2(1, 1))
	anim_p1.track_insert_key(track_scale, 1.0, Vector2(1, 1))
	
	anim_library.add_animation("energy_full_p1", anim_p1)
	
	# ========== ANIMACIÓN JUGADOR 2 (similar) ==========
	var anim_p2 = Animation.new()
	anim_p2.length = 1.0
	anim_p2.loop_mode = Animation.LOOP_NONE
	
	var track_color2 = anim_p2.add_track(Animation.TYPE_VALUE)
	anim_p2.track_set_path(track_color2, "Player2Panel/P2EnergyBar:modulate")
	anim_p2.track_insert_key(track_color2, 0.0, Color(1, 1, 1, 1))
	anim_p2.track_insert_key(track_color2, 0.1, Color(2, 2, 0, 1))
	anim_p2.track_insert_key(track_color2, 0.2, Color(1, 1, 1, 1))
	anim_p2.track_insert_key(track_color2, 0.3, Color(2, 2, 0, 1))
	anim_p2.track_insert_key(track_color2, 0.4, Color(1, 1, 1, 1))
	anim_p2.track_insert_key(track_color2, 1.0, Color(1, 1, 1, 1))
	
	var track_scale2 = anim_p2.add_track(Animation.TYPE_VALUE)
	anim_p2.track_set_path(track_scale2, "Player2Panel:scale")
	anim_p2.track_insert_key(track_scale2, 0.0, Vector2(1, 1))
	anim_p2.track_insert_key(track_scale2, 0.2, Vector2(1.1, 1.1))
	anim_p2.track_insert_key(track_scale2, 0.4, Vector2(1, 1))
	anim_p2.track_insert_key(track_scale2, 1.0, Vector2(1, 1))
	
	anim_library.add_animation("energy_full_p2", anim_p2)
	
	animation_player.add_animation_library("", anim_library)
