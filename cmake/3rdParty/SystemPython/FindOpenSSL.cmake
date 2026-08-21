#
# Copyright (c) Contributors to the Open 3D Engine Project. For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
#

# System-package variant of the OpenSSL 3rdParty find module (used when
# LY_PYTHON_USE_SYSTEM is set). The packaged OpenSSL is a static 1.1.1t that
# gets linked into engine libraries with default symbol visibility; those
# unversioned exports capture the OpenSSL calls of any python C extension in
# the same process that was built against the system OpenSSL 3 (for example
# _hashlib), corrupting its dispatch. Linking the system OpenSSL keeps a
# single coherent OpenSSL in the process.

set(OPENSSL_O3DE_NAMESPACE "3rdParty::OpenSSL")
if (TARGET ${OPENSSL_O3DE_NAMESPACE})
    return()
endif()

set(SSL_TARGETNAME "OpenSSL::SSL")
set(CRYPTO_TARGETNAME "OpenSSL::Crypto")

find_path(OPENSSL_SYSTEM_INCLUDE_DIR NAMES openssl/ssl.h)
find_library(OPENSSL_SYSTEM_SSL_LIBRARY NAMES ssl)
find_library(OPENSSL_SYSTEM_CRYPTO_LIBRARY NAMES crypto)

if (NOT OPENSSL_SYSTEM_INCLUDE_DIR OR NOT OPENSSL_SYSTEM_SSL_LIBRARY OR NOT OPENSSL_SYSTEM_CRYPTO_LIBRARY)
    message(FATAL_ERROR "OpenSSL (system): headers or libraries not found. Install the OpenSSL development package (e.g. openssl-devel).")
endif()

set(OPENSSL_FOUND True)
set(OPENSSL_INCLUDE_DIR ${OPENSSL_SYSTEM_INCLUDE_DIR})
set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_SYSTEM_CRYPTO_LIBRARY})
set(OPENSSL_CRYPTO_LIBRARIES
    ${OPENSSL_CRYPTO_LIBRARY}
    )
set(OPENSSL_SSL_LIBRARY ${OPENSSL_SYSTEM_SSL_LIBRARY})
set(OPENSSL_SSL_LIBRARIES
    ${OPENSSL_SSL_LIBRARY}
    ${OPENSSL_CRYPTO_LIBRARIES})
set(OPENSSL_LIBRARIES ${OPENSSL_SSL_LIBRARIES})
set(OPENSSL_VERSION "system")

add_library(${CRYPTO_TARGETNAME} SHARED IMPORTED GLOBAL)
set_target_properties(${CRYPTO_TARGETNAME} PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C")
set_target_properties(${CRYPTO_TARGETNAME} PROPERTIES IMPORTED_LOCATION "${OPENSSL_CRYPTO_LIBRARY}")

add_library(${SSL_TARGETNAME} SHARED IMPORTED GLOBAL)
set_target_properties(${SSL_TARGETNAME} PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C")
set_target_properties(${SSL_TARGETNAME} PROPERTIES IMPORTED_LOCATION "${OPENSSL_SSL_LIBRARY}")
target_link_libraries(${SSL_TARGETNAME} INTERFACE ${CRYPTO_TARGETNAME})

if (COMMAND ly_target_include_system_directories)
    ly_target_include_system_directories(TARGET ${SSL_TARGETNAME} INTERFACE ${OPENSSL_INCLUDE_DIR})
    ly_target_include_system_directories(TARGET ${CRYPTO_TARGETNAME} INTERFACE ${OPENSSL_INCLUDE_DIR})
else()
    target_include_directories(${SSL_TARGETNAME} SYSTEM INTERFACE ${OPENSSL_INCLUDE_DIR})
    target_include_directories(${CRYPTO_TARGETNAME} SYSTEM INTERFACE ${OPENSSL_INCLUDE_DIR})
endif()

add_library(${OPENSSL_O3DE_NAMESPACE} ALIAS ${SSL_TARGETNAME})

if (NOT LY_VERSION_ENGINE_NAME)
    message(STATUS "Using the system OpenSSL from ${OPENSSL_SYSTEM_SSL_LIBRARY}")
endif()
