# FindLibunibreak.cmake - Builds libunibreak from source if not found or version is too old

include(ExternalProject)

function(build_libunibreak_if_needed)
    # First try to find system libunibreak
    find_package(libunibreak 5.0 QUIET)
    
    if(NOT libunibreak_FOUND)
        message(STATUS "libunibreak >= 5.0 not found, building from source...")
        
        # Define paths
        set(LIBUNIBREAK_SOURCE_DIR ${CMAKE_BINARY_DIR}/libunibreak-src)
        set(LIBUNIBREAK_BUILD_DIR ${CMAKE_BINARY_DIR}/libunibreak-build)
        set(LIBUNIBREAK_INSTALL_DIR ${CMAKE_BINARY_DIR}/libunibreak-install)
        
        # Use ExternalProject to clone and build libunibreak
        ExternalProject_Add(libunibreak_external
            GIT_REPOSITORY https://github.com/adah1972/libunibreak.git
            GIT_TAG v6.1.0
            SOURCE_DIR ${LIBUNIBREAK_SOURCE_DIR}
            BINARY_DIR ${LIBUNIBREAK_BUILD_DIR}
            CONFIGURE_COMMAND ""
            BUILD_COMMAND
                COMMAND ${CMAKE_COMMAND} -E chdir ${LIBUNIBREAK_SOURCE_DIR}/src
                        cp -p Makefile.gcc Makefile
                COMMAND ${CMAKE_COMMAND} -E chdir ${LIBUNIBREAK_SOURCE_DIR}/src
                        make release
            INSTALL_COMMAND
                # Install static library
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${LIBUNIBREAK_SOURCE_DIR}/src/ReleaseDir/libunibreak.a
                        ${CMAKE_INSTALL_PREFIX}/lib/libunibreak.a
                # Install headers
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                        ${LIBUNIBREAK_SOURCE_DIR}/src
                        ${CMAKE_INSTALL_PREFIX}/include
                # Create and install pkg-config file
                COMMAND ${CMAKE_COMMAND} -E copy
                        ${LIBUNIBREAK_SOURCE_DIR}/libunibreak.pc.in
                        ${CMAKE_BINARY_DIR}/libunibreak.pc.tmp
                COMMAND sed -e "s|@prefix@|${CMAKE_INSTALL_PREFIX}|" 
                           -e "s|@VERSION@|6.1.0|"
                           ${CMAKE_BINARY_DIR}/libunibreak.pc.tmp > 
                           ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig/libunibreak.pc
                COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/libunibreak.pc.tmp
            BUILD_ALWAYS FALSE
            INSTALL_DIR ${CMAKE_INSTALL_PREFIX}
        )
        
        # Set variables for downstream use
        set(libunibreak_FOUND TRUE PARENT_SCOPE)
        set(libunibreak_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include PARENT_SCOPE)
        set(libunibreak_LIBRARIES ${CMAKE_INSTALL_PREFIX}/lib/libunibreak.a PARENT_SCOPE)
        set(libunibreak_VERSION "6.1.0" PARENT_SCOPE)
        
        # Create imported target
        add_library(libunibreak::libunibreak STATIC IMPORTED GLOBAL)
        set_target_properties(libunibreak::libunibreak PROPERTIES
            IMPORTED_LOCATION ${CMAKE_INSTALL_PREFIX}/lib/libunibreak.a
            INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_INSTALL_PREFIX}/include
        )
        add_dependencies(libunibreak::libunibreak libunibreak_external)
        
        message(STATUS "libunibreak will be built from source")
    else()
        message(STATUS "Found system libunibreak: ${libunibreak_VERSION}")
    endif()
endfunction()
