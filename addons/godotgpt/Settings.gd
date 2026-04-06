@tool
extends TabBar

var template = {
	"api-key": "",
	"settings-version": "1.2"
}
var settings_version = "1.2"


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
		
	update_gpt_v()


func serialize():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(get_parent().settings))


func update_ui():
	$SettingsList/APIKey/LineEdit.text = get_parent().settings["api-key"]
	var gpt_v_status = await get_parent().get_node("Chat/ChatGPT").get_gpt_v(get_parent().settings["api-key"])
	
	#if gpt_v_status:
	#	get_parent().gpt_v = gpt_v_status
	#	$SettingsList/GPTVersion/Label.text = "Running via " + get_parent().gpt_v
	#else:
#		$SettingsList/GPTVersion/Label.text = ""


func update_local_settings_var():
	get_parent().settings["api-key"] = $SettingsList/APIKey/LineEdit.text


func _on_open():
	deserialize()
	update_ui()


func _on_close():
	update_local_settings_var()
	serialize()


func update_gpt_v():
	var gpt_v_status = await get_parent().get_node("Chat/ChatGPT").get_gpt_v(get_parent().settings["api-key"])
	if gpt_v_status:
		get_parent().gpt_v = gpt_v_status
		$SettingsList/GPTVersion/Label.text = "Running via " + get_parent().gpt_v.to_upper()
	else:
		$SettingsList/GPTVersion/Label.text = ""
		

func _on_line_edit_text_submitted(new_text):
	update_local_settings_var()
	update_gpt_v()
