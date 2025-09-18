include(FetchContent)

# Disable tests, examples, docs to avoid target collisions
set(lager_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(lager_BUILD_FAILURE_TESTS OFF CACHE BOOL "" FORCE)
set(lager_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(lager_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(immer_BUILD_EXTRAS OFF CACHE BOOL "" FORCE)

if(NOT Lager_FOUND)
  message(STATUS "Fetching Lager library via FetchContent")
  FetchContent_Declare(
    lager
    GIT_REPOSITORY https://github.com/arximboldi/lager.git
    GIT_TAG master
  )
  FetchContent_MakeAvailable(lager)
endif()

set(Lager_FOUND TRUE CACHE BOOL "Lager found via FetchContent")
set(Lager_INCLUDE_DIRS ${lager_SOURCE_DIR}/include)
set(Lager_LIBRARIES lager)
