extends Node

# Глобальный менеджер состояния игры
# Сохраняет состояние между уровнями

signal amulet_obtained
signal amulet_state_changed(has_amulet: bool)

# Состояние амулета
var has_amulet: bool = false
var amulet_dialogues_completed: Array[String] = []
var amulet_texture_number: int = 16  # Текущая текстура амулета

# Состояние кристаллов
var collected_crystals: int = 0
var max_crystals: int = 4  # Максимальное количество кристаллов
var crystal_locations: Dictionary = {}  # Какие кристаллы уже собраны

# Состояние диалогов
var completed_dialogues: Dictionary = {}

# Состояние цветков
var collected_flowers: Dictionary = {}

# Состояние зачищенных зон
var cleared_areas: Dictionary = {}



func _ready():
	# Проверяем завершен ли диалог с Акжаном (dialog-1)
	# Если да - автоматически даем амулет
	call_deferred("check_amulet_from_dialogue")

func check_amulet_from_dialogue():
	"""Проверяет нужно ли дать амулет на основе завершенных диалогов"""
	if is_dialogue_completed("dialog-1") and not has_amulet:
		give_amulet()

# === АМУЛЕТ ===
func give_amulet():
	"""Дает амулет игроку"""
	if not has_amulet:
		has_amulet = true
		amulet_obtained.emit()
		amulet_state_changed.emit(true)
		
		# Показываем амулет в UI
		show_amulet_in_ui()
	else:
		pass

func remove_amulet():
	"""Убирает амулет у игрока"""
	has_amulet = false
	amulet_state_changed.emit(false)

func get_has_amulet() -> bool:
	"""Проверяет есть ли амулет у игрока"""
	return has_amulet

func set_amulet_texture(texture_number: int):
	"""Устанавливает текстуру амулета"""
	amulet_texture_number = texture_number
	
	# Обновляем текстуру у всех амулетов в UI
	var amulets = get_tree().get_nodes_in_group("amulet_character")
	for amulet in amulets:
		if amulet.has_method("set_texture"):
			amulet.set_texture(texture_number)

func get_amulet_texture() -> int:
	"""Возвращает текущую текстуру амулета"""
	return amulet_texture_number

# === ДИАЛОГИ ===
func mark_dialogue_completed(dialogue_id: String):
	"""Отмечает диалог как завершенный"""
	completed_dialogues[dialogue_id] = true

func is_dialogue_completed(dialogue_id: String) -> bool:
	"""Проверяет завершен ли диалог"""
	return completed_dialogues.get(dialogue_id, false)

# === ЦВЕТЫ ===
func collect_flower(flower_id: String):
	if not collected_flowers.has(flower_id):
		collected_flowers[flower_id] = true

func is_flower_collected(flower_id: String) -> bool:
	return collected_flowers.get(flower_id, false)

func get_collected_flower_count() -> int:
	return collected_flowers.size()

# === ЗОНЫ ===
func set_area_as_cleared(area_id: String):
	if not cleared_areas.has(area_id):
		cleared_areas[area_id] = true

func is_area_cleared(area_id: String) -> bool:
	return cleared_areas.get(area_id, false)



# === КРИСТАЛЛЫ ===
func collect_crystal(crystal_id: String):
	"""Собирает кристалл"""
	if crystal_locations.get(crystal_id, false):
		return
	
	crystal_locations[crystal_id] = true
	collected_crystals += 1

func is_crystal_collected(crystal_id: String) -> bool:
	"""Проверяет собран ли кристалл"""
	return crystal_locations.get(crystal_id, false)

func get_collected_crystals() -> int:
	"""Возвращает количество собранных кристаллов"""
	return collected_crystals

func get_max_crystals() -> int:
	"""Возвращает максимальное количество кристаллов"""
	return max_crystals

func reset_crystals():
	"""Сбрасывает состояние кристаллов (для тестирования)"""
	collected_crystals = 0
	crystal_locations.clear()

func start_new_level():
	"""Вызывается при начале нового уровня"""
	# Сбрасываем кристаллы для каждого уровня
	reset_crystals()

# === UI ===
func show_amulet_in_ui():
	"""Показывает амулет в UI на всех уровнях"""
	# Прямой поиск амулета в UI
	var amulet = get_tree().get_first_node_in_group("amulet_character")
	if amulet:
		if amulet.has_method("show_amulet"):
			amulet.show_amulet()
		else:
			amulet.visible = true
	else:
		# Попробуем через AmuletManager
		var amulet_manager = get_node_or_null("/root/AmuletManager")
		if amulet_manager and amulet_manager.has_method("show_amulet_ui"):
			amulet_manager.show_amulet_ui()

# === СОХРАНЕНИЕ/ЗАГРУЗКА ===
func save_game_state() -> Dictionary:
	"""Сохраняет состояние игры"""
	return {
		"has_amulet": has_amulet,
		"completed_dialogues": completed_dialogues,
		"amulet_dialogues_completed": amulet_dialogues_completed,
		"collected_crystals": collected_crystals,
		"crystal_locations": crystal_locations,
		"amulet_texture_number": amulet_texture_number
	}

func load_game_state(data: Dictionary):
	"""Загружает состояние игры"""
	has_amulet = data.get("has_amulet", false)
	completed_dialogues = data.get("completed_dialogues", {})
	amulet_dialogues_completed = data.get("amulet_dialogues_completed", [])
	collected_crystals = data.get("collected_crystals", 0)
	crystal_locations = data.get("crystal_locations", {})
	amulet_texture_number = data.get("amulet_texture_number", 16)
