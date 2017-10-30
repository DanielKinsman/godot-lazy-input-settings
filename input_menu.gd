tool
extends VBoxContainer

const InputAssigner = preload("input_assigner.tscn")

export var input_map_save_location = "user://input_map.json"
export var default_input_map = "res://default_input_map.json"

var assigners = {}

func _ready():
	for action in InputMap.get_actions():
		var assigner = InputAssigner.instance()
		assigner.action = action
		assigner.connect("reassigned", self, "_save_input_map_to_file")
		add_child(assigner)
		assigners[action] = assigner
	
	load_defaults()

func update():
	for child in assigners.values():
		child.update_input_label()

func load_defaults():
	var f = File.new()
	if not f.file_exists(default_input_map):
		return
	
	f.open(default_input_map, File.READ)
	var json_input_map = f.get_as_text()
	f.close()
	
	var dict_map = {}
	dict_map.parse_json(json_input_map)
	
	for action in dict_map["actions"].keys():
		var default = []
		for event_dict in dict_map["actions"][action]:
			default.append(deserialize_event(event_dict))
		
		assigners[action].default = default

func _save_input_map_to_file():
	if input_map_save_location.length() > 0:
		save_input_map_to_file(input_map_save_location)

static func save_input_map():
	var dict_map = {"actions": {}}
	for action in InputMap.get_actions():
		dict_map["actions"][action] = []
		for event in InputMap.get_action_list(action):
			dict_map["actions"][action].append(serialize_event(event))
	
	return dict_map.to_json()
	
static func save_input_map_to_file(path="user://input_map.json"):
	var f = File.new()
	f.open(path, File.WRITE)
	f.store_string(save_input_map())
	f.close()

static func load_input_map(json_input_map):
	var dict_map = {}
	dict_map.parse_json(json_input_map)
	
	for action in InputMap.get_actions():
		for event in InputMap.get_action_list(action):
			InputMap.action_erase_event(action, event)
	
	for action in dict_map["actions"].keys():
		for event_dict in dict_map["actions"][action]:
			var event = deserialize_event(event_dict)
			InputMap.action_add_event(action, event)

static func load_input_map_from_file(path="user://input_map.json"):
	var f = File.new()
	if not f.file_exists(path):
		return

	f.open(path, File.READ)
	load_input_map(f.get_as_text())
	f.close()

static func serialize_event(event):
	var serialized = {"type": event.type, "device": event.device}
	if event.type == InputEvent.KEY:
		serialized["scancode"] = event.scancode
	elif event.type in [InputEvent.JOYSTICK_BUTTON, InputEvent.MOUSE_BUTTON]:
		serialized["button_index"] = event.button_index
	elif event.type == InputEvent.JOYSTICK_MOTION:
		serialized["axis"] = event.axis
		serialized["value"] = event.value
	
	return serialized

static func deserialize_event(event_dict):
	var event = InputEvent()
	event.type = int(event_dict["type"])
	event.device = int(event_dict["device"])
	
	if event.type == InputEvent.KEY:
		event.scancode = int(event_dict["scancode"])
	elif event.type in [InputEvent.JOYSTICK_BUTTON, InputEvent.MOUSE_BUTTON]:
		event.button_index = int(event_dict["button_index"])
	elif event.type == InputEvent.JOYSTICK_MOTION:
		event.axis = int(event_dict["axis"])
		event.value = event_dict["value"]
	
	return event