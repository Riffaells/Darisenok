extends Node2D

# Hotbar - Система быстрого доступа к предметам
#
# Новые возможности управления:
# 1. Клавиши 1-9 - переключение активного слота
# 2. Клик ЛКМ по слоту - переключение активного слота
# 3. Колесико мыши - последовательное переключение слотов
# 4. Перетаскивание предметов между слотами и инвентарем

const SlotClass = preload("res://scripts/basic/items/slot.gd")
@onready var hotbar_slots = $HotbarSlots
@onready var active_item_label = $ActiveItemLabel
@onready var slots = hotbar_slots.get_children()

func _ready():
	PlayerInventory.active_item_updated.connect(update_active_item_label)
	for i in range(slots.size()):
		slots[i].mouse_entered.connect(show_item_info.bind(slots[i]))
		slots[i].mouse_exited.connect(hide_item_info)
		slots[i].slotType = SlotClass.SlotType.HOTBAR
		slots[i].slot_index = i
		PlayerInventory.active_item_updated.connect(slots[i].refresh_style)

	initialize_hotbar()
	# Принудительно обновляем стили слотов при запуске
	call_deferred("_refresh_all_slot_styles")

# Убрали _unhandled_input - вся логика ввода теперь обрабатывается в ui_manager.gd
# Это предотвращает конфликты и дублирование обработки событий

func _get_clicked_hotbar_slot() -> int:
	"""Возвращает индекс слота хотбара под курсором или -1 если не найден"""
	var mouse_pos = get_viewport().get_mouse_position()
	for i in range(slots.size()):
		if slots[i].get_global_rect().has_point(mouse_pos):
			return i
	return -1

func _on_slot_clicked(slot_index: int, event: InputEvent):
	"""Обработка кликов по слотам хотбара"""
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			select_slot(slot_index)

func initialize_hotbar():
	for i in range(slots.size()):
		if PlayerInventory.hotbar.has(i):
			slots[i].initialize_item(PlayerInventory.hotbar[i][0], PlayerInventory.hotbar[i][1])
	update_active_item_label()

func update_active_item_label():
	var active_slot_index = PlayerInventory.active_item_slot
	print("Hotbar: update_active_item_label вызван, активный слот: ", active_slot_index)
	if slots.size() > active_slot_index and slots[active_slot_index].item != null:
		var item_name = slots[active_slot_index].item.item_name
		if JsonData.item_data.has(item_name):
			var item_data = JsonData.item_data[item_name]
			active_item_label.text = item_data.get("display_name", item_name)
		else:
			active_item_label.text = item_name
	else:
		active_item_label.text = ""
	
	# Принудительно обновляем стили всех слотов
	_refresh_all_slot_styles()

func get_inventory_panel():
	var ui_manager = get_tree().root.find_child("UIManager", true, false)
	if ui_manager:
		return ui_manager.inventory
	return null

func show_item_info(slot: SlotClass):
	var inventory_panel = get_inventory_panel()
	if inventory_panel and inventory_panel.visible:
		inventory_panel.show_item_info(slot)

func hide_item_info():
	var inventory_panel = get_inventory_panel()
	if inventory_panel and inventory_panel.visible:
		inventory_panel.hide_item_info()

func get_active_slot() -> Node:
	var active_slot_index = PlayerInventory.active_item_slot
	if active_slot_index >= 0 and active_slot_index < slots.size():
		return slots[active_slot_index]
	return null

func select_slot(slot_index: int):
	print("Hotbar: select_slot вызван с индексом ", slot_index)
	PlayerInventory.set_active_item_slot(slot_index)

func scroll_left():
	print("Hotbar: scroll_left вызван")
	PlayerInventory.active_item_scroll_down()

func scroll_right():
	print("Hotbar: scroll_right вызван")
	PlayerInventory.active_item_scroll_up()

func get_active_item():
	var active_slot_index = PlayerInventory.active_item_slot
	if active_slot_index >= 0 and active_slot_index < slots.size():
		var slot = slots[active_slot_index]
		if slot and slot.item != null:
			return slot.item
	return null

func _refresh_all_slot_styles():
	"""Принудительно обновляет стили всех слотов"""
	for slot in slots:
		if slot.has_method("refresh_style"):
			slot.refresh_style()
