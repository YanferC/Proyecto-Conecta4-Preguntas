extends Area2D
class_name Piece

signal piece_landed(piece: Piece)

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var jugador: Jugador
var target_position: Vector2
var grid_row: int = -1
var grid_col: int = -1
var is_falling: bool = false
var fall_direction: int = 0

const FALL_SPEED := 800.0
const CELL_SIZE := 80

func setup(player: Jugador, target_row: int, target_col: int, start_pos: Vector2, offset_x: float, offset_y: float, gravity_dir: int):
	jugador = player
	grid_row = target_row
	grid_col = target_col
	fall_direction = gravity_dir
	
	# ⚠️ IMPORTANTE: NO recalcular position aquí
	# Usar directamente el start_pos que viene como parámetro
	position = start_pos  # ← Esta línea debe mantenerse
	
	# ❌ NO HACER ESTO (borra si existe):
	# position.y = start_y  
	# position.x = target_col * CELL_SIZE + CELL_SIZE / 2
	
	target_position = Vector2(
		offset_x + target_col * CELL_SIZE + CELL_SIZE / 2,
		offset_y + target_row * CELL_SIZE + CELL_SIZE / 2
	)
	
	is_falling = true
	
	if jugador:
		sprite.modulate = jugador.color
	
	print("🎯 Ficha configurada:")
	print("  - Dirección:", fall_direction)
	print("  - Inicio:", position)
	print("  - Objetivo:", target_position)
	print("  - Fila/Col destino:", target_row, "/", target_col)
	

func _physics_process(delta: float):
	if not is_falling:
		return
	
	# Movimiento según dirección de gravedad
	match fall_direction:
		0:  # DOWN (Gravity.DOWN)
			position.y += FALL_SPEED * delta
			if position.y >= target_position.y:
				position.y = target_position.y
				is_falling = false
				_land()
		
		1:  # RIGHT (Gravity.RIGHT) - La ficha viene desde la DERECHA y va hacia la IZQUIERDA
			position.x -= FALL_SPEED * delta  # ← Moverse hacia la IZQUIERDA
			if position.x <= target_position.x:
				position.x = target_position.x
				is_falling = false
				_land()
		
		2:  # LEFT (Gravity.LEFT) - La ficha viene desde la IZQUIERDA y va hacia la DERECHA
			position.x += FALL_SPEED * delta  # → Moverse hacia la DERECHA
			if position.x >= target_position.x:
				position.x = target_position.x
				is_falling = false
				_land()
		
		3:  # UP (Gravity.UP)
			position.y -= FALL_SPEED * delta
			if position.y <= target_position.y:
				position.y = target_position.y
				is_falling = false
				_land()

func _land():
	play_land_animation()
	emit_signal("piece_landed", self)

func play_land_animation():
	if not animation_player.has_animation("land"):
		create_land_animation()
	animation_player.play("land")

func create_land_animation():
	var animation = Animation.new()
	animation.length = 0.3
	
	var track_scale = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_scale, "Sprite:scale")
	
	animation.track_insert_key(track_scale, 0.0, Vector2(0.2, 0.2))
	animation.track_insert_key(track_scale, 0.1, Vector2(0.24, 0.16))
	animation.track_insert_key(track_scale, 0.2, Vector2(0.18, 0.22))
	animation.track_insert_key(track_scale, 0.3, Vector2(0.2, 0.2))
	
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("land", animation)
	animation_player.add_animation_library("", anim_library)
