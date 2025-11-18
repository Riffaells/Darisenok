extends Node
class_name PlayerStats

# Сигналы для обновления UI
signal health_changed(new_health: float, max_health: float)
signal energy_changed(new_energy: float, max_energy: float)

# Основные характеристики
@export var max_health: float = 100.0
@export var max_energy: float = 100.0

var current_health: float
var current_energy: float

# Регенерация
@export var health_regen_rate: float = 4.0  # здоровье в секунду (увеличено с 0.3 до 4.0)
@export var energy_regen_rate: float = 2.0  # энергия в секунду

# Таймеры для регенерации
var health_regen_timer: float = 0.0
var energy_regen_timer: float = 0.0

# Бафы
var active_buffs: Dictionary = {}

func _ready():
	# Инициализируем полные характеристики
	current_health = max_health
	current_energy = max_energy
	
	# Рандомная регенерация от 3 до 5
	health_regen_rate = randf_range(3.0, 5.0)
	print("Регенерация здоровья: ", health_regen_rate, " HP/сек")
	
	# Отправляем начальные сигналы
	health_changed.emit(current_health, max_health)
	energy_changed.emit(current_energy, max_energy)

func _process(delta):
	# Регенерация здоровья (медленная)
	if current_health < max_health:
		health_regen_timer += delta
		if health_regen_timer >= 1.0:  # Каждую секунду
			heal(health_regen_rate)
			health_regen_timer = 0.0
	
	# Регенерация энергии (быстрая)
	if current_energy < max_energy:
		energy_regen_timer += delta
		if energy_regen_timer >= 1.0 / energy_regen_rate:
			restore_energy(1)
			energy_regen_timer = 0.0
	

	
	# Обновляем бафы
	_update_buffs(delta)

func heal(amount: float) -> bool:
	if current_health >= max_health:
		return false
	
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	return true

func take_damage(amount: float) -> bool:
	current_health = max(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	print("Получен урон: -", amount, " (", current_health, "/", max_health, ")")
	
	if current_health <= 0:
		_on_death()
		return true
	return false

func restore_energy(amount: float) -> bool:
	if current_energy >= max_energy:
		return false
	
	current_energy = min(current_energy + amount, max_energy)
	energy_changed.emit(current_energy, max_energy)
	return true

func consume_energy(amount: float) -> bool:
	if current_energy < amount:
		return false
	
	current_energy -= amount
	energy_changed.emit(current_energy, max_energy)
	return true

func consume_energy_float(amount: float) -> bool:
	"""Версия для дробных значений энергии"""
	var amount_int = int(ceil(amount))  # Округляем вверх
	if current_energy < amount_int:
		return false
	
	current_energy -= amount_int
	if current_energy < 0:
		current_energy = 0
	energy_changed.emit(current_energy, max_energy)
	return true



func get_health() -> float:
	return current_health

func get_energy() -> float:
	return current_energy



func apply_buff(buff_type: String, duration: float):
	"""Применяет бафф на определенное время"""
	active_buffs[buff_type] = duration
	print("Применён бафф: ", buff_type, " на ", duration, " сек")
	
	# Применяем эффект баффа
	match buff_type:
		"speed":
			var player = get_parent()
			if player.has_method("set_speed_multiplier"):
				player.set_speed_multiplier(1.5)
		"strength":
			# Увеличиваем урон
			pass
		"regeneration":
			# Ускоряем регенерацию
			health_regen_rate *= 2.0

func _update_buffs(delta: float):
	"""Обновляет активные баффы"""
	var buffs_to_remove = []
	
	for buff_type in active_buffs:
		active_buffs[buff_type] -= delta
		if active_buffs[buff_type] <= 0:
			buffs_to_remove.append(buff_type)
	
	# Удаляем истекшие баффы
	for buff_type in buffs_to_remove:
		_remove_buff(buff_type)
		active_buffs.erase(buff_type)

func _remove_buff(buff_type: String):
	"""Убирает эффект баффа"""
	print("Бафф истёк: ", buff_type)
	
	match buff_type:
		"speed":
			var player = get_parent()
			if player.has_method("set_speed_multiplier"):
				player.set_speed_multiplier(1.0)
		"regeneration":
			health_regen_rate = 1.0

func _on_death():
	"""Обработка смерти игрока"""
	print("💀 Игрок погиб! Возрождение...")
	
	# Восстанавливаем здоровье до 70
	current_health = 70.0
	health_changed.emit(current_health, max_health)
	print("❤️ Здоровье восстановлено до 70")
	
	# Телепортируем к точке Home на текущем уровне
	print("🏠 Телепортация к точке Home...")
	var home = get_tree().get_first_node_in_group("home")
	if not home:
		home = get_tree().current_scene.get_node_or_null("Home")
	
	if home:
		var player = get_parent()
		if player:
			player.global_position = home.global_position
			print("✅ Игрок телепортирован к Home")
	else:
		print("⚠️ Home не найден, телепортируем в центр")
		var player = get_parent()
		if player:
			player.global_position = Vector2.ZERO