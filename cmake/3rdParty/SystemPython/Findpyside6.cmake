#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# System-package variant of the pyside6 3rdParty find module (used when
# LY_PYTHON_USE_SYSTEM is set). Resolves PySide6 and shiboken6 from the host
# distribution (e.g. Fedora python3-pyside6-devel and python3-shiboken6-devel)
# instead of the downloaded 3rdParty package. The distro modules are built for
# the system python and the system Qt, so:
#   - no site-package install into the venv is needed (the venv is created
#     with --system-site-packages in this mode), and
#   - no runtime library copies are made; everything resolves from the
#     standard system loader paths.

set(MY_NAME "pyside6")
set(TARGET_WITH_NAMESPACE "3rdParty::${MY_NAME}")
if (TARGET ${TARGET_WITH_NAMESPACE})
    return()
endif()

# Distro pyside/shiboken libraries are tagged with the interpreter SOABI
# (e.g. libpyside6.cpython-314-x86_64-linux-gnu.so); older layouts use abi3.
find_program(LY_PYTHON_SYSTEM_EXECUTABLE NAMES python3 REQUIRED)
execute_process(COMMAND ${LY_PYTHON_SYSTEM_EXECUTABLE} -c "import sysconfig; print(sysconfig.get_config_var('SOABI') or '')"
                OUTPUT_VARIABLE _pyside_soabi
                OUTPUT_STRIP_TRAILING_WHITESPACE
                RESULT_VARIABLE _pyside_soabi_result)
if (NOT _pyside_soabi_result EQUAL 0)
    message(FATAL_ERROR "pyside6 (system): could not query the python SOABI tag")
endif()

find_library(${MY_NAME}_SYSTEM_LIBRARY NAMES ${MY_NAME}.${_pyside_soabi} ${MY_NAME}.abi3)
find_library(${MY_NAME}_SYSTEM_SHIBOKEN_LIBRARY NAMES shiboken6.${_pyside_soabi} shiboken6.abi3)
find_path(${MY_NAME}_SYSTEM_INCLUDE_DIR NAMES PySide6/pyside.h)
find_path(${MY_NAME}_SYSTEM_SHIBOKEN_INCLUDE_DIR NAMES shiboken6/shiboken.h)
find_path(${MY_NAME}_SYSTEM_SHARE_DIR NAMES PySide6/typesystems PATHS /usr/share /usr/local/share)
find_program(${MY_NAME}_SYSTEM_SHIBOKEN_TOOL NAMES shiboken6)

foreach(_pyside_required_var
        ${MY_NAME}_SYSTEM_LIBRARY
        ${MY_NAME}_SYSTEM_SHIBOKEN_LIBRARY
        ${MY_NAME}_SYSTEM_INCLUDE_DIR
        ${MY_NAME}_SYSTEM_SHIBOKEN_INCLUDE_DIR
        ${MY_NAME}_SYSTEM_SHARE_DIR
        ${MY_NAME}_SYSTEM_SHIBOKEN_TOOL)
    if (NOT ${_pyside_required_var})
        message(FATAL_ERROR "pyside6 (system): ${_pyside_required_var} not found. Install the PySide6/shiboken6 development packages (e.g. python3-pyside6-devel python3-shiboken6-devel).")
    endif()
endforeach()

add_library(${TARGET_WITH_NAMESPACE} SHARED IMPORTED GLOBAL)

# Note: unlike the packaged variant there is no ly_pip_install_local_package_editable
# call here (the distro PySide6 is already importable through the venv's
# --system-site-packages) and no ly_add_target_files runtime copies (the
# libraries stay in the system paths).

ly_target_include_system_directories(TARGET ${TARGET_WITH_NAMESPACE}
    INTERFACE
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtConcurrent
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtCore
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtGui
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtNetwork
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtOpenGL
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtOpenGLWidgets
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtSql
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtSvg
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtSvgWidgets
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtUiTools
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtWidgets
        ${${MY_NAME}_SYSTEM_INCLUDE_DIR}/PySide6/QtXml
)

set_target_properties(${TARGET_WITH_NAMESPACE} PROPERTIES
    ${MY_NAME}_SHARE_DIR ${${MY_NAME}_SYSTEM_SHARE_DIR}
    IMPORTED_LOCATION "${${MY_NAME}_SYSTEM_LIBRARY}"
)

