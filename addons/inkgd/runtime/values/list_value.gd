# ############################################################################ #
# Copyright © 2015-2021 inkle Ltd.
# Copyright © 2019-2022 Frédéric Maquin <fred@ephread.com>
# All Rights Reserved
#
# This file is part of inkgd.
# inkgd is licensed under the terms of the MIT license.
# ############################################################################ #

extends InkValue

class_name InkListValue

# ############################################################################ #

func get_value_type():
	return ValueType.LIST

func get_is_truthy():
	return value.size() > 0

# The method takes a `StoryErrorMetadata` object as a parameter that
# doesn't exist in upstream. The metadat are used in case an 'exception'
# is raised. For more information, see story.gd.
func cast(new_type, metadata = null):
	if new_type == ValueType.INT:
		var max_item = value.max_item
		if max_item.key.is_null:
			return InkIntValue.new_with(0)
		else:
			return InkIntValue.new_with(max_item.value)

	elif new_type == ValueType.FLOAT:
		var max_item = value.max_item
		if max_item.key.is_null:
			return InkFloatValue.new_with(0.0)
		else:
			return InkFloatValue.new_with(float(max_item.value))

	elif new_type == ValueType.STRING:
		var max_item = value.max_item
		if max_item.key.is_null:
			return InkStringValue.new_with("")
		else:
			return InkStringValue.new_with(max_item.key._to_string())

	if new_type == value_type:
		return self

	InkUtils.throw_story_exception(bad_cast_exception_message(new_type), false, metadata)
	return null

func _init():
	value = InkList.new()

func _init_with_list(list):
	value = InkList.new_with_ink_list(list)

func _init_with_single_item(single_item, single_value):
	value = InkList.new_with_single_item(single_item, single_value)

# (InkObject, InkObject) -> void
static func retain_list_origins_for_assignment(old_value, new_value):
	var InkUtils = load("res://addons/inkgd/runtime/extra/utils.gd")

	var old_list = old_value as InkListValue
	var new_list = new_value as InkListValue

	if old_list && new_list && new_list.value.size() == 0:
		new_list.value.set_initial_origin_names(old_list.value.origin_names)

# ############################################################################ #
# GDScript extra methods
# ############################################################################ #

static func new_with(list):
	var value = InkListValue.new()
	value._init_with_list(list)
	return value

static func new_with_single_item(single_item, single_value):
	var value = InkListValue.new()
	value._init_with_single_item(single_item, single_value)
	return value
