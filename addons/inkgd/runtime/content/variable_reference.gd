# ############################################################################ #
# Copyright © 2015-2021 inkle Ltd.
# Copyright © 2019-2022 Frédéric Maquin <fred@ephread.com>
# All Rights Reserved
#
# This file is part of inkgd.
# inkgd is licensed under the terms of the MIT license.
# ############################################################################ #

extends InkObject

class_name InkVariableReference

# ############################################################################ #

# String
var name = null

var path_for_count: InkPath = null

var container_for_count: InkContainer : get = get_container_for_count
func get_container_for_count():
	return resolve_path(path_for_count).container

# String?
var path_string_for_count : get = get_path_string_for_count, set = set_path_string_for_count
func get_path_string_for_count():
	if path_for_count == null:
		return null

	return compact_path_string(path_for_count)

func set_path_string_for_count(value):
	if value == null:
		path_for_count = null
	else:
		path_for_count = InkPath.new_with_components_string(value)

# ############################################################################ #

func _init(name = null):
	if name:
		self.name = name

# ############################################################################ #

func _to_string() -> String:
	if name != null:
		return "var(%s)" % name
	else:
		var path_str = path_string_for_count
		return "read_count(%s)" % path_str
