cmake_minimum_required(VERSION 3.25)

# ── N-API addon target ───────────────────────────────────────────────────────
# This is designed to be invoked via cmake-js, which provides:
#   CMAKE_JS_INC  — Node/N-API include directories
#   CMAKE_JS_LIB  — (Windows only) node import library
#   CMAKE_JS_SRC  — (optional) additional sources

add_library(agent_core_napi MODULE
    agent_core_napi.cpp
)

set_target_properties(agent_core_napi PROPERTIES
    PREFIX ""
    SUFFIX ".node"
    CXX_STANDARD 23
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)

set(AGENT_CORE_NODE_INCLUDE_DIRS ${CMAKE_JS_INC})
if(NOT AGENT_CORE_NODE_INCLUDE_DIRS)
    execute_process(
        COMMAND node -p "process.execPath"
        OUTPUT_VARIABLE AGENT_CORE_NODE_EXECUTABLE
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(AGENT_CORE_NODE_EXECUTABLE)
        get_filename_component(AGENT_CORE_NODE_BIN_DIR "${AGENT_CORE_NODE_EXECUTABLE}" DIRECTORY)
        get_filename_component(AGENT_CORE_NODE_ROOT_DIR "${AGENT_CORE_NODE_BIN_DIR}/.." ABSOLUTE)
        if(EXISTS "${AGENT_CORE_NODE_ROOT_DIR}/include/node/node_api.h")
            list(APPEND AGENT_CORE_NODE_INCLUDE_DIRS "${AGENT_CORE_NODE_ROOT_DIR}/include/node")
        endif()
    endif()
endif()

if(NOT AGENT_CORE_NODE_INCLUDE_DIRS)
    message(FATAL_ERROR "Node headers not found. Set CMAKE_JS_INC or install Node headers.")
endif()

target_include_directories(agent_core_napi PRIVATE
    ${AGENT_CORE_NODE_INCLUDE_DIRS}
)

target_link_libraries(agent_core_napi PRIVATE
    agent_core
    ${CMAKE_JS_LIB}
)

if(NOT CMAKE_JS_LIB AND APPLE)
    target_link_options(agent_core_napi PRIVATE
        "-undefined"
        "dynamic_lookup"
    )
endif()

if(BUILD_TESTING)
    add_test(
        NAME agent_core_node_memory_smoke
        COMMAND node ${CMAKE_CURRENT_SOURCE_DIR}/tests/memory_smoke.js $<TARGET_FILE:agent_core_napi>
    )
endif()
