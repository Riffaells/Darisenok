extends Node
class_name ItemManager

# Синглтон для управления предметами
static var instance: ItemManager

func _ready():
	instance = self

# Создание предмета с базовыми свойствами
static func create_item(item_name: String, quantity: int = 1) -> EnhancedItem:
	var item_scene = preload("res://scenes/player/inventory/enhanced_item.tscn")
	var item = item_scene.instantiate()
	item.set_item(item_name, quantity)
	return item

# Создание предмета с кастомными свойствами
static func create_custom_item(item_name: String, quantity: int = 1, custom_data: Dictionary = {}) -> EnhancedItem:
	var item_scene = preload("res://scenes/player/inventory/enhanced_item.tscn")
	var item = item_scene.instantiate()
	item.set_item(item_name, quantity, custom_data)
	return item

# Примеры создания разных вариантов предметов
static func create_examples():
	print("=== Примеры создания предметов ===")

	# 1. Обычный кухонный нож
	var normal_knife = create_item("Kitchen Knife", 1)
	print("Обычный нож: ", normal_knife.get_display_name(), " - урон: ", normal_knife.item_data.get("damage", 0))

	# 2. Усиленный кухонный нож
	var enhanced_knife = create_custom_item("Kitchen Knife", 1, {
		"damage": 30,
		"display_name": "Заточенный кухонный нож",
		"description": "Идеально заточенный нож. Режет как бритва."
	})
	print("Усиленный нож: ", enhanced_knife.get_display_name(), " - урон: ", enhanced_knife.item_data.get("damage", 0))

	# 3. Кухонный нож-ключ (комбо предмет)
	var knife_key = create_custom_item("Kitchen Knife", 1, {
		"key_id": "kitchen_door",
		"display_name": "Нож-ключ",
		"description": "Странный нож с зубчиками. Может открывать замки.",
		"use_range": 70
	})
	print("Нож-ключ: ", knife_key.get_display_name(), " - может атаковать И открывать замки")

	# 4. Разные ключи для разных дверей
	var house_key = create_custom_item("Old Key", 1, {
		"key_id": "house_main",
		"display_name": "Ключ от дома",
		"description": "Ключ от главного входа в дом."
	})

	var basement_key = create_custom_item("Old Key", 1, {
		"key_id": "house_basement",
		"display_name": "Ключ от подвала",
		"description": "Ключ от подвала дома. Пахнет сыростью."
	})

	print("Ключ от дома: ", house_key.item_data.get("key_id"))
	print("Ключ от подвала: ", basement_key.item_data.get("key_id"))

	# 5. Супер-яблоко
	var super_apple = create_custom_item("Green Apple", 1, {
		"heal_amount": 50,
		"energy_amount": 30,
		"display_name": "Золотое яблоко",
		"description": "Волшебное яблоко, дающее невероятную силу.",
		"rarity": "Epic"
	})
	print("Супер-яблоко: ", super_apple.get_display_name(), " - лечение: ", super_apple.item_data.get("heal_amount", 0))

# Функция для тестирования использования предметов
static func test_item_usage():
	print("\n=== Тестирование использования предметов ===")

	# Создаем тестового игрока (заглушка)
	var test_player = Node2D.new()
	test_player.name = "TestPlayer"

	# Добавляем методы для тестирования
	test_player.set_script(GDScript.new())
	test_player.get_script().source_code = """
extends Node2D

func heal(amount: int):
	print('Игрок восстановил ', amount, ' здоровья')

func restore_energy(amount: int):
	print('Игрок восстановил ', amount, ' энергии')

func take_damage(amount: int):
	print('Игрок получил ', amount, ' урона')
"""

	# Тестируем разные предметы
	var apple = create_item("Green Apple", 3)
	var knife = create_item("Kitchen Knife", 1)
	var key = create_item("Old Key", 1)

	print("\n--- Тест еды ---")
	print("Использую яблоко...")
	apple.use_item(test_player)

	print("\n--- Тест оружия ---")
	print("Использую нож...")
	knife.use_item(test_player)

	print("\n--- Тест ключа ---")
	print("Использую ключ (без двери поблизости)...")
	key.use_item(test_player)

	# Очистка
	test_player.queue_free()

static func test_weapons():
	print("=== Тестирование оружия ===")

	# Создаем тестового игрока
	var test_player = Node2D.new()
	test_player.name = "TestPlayer"

	# Тестируем разные типы оружия
	var knife = create_item("Kitchen Knife", 1)
	var bow = create_item("Wooden Bow", 1)
	var staff = create_item("Fire Staff", 1)

	print("\n--- Тест ножа (ближний бой) ---")
	knife.use_item(test_player)

	print("\n--- Тест лука (дальний бой) ---")
	bow.use_item(test_player)

	print("\n--- Тест посоха (магия) ---")
	staff.use_item(test_player)

	# Создаем кастомные варианты
	var super_knife = create_custom_item("Kitchen Knife", 1, {
		"damage": 100,
		"display_name": "Супер-нож",
		"description": "Невероятно острый нож!"
	})

	print("\n--- Тест супер-ножа ---")
	print("Название: ", super_knife.get_display_name())
	print("Урон: ", super_knife.item_data.get("damage"))

	test_player.queue_free()
