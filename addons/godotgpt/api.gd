@tool
extends Node

var api_key: String = "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"
var url: String = "https://api.openai.com/v1/chat/completions"
var temperature: float = 0.5
var max_tokens: int = 1024
var headers = ["Content-type: application/json", "Authorization: Bearer " + api_key]
var model: String = "gpt-3.5-turbo"
var messages = []
var request: HTTPRequest

func _ready():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", _on_request_completed)

func dialogue_request(player_dialogue):
	var prompt: String = "This is the currently opened script:\n"
	prompt += EditorInterface.get_script_editor().get_current_script().source_code + "\n"
	prompt += player_dialogue
	messages.append({
		"role": "user",
		"content": prompt
		})
		
	var body = JSON.new().stringify({
		"messages": messages,
		"temperature": temperature,
		"max_tokens": max_tokens,
		"model": model
	})
	
	var send_request = request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if send_request != OK:
		print("There was an error!")
		
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var message = response["choices"][0]["message"]["content"]
	
	get_parent()._on_request_completed(message)
