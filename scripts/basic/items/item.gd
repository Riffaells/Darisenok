extends Node2D

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

var item_name: String
var item_quantity: int
const ItemClass = preload("res://scenes/player/inventory/item.tscn")

func _ready():
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_item(nm: String, qt: int):
	item_name = nm
	item_quantity = qt

	if JsonData.item_data.has(item_name):
		var item_data = JsonData.item_data[item_name]
		texture_rect.texture = load(item_data["Icon"])

		var stack_size = int(item_data["StackSize"])
		if stack_size == 1:
			label.visible = false
		else:
			label.visible = true
			label.text = str(item_quantity)
	else:
		label.text = str(item_quantity)

func add_item_quantity(amount_to_add: int):
	item_quantity += amount_to_add
	label.text = str(item_quantity)

func decrease_item_quantity(amount_to_remove: int):
	item_quantity -= amount_to_remove
	label.text = str(item_quantity)

func get_texture() -> Texture2D:
	"""Возвращает текстуру предмета для системы перетаскивания"""
	if texture_rect and texture_rect.texture:
		return texture_rect.texture
	return null
