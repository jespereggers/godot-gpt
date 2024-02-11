@tool
extends Label

var content: String
var role: String

func _ready():
	text = content
	
	if role == "assistant":
		$background.color.b = 0.5
	else:
		$background.color.b = 0.0
