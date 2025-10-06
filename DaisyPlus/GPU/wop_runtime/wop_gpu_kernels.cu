#include <cuda_runtime.h>

extern "C" __global__ void wop_memcpy_kernel(const uint32_t *src, uint32_t *dst, size_t words) {
    size_t idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < words) {
        dst[idx] = src[idx];
    }
}

