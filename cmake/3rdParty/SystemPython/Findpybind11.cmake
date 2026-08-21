#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# System-package variant of the pybind11 3rdParty find module (used when
# LY_PYTHON_USE_SYSTEM is set). The distro pybind11 (e.g. Fedora
# pybind11-devel) tracks the distro python, so the two stay ABI-consistent.

set(TARGET_WITH_NAMESPACE "3rdParty::pybind11")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

set(LIB_NAME "pybind11")

find_path(${LIB_NAME}_SYSTEM_INCLUDE_DIR NAMES pybind11/pybind11.h)
if (NOT ${LIB_NAME}_SYSTEM_INCLUDE_DIR)
    message(FATAL_ERROR "pybind11 (system): pybind11/pybind11.h not found. Install the pybind11 development package (e.g. pybind11-devel).")
endif()

add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${LIB_NAME}_SYSTEM_INCLUDE_DIR})

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    target_compile_options(3rdParty::pybind11 INTERFACE -fsized-deallocation)
endif()

set(${LIB_NAME}_FOUND True)
