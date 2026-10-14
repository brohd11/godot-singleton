#! namespace Singletons class CheckInstance

const DEFAULT_PATH = "EditorNode<t>/EditorSingletons"

static func check_valid(singleton_name:String, path:=DEFAULT_PATH) -> bool:
	var node:Variant = get_instance(singleton_name, path)
	return is_instance_valid(node)

static func call_on_ready(singleton_name:String, callable:Callable, path:=DEFAULT_PATH):
	var node:Variant = get_instance(singleton_name, path)
	if is_instance_valid(node):
		node.call_on_ready(callable)
	else:
		callable.call()

static func get_instance(singleton_name:String, path:=DEFAULT_PATH) -> Variant:
	var root = Engine.get_main_loop().root
	var full_path:String = ""
	if path == DEFAULT_PATH:
		var ed_node:Node = _get_node_of_type(root, "EditorNode")
		if not is_instance_valid(ed_node):
			printerr("Singletons - Could not get EditorNode")
			return null
		full_path = ed_node.name.path_join("EditorSingletons").path_join(singleton_name)
	else:
		full_path = path.path_join(singleton_name)
	return root.get_node_or_null(full_path)

static func _get_node_of_type(node:Node, type:String) -> Variant:
	type = type.trim_suffix("<t>")
	for c in node.get_children():
		if c.get_class() == type:
			return c
	return null
