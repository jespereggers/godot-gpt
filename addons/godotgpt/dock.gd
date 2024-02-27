@tool
extends Control


func _ready():
	$Tabs/Settings.deserialize()
