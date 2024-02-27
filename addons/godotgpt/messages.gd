@tool
extends VBoxContainer

@onready var box_template = preload("res://addons/godotgpt/message.tscn")

func add_message(content: String, role: String):
	var box = box_template.instantiate()
	box.content = content
	box.role = role
	add_child(box)
