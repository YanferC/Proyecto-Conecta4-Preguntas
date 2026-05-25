extends Node

class_name Jugador

signal energy_updated(player_id: int, new_energy: int)
signal power_unlocked(power_type: int)
signal power_used(power_type: int)

var id: int
var energy: int = 0
var color: Color

const MAX_ENERGY = 5
var ability_ready: bool = false

enum PowerType {
	NONE,
	STEAL_ENERGY,      # Medio: robar energía
	REMOVE_PIECE,      # Medio: eliminar 1 ficha
	REMOVE_LINE,       # Alto: eliminar fila/columna
	SKIP_TURN          # Alto: saltar turno rival
}

enum PowerLevel {
	NONE,
	MEDIUM,
	HIGH
}


var unlocked_power: PowerType = PowerType.NONE
var unlocked_power_level: PowerLevel = PowerLevel.NONE
var power_blocked: bool = false  # Si respondió mal la pregunta obligatoria
var can_retry_with_quick: bool = true  # Puede reintentar con pregunta rápida


func _init(jugador_id: int, jugador_color: Color):
	id = jugador_id
	color = jugador_color

# ========== SISTEMA DE ENERGÍA ==========
func add_energy(amount: int):
	var before_energy = energy
	energy += amount
	
	if energy >= MAX_ENERGY:
		energy = MAX_ENERGY
		if not ability_ready:
			ability_ready = true
			power_blocked = true  # Bloqueado inicialmente hasta responder pregunta
			can_retry_with_quick = true
			print("⚡ Jugador", id, " - Energía completa! Debe responder pregunta obligatoria")
	
	energy_updated.emit(id, energy)

func use_energy(amount: int) -> bool:
	if energy >= amount:
		energy -= amount
		
		if energy < MAX_ENERGY:
			ability_ready = false
			unlocked_power = PowerType.NONE
			unlocked_power_level = PowerLevel.NONE
			power_blocked = false
			can_retry_with_quick = true
		
		energy_updated.emit(id, energy)
		return true
	return false

# ========== DESBLOQUEAR PODER (respuesta correcta en pregunta obligatoria) ==========
func unlock_power(power_type: PowerType, power_level: PowerLevel):
	unlocked_power = power_type
	unlocked_power_level = power_level
	power_blocked = false  # Ya no está bloqueado, puede usarlo
	can_retry_with_quick = false
	print("🔓 Jugador", id, " desbloqueó poder:", PowerType.keys()[power_type], " (Nivel:", PowerLevel.keys()[power_level], ")")
	power_unlocked.emit(power_type)

# ========== BLOQUEAR PODER (respuesta incorrecta) ==========
func block_power():
	power_blocked = true
	unlocked_power = PowerType.NONE
	unlocked_power_level = PowerLevel.NONE
	ability_ready = false
	energy = 0  # Reiniciar energía a 0
	can_retry_with_quick = false  # Ya no puede reintentar
	print("🔒 Jugador", id, " - PODER BLOQUEADO PERMANENTEMENTE! Energía reiniciada a 0")
	energy_updated.emit(id, energy)

# ========== REINTENTAR CON PREGUNTA RÁPIDA ==========
func retry_with_quick_question():
	if can_retry_with_quick and power_blocked and ability_ready:
		can_retry_with_quick = false
		print("🔄 Jugador", id, " - Reintentando desbloquear poder con pregunta rápida")
		return true
	return false

# ========== USAR PODER ==========
func use_unlocked_power() -> bool:
	if power_blocked:
		print("❌ Jugador", id, " - El poder está bloqueado!")
		return false
	
	if unlocked_power == PowerType.NONE:
		print("❌ Jugador", id, " - No hay poder desbloqueado!")
		return false
	
	# Marcar que se usó el poder
	var used_power = unlocked_power
	power_used.emit(unlocked_power)
	
	# REINICIAR ENERGÍA Y ESTADO DESPUÉS DE USAR PODER
	unlocked_power = PowerType.NONE
	unlocked_power_level = PowerLevel.NONE
	ability_ready = false
	energy = 0  # Reiniciar a 0
	power_blocked = false
	can_retry_with_quick = true
	
	energy_updated.emit(id, energy)
	
	print("💥 Jugador", id, " usó poder:", PowerType.keys()[used_power], "- Energía reiniciada a 0")
	return true
