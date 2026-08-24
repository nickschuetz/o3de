/*
 * Copyright (c) Contributors to the Open 3D Engine Project.
 * For complete copyright and license terms please see the LICENSE at the root of this distribution.
 *
 * SPDX-License-Identifier: Apache-2.0 OR MIT
 *
 */
#pragma once

#include <AzCore/Debug/Trace.h>
#include <dlfcn.h>

namespace QtForPython
{
    // These names must match the python/pyside/shiboken libraries the engine is
    // built against. The build provides the O3DE_*_SHARED_LIBRARY_NAME macros
    // when the configured stack differs from the default 3rdParty packages
    // (e.g. LY_PYTHON_USE_SYSTEM); the literals match the packaged layout.
#if !defined(O3DE_PYTHON_SHARED_LIBRARY_NAME)
    #error O3DE_PYTHON_SHARED_LIBRARY_NAME must be defined; it is wired from LY_PYTHON_SHARED_LIB in the gem CMakeLists.txt
#endif
    const char* s_libPythonLibraryFile = O3DE_PYTHON_SHARED_LIBRARY_NAME;
#if defined(O3DE_PYSIDE6_SHARED_LIBRARY_NAME)
    const char* s_libPysideLibraryFile = O3DE_PYSIDE6_SHARED_LIBRARY_NAME;
#else
    const char* s_libPysideLibraryFile = "libpyside6.abi3.so.6.10";
#endif
#if defined(O3DE_SHIBOKEN6_SHARED_LIBRARY_NAME)
    const char* s_libShibokenLibraryFile = O3DE_SHIBOKEN6_SHARED_LIBRARY_NAME;
#else
    const char* s_libShibokenLibraryFile = "libshiboken6.abi3.so.6.10";
#endif
    const char* s_libQtTestLibraryFile = "libQt6Test.so.6";

    class InitializeEmbeddedPyside
    {
    public:
        InitializeEmbeddedPyside()
        {
            m_libPythonLibraryFile = InitializeEmbeddedPyside::LoadModule(s_libPythonLibraryFile);
            m_libPysideLibraryFile = InitializeEmbeddedPyside::LoadModule(s_libPysideLibraryFile);
            m_libShibokenLibraryFile = InitializeEmbeddedPyside::LoadModule(s_libShibokenLibraryFile);
            m_libQtTestLibraryFile = InitializeEmbeddedPyside::LoadModule(s_libQtTestLibraryFile);
        }
        virtual ~InitializeEmbeddedPyside()
        {
            InitializeEmbeddedPyside::UnloadModule(m_libQtTestLibraryFile);
            InitializeEmbeddedPyside::UnloadModule(m_libShibokenLibraryFile);
            InitializeEmbeddedPyside::UnloadModule(m_libPysideLibraryFile);
            InitializeEmbeddedPyside::UnloadModule(m_libPythonLibraryFile);
        }

    private:
        static void* LoadModule(const char* moduleToLoad)
        {
            void* moduleHandle = dlopen(moduleToLoad, RTLD_NOW | RTLD_GLOBAL);
            if (!moduleHandle)
            {
                [[maybe_unused]] const char* loadError = dlerror();
                AZ_Error("QtForPython", false, "Unable to load python library %s for Pyside: %s", moduleToLoad,
                         loadError ? loadError : "Unknown Error");
            }
            return moduleHandle;
        }

        static void UnloadModule(void* moduleHandle)
        {
            if (moduleHandle)
            {
                dlclose(moduleHandle);
            }
        }

        void* m_libPythonLibraryFile;
        void* m_libPysideLibraryFile;
        void* m_libShibokenLibraryFile;
        void* m_libQtTestLibraryFile;
    };
} // namespace QtForPython
