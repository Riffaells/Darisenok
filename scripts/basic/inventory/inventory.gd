extends Node2D

const SlotClass = preload("res://scripts/basic/items/slot.gd")
@onready var grid_container = $GridContainer
@onready var equip_slots_container = $EquipSlots
@onready var item_name_label = $ItemInfoPanel/ItemNameLabel
@onready var item_description_label = $ItemInfoPanel/ItemDescriptionLabel
@onready var slots = grid_container.get_children()
@onready var equip_slots = equip_slots_container.get_children()

func _ready():
	for i in range(slots.size()):
		slots[i].mouse_entered.connect(show_item_info.bind(slots[i]))
		slots[i].mouse_exited.connect(hide_item_info)
		slots[i].slotType = SlotClass.SlotType.INVENTORY; slots[i].slot_index = i

	if equip_slots.size() >= 3:
		equip_slots[0].mouse_entered.connect(show_item_info.bind(equip_slots[0]))
		equip_slots[0].mouse_exited.connect(hide_item_info)
		equip_slots[0].slotType = SlotClass.SlotType.SHIRT; equip_slots[0].slot_index = 0
		equip_slots[1].mouse_entered.connect(show_item_info.bind(equip_slots[1]))
		equip_slots[1].mouse_exited.connect(hide_item_info)
		equip_slots[1].slotType = SlotClass.SlotType.PANTS; equip_slots[1].slot_index = 1
		equip_slots[2].mouse_entered.connect(show_item_info.bind(equip_slots[2]))
		equip_slots[2].mouse_exited.connect(hide_item_info)
		equip_slots[2].slotType = SlotClass.SlotType.SHOES; equip_slots[2].slot_index = 2

	initialize_inventory()
	hide_item_info()

func setup(player_inventory_ref):
	"""Метод для совместимости с ui_manager.gd. Инвентарь уже использует глобальный PlayerInventory."""
	# Этот метод нужен для совместимости, но фактически ничего не делает
	# так как inventory.gd уже работает с глобальным PlayerInventory
	pass

func initialize_inventory():
	for i in range(slots.size()):
		if PlayerInventory.inventory.has(i):
			slots[i].initialize_item(PlayerInventory.inventory[i][0], PlayerInventory.inventory[i][1])
	if equip_slots.size() >= 3:
		if PlayerInventory.equips.has(0): equip_slots[0].initialize_item(PlayerInventory.equips[0][0], PlayerInventory.equips[0][1])
		if PlayerInventory.equips.has(1): equip_slots[1].initialize_item(PlayerInventory.equips[1][0], PlayerInventory.equips[1][1])
		if PlayerInventory.equips.has(2): equip_slots[2].initialize_item(PlayerInventory.equips[2][0], PlayerInventory.equips[2][1])

func show_item_info(slot: SlotClass):
	if not slot.is_empty():
		item_name_label.text = slot.item.get_display_name()
		item_description_label.text = slot.item.get_description()
		item_name_label.modulate = slot.item.get_rarity_color()
	else:
		hide_item_info()

func hide_item_info():
	item_name_label.text = "Наведите на предмет"
	item_description_label.text = "Здесь будет отображаться информация о предмете"
