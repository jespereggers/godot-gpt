@tool
extends Node


func get_script() -> String:
	var script = EditorInterface.get_script_editor().get_current_script().source_code
	return script 


func replace_line(arg) -> String:
	var json = JSON.new()
	var error = json.parse(arg)
	
	if error != OK:
		return "An error occurred, could not implement changes."
	
	var data = json.get_data()
		
	var res_path: String = EditorInterface.get_script_editor().get_current_script().resource_path
	var code = EditorInterface.get_script_editor().get_current_script().source_code
	var lines = code.split("\n")
	
	var line_number = int(data["line_number"] + 1)
	
	if EditorInterface.get_script_editor().get_current_script().is_tool():
		line_number += 1
	
	if line_number < 0 or line_number >= lines.size():
		return "Line is not reachable"
	
	var indent_count = lines[line_number].split("\t").size() - 1
	lines[line_number] = ""
	
	for i in indent_count:
		lines[line_number] += "\t"
	lines[line_number] += data["new_code"]
	
	var new_code = "\n".join(lines)

	var file = FileAccess.open(res_path, FileAccess.WRITE)
	file.store_string(new_code)
	file.close()
	
	EditorInterface.get_resource_filesystem().scan()
	
	var compilation_result = check_compilability(res_path)
	if compilation_result != "success":
		return compilation_result
	
	return "success"


func check_compilability(script_path: String) -> String:
	var script = load(script_path)
	if script == null:
		return "Error: Could not load the script."
	
	var err = script.reload()
	if err != OK:
		return "Error: The script contains syntax errors."
	
	var instance = script.new()
	if instance == null:
		return "Error: The script could not be instantiated."
	
	return "success"
