cmake_minimum_required(VERSION 3.18)
project(wop_gpu_runtime LANGUAGES CXX)

option(WOP_ENABLE_CUDA "Enable CUDA kernels" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(wop_gpu_runtime STATIC
    wop_gpu_runtime.cpp
)

if (WOP_ENABLE_CUDA)
  enable_language(CUDA)
  add_library(wop_gpu_kernels STATIC wop_gpu_kernels.cu)
  set_target_properties(wop_gpu_kernels PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
  target_link_libraries(wop_gpu_runtime PRIVATE wop_gpu_kernels)
endif()

target_include_directories(wop_gpu_runtime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/../..//OpenSSD/Micron_NAND/daisyplus_openssd_micron_4c2w_ns/cosm-plus-sys/cosm-plus-sys.sdk/run-gr3ftl/src/nvme)

add_executable(wop_gpu_daemon main.cpp)
target_link_libraries(wop_gpu_daemon PRIVATE wop_gpu_runtime)

