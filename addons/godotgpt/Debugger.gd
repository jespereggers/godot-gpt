@tool
extends Node

var key: String = ""
var version: String = "gpt-4o"

var assist_url: String = "https://api.openai.com/v1/assistants"
var threads_url: String = "https://api.openai.com/v1/threads"
var messages_url: String
var run_url: String
var run_steps_url: String
var tool_outputs_url: String

var request: HTTPRequest
var temperature: float = 0.5
var max_tokens: int = 1024

var chat_history: Array = []
var displayed_created_at: Array = []

var assist_id: String = ""
var thread_id: String = ""

var request_count: int = 0
var displayed_msg_count: int = 0

var processing_func_call: bool = false


func _ready():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", _on_request_completed)
	
	create_assistant()


func add_post_req(url, header, method, body):
	var req_node = HTTPRequest.new()
	add_child(req_node)
	req_node.connect("request_completed", _on_request_completed)
	request_count += 1
	req_node.request(url, header, method, body)


func add_get_req(url, header, method, body: String = ""):
	var req_node = HTTPRequest.new()
	add_child(req_node)
	req_node.connect("request_completed", _on_request_completed)
	req_node.request(url, header, method, body)


func get_run_steps():
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	add_get_req(run_steps_url, header, HTTPClient.METHOD_GET)


func create_assistant():
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	var body = JSON.new().stringify({
		"instructions": "You are an expert in gdscript. use the get_script tool if you need
		insights and replace_line to replace a line in code, for example to fix a bug.",
		"name": "GodotGPT",
		"tools": [
			{
				"type": "function",
				"function": {
					"description": "Get the currently opened GDScript file.",
					"name": "get_script"
					}
			},
			{
				"type": "function",
				"function": {
					"description": "Replace a line with new code.",
					"name": "replace_line",
					"parameters": {
						"type": "object",
						"properties": {
							"new_code": {
								"type": "string",
								"description": "The code to replace a line with."
							},
							"line_number": {
								"type": "integer",
								"description": "Line number to replace with new code."
							}
						},
						"required": ["new_code", "line_number"]
					}
				}
			},
			{
				"type": "function",
				"function": {
					"description": "Replace a line with new code.",
					"name": "check_compilability",
					"parameters": {
						"type": "object",
						"properties": {
							"proposed_code": {
								"type": "string",
								"description": "The fixed code."
							}
						},
						"required": ["proposed_code"]
					}
				}
			}],
		"model": version
	})
	
	add_post_req(assist_url, header, HTTPClient.METHOD_POST, body)


func create_thread():
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	add_post_req(threads_url, header, HTTPClient.METHOD_POST, "")


func add_message(role, message):
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	var body = JSON.new().stringify({
		"role": role,
		"content": message
	})
	
	add_post_req(messages_url, header, HTTPClient.METHOD_POST, body)


func get_messages():
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	add_get_req(messages_url, header, HTTPClient.METHOD_GET, "")
	

func run(prompt: String):
	add_message("user", prompt)
	
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	var body = JSON.new().stringify({
		"assistant_id": assist_id,
		"instructions": "Keep your answers precise and very short."
	})
	
	add_post_req(run_url, header, HTTPClient.METHOD_POST, body)


func send_func_output(tool_calls: Array):
	if tool_calls == []:
		get_run_steps()
		return
		
	var outputs: Array
	
	for call in tool_calls:
		if call["type"] == "function":
			if $AssistTools.has_method(call["function"]["name"]):
				var arg = call["function"]["arguments"]
				var call_response
				
				if arg == "{}":
					call_response = $AssistTools.call(call["function"]["name"])
				else:
					call_response = $AssistTools.call(call["function"]["name"], call["function"]["arguments"])
				
				outputs.append({"tool_call_id": call["id"], "output": call_response})
	
	var header = [
	"Content-type: application/json",
	"Authorization: Bearer " + key,
	"OpenAI-Beta: assistants=v2"
	]
	
	var body = JSON.new().stringify({
		"tool_outputs": outputs
	})
	
	add_post_req(tool_outputs_url, header, HTTPClient.METHOD_POST, body)
	

func _on_request_completed(result, response_code, headers, body):
	print(".")

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response_code != 200:
		print("ERROR")
		print(response)
		get_parent()._on_request_completed("Something went wrong, maybe check settings? \nError: " + str(response_code))
		return
	
	match response["object"]:
		"assistant":
			assist_id = response["id"]
			
		"thread":
			thread_id = response["id"]
			messages_url = threads_url + "/" + thread_id + "/messages"
			run_url = threads_url + "/" + thread_id + "/runs"

		"thread.message":
			pass
			
		"thread.run":
			run_steps_url = run_url + "/" + response["id"] + "/steps"
			tool_outputs_url = run_url + "/" + response["id"] + "/submit_tool_outputs"
			$Timer.start()
			
		"list":
			if not response["data"].is_empty():
				match response["data"][0]["object"]:
					"thread.run.step":
						if response["data"][0]["status"] == "completed":
							$Timer.stop()
							
						match response["data"][0]["step_details"]["type"]:
							"tool_calls":
								send_func_output(response["data"][0]["step_details"]["tool_calls"])
							"message_creation":
								get_messages()
								
					"thread.message":
						if response["data"].size() > 0 and response["data"][0]["content"].size() > 0:
							if response["data"][0]["role"] == "assistant" and not response["data"][0]["created_at"] in displayed_created_at:
								displayed_created_at.append(response["data"][0]["created_at"])
								get_parent()._on_request_completed(response["data"][0]["content"][0]["text"]["value"])
	if request_count == 1:
		create_thread()


func _on_timer_timeout():
	get_messages()
	
	if run_steps_url != "":
		get_run_steps()
