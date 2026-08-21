#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# Setup the Python global variables and download and associate python to the correct package

if (LY_PYTHON_USE_SYSTEM)

    # System-Python mode: resolve the host interpreter instead of downloading
    # the 3rdParty python package. The per-engine venv is still created (from
    # the system interpreter, with access to the distro site-packages) so
    # downstream tooling uses the same venv layout in both modes.
    find_program(LY_PYTHON_SYSTEM_EXECUTABLE NAMES python3 REQUIRED)
    execute_process(COMMAND ${LY_PYTHON_SYSTEM_EXECUTABLE} -c "import sys, sysconfig; print(';'.join(['%d.%d.%d' % sys.version_info[:3], '%d.%d' % sys.version_info[:2], sysconfig.get_config_var('INSTSONAME') or '']))"
                    OUTPUT_VARIABLE _ly_system_python_info
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE _ly_system_python_result)
    if (NOT _ly_system_python_result EQUAL 0)
        message(FATAL_ERROR "LY_PYTHON_USE_SYSTEM is set but the system python interpreter could not be queried")
    endif()
    list(GET _ly_system_python_info 0 _ly_system_python_version)
    list(GET _ly_system_python_info 1 _ly_system_python_version_major_minor)
    list(GET _ly_system_python_info 2 _ly_system_python_soname)

    # Python info (no 3rdParty package in this mode; the package name and hash
    # are sentinels. The hash keys the venv to the system interpreter version
    # so a distro python upgrade regenerates the venv.)
    ly_set(LY_PYTHON_VERSION ${_ly_system_python_version})
    ly_set(LY_PYTHON_VERSION_MAJOR_MINOR ${_ly_system_python_version_major_minor})
    ly_set(LY_PYTHON_PACKAGE_NAME system-python)
    ly_set(LY_PYTHON_PACKAGE_HASH system-python-${_ly_system_python_version})

    ly_set(LY_PYTHON_BIN_PATH "bin")
    ly_set(LY_PYTHON_LIB_PATH "lib")
    ly_set(LY_PYTHON_EXECUTABLE "python3")
    ly_set(LY_PYTHON_SHARED_LIB "${_ly_system_python_soname}")

    # Python venv relative paths
    ly_set(LY_PYTHON_VENV_BIN_PATH "bin")
    ly_set(LY_PYTHON_VENV_LIB_PATH "lib")
    ly_set(LY_PYTHON_VENV_SITE_PACKAGES "${LY_PYTHON_VENV_LIB_PATH}/python${LY_PYTHON_VERSION_MAJOR_MINOR}/site-packages")
    ly_set(LY_PYTHON_VENV_PYTHON "${LY_PYTHON_VENV_BIN_PATH}/python")

    function(ly_post_python_venv_install venv_path)
        # Nothing to do: the system interpreter's shared library resolves
        # through the standard system loader paths.
    endfunction()

else()

    # Python package info
    ly_set(LY_PYTHON_VERSION 3.10.13)
    ly_set(LY_PYTHON_VERSION_MAJOR_MINOR 3.10)
    ly_set(LY_PYTHON_PACKAGE_NAME python-3.10.13-rev2-linux)
    ly_set(LY_PYTHON_PACKAGE_HASH a7832f9170a3ac93fbe678e9b3d99a977daa03bb667d25885967e8b4977b86f8)

    # Python package relative paths
    ly_set(LY_PYTHON_BIN_PATH "python/bin")
    ly_set(LY_PYTHON_LIB_PATH "python/lib")
    ly_set(LY_PYTHON_EXECUTABLE "python")
    ly_set(LY_PYTHON_SHARED_LIB "libpython3.10.so.1.0")

    # Python venv relative paths
    ly_set(LY_PYTHON_VENV_BIN_PATH "bin")
    ly_set(LY_PYTHON_VENV_LIB_PATH "lib")
    ly_set(LY_PYTHON_VENV_SITE_PACKAGES "${LY_PYTHON_VENV_LIB_PATH}/python3.10/site-packages")
    ly_set(LY_PYTHON_VENV_PYTHON "${LY_PYTHON_VENV_BIN_PATH}/python")

    function(ly_post_python_venv_install venv_path)

        # We need to create a symlink to the shared library in the venv
        execute_process(COMMAND ln -s -f "${PYTHON_PACKAGES_ROOT_PATH}/${LY_PYTHON_PACKAGE_NAME}/${LY_PYTHON_LIB_PATH}/${LY_PYTHON_SHARED_LIB}" ${LY_PYTHON_SHARED_LIB}
                        WORKING_DIRECTORY "${PYTHON_VENV_PATH}/${LY_PYTHON_VENV_LIB_PATH}"
                        RESULT_VARIABLE command_result)
        if (NOT ${command_result} EQUAL 0)
            message(WARNING "Unable to create a venv shared library link.")
        endif()

    endfunction()

endif()
