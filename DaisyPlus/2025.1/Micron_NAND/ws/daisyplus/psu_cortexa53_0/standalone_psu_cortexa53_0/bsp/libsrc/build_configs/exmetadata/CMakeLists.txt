
cmake_minimum_required(VERSION 3.15)
project(bsp)

# Use CMAKE_LIBRARY_PATH in link_directories
link_directories(${CMAKE_LIBRARY_PATH})
        
set(DRIVER_TARGETS bram;scugic;zdma;sysmonpsu;axipmon;coresightps_dcc;resetps;clockps;csudma;ddrcpsu;emacps;gpiops;iicps;ipipsu;qspipsu;rtcpsu;sdps;uartps)
set(DRIVER_LOCATIONS D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/bram_v4_12;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/scugic_v5_5;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/zdma_v1_20;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/sysmonpsu_v3_1;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/axipmon_v6_12;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/coresightps_dcc_v1_12;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/resetps_v1_7;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/clockps_v1_6;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/csudma_v1_17;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/ddrcpsu_v1_8;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/emacps_v3_22;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/gpiops_v3_14;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/iicps_v3_21;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/ipipsu_v2_17;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/qspipsu_v1_21;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/rtcpsu_v1_15;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/sdps_v4_4;D:/Xilinx/2025.1/Vitis/data/embeddedsw/XilinxProcessorIPLib/drivers/uartps_v3_16)

list(LENGTH DRIVER_TARGETS no_of_drivers)
set(index 0)

while(${index} LESS ${no_of_drivers})
    list(GET DRIVER_TARGETS ${index} drv)
    list(GET DRIVER_LOCATIONS ${index} drv_dir)
    set(exp_dir "${drv_dir}/examples")
    add_custom_target(
        ${drv}_example ALL
        COMMAND lopper -f -O D:/sources/workspace/daisyplus_openssd_micron/daisyplus/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp/libsrc/${drv} D:/sources/workspace/daisyplus_openssd_micron/daisyplus/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp/hw_artifacts/psu_cortexa53_0_baremetal.dts -- bmcmake_metadata_xlnx psu_cortexa53_0 ${exp_dir} drvcmake_metadata
        BYPRODUCTS x${drv}_exlist.yaml)
    MATH(EXPR index "${index}+1")
endwhile()
