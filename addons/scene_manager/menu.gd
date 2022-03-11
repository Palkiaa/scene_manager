tool
extends Control

const PATH: String = "res://scenes.json"
const ROOT_ADDRESS = "res://"
var id: int = 1
var normal_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_normal.tres")
var duplicate_line_edit: StyleBox = load("res://addons/scene_manager/themes/line_edit_duplicate.tres")

func absolute_current_working_directory() -> String:
	return ProjectSettings.globalize_path(Directory.new().get_current_dir())

func merge_dict(dest: Dictionary, source: Dictionary) -> void:
	for key in source:
		if dest.has(key):
			var dest_value = dest[key]
			var source_value = source[key]
			if typeof(dest_value) == TYPE_DICTIONARY:       
				if typeof(source_value) == TYPE_DICTIONARY: 
					merge_dict(dest_value, source_value)  
				else:
					dest[key] = source_value
			else:
				dest[key] = source_value
		else:
			dest[key] = source[key]

func get_scenes(root_path: String) -> Dictionary:
	var files: Dictionary = {}
	var folders: Array = []
	var dir = Directory.new()
	if dir.open(root_path) == OK:
		dir.list_dir_begin(true, true)

		while true:
			var file_folder = dir.get_next()
			if file_folder == "":
				break
			elif dir.current_is_dir():
				folders.append(file_folder)
			elif file_folder.get_extension() == "tscn":
				files[file_folder.replace("."+file_folder.get_extension(), "")] = root_path + file_folder

		dir.list_dir_end()

		for folder in folders:
			var new_files: Dictionary = get_scenes(root_path + folder + "/")
			if len(new_files) != 0:
				merge_dict(files, new_files)
	else:
		print("Couln't open ", root_path)

	return files

func clear_scenes() -> void:
	id = 1
	while get_child_count() > 1:
		get_child(1).remove_and_skip()

func add_item(key: String, value: String) -> void:
	var item = preload("res://addons/scene_manager/item.tscn").instance()
	item.set_id(String(id))
	item.set_key(key)
	item.set_value(value)
	add_child(item)
	id += 1

func _on_refresh_button_up() -> void:
	clear_scenes()
	var data: Dictionary = load_scenes(PATH)
	var scenes: Dictionary = get_scenes(ROOT_ADDRESS)
	var scenes_values: Array = scenes.values()
	for key in data:
		if !(data[key] in scenes_values):
			continue
		add_item(key, data[key])

	var data_values: Array = []
	if data:
		data_values = data.values()
	for key in scenes:
		if !(scenes[key] in data_values):
			add_item(key, scenes[key])
	check_if_saved_values_are_same_with_view()

func _ready() -> void:
	_on_refresh_button_up()

func save_scenes(address: String, data: Dictionary) -> void:
	var file = File.new()
	file.open(address, File.WRITE)
	file.store_var(to_json(data))
	file.close()

func load_scenes(address: String) -> Dictionary:
	var data: Dictionary = {}

	if file_exists(address):
		var file = File.new()
		file.open(address, File.READ)
		data = parse_json(file.get_var())
		file.close()

	return data

func file_exists(address: String) -> bool:
	return Directory.new().file_exists(address)

func get_scenes_from_view() -> Dictionary:
	var data: Dictionary = {}
	for i in range(get_child_count()):
		if i == 0: continue
		var node: Node = get_child(i)
		data[node.get_key()] = node.get_value()

	return data

func get_scene_nodes_from_view(except: Node = null) -> Array:
	var nodes: Array = []
	for i in range(get_child_count()):
		if i == 0: continue
		var node: Node = get_child(i)
		if node != except:
			nodes.append(node)

	return nodes

func get_duplications(new_key: String, except: Node) -> Node:
	for node in get_scene_nodes_from_view(except):
		if node.get_key() == new_key:
			return node

	return null

func check_if_saved_values_are_same_with_view():
	var save_button: Button = get_parent().get_parent().get_node("MarginContainer/VBoxContainer/HBoxContainer/save")
	var loaded_scenes = load_scenes(PATH)
	var view_scenes = get_scenes_from_view()
	if len(loaded_scenes) != len(view_scenes):
		save_button.disabled = false
		return
	for key in view_scenes:
		if !loaded_scenes.has(key) || loaded_scenes[key] != view_scenes[key]:
			save_button.disabled = false
			return
	save_button.disabled = true

func all_nodes_to_default_theme():
	for node in get_scene_nodes_from_view():
		node = node.get_key_node()
		node.add_stylebox_override("normal", normal_line_edit)
		node.add_stylebox_override("focus", normal_line_edit)

func _on_save_button_up():
	save_scenes(PATH, get_scenes_from_view())
	var save_button: Button = get_parent().get_parent().get_node("MarginContainer/VBoxContainer/HBoxContainer/save")
	save_button.disabled = true
