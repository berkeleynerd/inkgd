# ############################################################################ #
# Copyright © 2015-2021 inkle Ltd.
# Copyright © 2019-2022 Frédéric Maquin <fred@ephread.com>
# All Rights Reserved
#
# This file is part of inkgd.
# inkgd is licensed under the terms of the MIT license.
# ############################################################################ #

extends InkObject

class_name InkContainer

# ############################################################################ #

# String
var name = null

# Array<InkObject>
var content: Array: get = get_content, set = set_content
func get_content() -> Array:
	return _content
func set_content(value: Array):
	add_content(value)

# Array<InkObject>
var _content: Array

# Dictionary<string, INamedContent>
var named_content: Dictionary

# Dictionary<string, InkObject>?
var named_only_content : get = get_named_only_content, set = set_named_only_content
func get_named_only_content():
	var named_only_content_dict = {} # Dictionary<string, InkObject>
	for key in named_content:
		named_only_content_dict[key] = named_content[key]

	for c in content:
		var named = InkUtils.as_INamedContent_or_null(c)
		if named != null && named.has_valid_name:
			named_only_content_dict.erase(named.name)

	if named_only_content_dict.size() == 0:
		named_only_content_dict = null

	return named_only_content_dict
func set_named_only_content(value):
	var existing_named_only = named_only_content
	if existing_named_only != null:
		for key in existing_named_only:
			named_content.erase(key)

	if value == null:
		return

	for key in value:
		var named = InkUtils.as_INamedContent_or_null(value[key])
		if named != null:
			add_to_named_content_only(named)


var visits_should_be_counted: bool = false
var turn_index_should_be_counted: bool = false
var counting_at_start_only: bool = false

enum CountFlags {
	VISITS = 1,
	TURNS = 2,
	COUNT_START_ONLY = 4
}

# CountFlags
var count_flags: int: get = get_count_flags, set = set_count_flags
func get_count_flags() -> int:
	var flags = 0

	if visits_should_be_counted:     flags |= CountFlags.VISITS
	if turn_index_should_be_counted: flags |= CountFlags.TURNS
	if counting_at_start_only:       flags |= CountFlags.COUNT_START_ONLY

	if flags == CountFlags.COUNT_START_ONLY:
		flags = 0

	return flags
func set_count_flags(value: int):
	var flag = value
	if (flag & CountFlags.VISITS) > 0:           visits_should_be_counted = true
	if (flag & CountFlags.TURNS) > 0:            turn_index_should_be_counted = true
	if (flag & CountFlags.COUNT_START_ONLY) > 0: counting_at_start_only = true

var has_valid_name: bool: get = get_has_valid_name
func get_has_valid_name() -> bool:
	return name != null && name.length() > 0

var path_to_first_leaf_content: InkPath: get = get_path_to_first_leaf_content
func get_path_to_first_leaf_content() -> InkPath:
	if _path_to_first_leaf_content == null:
		_path_to_first_leaf_content = path.path_by_appending_path(internal_path_to_first_leaf_content)

	return _path_to_first_leaf_content

var _path_to_first_leaf_content: InkPath = null

# TODO: Make inspectable
var internal_path_to_first_leaf_content: InkPath: get = get_internal_path_to_first_leaf_content
func get_internal_path_to_first_leaf_content() -> InkPath:
	var components: Array = [] # Array<Path3D.Component>
	var container: InkContainer = self
	while container != null:
		if container.content.size() > 0:
			components.append(InkPath.Component.new(0))
			container = container.content[0] as InkContainer

	return InkPath.new_with_components(components)

func _init():
	_content = [] # Array<InkObject>
	named_content = {} # Dictionary<string, INamedContent>

func add_content(content_obj_or_content_list) -> void:
	if content_obj_or_content_list is InkObject:
		var content_obj = content_obj_or_content_list
		content.append(content_obj)

		if content_obj.parent:
			InkUtils.throw_exception("content is already in %s" % content_obj.parent._to_string())
			return

		content_obj.parent = self

		try_add_named_content(content_obj)
	elif content_obj_or_content_list is Array:
		var content_list = content_obj_or_content_list
		for c in content_list:
			add_content(c)

func insert_content(content_obj: InkObject, index: int) -> void:
	content.insert(index, content_obj)

	if content_obj.parent:
		InkUtils.throw_exception("content is already in %s" % content_obj.parent._to_string())
		return

	content_obj.parent = self

	try_add_named_content(content_obj)

