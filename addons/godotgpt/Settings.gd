@tool
extends TabBar

var template = {
	"api-key": "",
	"gpt-version": "gpt-3.5-turbo",
	"settings-version": "1.0"
}
var gpt_versions = ["gpt-3.5-turbo", "gpt-4"]
var settings_version = "1.0"


func deserialize():
	if FileAccess.file_exists("user://settings.json"):
		var json_as_text = FileAccess.get_file_as_string("user://settings.json")
		var json_as_dict = JSON.parse_string(json_as_text)
		
		if json_as_dict["settings-version"] == settings_version:
			get_parent().settings = json_as_dict
		else:
			get_parent().settings = template
	else:
		get_parent().settings = template


func serialize():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(get_parent().settings))


func update_ui():
	$SettingsList/APIKey/LineEdit.text = get_parent().settings["api-key"]
	$SettingsList/GPTVersion/Button.selected = gpt_versions.find(get_parent().settings["gpt-version"])


func update_local_settings_var():
	get_parent().settings["api-key"] = $SettingsList/APIKey/LineEdit.text
	get_parent().settings["gpt-version"] = gpt_versions[$SettingsList/GPTVersion/Button.selected]


func _on_open():
	deserialize()
	update_ui()


func _on_close():
	update_local_settings_var()
	serialize()
