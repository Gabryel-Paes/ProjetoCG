class_name Inventory
extends Node

signal inventory_updated

@export var capacity: int = 9
var slots: Array = []

func _ready() -> void:
	slots.resize (capacity)
	slots.fill (null)
	
