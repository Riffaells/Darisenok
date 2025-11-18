extends Node

# Глобальный менеджер амулета - управляет появлением амулета после диалогов
# УСТАРЕЛ: Теперь используется GameStateManager

var has_amulet: bool = false

func _ready():
	print("AmuletManager готов (УСТАРЕЛ - используйте GameStateManager)")
	
	# Подключаемся к новому менеджеру состояния
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		game_state.amulet_obtained.connect(_on_amulet_obtained)
		# Синхронизируем состояние
		has_amulet = game_state.get_has_amulet()

func _on_amulet_obtained():
	"""Вызывается когда игрок получает амулет через GameStateManager"""
	has_amulet = true
	show_amulet_ui()

func give_amulet():
	"""Дает амулет игроку (УСТАРЕЛ - используйте GameStateManager.give_amulet())"""
	print("⚠️ AmuletManager.give_amulet() УСТАРЕЛ! Используйте GameStateManager.give_amulet()")
	
	# Перенаправляем на новый менеджер
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		game_state.give_amulet()
	else:
		# Старый код для совместимости
		if has_amulet:
			return
		
		has_amulet = true
		print("Игрок получил амулет!")
		show_amulet_ui()

func show_amulet_ui():
	"""Показывает амулет в UI"""
	var amulet = find_amulet_in_hotbar()
	if amulet:
		amulet.show_amulet()
	else:
		print("Амулет в hotbar не найден!")

func find_amulet_in_hotbar() -> AmuletCharacter:
	"""Находит амулет в hotbar"""
	# Ищем по всему дереву сцены
	var hotbar = get_tree().get_first_node_in_group("hotbar")
	if hotbar:
		var amulet = hotbar.get_node_or_null("AmuletCharacter")
		if amulet:
			return amulet
	
	# Альтернативный поиск
	var all_amulets = get_tree().get_nodes_in_group("amulet_character")
	if all_amulets.size() > 0:
		return all_amulets[0]
	
	# Поиск по имени узла
	var found_amulet = get_tree().root.find_child("AmuletCharacter", true, false)
	return found_amulet

func has_amulet_item() -> bool:
	"""Проверяет есть ли у игрока амулет"""
	# Проверяем через новый менеджер состояния
	var game_state = get_node_or_null("/root/GameStateManager")
	if game_state:
		return game_state.get_has_amulet()
	
	return has_amulet
