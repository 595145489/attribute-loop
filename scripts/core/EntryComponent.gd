class_name EntryComponent
extends Resource

enum SlotType { TRIGGER, VERB, EFFECT }

@export var slot_type: SlotType
@export var label: String
@export var description: String
@export var data: Dictionary = {}
