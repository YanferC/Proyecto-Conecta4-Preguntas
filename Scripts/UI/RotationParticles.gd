extends CPUParticles2D
class_name RotationParticles

func _ready():
	emitting = false
	one_shot = true
	amount = 50
	lifetime = 1.5
	speed_scale = 2.0
	
	# Configurar emisión circular
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 300.0
	
	# Configurar colores (dorado/amarillo)
	color = Color(1, 0.84, 0, 1)
	color_ramp = Gradient.new()
	color_ramp.add_point(0.0, Color(1, 1, 0, 1))
	color_ramp.add_point(1.0, Color(1, 0.5, 0, 0))
	
	# Configurar física
	gravity = Vector2(0, 200)
	initial_velocity_min = 100
	initial_velocity_max = 300
	
	# Escala
	scale_amount_min = 2.0
	scale_amount_max = 4.0

func emit_burst():
	emitting = true
	await get_tree().create_timer(lifetime).timeout
	queue_free()
