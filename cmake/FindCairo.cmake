find_package(PkgConfig)
pkg_check_modules(PC_CAIRO QUIET cairo)

find_path(CAIRO_INCLUDE_DIRS
    NAMES cairo.h
    HINTS ${PC_CAIRO_INCLUDEDIR}
          ${PC_CAIRO_INCLUDE_DIRS}
    PATH_SUFFIXES cairo
)

find_library(CAIRO_LIBRARIES
    NAMES cairo
    HINTS ${PC_CAIRO_LIBDIR}
          ${PC_CAIRO_LIBRARY_DIRS}
)
find_library(CAIRO_LIBRARIES_DEBUG
    NAMES cairod
    HINTS ${PC_CAIRO_LIBDIR}
          ${PC_CAIRO_LIBRARY_DIRS}
)

if (CAIRO_INCLUDE_DIRS)
    set(_CAIRO_PATH ${CAIRO_INCLUDE_DIRS})
    while(TRUE)
        get_filename_component(_CAIRO_PATH_PART ${_CAIRO_PATH} NAME)
        string(TOLOWER ${_CAIRO_PATH_PART} _CAIRO_PATH_PART)
        if (${_CAIRO_PATH_PART} STREQUAL "cairo" OR ${_CAIRO_PATH_PART} STREQUAL "include")
            get_filename_component(_CAIRO_PATH ${_CAIRO_PATH} DIRECTORY)
            continue()
        endif()
        if (NOT (${_CAIRO_PATH} STREQUAL ""))
            set(CAIRO_PATH ${_CAIRO_PATH})
            set(CAIRO_PATH ${CAIRO_PATH} PARENT_SCOPE)
        endif()
        break()
    endwhile()
endif()

find_file(CAIRO_DLL
    NAMES cairo.dll
    HINTS ${CAIRO_PATH}
    PATH_SUFFIXES bin
)
find_file(CAIRO_DLL_DEBUG
    NAMES cairod.dll
    HINTS ${CAIRO_PATH}
    PATH_SUFFIXES debug/bin
)

if (CAIRO_INCLUDE_DIRS)
    if (EXISTS "${CAIRO_INCLUDE_DIRS}/cairo-version.h")
        file(READ "${CAIRO_INCLUDE_DIRS}/cairo-version.h" CAIRO_VERSION_CONTENT)

        string(REGEX MATCH "#define +CAIRO_VERSION_MAJOR +([0-9]+)" _dummy "${CAIRO_VERSION_CONTENT}")
        set(CAIRO_VERSION_MAJOR "${CMAKE_MATCH_1}")

        string(REGEX MATCH "#define +CAIRO_VERSION_MINOR +([0-9]+)" _dummy "${CAIRO_VERSION_CONTENT}")
        set(CAIRO_VERSION_MINOR "${CMAKE_MATCH_1}")

        string(REGEX MATCH "#define +CAIRO_VERSION_MICRO +([0-9]+)" _dummy "${CAIRO_VERSION_CONTENT}")
        set(CAIRO_VERSION_MICRO "${CMAKE_MATCH_1}")

        set(CAIRO_VERSION "${CAIRO_VERSION_MAJOR}.${CAIRO_VERSION_MINOR}.${CAIRO_VERSION_MICRO}")
    endif ()
endif ()

if ("${Cairo_FIND_VERSION}" VERSION_GREATER "${CAIRO_VERSION}")
    message(FATAL_ERROR "Required version (" ${Cairo_FIND_VERSION} ") is higher than found version (" ${CAIRO_VERSION} ")")
endif ()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Cairo REQUIRED_VARS CAIRO_INCLUDE_DIRS CAIRO_LIBRARIES
                                        VERSION_VAR CAIRO_VERSION)

mark_as_advanced(
    CAIRO_INCLUDE_DIRS
    CAIRO_LIBRARIES
    CAIRO_LIBRARIES_DEBUG
)

# Create CMake targets
if (CAIRO_FOUND AND NOT TARGET Cairo::Cairo)
    if (CAIRO_DLL)
        # Not using 'SHARED' when Cairo is available through a .dll can
        # cause build issues with MSVC, at least when trying to link against
        # a vcpkg-provided copy of "cairod".
        add_library(Cairo::Cairo SHARED IMPORTED)
    else()
        add_library(Cairo::Cairo UNKNOWN IMPORTED)
    endif()

    set_target_properties(Cairo::Cairo PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
        INTERFACE_INCLUDE_DIRECTORIES ${CAIRO_INCLUDE_DIRS}
    )

    if(CAIRO_DLL)
        # When using a .dll, the location of *both( the .dll file, and its .lib,
        # needs to be specified to CMake.  The path to the .dll goes into
        # IMPORTED_LOCATION(_*), whereas the path to the .lib goes into
        # IMPORTED_IMPLIB(_*).
        set_target_properties(Cairo::Cairo PROPERTIES
            IMPORTED_LOCATION ${CAIRO_DLL}
            IMPORTED_IMPLIB ${CAIRO_LIBRARIES}
        )
        if (CAIRO_DLL_DEBUG)
            set_target_properties(Cairo::Cairo PROPERTIES
                IMPORTED_LOCATION_DEBUG ${CAIRO_DLL_DEBUG}
            )
        endif()
        if (CAIRO_LIBRARIES_DEBUG)
            set_target_properties(Cairo::Cairo PROPERTIES
                IMPORTED_IMPLIB_DEBUG ${CAIRO_LIBRARIES_DEBUG}
            )
        endif()
    else()
        set_target_properties(Cairo::Cairo PROPERTIES
            IMPORTED_LOCATION ${CAIRO_LIBRARIES}
        )
        if (CAIRO_LIBRARIES_DEBUG)
            set_target_properties(Cairo::Cairo PROPERTIES
                IMPORTED_LOCATION_DEBUG ${CAIRO_LIBRARIES_DEBUG}
            )
        endif()
    endif()
endif()
