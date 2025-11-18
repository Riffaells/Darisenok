extends Node2D
class_name EnhancedItem

# Базовые свойства предмета
var item_name: String = ""
var item_quantity: int = 1
var item_data: Dictionary = {}

# Поведения предмета
var behaviors: Array[ItemBehaviors.IItemBehavior] = []

# UI элементы
@onready var item_sprite: Sprite2D = $ItemSprite
@onready var quantity_label: Label = $QuantityLabel

func _ready():
	# Настройка UI
	if quantity_label:
		quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Загрузка данных предмета
	if item_name != "":
		load_item_data()
		_setup_behaviors()
		_update_display()

func set_item(new_item_name: String, new_quantity: int = 1, variant_data: Dictionary = {}):
	"""
	Устанавливает предмет с возможностью кастомизации через variant_data

	Пример использования:
	set_item("Kitchen Knife", 1, {"damage": 25, "key_id": "special_door"})
	"""
	item_name = new_item_name
	item_quantity = new_quantity

	# Загружаем базовые данные
	load_item_data()

	# Применяем кастомные данные (перезаписывают базовые)
	for key in variant_data:
		item_data[key] = variant_data[key]

	# Настраиваем поведения
	_setup_behaviors()

	# Обновляем UI (отложенно, чтобы узел был готов)
	call_deferred("_update_display")

func load_item_data():
	"""Загружает базовые данные предмета из JSON"""
	if JsonData.item_data.has(item_name):
		item_data = JsonData.item_data[item_name].duplicate(true)
	else:
		print("Предмет не найден в базе данных: ", item_name)
		item_data = {
			"display_name": item_name,
			"description": "Неизвестный предмет",
			"Icon": "res://assets/basic/inventory/slot.png"
		}

func _setup_behaviors():
	"""Настраивает поведения предмета на основе его данных"""
	behaviors.clear()

	var weapon_type = item_data.get("weapon_type", "")
	var usage_types = item_data.get("usage_types", [])
	var item_category = item_data.get("ItemCategory", "")

	# Определяем тип оружия
	match weapon_type:
		"melee":
			behaviors.append(ItemBehaviors.MeleeWeaponBehavior.new())
		"ranged":
			behaviors.append(ItemBehaviors.RangedWeaponBehavior.new())
		"magic":
			behaviors.append(ItemBehaviors.MagicWeaponBehavior.new())

	# Определяем по категории предмета
	match item_category:
		"Consumable":
			behaviors.append(ItemBehaviors.FoodBehavior.new())
		"Weapon":
			if weapon_type == "":  # Если тип оружия не указан, используем ближний бой
				behaviors.append(ItemBehaviors.MeleeWeaponBehavior.new())

	# Определяем по типам использования
	if usage_types.has("Health"):
		behaviors.append(ItemBehaviors.FoodBehavior.new())
	
	if usage_types.has("Combat") and weapon_type == "":
		behaviors.append(ItemBehaviors.MeleeWeaponBehavior.new())

	# Ключи
	if item_data.has("key_id"):
		behaviors.append(ItemBehaviors.KeyBehavior.new())

func use_item(user: Node2D) -> bool:
	"""
	Использует предмет. Возвращает true если предмет был использован и должен быть удален
	"""
	for behavior in behaviors:
		if behavior.can_use(item_data, user):
			var consumed = behavior.use(item_data, user)
			if consumed:
				item_quantity -= 1
				_update_display()
				return item_quantity <= 0
			break
	return false

func can_use(user: Node2D) -> bool:
	"""Проверяет, можно ли использовать предмет"""
	for behavior in behaviors:
		if behavior.can_use(item_data, user):
			return true
	return false

func get_use_description() -> String:
	"""Возвращает описание действия при использовании"""
	for behavior in behaviors:
		return behavior.get_use_description()
	return "Использовать"

func _update_display():
	"""Обновляет отображение предмета"""
	# Обновляем иконку
	if item_sprite and item_data.has("Icon"):
		var texture = load(item_data["Icon"])
		if texture:
			item_sprite.texture = texture

	# Обновляем количество
	if quantity_label:
		if item_quantity > 1:
			quantity_label.text = str(item_quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false

func get_display_name() -> String:
	"""Возвращает отображаемое имя предмета"""
	return item_data.get("display_name", item_name)

func get_description() -> String:
	"""Возвращает описание предмета"""
	var desc = item_data.get("description", "")
	var info = []

	if item_data.has("damage"):
		info.append("Урон: " + str(item_data["damage"]))
	if item_data.has("heal_amount"):
		info.append("Лечение: " + str(item_data["heal_amount"]))
	if item_data.has("mana_cost"):
		info.append("Стоимость маны: " + str(item_data["mana_cost"]))

	if info.size() > 0:
		desc += "\n\n" + "\n".join(info)

	return desc

func get_rarity_color() -> Color:
	"""Возвращает цвет редкости предмета"""
	match item_data.get("rarity", "Common"):
		"Common":
			return Color.WHITE
		"Uncommon":
			return Color.GREEN
		"Rare":
			return Color.BLUE
		"Epic":
			return Color.PURPLE
		"Legendary":
			return Color.ORANGE
		_:
			return Color.WHITE

func get_texture() -> Texture2D:
	"""Возвращает текстуру предмета для системы перетаскивания"""
	if item_sprite and item_sprite.texture:
		return item_sprite.texture
	return null
