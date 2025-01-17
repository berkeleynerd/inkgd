# ############################################################################ #
# Copyright © 2015-2021 inkle Ltd.
# Copyright © 2019-2022 Frédéric Maquin <fred@ephread.com>
# All Rights Reserved
#
# This file is part of inkgd.
# inkgd is licensed under the terms of the MIT license.
# ############################################################################ #


enum ValueType {
	BOOL = -1,

	INT,
	FLOAT,
	LIST,
	STRING,

	DIVERT_TARGET,
	VARIABLE_POINTER
}
