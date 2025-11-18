extends Node

var item_data: Dictionary = {}

func _ready():
	item_data = LoadData("res://data/item_data.json")

func LoadData(file_path):
	if not FileAccess.file_exists(file_path):
		print("Файл данных предметов не найден: ", file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		if content.strip_edges().is_empty():
			print("Файл данных предметов пуст: ", file_path)
			return {}

		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data = json.get_data()
			print("Загружено предметов: ", data.size())
			_validate_item_data(data)
			return data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", file_path, " at line ", json.get_error_line())
			return {}
	return {}

func _validate_item_data(data: Dictionary):
	"""Проверяет корректность данных предметов"""
	for item_name in data:
		var item = data[item_name]
		
		# Проверяем обязательные поля
		if not item.has("display_name"):
			print("Предупреждение: У предмета '", item_name, "' нет display_name")
		if not item.has("Icon"):
			print("Предупреждение: У предмета '", item_name, "' нет иконки")
		if not item.has("ItemCategory"):
			print("Предупреждение: У предмета '", item_name, "' нет категории")
		
		# Устанавливаем значения по умолчанию
		if not item.has("StackSize"):
			item["StackSize"] = 1
		if not item.has("rarity"):
			item["rarity"] = "Common"
		if not item.has("consumable"):
			item["consumable"] = false

func reload_data():
	"""Перезагружает данные предметов (полезно для разработки)"""
	item_data = LoadData("res://data/item_data.json")

func get_item_info(item_name: String) -> Dictionary:
	"""Возвращает информацию о предмете с проверкой"""
	if item_data.has(item_name):
		return item_data[item_name]
	else:
		print("Предмет не найден: ", item_name)
		return {
			"display_name": item_name,
			"description": "Неизвестный предмет",
			"Icon": "res://assets/basic/inventory/slot.png",
			"ItemCategory": "Unknown",
			"StackSize": 1,
			"rarity": "Common"
		}
