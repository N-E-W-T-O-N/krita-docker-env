include(FetchContent)

set(zug_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(zug_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(zug_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(zug_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(zug_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(zug_BUILD_DOCS OFF CACHE BOOL "" FORCE)
if(NOT Zug_FOUND)
  message(STATUS "Fetching Zug library via FetchContent")
  FetchContent_Declare(
    zug
    GIT_REPOSITORY https://github.com/arximboldi/zug.git
    GIT_TAG master
  )
  FetchContent_MakeAvailable(zug)
endif()

set(Zug_FOUND TRUE CACHE BOOL "Zug found via FetchContent")
set(Zug_INCLUDE_DIRS ${zug_SOURCE_DIR}/include)
set(Zug_LIBRARIES zug)