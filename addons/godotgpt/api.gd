@tool
extends Node

var url: String = "https://api.openai.com/v1/chat/completions"
var temperature: float = 0.5
var max_completion_tokens: int = 1024
var chat_history = []
var request: HTTPRequest
var msg_memory_n = 8


func _ready():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", _on_request_completed)
	
	
func dialogue_request(player_dialogue, settings):
	if get_parent().get_parent().gpt_v == "":
		get_parent().get_parent().gpt_v = await get_gpt_v(settings["api-key"])
		
	var headers = ["Content-type: application/json", "Authorization: Bearer " + settings["api-key"]]
	
	var modified_chat_history = chat_history.duplicate()
	
	var context_message: Dictionary
	
	if EditorInterface.get_script_editor().get_open_scripts().is_empty():
		context_message = {
			"role": "user",
			"content": "I am writing GDScript in Godot Engine:\n"
			+ "Please keep you answers very short and precise. "
		}
	else:
		context_message = {
			"role": "user",
			"content": "Look at my currently opened GDScript written in Godot Engine:\n"
			+ EditorInterface.get_script_editor().get_current_script().source_code + "\n"
			+ "Please keep you answers very short and precise. "
		}
	
	if chat_history.size() > msg_memory_n:
		modified_chat_history.resize(msg_memory_n)
	
	modified_chat_history.append(context_message)
	
	chat_history.append({
		"role": "user",
		"content": player_dialogue
	})
	
	modified_chat_history.append({
		"role": "user",
		"content": player_dialogue
	})
	
	var body = JSON.new().stringify({
		"messages": modified_chat_history,
		"temperature": temperature,
		"max_completion_tokens": max_completion_tokens,
		"model": get_parent().get_parent().gpt_v
	})
	
	var send_request = request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if send_request != OK:
		get_parent()._on_request_completed("Sorry, there was an error sending your request.")
		print("There was an error!")


func _on_request_completed(result, response_code, headers, body):
	var message = ""
	
	if response_code != 200:
		if response_code == 429:
			message = "My key reached its usage limit."
		if response_code == 401:
			message = "My API key is invalid."
		else:
			message = "Something went wrong, maybe check settings? \nError: " + str(response_code)
	else:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		message = response["choices"][0]["message"]["content"]
		
	chat_history.append({
		"role": "assistant",
		"content": message
	})
	
	get_parent()._on_request_completed(message)


func get_gpt_v(api_key: String) -> String:
	var gpt_list = await get_available_models(api_key)
	if gpt_list:
		return gpt_list[max(0, gpt_list.size()-1)]
	else:
		return ""
	

func get_available_models(api_key: String) -> Array:
	var models_request := HTTPRequest.new()
	add_child(models_request)

	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var err := models_request.request(
		"https://api.openai.com/v1/models",
		headers,
		HTTPClient.METHOD_GET
	)

	if err != OK:
		models_request.queue_free()
		return []

	var result_data = await models_request.request_completed
	models_request.queue_free()

	var result = result_data[0]
	var response_code = result_data[1]
	var response_headers = result_data[2]
	var body = result_data[3]

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return []

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		return []

	var model_ids: Array = []
	for item in parsed["data"]:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			model_ids.append(item["id"])

	model_ids.sort()
	
	var filtered: Array = []

	var regex := RegEx.new()
	regex.compile("^gpt-[0-9]+(\\.[0-9]+)?$")

	for model in model_ids:
		var text := str(model)
		if regex.search(text):
			filtered.append(text)
			
	return filtered
