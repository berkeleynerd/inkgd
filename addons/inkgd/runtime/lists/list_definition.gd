# ############################################################################ #
# Copyright © 2015-2021 inkle Ltd.
# Copyright © 2019-2022 Frédéric Maquin <fred@ephread.com>
# All Rights Reserved
#
# This file is part of inkgd.
# inkgd is licensed under the terms of the MIT license.
# ############################################################################ #

extends InkObject

class_name InkListDefinition

# ############################################################################ #

var name: String: get = get_name
func get_name() -> String:
	return _name

# Dictionary<InkListItem, int> => Dictionary<String, int>
# Note: 'InkListItem' should actually be serialized into a String, because it
# needs to be a value type.
var items: Dictionary: get = get_items
func get_items() -> Dictionary:
	if _items == null:
		_items = {}
		for item_name_and_value_key in _item_name_to_values:
			var item = InkListItem.new_with_origin_name(name, item_name_and_value_key)
			_items[item.serialized()] = _item_name_to_values[item_name_and_value_key]

	return _items
var _items

# ############################################################################ #

func value_for_item(item: InkListItem) -> int:
	if (_item_name_to_values.has(item.item_name)):
		var intVal = _item_name_to_values[item.item_name]
		return intVal
	else:
		return 0

func contains_item(item: InkListItem) -> bool:
	if item.origin_name != name:
		return false

	return _item_name_to_values.has(item.item_name)

func contains_item_with_name(item_name: String) -> bool:
	return _item_name_to_values.has(item_name)

# (int) -> { result: InkListItem, exists: bool }
func try_get_item_with_value(val: int) -> InkTryGetResult:
	for named_item_key in _item_name_to_values:
		if (_item_name_to_values[named_item_key] == val):
			return InkTryGetResult.new(
					true,
					InkListItem.new_with_origin_name(name, named_item_key)
			)

	return InkTryGetResult.new(false, InkListItem.new_null())

# (InkListItem) -> { result: InkListItem, exists: bool }
func try_get_value_for_item(item: InkListItem) -> InkTryGetResult:
	if item == null:
		return InkTryGetResult.new(false, 0)

	var value = _item_name_to_values.get(item.item_name)

	if value == null:
		InkTryGetResult.new(false, 0)

	return InkTryGetResult.new(true, value)

# (String name, Dictionary<String, int>) -> InkListDefinition
func _init(name: String, items: Dictionary):
	_name = name
	_item_name_to_values = items

var _name: String
var _item_name_to_values: Dictionary # Dictionary<String, int>

# ############################################################################ #
# GDScript extra methods
# ############################################################################ #

func _to_string() -> String:
	return "[InkListDefinition \"%s\"]" % get_name()
