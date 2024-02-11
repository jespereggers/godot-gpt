@tool
extends Control


func send_message():
	$interface/interactions/send.disabled = $interface/interactions/input.text.is_empty()
	$api.dialogue_request($interface/interactions/input.text)
	$interface/scroller/chat.add_message($interface/interactions/input.text, "user")
	$interface/interactions/input.text = ""


func receive_message(response: String):
	$interface/scroller/chat.add_message(response, "assistant")
	$interface/interactions/send.disabled = $interface/interactions/input.text.is_empty()


func _on_send_pressed():
	send_message()


func _on_input_text_changed(new_text):
	$interface/interactions/send.disabled = $interface/interactions/input.text.is_empty()


func _on_input_text_submitted(new_text):
	send_message()


func _on_request_completed(response: String):
	receive_message(response)