# Consumed by the Linux QtForPython code that preloads the pyside/shiboken
# libraries by name (InitializeEmbeddedPyside.h); full paths are valid dlopen
# arguments and sidestep SOABI-tagged file names.
target_compile_definitions(${TARGET_WITH_NAMESPACE}
    INTERFACE
        O3DE_PYSIDE6_SHARED_LIBRARY_NAME="${${MY_NAME}_SYSTEM_LIBRARY}"
        O3DE_SHIBOKEN6_SHARED_LIBRARY_NAME="${${MY_NAME}_SYSTEM_SHIBOKEN_LIBRARY}"
)

add_library(${MY_NAME}::Tools SHARED IMPORTED GLOBAL)

ly_target_include_system_directories(TARGET ${MY_NAME}::Tools
    INTERFACE ${${MY_NAME}_SYSTEM_SHIBOKEN_INCLUDE_DIR}/shiboken6
)

set_target_properties(${MY_NAME}::Tools PROPERTIES
    IMPORTED_LOCATION "${${MY_NAME}_SYSTEM_SHIBOKEN_LIBRARY}"
)

add_library(${TARGET_WITH_NAMESPACE}::Tools ALIAS ${MY_NAME}::Tools)

# Add shiboken generator exe tool.
add_executable(${MY_NAME}::ShibokenTool IMPORTED GLOBAL)
set_target_properties(${MY_NAME}::ShibokenTool PROPERTIES IMPORTED_LOCATION "${${MY_NAME}_SYSTEM_SHIBOKEN_TOOL}")
add_executable(${TARGET_WITH_NAMESPACE}::ShibokenTool ALIAS ${MY_NAME}::ShibokenTool)

