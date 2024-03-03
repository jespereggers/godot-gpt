@tool
extends Node

var url: String = "https://api.openai.com/v1/chat/completions"
var temperature: float = 0.5
var max_tokens: int = 1024
var chat_history = []
var request: HTTPRequest


func _ready():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", _on_request_completed)


func dialogue_request(player_dialogue, settings):
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
	
	if chat_history.size() > 4:
		modified_chat_history.resize(4)
	
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
		"max_tokens": max_tokens,
		"model": settings["gpt-version"]
	})
	
	var send_request = request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if send_request != OK:
		get_parent()._on_request_completed("Sorry, there was an error sending your request.")
		print("There was an error!")


func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		get_parent()._on_request_completed("Something went wrong, maybe check settings? \nError: " + str(response_code))
		return
		
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var message = response["choices"][0]["message"]["content"]
	
	chat_history.append({
		"role": "assistant",
		"content": message
	})
	
	get_parent()._on_request_completed(message)
