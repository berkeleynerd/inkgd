# ############################################################################ #
# Copyright © 2019-2022 Frédéric Maquin <fred@ephread.com>
# Licensed under the MIT License.
# See LICENSE in the project root for license information.
# ############################################################################ #

extends Node

# ############################################################################ #
# Imports
# ############################################################################ #

var ErrorType := preload("res://addons/inkgd/runtime/enums/error.gd").ErrorType
var LineLabel := load("res://examples/scenes/common/label.tscn") as PackedScene
const ChoiceContainerScene = preload("res://examples/scenes/common/choice_container.tscn")


# ############################################################################ #
# Constants
# ############################################################################ #

const USE_SIGNALS = true


# ############################################################################ #
# Properties
# ############################################################################ #

# If you're trying to figure out how to use inkgd,
# you can ignore those exports. They just make overriding
# the story and creating multiple scenes easier.
# For context, see main.tscn.
@export var ink_file: Resource
@export var title: String
@export var bind_externals: bool = false


# ############################################################################ #
# Private Properties
# ############################################################################ #

var _current_choice_container: ChoiceContainer

# InkPlayer is created through the factory so that it returns the appropriate
# node depending on whether the project is using Mono or not.
#
# In your project you can also add it in the scene tree and use the inspector
# to set the variables.
var _ink_player = InkPlayerFactory.create()


# ############################################################################ #
# Node
# ############################################################################ #

@onready var _story_vbox_container = $StoryMarginContainer/StoryScrollContainer/StoryVBoxContainer


# ############################################################################ #
# Lifecycle
# ############################################################################ #

func _ready():
	add_child(_ink_player)

	# Again, if you're just trying to figure out how to use
	# inkgd, you can ignore this call.
	_override_story()

	if USE_SIGNALS:
		_connect_optional_signals()

	_connect_signals()

	_ink_player.create_story()


# ############################################################################ #
# Private Methods
# ############################################################################ #

func _continue_story():
	if USE_SIGNALS:
		_ink_player.continue_story()
	else:
		while _ink_player.can_continue:
			var text = _ink_player.continue_story()
			_add_label(text)

		if _ink_player.has_choices:
			_prompt_choices(_ink_player.current_choices)
		else:
			_ended()


# ############################################################################ #
# Signal Receivers
# ############################################################################ #

func _loaded(successfully: bool):
	if !successfully:
		return

	_bind_externals()
	_evaluate_functions()
	_continue_story()


func _continued(text, _tags):
	_add_label(text)

	_ink_player.continue_story()


func _add_label(text):
	var label = LineLabel.instantiate()
	label.text = text

	_story_vbox_container.add_child(label)


func _prompt_choices(choices):
	if !choices.is_empty():
		_current_choice_container = ChoiceContainerScene.instantiate()
		_story_vbox_container.add_child(_current_choice_container)

		_current_choice_container.create_choices(choices)
		_current_choice_container.choice_selected.connect(_choice_selected)


func _ended():
	# End of story: let's check whether you took the cup of tea.
	var teacup = _ink_player.get_variable("teacup")

	if teacup:
		print("Took the tea.")
	else:
		print("Didn't take the tea.")


func _choice_selected(index):
	_story_vbox_container.remove_child(_current_choice_container)
	_current_choice_container.queue_free()

	_ink_player.choose_choice_index(index)
	_continue_story()


func _exception_raised(message, stack_trace):
	# This method gives a chance to react to a story-breaking exception.
	printerr(message)
	for line in stack_trace:
		printerr(line)


func _error_encountered(message, type):
	match type:
		ErrorType.ERROR:
			printerr(message)
		ErrorType.WARNING:
			print(message)
		ErrorType.AUTHOR:
			print(message)


# ############################################################################ #
# Private Methods
# ############################################################################ #

## Overrides the title and resource loaded with the values set through
## exported properties. The sole purpose of this method is to faccilitate
## the creation of multiple examples. For context, see main.tscn.
func _override_story():
	if ink_file != null:
		_ink_player.ink_file = ink_file


func _should_show_debug_menu(debug):
	# Contrived external function example, where
	# we just return the pre-existing value.
	print("_should_show_debug_menu called")
	return debug


func _observe_variables(variable_name, new_value):
	print("Variable '%s' changed to: %s" %[variable_name, new_value])


func _bind_externals():
	# Externals are contextual to the story. Here, variables
	# 'forceful' & 'evasive' as well asfunction 'should_show_debug_menu'
	# only exists in The Intercept.
	if !bind_externals:
		return

	_ink_player.observe_variables(["forceful", "evasive"], self, "_observe_variables")
	_ink_player.bind_external_function("should_show_debug_menu", self, "_should_show_debug_menu")


func _evaluate_functions():
	## An example of how to evaluate functions. Both Crime Scene and
	## the Intercept declare thse dummy functions.
	var result = _ink_player.evaluate_function("test_function", [3, 4])
	print(
			"function 'test_function': [Text Output: '%s'] [Return Value: %s]" % \
			[result.text_output.replace("\n", "\\n"), result.return_value]
	)

	var result_output = _ink_player.evaluate_function("test_function_output", [3, 4, 5])
	print(
			"function 'test_function_output': [Text Output: '%s'] [Return Value: %s]" % \
			[result_output.text_output.replace("\n", "\\n"), result_output.return_value]
	)


func _connect_signals():
	_ink_player.loaded.connect(_loaded)


func _connect_optional_signals():
	_ink_player.continued.connect(_continued)
	_ink_player.prompt_choices.connect(_prompt_choices)
	_ink_player.ended.connect(_ended)

	_ink_player.exception_raised.connect(_exception_raised)
	_ink_player.error_encountered.connect(_error_encountered)
