extends Node

# Тестовый файл для проверки функциональности инвентаря
# Добавьте этот скрипт к любому узлу в сцене для тестирования

# Тестовые команды (добавьте в _ready или вызовите из консоли)
func test_inventory_system():
	print("=== Тестирование системы инвентаря ===")

	# Тест 1: Добавление предметов
	print("\n1. Тестирование добавления предметов")
	PlayerInventory.add_item("Kitchen Knife", 2)
	PlayerInventory.add_item("Green Apple", 5)
	PlayerInventory.add_item("Health Potion", 3)
	print("Предметы добавлены в инвентарь")

	# Тест 2: Переключение активного слота
	print("\n2. Тестирование переключения слотов")
	for i in range(3):
		PlayerInventory.set_active_item_slot(i)
		print("Активный слот: ", i)
		await get_tree().create_timer(0.5).timeout

	# Тест 3: Прокрутка хотбара
	print("\n3. Тестирование прокрутки хотбара")
	PlayerInventory.active_item_scroll_up()
	print("Прокрутка вверх, активный слот: ", PlayerInventory.active_item_slot)
	PlayerInventory.active_item_scroll_down()
	print("Прокрутка вниз, активный слот: ", PlayerInventory.active_item_slot)

func _ready():
	# Запускаем тест через секунду после загрузки
	await get_tree().create_timer(1.0).timeout
	test_inventory_system()

# Функции для ручного тестирования через консоль
func add_test_item(item_name: String, quantity: int = 1):
	PlayerInventory.add_item(item_name, quantity)
	print("Добавлен предмет: ", item_name, " x", quantity)

func switch_slot(slot_index: int):
	PlayerInventory.set_active_item_slot(slot_index)
	print("Переключено на слот: ", slot_index)

func print_inventory_status():
	print("=== Состояние инвентаря ===")
	print("Активный слот: ", PlayerInventory.active_item_slot)
	print("Инвентарь: ", PlayerInventory.inventory)
	print("Хотбар: ", PlayerInventory.hotbar)
	print("Экипировка: ", PlayerInventory.equips)

# Горячие клавиши для тестирования (если нужно)
func _input(event):
	if event.is_action_pressed("ui_accept"): # Пробел
		print_inventory_status()
	elif event.is_action_pressed("pickup"): # Z
		add_test_item("Green Apple", 1)
