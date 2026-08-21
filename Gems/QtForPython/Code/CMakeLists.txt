#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#
if(NOT PAL_TRAIT_BUILD_HOST_TOOLS)
    return()
endif()

set(common_source_dir ${CMAKE_CURRENT_LIST_DIR}/Source/Platform/Common)

include(${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${PAL_PLATFORM_NAME}/PAL_${PAL_PLATFORM_NAME_LOWERCASE}.cmake)

if(NOT PAL_TRAIT_BUILD_QTFORPYTHON_SUPPORTED)
    return()
endif()

ly_add_target(
    NAME ${gem_name}.Editor.Static STATIC
    NAMESPACE Gem
    FILES_CMAKE
        qtforpython_editor_files.cmake
        ${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${PAL_PLATFORM_NAME}/qtforpython_editor_${PAL_PLATFORM_NAME_LOWERCASE}_files.cmake
    PLATFORM_INCLUDE_FILES
        ${common_source_dir}/${PAL_TRAIT_COMPILER_ID}/qtforpython_${PAL_TRAIT_COMPILER_ID_LOWERCASE}.cmake
    INCLUDE_DIRECTORIES
        PUBLIC
            Include
            Source
    BUILD_DEPENDENCIES
        PUBLIC
            AZ::AzCore
            AZ::AzFramework
            AZ::AzToolsFramework
            3rdParty::Qt::Widgets
            Gem::EditorPythonBindings.Static
    RUNTIME_DEPENDENCIES
        3rdParty::pyside6
        3rdParty::Qt::Test
)

ly_add_target(
    NAME ${gem_name}.Editor GEM_MODULE
    NAMESPACE Gem
    FILES_CMAKE
        qtforpython_shared_files.cmake
    INCLUDE_DIRECTORIES
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/Source/Platform/${PAL_PLATFORM_NAME}
    BUILD_DEPENDENCIES
        PRIVATE
            Gem::${gem_name}.Editor.Static
    RUNTIME_DEPENDENCIES
        3rdParty::pyside6::Tools
        Gem::EditorPythonBindings.Editor
)

# Inject the gem name into the Module source file
ly_add_source_properties(
    SOURCES
        Source/QtForPythonModule.cpp
    PROPERTY COMPILE_DEFINITIONS
        VALUES
            O3DE_GEM_NAME=${gem_name}
            O3DE_GEM_VERSION=${gem_version})

# the above target is used in both builders like AssetProcessor and Tools like the Editor
# but is not used in clients or servers
ly_create_alias(NAME ${gem_name}.Tools     NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)
ly_create_alias(NAME ${gem_name}.Builders  NAMESPACE Gem TARGETS Gem::${gem_name}.Editor)

if (LY_PYTHON_USE_SYSTEM AND PAL_PLATFORM_NAME STREQUAL "Linux")
    # Exercise the add_shiboken_project code generation path against the
    # system shiboken6 generator and pyside6: wrap a minimal QObject-derived
    # type into a loadable python module.
    find_package(pyside6 REQUIRED)

    find_path(spike_qt_system_include_dir NAMES QtCore/QObject PATHS /usr/include/qt6)
    if (NOT spike_qt_system_include_dir)
        message(FATAL_ERROR "ShibokenSpike: system Qt6 headers not found (install qt6-qtbase-devel)")
    endif()

    add_library(ShibokenSpike.Headers INTERFACE)
    # The system pyside6 headers match the system Qt version, so this target
    # must compile against the system Qt headers, not the bundled Qt package's
    # (e.g. pyside6_qtcore_python.h referencing Qt API newer than the bundle).
    # Plain include directories are searched before the bundled -isystem dirs.
    target_include_directories(ShibokenSpike.Headers INTERFACE
        ${CMAKE_CURRENT_LIST_DIR}/ShibokenSpike
        ${spike_qt_system_include_dir}
        ${spike_qt_system_include_dir}/QtCore
        ${spike_qt_system_include_dir}/QtGui
        ${spike_qt_system_include_dir}/QtWidgets
    )

    add_shiboken_project(
        MODULE_NAME azshibokenspike
        NAME ShibokenSpike
        NAMESPACE Gem
        WRAPPED_HEADER ${CMAKE_CURRENT_LIST_DIR}/ShibokenSpike/spike_bindings.h
        TYPESYSTEM_FILE ${CMAKE_CURRENT_LIST_DIR}/ShibokenSpike/spike_typesystem.xml
        GENERATED_FILES ${CMAKE_CURRENT_LIST_DIR}/ShibokenSpike/spike_generated_files.cmake
        LICENSE_HEADER ${CMAKE_CURRENT_LIST_DIR}/ShibokenSpike/spike_license.txt
        INCLUDE_DIRS
            ${CMAKE_CURRENT_LIST_DIR}/ShibokenSpike
            ${spike_qt_system_include_dir}
            ${spike_qt_system_include_dir}/QtCore
        DEPENDENCIES
            ShibokenSpike.Headers
            3rdParty::Python
    )
endif()

