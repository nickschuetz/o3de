#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# System-Python find module (used when LY_PYTHON_USE_SYSTEM is set).
# Mirrors the variable and target contract of the python 3rdParty package's
# python-config.cmake, but resolves everything from the host interpreter via
# sysconfig instead of a downloaded package.

set(MY "Python")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    set(${MY}_FOUND True)
    return()
endif()

find_program(LY_PYTHON_SYSTEM_EXECUTABLE NAMES python3 REQUIRED)

# One interpreter round trip; ';' separators make the output a cmake list.
execute_process(
    COMMAND ${LY_PYTHON_SYSTEM_EXECUTABLE} -c
"import sys, sysconfig
print(';'.join([
    '%d.%d.%d' % sys.version_info[:3],
    sysconfig.get_config_var('INCLUDEPY') or '',
    sysconfig.get_config_var('LIBDIR') or '',
    sysconfig.get_config_var('INSTSONAME') or '',
    sys.prefix,
    sysconfig.get_path('stdlib'),
    sysconfig.get_path('platstdlib'),
    sysconfig.get_path('purelib'),
    sysconfig.get_path('platlib'),
]))"
    OUTPUT_VARIABLE _ly_syspy_info
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _ly_syspy_result)
if (NOT _ly_syspy_result EQUAL 0)
    message(FATAL_ERROR "FindPython (system): failed to query ${LY_PYTHON_SYSTEM_EXECUTABLE} via sysconfig")
endif()

list(GET _ly_syspy_info 0 _ly_syspy_version)
list(GET _ly_syspy_info 1 _ly_syspy_include_dir)
list(GET _ly_syspy_info 2 _ly_syspy_libdir)
list(GET _ly_syspy_info 3 _ly_syspy_soname)
list(GET _ly_syspy_info 4 _ly_syspy_prefix)
list(GET _ly_syspy_info 5 _ly_syspy_stdlib)
list(GET _ly_syspy_info 6 _ly_syspy_platstdlib)
list(GET _ly_syspy_info 7 _ly_syspy_purelib)
list(GET _ly_syspy_info 8 _ly_syspy_platlib)

set(${MY}_VERSION ${_ly_syspy_version})
set(${MY}_INTERPRETER_ID    "Python")
set(${MY}_EXECUTABLE        ${LY_PYTHON_SYSTEM_EXECUTABLE})
set(${MY}_HOME              ${_ly_syspy_prefix})
set(${MY}_PATHS             ${_ly_syspy_stdlib}
                            ${_ly_syspy_platstdlib}
                            ${_ly_syspy_platstdlib}/lib-dynload
                            ${_ly_syspy_purelib}
                            ${_ly_syspy_platlib})
list(REMOVE_DUPLICATES ${MY}_PATHS)

if (${PAL_PLATFORM_NAME} STREQUAL "Linux")
    set(${MY}_Interpreter_FOUND TRUE)
    set(${MY}_Development_FOUND TRUE)
    set(${MY}_LIBRARY_DEBUG   ${_ly_syspy_libdir}/${_ly_syspy_soname})
    set(${MY}_LIBRARY_RELEASE ${_ly_syspy_libdir}/${_ly_syspy_soname})
    set(${MY}_INCLUDE_DIR     ${_ly_syspy_include_dir})
    set(${MY}_COMPILE_DEFINITIONS
        DEFAULT_LY_PYTHONHOME="${_ly_syspy_prefix}"
        # Consumed by the Linux gem code that preloads libpython by name
        # (EditorPythonBindings/QtForPython InitializePython headers).
        O3DE_PYTHON_SHARED_LIBRARY_NAME="${_ly_syspy_soname}")
    set(${MY}_LIBRARY "$<IF:$<CONFIG:Debug>,${${MY}_LIBRARY_DEBUG},${${MY}_LIBRARY_RELEASE}>")

    if (NOT EXISTS ${${MY}_LIBRARY_RELEASE})
        message(FATAL_ERROR "FindPython (system): ${${MY}_LIBRARY_RELEASE} not found. Install the python development package (e.g. python3-devel).")
    endif()
    if (NOT EXISTS ${${MY}_INCLUDE_DIR}/Python.h)
        message(FATAL_ERROR "FindPython (system): Python.h not found in ${${MY}_INCLUDE_DIR}. Install the python development package (e.g. python3-devel).")
    endif()

    add_library(${TARGET_WITH_NAMESPACE} INTERFACE IMPORTED GLOBAL)
    ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE} INTERFACE ${${MY}_INCLUDE_DIR})
    target_link_libraries(${TARGET_WITH_NAMESPACE} INTERFACE "${${MY}_LIBRARY}")
    target_compile_definitions(${TARGET_WITH_NAMESPACE} INTERFACE "${${MY}_COMPILE_DEFINITIONS}")
    # Unlike the packaged python, no INTERFACE_IMPORTED_LOCATION is set here:
    # the shared library comes from the system loader paths and must not be
    # copied into the build or install output.
endif()

set(${MY}_FOUND True)