func try_add_named_content(content_obj: InkObject) -> void:
	var named_content_obj = InkUtils.as_INamedContent_or_null(content_obj)
	if (named_content_obj != null && named_content_obj.has_valid_name):
		add_to_named_content_only(named_content_obj)


# (INamedContent) -> void
func add_to_named_content_only(named_content_obj: InkObject) -> void:
	InkUtils.__assert__(named_content_obj != null, "Can only add Runtime.Objects to a Runtime.Container")
	var runtime_obj = named_content_obj
	runtime_obj.parent = self

	named_content[named_content_obj.name] = named_content_obj

func add_contents_of_container(other_container: InkContainer) -> void:
	content = content + other_container.content
	for obj in other_container.content:
		obj.parent = self
		try_add_named_content(obj)

func content_with_path_component(component: InkPath.Component) -> InkObject:
	if component.is_index:
		if component.index >= 0 && component.index < content.size():
			return content[component.index]
		else:
			return null
	elif component.is_parent:
		return parent
	else:
		if named_content.has(component.name):
			var found_content = named_content[component.name]
			return found_content
		else:
			return null

# (InkPath, int, int) -> InkSearchResult
func content_at_path(
		path: InkPath,
		partial_path_start: int = 0,
		partial_path_length: int = -1
) -> InkSearchResult:
	if partial_path_length == -1:
		partial_path_length = path.length

	var result: InkSearchResult = InkSearchResult.new()
	result.approximate = false

	var current_container: InkContainer = self
	var current_obj: InkObject = self

	var i: int = partial_path_start
	while i < partial_path_length:
		var comp = path.get_component(i)

		if current_container == null:
			result.approximate = true
			break

		var found_obj: InkObject = current_container.content_with_path_component(comp)

		if found_obj == null:
			result.approximate = true
			break

		current_obj = found_obj
		current_container = found_obj as InkContainer

		i += 1

	result.obj = current_obj

	return result

# (String, int, InkObject) -> string
func build_string_of_hierarchy(
		existing_hierarchy: String,
		indentation: int,
		pointed_obj: InkObject
) -> String:
	existing_hierarchy = _append_indentation(existing_hierarchy, indentation)
	existing_hierarchy += "["

	if has_valid_name:
		existing_hierarchy += str(" (%s) " % name)

	if self == pointed_obj:
		existing_hierarchy += "  <---"

	existing_hierarchy += "\n"

	indentation += 1

	var i = 0
	while i < content.size():
		var obj = content[i]

		if obj is InkContainer:
			existing_hierarchy = obj.build_string_of_hierarchy(existing_hierarchy, indentation, pointed_obj)
		else:
			existing_hierarchy = _append_indentation(existing_hierarchy, indentation)
			if obj is InkStringValue:
				existing_hierarchy += "\""
				existing_hierarchy += obj._to_string().replace("\n", "\\n")
				existing_hierarchy += "\""
			else:
				existing_hierarchy += obj._to_string()

		if i != content.size() - 1:
			existing_hierarchy += ","

		if !obj is InkContainer && obj == pointed_obj:
			existing_hierarchy += "  <---"

		existing_hierarchy += "\n"
		i += 1

	var only_named: Dictionary = {} # Dictionary<String, INamedContent>

	for obj_key in named_content:
		var value = named_content[obj_key]
		if content.find(value) != -1:
			continue
		else:
			only_named[obj_key] = value

	if only_named.size() > 0:
		existing_hierarchy = _append_indentation(existing_hierarchy, indentation)
		existing_hierarchy += "-- named: --\n"

		for object_key in only_named:
			var value = only_named[object_key]
			InkUtils.__assert__(value is InkContainer, "Can only print out named Containers")
			var container = value
			existing_hierarchy = container.build_string_of_hierarchy(existing_hierarchy, indentation, pointed_obj)
			existing_hierarchy += "\n"

	indentation -= 1

	existing_hierarchy = _append_indentation(existing_hierarchy, indentation)
	existing_hierarchy += "]"

	return existing_hierarchy

func build_full_string_of_hierarchy() -> String:
	return build_string_of_hierarchy("", 0, null)

func _append_indentation(string: String, indentation: int) -> String:
	var spaces_per_indent = 4
	var i = 0
	while(i < spaces_per_indent * indentation):
		string += " "
		i += 1

	return string
