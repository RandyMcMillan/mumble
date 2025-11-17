# Copyright (c) 2015-2023 Moritz Aurel Pascal Schubotz
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Find Poco C++ Libraries
#
# This module is intended to find the Poco C++ Libraries.
# It supports the following components:
#   Util, Foundation, XML, Zip, Crypto, Data, Net, NetSSL_OpenSSL, OSP
#
# Usage:
#   find_package(Poco REQUIRED [COMPONENTS Util Foundation XML Zip Crypto Data Net NetSSL_OpenSSL OSP])
#
# Variables defined:
#   Poco_FOUND - true if Poco was found, false otherwise.
#   Poco_LIBRARIES - The Poco libraries to link against.
#   Poco_INCLUDE_DIRS - The directories to search for Poco header files.
#
#   Poco_Xxx_FOUND - true if the component Xxx was found.
#   Poco_Xxx_LIBRARY - The library for component Xxx.
#   Poco_Xxx_LIBRARY_DEBUG - The debug library for component Xxx.
#   Poco_Xxx_INCLUDE_DIR - The include directory for component Xxx.
#
# Example:
#   set(ENV{Poco_DIR} path/to/poco/sdk)
#   find_package(Poco REQUIRED OSP Data Crypto)
#   add_executable(my_app main.cpp)
#   target_link_libraries(my_app PRIVATE Poco_LIBRARIES)
#

include(FindPackageHandleStandardArgs)

set(POCO_NAMES "Poco")

# Try to find Poco using find_package first
find_package(Poco REQUIRED)

if(Poco_FOUND)
    set(POCO_INCLUDE_DIRS ${Poco_INCLUDE_DIRS})
    set(POCO_LIBRARIES ${Poco_LIBRARIES})
    set(Poco_FOUND TRUE)
else()
    message(STATUS "Poco not found via find_package. Trying manual search...")

    # Try to find Poco using environment variables and common installation paths
    set(POCO_ROOT_HINTS
        $ENV{POCO_ROOT}
        ${CMAKE_PREFIX_PATH}
        /usr/local
        /opt/local
        /usr
    )

    set(POCO_INCLUDE_DIRS "")
    set(POCO_LIBRARIES "")

    # Find Poco headers
    find_path(POCO_INCLUDE_DIRS
        NAMES Poco/Poco.h
        HINTS ${POCO_ROOT_HINTS}
        PATH_SUFFIXES include
    )

    # Find Poco libraries
    set(POCO_COMPONENTS "Util;Foundation;XML;Zip;Crypto;Data;Net;NetSSL_OpenSSL;OSP")
    foreach(component ${POCO_COMPONENTS})
        string(TOUPPER ${component} COMPONENT_UPPER)
        set(POCO_${COMPONENT_UPPER}_LIBRARY_RELEASE "")
        set(POCO_${COMPONENT_UPPER}_LIBRARY_DEBUG "")
        set(POCO_${COMPONENT_UPPER}_LIBRARY "")

        find_library(POCO_${COMPONENT_UPPER}_LIBRARY_RELEASE
            NAMES ${component}
            HINTS ${POCO_ROOT_HINTS}
            PATH_SUFFIXES lib
        )
        find_library(POCO_${COMPONENT_UPPER}_LIBRARY_DEBUG
            NAMES ${component}
            HINTS ${POCO_ROOT_HINTS}
            PATH_SUFFIXES lib
        )

        if(POCO_${COMPONENT_UPPER}_LIBRARY_RELEASE)
            list(APPEND POCO_LIBRARIES ${POCO_${COMPONENT_UPPER}_LIBRARY_RELEASE})
            set(POCO_${COMPONENT_UPPER}_LIBRARY ${POCO_${COMPONENT_UPPER}_LIBRARY_RELEASE})
            set(POCO_${COMPONENT_UPPER}_FOUND TRUE)
        endif()
        if(POCO_${COMPONENT_UPPER}_LIBRARY_DEBUG)
            list(APPEND POCO_LIBRARIES ${POCO_${COMPONENT_UPPER}_LIBRARY_DEBUG})
            set(POCO_${COMPONENT_UPPER}_LIBRARY ${POCO_${COMPONENT_UPPER}_LIBRARY_DEBUG})
            set(POCO_${COMPONENT_UPPER}_FOUND TRUE)
        endif()
    endforeach()

    # Set Poco_FOUND based on whether essential components were found
    # We consider Foundation and Util as essential for most Poco applications.
    if(POCO_FOUNDATION_FOUND AND POCO_UTIL_FOUND)
        set(Poco_FOUND TRUE)
        message(STATUS "Poco found manually. Include dirs: ${POCO_INCLUDE_DIRS}, Libraries: ${POCO_LIBRARIES}")
    else()
        set(Poco_FOUND FALSE)
        message(WARNING "Poco essential components (Foundation, Util) not found.")
    endif()
endif()

# Set standard CMake variables
find_package_handle_standard_args(Poco DEFAULT_MSG POCO_FOUND POCO_INCLUDE_DIRS POCO_LIBRARIES)

# Define target-specific variables for components
foreach(component ${POCO_COMPONENTS})
    string(TOUPPER ${component} COMPONENT_UPPER)
    if(POCO_${COMPONENT_UPPER}_FOUND)
        set(Poco_${component}_FOUND TRUE)
        set(Poco_${component}_LIBRARY ${POCO_${COMPONENT_UPPER}_LIBRARY})
        set(Poco_${component}_INCLUDE_DIR ${POCO_${COMPONENT_UPPER}_INCLUDE_DIR})
    endif()
endforeach()
