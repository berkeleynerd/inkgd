# ############################################################################ #
# Copyright © 2018-present Paul Joannon
# Copyright © 2019-present Frédéric Maquin <fred@ephread.com>
# Licensed under the MIT License.
# See LICENSE in the project root for license information.
# ############################################################################ #

tool
extends Node

class_name InkPlayerFactory

# ############################################################################ #
# Methods
# ############################################################################ #

static func create():
	if _should_use_mono():
		var InkPlayer = load("res://addons/inkgd/mono/InkPlayer.cs")
		if InkPlayer.can_instance():
			return InkPlayer.new()
		else:
			printerr(
					"[inkgd] [ERROR] InkPlayer can't be instantiated. Was ink-runtime-engine.dll added to the " +
					"project? If this is the case, try to rebuild the C# solution then reload the project."
			)
			print("[inkgd] [INFO] Falling back to the GDScript runtime.")

	# Falling back to GDscript.
	return load("res://addons/inkgd/ink_player.gd").new()


static func _should_use_mono() -> bool:
	var do_not_use_mono = ProjectSettings.get_setting("inkgd/do_not_use_mono_runtime")
	if do_not_use_mono == null:
		do_not_use_mono = false

	return _can_run_mono() && !do_not_use_mono

static func _can_run_mono() -> bool:
	return type_exists("_GodotSharp")