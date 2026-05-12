extends Control
class_name EventNotification

@onready var background: ColorRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var desc_label: Label = $DescLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal notification_finished

func _ready():
	# Ocultar al inicio
	modulate.a = 0
	scale = Vector2(0.5, 0.5)
	
	# Crear animaciones si no existen
	if not animation_player.has_animation("show"):
		create_animations()

func show_event(event_name: String, description: String, icon: String = "⚠️"):
	title_label.text = icon + " " + event_name.to_upper()
	desc_label.text = description
	
	# Reiniciar estado visual
	modulate.a = 0
	scale = Vector2(0.5, 0.5)
	background.position = Vector2.ZERO
	
	# Reproducir animación de entrada
	animation_player.play("show")
	await animation_player.animation_finished
	
	# Esperar un momento
	await get_tree().create_timer(2.0).timeout
	
	# Reproducir animación de salida
	animation_player.play("hide")
	await animation_player.animation_finished
	
	emit_signal("notification_finished")

func create_animations():
	var anim_library = AnimationLibrary.new()
	
	# =========================================================
	# ANIMACIÓN DE ENTRADA
	# =========================================================
	var show_anim = Animation.new()
	show_anim.length = 0.5
	
	# Fade in
	var track_alpha = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_alpha, ".:modulate:a")
	show_anim.track_insert_key(track_alpha, 0.0, 0.0)
	show_anim.track_insert_key(track_alpha, 0.5, 1.0)
	show_anim.track_set_interpolation_type(
		track_alpha,
		Animation.INTERPOLATION_CUBIC
	)
	
	# Escala (zoom)
	var track_scale = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_scale, ".:scale")
	show_anim.track_insert_key(track_scale, 0.0, Vector2(0.5, 0.5))
	show_anim.track_insert_key(track_scale, 0.3, Vector2(1.1, 1.1))
	show_anim.track_insert_key(track_scale, 0.5, Vector2(1.0, 1.0))
	show_anim.track_set_interpolation_type(
		track_scale,
		Animation.INTERPOLATION_CUBIC
	)
	
	# Rotación del título
	var track_rotation = show_anim.add_track(Animation.TYPE_VALUE)
	show_anim.track_set_path(track_rotation, "TitleLabel:rotation")
	show_anim.track_insert_key(track_rotation, 0.0, deg_to_rad(-10))
	show_anim.track_insert_key(track_rotation, 0.5, 0.0)
	show_anim.track_set_interpolation_type(
		track_rotation,
		Animation.INTERPOLATION_CUBIC
	)
	
	anim_library.add_animation("show", show_anim)
	
	# =========================================================
	# ANIMACIÓN DE SALIDA
	# =========================================================
	var hide_anim = Animation.new()
	hide_anim.length = 0.4
	
	# Fade out
	var hide_alpha = hide_anim.add_track(Animation.TYPE_VALUE)
	hide_anim.track_set_path(hide_alpha, ".:modulate:a")
	hide_anim.track_insert_key(hide_alpha, 0.0, 1.0)
	hide_anim.track_insert_key(hide_alpha, 0.4, 0.0)
	hide_anim.track_set_interpolation_type(
		hide_alpha,
		Animation.INTERPOLATION_CUBIC
	)
	
	# Escala pequeña
	var hide_scale = hide_anim.add_track(Animation.TYPE_VALUE)
	hide_anim.track_set_path(hide_scale, ".:scale")
	hide_anim.track_insert_key(hide_scale, 0.0, Vector2(1.0, 1.0))
	hide_anim.track_insert_key(hide_scale, 0.4, Vector2(0.3, 0.3))
	hide_anim.track_set_interpolation_type(
		hide_scale,
		Animation.INTERPOLATION_CUBIC
	)
	
	# Movimiento hacia arriba
	# Movimiento hacia arriba SOLO del fondo
	var hide_pos = hide_anim.add_track(Animation.TYPE_VALUE)
	hide_anim.track_set_path(hide_pos, "Background:position")
	hide_anim.track_insert_key(hide_pos, 0.0, Vector2(0, 0))
	hide_anim.track_insert_key(hide_pos, 0.4, Vector2(0, -100))
	hide_anim.track_set_interpolation_type(
		hide_pos,
		Animation.INTERPOLATION_CUBIC
	)
	
	anim_library.add_animation("hide", hide_anim)
	
	# Agregar biblioteca al AnimationPlayer
	animation_player.add_animation_library("", anim_library)
