#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# This file serves double duty for add_shiboken_project: it is the FILES_CMAKE
# for the module target (intentionally with no FILES list, since the sources do
# not exist until the generator runs) and it declares the files that shiboken
# will generate for the azshibokenspike typesystem.
set(GENERATED_FILES
    azshibokenspike_module_wrapper.cpp
    spikeobject_wrapper.cpp
)
