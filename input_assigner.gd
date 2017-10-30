tool
extends Container

export var action_description = "" setget set_action_description, get_action_description
export var action = "" setget set_action, get_action
var default = []

signal reassigned

func set_action_description(value):
	if action_description != value:
		action_description = value
		
	if not get_children().empty():
		get_node("HBoxContainer/LabelDescription").set_text(action_description)
		get_node("WindowDialog").set_title(action_description)

func get_action_description():
	return action_description

func set_action(value):
	if action != value:
		action = value
		if not get_children().empty():
			update_input_label()

func get_action():
	return action

func _ready():
	if action_description.empty():
		if action.begins_with("ui_"):
			action_description = "menu %s" % action.substr(3, 9999)
		else:
			action_description = action
	
	get_node("HBoxContainer/LabelDescription").set_text(action_description)
	get_node("WindowDialog").set_title(action_description)
	update_input_label()
	
	get_node("HBoxContainer/ButtonReassign").connect("pressed", self, "reassign")
	get_node("WindowDialog/ButtonAssign").connect("pressed", self, "assign")
	get_node("WindowDialog/ButtonDefault").connect("pressed", self, "assign_default")
	get_node("WindowDialog/ButtonClear").connect("pressed", self, "clear")
	
	#var crap = InputEvent()
	#crap.type = InputEvent.KEY
	#crap.scancode = KEY_Z
	#default.append(crap)

func update_input_label():
	var input_text = ""
	for e in InputMap.get_action_list(action):
		if input_text.length() > 0:
			input_text = "%s, " % input_text
		
		input_text = "%s %s" % [input_text, user_string_for_event(e)]
	
	get_node("HBoxContainer/ButtonReassign").set_text(input_text)
	get_node("WindowDialog/Label").set_text(input_text)

func reassign():
	get_node("WindowDialog").popup_centered()
	get_node("WindowDialog/ButtonAssign").grab_focus()
	
func assign():
	set_process_input(true)
	get_node("WindowDialog/Label").set_text("%s, press any key or button..." % get_node("WindowDialog/Label").get_text())
	# Prevent calling assign a second time when remapping ui_select or ui_accept
	get_node("WindowDialog/ButtonAssign").release_focus()

func clear():
	for event in InputMap.get_action_list(action):
		InputMap.action_erase_event(action, event)
	
	update_input_label()

func assign_default():
	clear()
	
	for event in default:
		InputMap.action_add_event(action, event)
	
	update_input_label()

func _input(event):
	if (event.type in [InputEvent.KEY, InputEvent.JOYSTICK_BUTTON, InputEvent.JOYSTICK_MOTION, InputEvent.MOUSE_BUTTON]
			and event.is_pressed()):
		set_process_input(false)
		get_tree().set_input_as_handled()
		InputMap.action_add_event(action, event)
		update_input_label()
		emit_signal("reassigned")

static func user_string_for_event(event):
	if event.type == InputEvent.KEY:
		# TODO ctrl shift modifiers?
		return OS.get_scancode_string(event.scancode)
	elif event.type == InputEvent.MOUSE_BUTTON:
		return "mouse button %d" % event.button_index
	elif event.type == InputEvent.JOYSTICK_BUTTON:
		return "joy %s button %d" % [event.device, event.button_index]
	elif event.type == InputEvent.JOYSTICK_MOTION:
		return "joy %s axis %d%s" % [event.device, event.axis, "-" if event.value < 0.0 else "+"]
	
	return "unknown input"