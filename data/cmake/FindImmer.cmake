include(FetchContent)

set(immer_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(IMMER_BUILD_TESTS OFF CACHE BOOL "" FORCE)  

# Immer
if(NOT Immer_FOUND)
  message(STATUS "Fetching Immer library via FetchContent")

  FetchContent_Declare(
    immer
    GIT_REPOSITORY https://github.com/arximboldi/immer.git
    GIT_TAG master
  )
  FetchContent_MakeAvailable(immer)
endif()

set(Immer_FOUND TRUE CACHE BOOL "Immer found via FetchContent")
set(Immer_INCLUDE_DIRS ${immer_SOURCE_DIR}/include)
set(Immer_LIBRARIES immer)