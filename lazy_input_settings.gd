tool
extends EditorPlugin

func get_name(): 
	return "LazyInputSettings"

func _init():
    pass

func _enter_tree():
	add_custom_type("InputMenu", "VBoxContainer", preload("input_menu.gd"), null)

func _exit_tree():
	remove_custom_type("InputMenu")