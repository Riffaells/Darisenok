extends Node

signal active_item_updated

const SlotClass = preload("res://scripts/basic/items/slot.gd")
const ItemClass = preload("res://scenes/player/inventory/item.tscn")
const NUM_INVENTORY_SLOTS = 20
const NUM_HOTBAR_SLOTS = 9

var active_item_slot = 0

var inventory = {
	0: ["Frying Pan", 1],
	1: ["Energy Bar", 10],
}

var hotbar = {
	0: ["Frying Pan", 1],
	1: ["Energy Bar", 10],
}

var equips = {}

func set_active_item_slot(new_slot_index: int):
	print("set_active_item_slot called with index: ", new_slot_index)
	if new_slot_index >= 0 and new_slot_index < NUM_HOTBAR_SLOTS:
		active_item_slot = new_slot_index
		active_item_updated.emit()
		print("Active slot set to: ", active_item_slot, " and signal emitted")
	else:
		print("Invalid slot index: ", new_slot_index, " (valid range: 0-", NUM_HOTBAR_SLOTS-1, ")")

# TODO: First try to add to hotbar
func add_item(item_name, item_quantity):
	var slot_indices: Array = inventory.keys()
	slot_indices.sort()
	for item in slot_indices:
		if inventory[item][0] == item_name:
			var stack_size = int(JsonData.item_data[item_name]["StackSize"])
			var able_to_add = stack_size - inventory[item][1]
			if able_to_add >= item_quantity:
				inventory[item][1] += item_quantity
				update_slot_visual(item, inventory[item][0], inventory[item][1])
				return
			else:
				inventory[item][1] += able_to_add
				update_slot_visual(item, inventory[item][0], inventory[item][1])
				item_quantity = item_quantity - able_to_add

	# item doesn't exist in inventory yet, so add it to an empty slot
	for i in range(NUM_INVENTORY_SLOTS):
		if inventory.has(i) == false:
			inventory[i] = [item_name, item_quantity]
			update_slot_visual(i, inventory[i][0], inventory[i][1])
			return

# TODO: Make compatible with hotbar as well
# This function needs to be rewritten to get the node correctly.
# I will assume a scene structure for now.
func update_slot_visual(slot_index, item_name, new_quantity):
	# Попытаемся найти UIManager в дереве сцен
	var ui_manager = get_tree().root.find_child("UIManager", true, false)
	if not ui_manager:
		print("PlayerInventory: UIManager не найден в дереве сцен")
		return
	
	# Ищем инвентарь
	var inventory_node = ui_manager.get_node_or_null("Inventory")
	if not inventory_node:
		print("PlayerInventory: Inventory не найден в UIManager")
		return
	
	# Ищем GridContainer
	var grid_container = inventory_node.get_node_or_null("GridContainer")
	if not grid_container:
		print("PlayerInventory: GridContainer не найден в Inventory")
		return
	
	# Получаем слот по индексу
	var slots = grid_container.get_children()
	if slot_index >= 0 and slot_index < slots.size():
		var slot = slots[slot_index]
		if slot.item != null:
			slot.item.set_item(item_name, new_quantity)
		else:
			slot.initialize_item(item_name, new_quantity)
	else:
		print("PlayerInventory: Неверный индекс слота: ", slot_index)

func remove_item(slot: SlotClass):
	match slot.slotType:
		SlotClass.SlotType.HOTBAR:
			hotbar.erase(slot.slot_index)
		SlotClass.SlotType.INVENTORY:
			inventory.erase(slot.slot_index)
		_:
			equips.erase(slot.slot_index)

func add_item_to_empty_slot(item: Node, slot: SlotClass):
	match slot.slotType:
		SlotClass.SlotType.HOTBAR:
			hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
		SlotClass.SlotType.INVENTORY:
			inventory[slot.slot_index] = [item.item_name, item.item_quantity]
		_:
			equips[slot.slot_index] = [item.item_name, item.item_quantity]

func add_item_quantity(slot: SlotClass, quantity_to_add: int):
	match slot.slotType:
		SlotClass.SlotType.HOTBAR:
			hotbar[slot.slot_index][1] += quantity_to_add
		SlotClass.SlotType.INVENTORY:
			inventory[slot.slot_index][1] += quantity_to_add
		_:
			equips[slot.slot_index][1] += quantity_to_add

func update_item_quantity(slot: SlotClass, new_quantity: int):
	if new_quantity <= 0:
		remove_item(slot)
		return

	match slot.slotType:
		SlotClass.SlotType.HOTBAR:
			if hotbar.has(slot.slot_index):
				hotbar[slot.slot_index][1] = new_quantity
		SlotClass.SlotType.INVENTORY:
			if inventory.has(slot.slot_index):
				inventory[slot.slot_index][1] = new_quantity
		_:
			if equips.has(slot.slot_index):
				equips[slot.slot_index][1] = new_quantity

func swap_items(slot1: SlotClass, slot2: SlotClass):
	print("🔄 Перемещение предметов между слотами")
	print("   Слот 1: ", slot1.slotType, " индекс ", slot1.slot_index)
	print("   Слот 2: ", slot2.slotType, " индекс ", slot2.slot_index)
	
	# Получаем данные из словарей ДО изменения слотов
	var data1 = get_item_data_from_slot(slot1)
	var data2 = get_item_data_from_slot(slot2)
	
	print("   Данные слота 1: ", data1)
	print("   Данные слота 2: ", data2)
	
	# Сначала очищаем оба слота в словарях
	remove_item(slot1)
	remove_item(slot2)
	
	# Получаем предметы из UI слотов
	var item1 = slot1.pickFromSlot()
	var item2 = slot2.pickFromSlot()
	
	# Устанавливаем новые данные в словари
	if data1.size() > 0:
		set_item_data_for_slot(slot2, data1)
	if data2.size() > 0:
		set_item_data_for_slot(slot1, data2)
	
	# Размещаем предметы в новых слотах UI
	if item1:
		slot2.putIntoSlot(item1)
	if item2:
		slot1.putIntoSlot(item2)
	
	print("✅ Перемещение завершено")

func get_item_data_from_slot(slot: SlotClass) -> Array:
	match slot.slotType:
		SlotClass.SlotType.HOTBAR: return hotbar.get(slot.slot_index, [])
		SlotClass.SlotType.INVENTORY: return inventory.get(slot.slot_index, [])
		_: return equips.get(slot.slot_index, [])

func set_item_data_for_slot(slot: SlotClass, data: Array):
	if data.is_empty(): return
	match slot.slotType:
		SlotClass.SlotType.HOTBAR: hotbar[slot.slot_index] = data
		SlotClass.SlotType.INVENTORY: inventory[slot.slot_index] = data
		_: equips[slot.slot_index] = data

###
### Hotbar Related Functions
func active_item_scroll_up() -> void:
	var new_slot = (active_item_slot + 1) % NUM_HOTBAR_SLOTS
	set_active_item_slot(new_slot)

func active_item_scroll_down() -> void:
	var new_slot = active_item_slot - 1
	if new_slot < 0:
		new_slot = NUM_HOTBAR_SLOTS - 1
	set_active_item_slot(new_slot)
