@tool
extends RichTextLabel

var content: String
var role: String

func _ready():
	text = content
	
	if role == "user":
		self.modulate.a = 0.5
	else:
		self.modulate.a = 1.0
		
