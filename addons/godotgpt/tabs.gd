@tool
extends TabContainer

var tab_puffer = 0
var settings: Dictionary = {}
var gpt_v: String = ""


func _on_tab_changed(tab):
	get_child(tab_puffer)._on_close()
	get_child(tab)._on_open()
	tab_puffer = tab
