extends Node

# Простой тест для системы перетаскивания

func _ready():
	# Ждем секунду чтобы все инициализировалось
	await get_tree().create_timer(1.0).timeout
	test_drag_system()

func test_drag_system():
	print("=== Тест системы перетаскивания ===")

	# Проверяем, что UI Manager существует
	var ui_manager = get_tree().root.find_child("UIManager", true, false)
	if not ui_manager:
		print("ОШИБКА: UIManager не найден!")
		return

	print("UI Manager найден: ", ui_manager.name)

	# Проверяем компоненты
	if ui_manager.inventory:
		print("Инвентарь найден, слоты: ", ui_manager.inventory.slots.size())
	else:
		print("ОШИБКА: Инвентарь не найден!")

	if ui_manager.hotbar:
		print("Хотбар найден, слоты: ", ui_manager.hotbar.slots.size())
	else:
		print("ОШИБКА: Хотбар не найден!")

	if ui_manager.dragged_item_display:
		print("Дисплей перетаскивания найден")
	else:
		print("ОШИБКА: Дисплей перетаскивания не найден!")

	# Проверяем предметы в слотах
	var item_count = 0
	for slot in ui_manager.inventory.slots:
		if not slot.is_empty():
			item_count += 1
			print("Предмет в слоте: ", slot.get_item_name())

	for slot in ui_manager.hotbar.slots:
		if not slot.is_empty():
			item_count += 1
			print("Предмет в хотбаре: ", slot.get_item_name())

	print("Всего предметов: ", item_count)

	if item_count == 0:
		print("Добавляем тестовые предметы...")
		PlayerInventory.add_item("Kitchen Knife", 1)
		PlayerInventory.add_item("Green Apple", 3)

func _input(event):
	# Тестовая клавиша для проверки состояния
	if event.is_action_pressed("pickup"): # Z
		print("\n=== Состояние системы ===")
		var ui_manager = get_tree().root.find_child("UIManager", true, false)
		if ui_manager:
			print("Перетаскивание активно: ", ui_manager.dragged_slot != null)
			if ui_manager.dragged_slot:
				print("Перетаскиваемый предмет: ", ui_manager.dragged_slot.get_item_name())
			print("Инвентарь открыт: ", ui_manager.inventory.visible)

	# Принудительно открыть инвентарь для тестирования
	elif event.is_action_pressed("ui_accept"): # Пробел
		var ui_manager = get_tree().root.find_child("UIManager", true, false)
		if ui_manager:
			ui_manager.toggle_inventory()
			print("Инвентарь переключен: ", ui_manager.inventory.visible)
