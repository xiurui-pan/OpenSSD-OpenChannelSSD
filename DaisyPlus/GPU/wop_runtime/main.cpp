#include "wop_gpu_runtime.hpp"

#include <iostream>

int main(int argc, char **argv) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <doorbell_fifo> <dram_img>\n";
        return 1;
    }

    WopGpuConfig cfg;
    cfg.doorbell_path = argv[1];
    cfg.dram_path = argv[2];
    cfg.enable_cuda = false;

    try {
        WopGpuRuntime runtime(cfg);
        while (true) {
            runtime.run_once();
        }
    } catch (const std::exception &ex) {
        std::cerr << "[WOP-GPU] runtime error: " << ex.what() << "\n";
        return 1;
    }
    return 0;
}
