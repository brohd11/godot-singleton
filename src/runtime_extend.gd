#! namespace Singletons class RuntimeExtend
## Extends a singleton module's base without naming its global. `extends` resolves at
## parse time, so the source's extends line is a placeholder, swapped in place (line
## numbers survive) for the live base's path. The body must not name that package's
## globals or override _init (the base's _init logic gets skipped), and it does not
## hot reload. Mark the file `#! pe-skip-parse` so exports copy it untouched.

const CheckInstance = preload("res://addons/_lib/singleton/src/check_instance.gd")

## Null when that singleton is not running or has no such const.
static func build_from_singleton(source_path:String, singleton_name:String, base_const:String, singleton_path:=CheckInstance.DEFAULT_PATH) -> GDScript:
	var base = get_singleton_const(singleton_name, base_const, singleton_path)
	if base == null:
		return null
	return build(source_path, base)

## Read off the live instance's script, so a versioned or relocated module still
## hands back its own base.
static func get_singleton_const(singleton_name:String, const_name:String, singleton_path:=CheckInstance.DEFAULT_PATH) -> Variant:
	var singleton = CheckInstance.get_instance(singleton_name, singleton_path)
	if not is_instance_valid(singleton):
		return null
	return singleton.get_script().get_script_constant_map().get(const_name)

static func build(source_path:String, base:Script) -> GDScript:
	if base == null or base.resource_path.is_empty():
		printerr("RuntimeExtend - no base script with a path for: %s" % source_path)
		return null
	var source = FileAccess.get_file_as_string(source_path)
	if source.is_empty():
		printerr("RuntimeExtend - could not read: %s" % source_path)
		return null

	var regex = RegEx.create_from_string("(?m)^extends\\s.*$")
	var found = regex.search(source)
	if found == null:
		printerr("RuntimeExtend - no extends line in: %s" % source_path)
		return null
	var line = 'extends "%s"' % base.resource_path
	source = source.substr(0, found.get_start()) + line + source.substr(found.get_end())

	var script = GDScript.new()
	script.source_code = source
	# Errors then name the real file. Unlike assigning resource_path this skips the
	# resource cache, so load() still returns the file and a loaded original can't clash.
	script.set_path_cache(source_path)
	var err = script.reload()
	if err != OK:
		printerr("RuntimeExtend - failed to compile %s (%s)" % [source_path, error_string(err)])
		return null
	return script