function(add_shiboken_project)
    set(oneValueArgs MODULE_NAME NAMESPACE NAME WRAPPED_HEADER TYPESYSTEM_FILE GENERATED_FILES LICENSE_HEADER)
    set(multiValueArgs INCLUDE_DIRS DEPENDENCIES)
    cmake_parse_arguments(add_shiboken_project "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    # Validate arguments
    if (NOT add_shiboken_project_MODULE_NAME)
        message(FATAL_ERROR "You must provide a module name matching the package name in the xml typesystem file. This is the name of the output Python module.")
    endif()

    if(NOT add_shiboken_project_WRAPPED_HEADER)
        message(FATAL_ERROR "You must provide a header file containing all headers to be reflected.")
    endif()

    if(NOT add_shiboken_project_TYPESYSTEM_FILE)
        message(FATAL_ERROR "You must provide a typesystem file containing all items to be reflected.")
    endif()

    if(NOT add_shiboken_project_GENERATED_FILES)
        message(FATAL_ERROR "You must provide a cmake file containing all the cpp files that will be generated.")
    endif()

    # Include generated_files: this should define the GENERATED_FILES list.
    include(${add_shiboken_project_GENERATED_FILES})
    if(NOT GENERATED_FILES)
        message(FATAL_ERROR "You must provide a GENERATED_FILES list.")
    endif()

    # Reformat the include dirs array to add in "-I" to each entry, or shiboken won't work.
    list(TRANSFORM add_shiboken_project_INCLUDE_DIRS PREPEND "-I")

    # Reformat the generated files list to prepend the containing folder.
    list(TRANSFORM GENERATED_FILES PREPEND "${CMAKE_CURRENT_BINARY_DIR}/${add_shiboken_project_MODULE_NAME}/")

    get_property(SHARE_DIR TARGET 3rdParty::pyside6 PROPERTY pyside6_SHARE_DIR)

    # Allow AUTOMOC/AUTOUIC on generated files.
    if(POLICY CMP0071)
      cmake_policy(SET CMP0071 NEW)
    endif()
    set(CMAKE_AUTOMOC ON)

    set(shiboken_options --generator-set=shiboken --enable-parent-ctor-heuristic
        --enable-pyside-extensions --enable-return-value-heuristic --use-isnull-as-nb_nonzero
        --avoid-protected-hack --language-level=c++20 --debug-level=full
        --license-file=${add_shiboken_project_LICENSE_HEADER}
        --compiler-path=${CMAKE_CXX_COMPILER}
        ${add_shiboken_project_INCLUDE_DIRS}
        -T${SHARE_DIR}/PySide6
        -T${SHARE_DIR}/PySide6/typesystems
        --output-directory=${CMAKE_CURRENT_BINARY_DIR}
    )

    set(generated_sources_dependencies ${add_shiboken_project_WRAPPED_HEADER} ${add_shiboken_project_TYPESYSTEM_FILE})

    # The system shiboken loads its libraries from the standard loader paths,
    # so no special working directory is required; keep a defined one.
    if (QT_PATH)
        set(_shiboken_working_directory ${QT_PATH}/bin)
    else()
        set(_shiboken_working_directory ${CMAKE_CURRENT_BINARY_DIR})
    endif()

    # Custom shiboken command to generate wrapped files.
    add_custom_command(
        OUTPUT ${GENERATED_FILES}
        COMMAND 3rdParty::pyside6::ShibokenTool ${shiboken_options} ${add_shiboken_project_WRAPPED_HEADER} ${add_shiboken_project_TYPESYSTEM_FILE}
        DEPENDS ${generated_sources_dependencies} 3rdParty::pyside6
        COMMENT "Running generator for ${add_shiboken_project_TYPESYSTEM_FILE}."
        WORKING_DIRECTORY ${_shiboken_working_directory}
        VERBATIM
    )

    # Set up the project for building the code generated by shiboken.
    ly_add_target(
        NAME ${add_shiboken_project_NAME}.Editor MODULE
        NAMESPACE add_shiboken_project_NAMESPACE
        OUTPUT_NAME ${add_shiboken_project_MODULE_NAME}
        # We need to provide a FILES_CMAKE, but as the files do not yet exist, project creation would fail if it actually
        # had a FILES list. The files are actually added in by the following TARGET_SOURCES step.
        FILES_CMAKE
            ${add_shiboken_project_GENERATED_FILES}
        BUILD_DEPENDENCIES
            PUBLIC
                3rdParty::pyside6
                Qt6::Widgets
                Qt6::Core
                Qt6::Widgets
                Qt6::Gui
                ${add_shiboken_project_DEPENDENCIES}
            PRIVATE
                3rdParty::pyside6::Tools
    )

    ly_create_alias(NAME ${add_shiboken_project_NAME}.Builders NAMESPACE add_shiboken_project_NAMESPACE TARGETS ${add_shiboken_project_NAME}.Editor)
    ly_create_alias(NAME ${add_shiboken_project_NAME}.Tools NAMESPACE add_shiboken_project_NAMESPACE TARGETS ${add_shiboken_project_NAME}.Builders)

    target_sources(${add_shiboken_project_NAME}.Editor PRIVATE ${GENERATED_FILES})

    # Building the wrapper files will not work with a unity build.
    set_target_properties(${add_shiboken_project_NAME}.Editor PROPERTIES UNITY_BUILD OFF)

    if (PAL_PLATFORM_NAME STREQUAL "Windows")
        # Append _d to the module name in a debug build.
        set_target_properties(${add_shiboken_project_NAME}.Editor PROPERTIES DEBUG_POSTFIX "_d")

        # Disable various warnings in shiboken generated wrapper code.
        target_compile_options(${add_shiboken_project_NAME}.Editor PRIVATE /wd4127 /wd4100 /wd4456 /wd4458 /wd4505)
    endif()

    # Fix the name of the module.
    set_property(TARGET ${add_shiboken_project_NAME}.Editor PROPERTY PREFIX "")
    if (PAL_PLATFORM_NAME STREQUAL "Windows")
        set_property(TARGET ${add_shiboken_project_NAME}.Editor PROPERTY SUFFIX ".pyd")
    elseif (PAL_PLATFORM_NAME STREQUAL "Linux" OR PAL_PLATFORM_NAME STREQUAL "Mac")
        set_property(TARGET ${add_shiboken_project_NAME}.Editor PROPERTY SUFFIX ".so")
    endif()

    set_target_properties(${add_shiboken_project_NAME}.Editor PROPERTIES LINK_FLAGS "${python_additional_link_flags}")
endfunction()

set(${MY_NAME}_FOUND True)
