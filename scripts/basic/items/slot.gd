extends Panel

var default_tex = preload("res://assets/tinyRPG_manaSoulGUI_v_1_0/20250420manaSoul9SlicesE-Sheet.png")
var selected_tex = preload("res://assets/tinyRPG_manaSoulGUI_v_1_0/20250420manaSoul9SlicesD-Sheet.png")

var default_style: StyleBoxTexture = null
var selected_style: StyleBoxTexture = null

const ItemClass = preload("res://scenes/player/inventory/enhanced_item.tscn")
var item: EnhancedItem = null
var slot_index: int

enum SlotType {
	HOTBAR = 0,
	INVENTORY,
	SHIRT,
	PANTS,
	SHOES,
}

var slotType = SlotType.INVENTORY

func _ready():
	default_style = StyleBoxTexture.new()
	selected_style = StyleBoxTexture.new()
	default_style.texture = default_tex
	selected_style.texture = selected_tex
	resized.connect(_on_Slot_resized)
	refresh_style()

	# Важно: разрешаем обработку событий мыши
	mouse_filter = Control.MOUSE_FILTER_PASS

func _on_Slot_resized():
	call_deferred("_update_item_scale")

func refresh_style():
	if slotType == SlotType.HOTBAR and PlayerInventory.active_item_slot == slot_index:
		self.set("theme_override_styles/panel", selected_style)
	else:
		self.set("theme_override_styles/panel", default_style)

func pickFromSlot() -> EnhancedItem:
	if item:
		var picked_item = item
		remove_child(picked_item)
		item = null
		refresh_style()
		return picked_item
	return null

func putIntoSlot(new_item: EnhancedItem):
	if new_item:
		if item:
			item.queue_free()
		item = new_item
		item.position = size / 2
		add_child(item)
		call_deferred("_update_item_scale")
		refresh_style()

func initialize_item(item_name: String, item_quantity: int = 1, variant_data: Dictionary = {}):
	if item:
		item.queue_free()

	item = ItemClass.instantiate()
	add_child(item)
	item.set_item(item_name, item_quantity, variant_data)
	item.position = size / 2
	call_deferred("_update_item_scale")
	refresh_style()

func _update_item_scale():
	if item and item.item_sprite and item.item_sprite.texture:
		var texture_size = item.item_sprite.texture.get_size()
		if texture_size.x == 0 or texture_size.y == 0: return

		var slot_size = size * 0.8
		var scale_x = slot_size.x / texture_size.x
		var scale_y = slot_size.y / texture_size.y
		item.scale = Vector2(min(scale_x, scale_y), min(scale_x, scale_y))

func use_item(user: Node2D) -> bool:
	if item and item.can_use(user):
		var consumed = item.use_item(user)
		if consumed:
			remove_child(item)
			item = null
			refresh_style()
			return true
	return false

func get_item_name() -> String:
	if item:
		return item.item_name
	return ""

func get_item_quantity() -> int:
	if item:
		return item.item_quantity
	return 0

func get_display_name() -> String:
	if item:
		return item.get_display_name()
	return ""

func get_description() -> String:
	if item:
		return item.get_description()
	return ""

func is_empty() -> bool:
	return item == null

func _gui_input(event):
	# Пропускаем события дальше для обработки в других системах
	# Это нужно для совместимости с hotbar.gd и ui_manager.gd
	pass
