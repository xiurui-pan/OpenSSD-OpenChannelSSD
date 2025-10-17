
################################################################
# This is a generated script based on design: sys_top
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

if {![namespace exists ::common]} {
  namespace eval ::common {}
}
if {[info commands ::common::send_gid_msg] eq ""} {
  proc ::common::send_gid_msg {args} {
    # Vivado 2019.1 lacks this helper; silently ignore.
    return
  }
}

# Helper: sanitize double underscores in requested net names before wiring.
proc connect_net_sanitized {net args} {
  set sanitized [string map {"__" "_"} $net]
  uplevel 1 [list connect_bd_net -net $sanitized {*}$args]
}

# Downgrade known benign diagnostics for Vivado 2019.1 replay.
catch { set_msg_config -id {BD 41-237} -new_severity {WARNING} }
catch { set_msg_config -id {xilinx.com:ip:smartconnect:1.0-1} -new_severity {WARNING} }
catch { set_msg_config -id {BD 41-1276} -new_severity {WARNING} }


################################################################
# NOTE: Original script generated under Vivado 2024.2.
# Version gating removed to permit replay with Vivado 2019.1.
################################################################

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source sys_top_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu17eg-ffvc1760-2-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name sys_top

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 0
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:zynq_ultra_ps_e:3.3\
xilinx.com:ip:axi_bram_ctrl:4.1\
enclab:user:bch_sccs_256B_21B_13b:1.0.0\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
enclab:user:t4nfc_hlper:1.0.2\
enclab:user:bch_skes_256B_21B_13b:1.0.2\
ENCLab:user:iodelay_if:1.0.0\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:smartconnect:1.0\
enclab:user:v2nfc:1.4.1\
crztech:user:nvme_ctrl:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create interface ports
  set nand_if_0 [ create_bd_intf_port -mode Master -vlnv enclab:user:nand_if_rtl:1.0 nand_if_0 ]

  set nand_if_1 [ create_bd_intf_port -mode Master -vlnv enclab:user:nand_if_rtl:1.0 nand_if_1 ]

  set nand_if_2 [ create_bd_intf_port -mode Master -vlnv enclab:user:nand_if_rtl:1.0 nand_if_2 ]

  set nand_if_3 [ create_bd_intf_port -mode Master -vlnv enclab:user:nand_if_rtl:1.0 nand_if_3 ]

  set pci_exp_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp_0 ]

  set pcie_ref [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_ref ]


  # Create ports
  set user_lnk_up_0 [ create_bd_port -dir O user_lnk_up_0 ]
  set pcie_perst_n [ create_bd_port -dir I -type rst pcie_perst_n ]

  # Create instance: zynq_ultra_ps_e_0, and set properties
  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0 ]
  set_property -dict [list \
    CONFIG.PSU_DDR_RAM_HIGHADDR {0x7FFFFFFF} \
    CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x00000002} \
    CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
    CONFIG.PSU_MIO_1_DRIVE_STRENGTH {12} \
    CONFIG.PSU_MIO_1_SLEW {fast} \
    CONFIG.PSU_MIO_4_INPUT_TYPE {cmos} \
    CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash##Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad\
SPI Flash##I2C 0#I2C 0#I2C 1#I2C 1#UART 0#UART 0#UART 1#UART 1########################SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#############Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem\
3#MDIO 3#MDIO 3} \
    CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out##n_ss_out_upper#mo_upper[0]#mo_upper[1]#mo_upper[2]#mo_upper[3]#sclk_out_upper##scl_out#sda_out#scl_out#sda_out#rxd#txd#txd#rxd########################sdio1_cd_n#sdio1_data_out[0]#sdio1_data_out[1]#sdio1_data_out[2]#sdio1_data_out[3]#sdio1_cmd_out#sdio1_clk_out#############rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem3_mdc#gem3_mdio_out}\
\
    CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {4} \
    CONFIG.PSU__ACT_DDR_FREQ_MHZ {799.992004} \
    CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1333.320068} \
    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {399.996002} \
    CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1066} \
    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {599.994019} \
    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {599.994019} \
    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {599.994019} \
    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {533.328003} \
    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {499.994995} \
    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {49.999500} \
    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.994995} \
    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1499.984985} \
    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__ACT_FREQMHZ {124.998749} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {499.994995} \
    CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.498123} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {49.999500} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {50} \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {199.998001} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {DPLL} \
    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__ACT_FREQMHZ {199.998001} \
    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__FREQMHZ {200} \
    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__ACT_FREQMHZ {249.997498} \
    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__FREQMHZ {250} \
    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__SRCSEL {RPLL} \
    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {299.997009} \
    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {199.998001} \
    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {33.333000} \
    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__ACT_FREQMHZ {99.999001} \
    CONFIG.PSU__DDRC__ADDR_MIRROR {1} \
    CONFIG.PSU__DDRC__BUS_WIDTH {32 Bit} \
    CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
    CONFIG.PSU__DDRC__DM_DBI {DM_NO_DBI} \
    CONFIG.PSU__DDRC__DQMAP_0_3 {0} \
    CONFIG.PSU__DDRC__DQMAP_12_15 {0} \
    CONFIG.PSU__DDRC__DQMAP_16_19 {0} \
    CONFIG.PSU__DDRC__DQMAP_20_23 {0} \
    CONFIG.PSU__DDRC__DQMAP_24_27 {0} \
    CONFIG.PSU__DDRC__DQMAP_28_31 {0} \
    CONFIG.PSU__DDRC__DQMAP_32_35 {0} \
    CONFIG.PSU__DDRC__DQMAP_36_39 {0} \
    CONFIG.PSU__DDRC__DQMAP_40_43 {0} \
    CONFIG.PSU__DDRC__DQMAP_44_47 {0} \
    CONFIG.PSU__DDRC__DQMAP_48_51 {0} \
    CONFIG.PSU__DDRC__DQMAP_4_7 {0} \
    CONFIG.PSU__DDRC__DQMAP_52_55 {0} \
    CONFIG.PSU__DDRC__DQMAP_56_59 {0} \
    CONFIG.PSU__DDRC__DQMAP_60_63 {0} \
    CONFIG.PSU__DDRC__DQMAP_64_67 {0} \
    CONFIG.PSU__DDRC__DQMAP_68_71 {0} \
    CONFIG.PSU__DDRC__DQMAP_8_11 {0} \
    CONFIG.PSU__DDRC__DRAM_WIDTH {32 Bits} \
    CONFIG.PSU__DDRC__ENABLE_LP4_HAS_ECC_COMP {0} \
    CONFIG.PSU__DDRC__ENABLE_LP4_SLOWBOOT {1} \
    CONFIG.PSU__DDRC__LPDDR4_T_REF_RANGE {Normal (0-85)} \
    CONFIG.PSU__DDRC__MEMORY_TYPE {LPDDR 4} \
    CONFIG.PSU__DDRC__RANK_ADDR_COUNT {1} \
    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {15} \
    CONFIG.PSU__DDRC__SPEED_BIN {LPDDR4_2133} \
    CONFIG.PSU__DDRC__T_FAW {40.0} \
    CONFIG.PSU__DDRC__T_RAS_MIN {42} \
    CONFIG.PSU__DDRC__T_RC {63} \
    CONFIG.PSU__DDRC__T_RCD {20} \
    CONFIG.PSU__DDRC__T_RP {23} \
    CONFIG.PSU__DDRC__VENDOR_PART {OTHERS} \
    CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {0} \
    CONFIG.PSU__DDR__INTERFACE__FREQMHZ {533.000} \
    CONFIG.PSU__DLL__ISUSED {1} \
    CONFIG.PSU__ENET3__FIFO__ENABLE {0} \
    CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
    CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
    CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
    CONFIG.PSU__ENET3__PTP__ENABLE {0} \
    CONFIG.PSU__ENET3__TSU__ENABLE {0} \
    CONFIG.PSU__FPGA_PL1_ENABLE {1} \
    CONFIG.PSU__FPGA_PL2_ENABLE {1} \
    CONFIG.PSU__FPGA_PL3_ENABLE {1} \
    CONFIG.PSU__GEM3_COHERENCY {0} \
    CONFIG.PSU__GEM3_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__GEM__TSU__ENABLE {0} \
    CONFIG.PSU__GPIO_EMIO__WIDTH {[91:0]} \
    CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 14 .. 15} \
    CONFIG.PSU__I2C1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__I2C1__PERIPHERAL__IO {MIO 16 .. 17} \
    CONFIG.PSU__MAXIGP0__DATA_WIDTH {64} \
    CONFIG.PSU__MAXIGP1__DATA_WIDTH {64} \
    CONFIG.PSU__NUM_FABRIC_RESETS {4} \
    CONFIG.PSU__PL_CLK1_BUF {TRUE} \
    CONFIG.PSU__PL_CLK2_BUF {TRUE} \
    CONFIG.PSU__PL_CLK3_BUF {TRUE} \
    CONFIG.PSU__PROTECTION__FPD_SEGMENTS {SA:0xFD1A0000; SIZE:1280; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware |  SA:0xFD000000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write;\
subsystemId:PMU Firmware |  SA:0xFD010000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware |  SA:0xFD020000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU\
Firmware |  SA:0xFD030000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware |  SA:0xFD040000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware\
|  SA:0xFD050000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware |  SA:0xFD610000; SIZE:512; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware\
|  SA:0xFD5D0000; SIZE:64; UNIT:KB; RegionTZ:Secure; WrAllowed:Read/Write; subsystemId:PMU Firmware | SA:0xFD1A0000 ; SIZE:1280; UNIT:KB; RegionTZ:Secure ; WrAllowed:Read/Write; subsystemId:Secure Subsystem}\
\
    CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;0|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;1|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;0|SATA1:NonSecure;0|SATA0:NonSecure;0|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;0|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;1|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;0|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1}\
\
    CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;0|LPD;USB3_1;FF9E0000;FF9EFFFF;0|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;0|LPD;USB3_0;FF9D0000;FF9DFFFF;0|LPD;UART1;FF010000;FF01FFFF;1|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;0|LPD;TTC2;FF130000;FF13FFFF;0|LPD;TTC1;FF120000;FF12FFFF;0|LPD;TTC0;FF110000;FF11FFFF;0|FPD;SWDT1;FD4D0000;FD4DFFFF;0|LPD;SWDT0;FF150000;FF15FFFF;0|LPD;SPI1;FF050000;FF05FFFF;0|LPD;SPI0;FF040000;FF04FFFF;0|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;1|LPD;SD0;FF160000;FF16FFFF;0|FPD;SATA;FD0C0000;FD0CFFFF;0|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;0|FPD;PCIE_LOW;E0000000;EFFFFFFF;0|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;0|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;0|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;0|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;0|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;1|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;1|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;1|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;0|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display\
Port;FD4A0000;FD4AFFFF;0|FPD;DPDMA;FD4C0000;FD4CFFFF;0|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;800000000;0|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;1|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;0|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1}\
\
    CONFIG.PSU__QSPI_COHERENCY {0} \
    CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {0} \
    CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
    CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 12} \
    CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
    CONFIG.PSU__SAXIGP2__DATA_WIDTH {64} \
    CONFIG.PSU__SAXIGP3__DATA_WIDTH {64} \
    CONFIG.PSU__SD1_COHERENCY {0} \
    CONFIG.PSU__SD1_ROUTE_THROUGH_FPD {0} \
    CONFIG.PSU__SD1__DATA_TRANSFER_MODE {4Bit} \
    CONFIG.PSU__SD1__GRP_CD__ENABLE {1} \
    CONFIG.PSU__SD1__GRP_CD__IO {MIO 45} \
    CONFIG.PSU__SD1__GRP_POW__ENABLE {0} \
    CONFIG.PSU__SD1__GRP_WP__ENABLE {0} \
    CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 46 .. 51} \
    CONFIG.PSU__SD1__SLOT_TYPE {SD 2.0} \
    CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
    CONFIG.PSU__UART0__BAUD_RATE {115200} \
    CONFIG.PSU__UART0__MODEM__ENABLE {0} \
    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 18 .. 19} \
    CONFIG.PSU__UART1__BAUD_RATE {115200} \
    CONFIG.PSU__UART1__MODEM__ENABLE {0} \
    CONFIG.PSU__UART1__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__UART1__PERIPHERAL__IO {MIO 20 .. 21} \
    CONFIG.PSU__USE__IRQ0 {1} \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__USE__M_AXI_GP1 {1} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__USE__S_AXI_GP2 {1} \
    CONFIG.PSU__USE__S_AXI_GP3 {1} \
    CONFIG.PSU__USE__S_AXI_GP4 {0} \
    CONFIG.SUBPRESET1 {Custom} \
  ] $zynq_ultra_ps_e_0


  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_0


  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_1


  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_2 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_2


  # Create instance: axi_bram_ctrl_3, and set properties
  set axi_bram_ctrl_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_3 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_3


  # Create instance: bch_sccs_256B_21B_13b_0, and set properties
  set bch_sccs_256B_21B_13b_0 [ create_bd_cell -type ip -vlnv enclab:user:bch_sccs_256B_21B_13b:1.0.0 bch_sccs_256B_21B_13b_0 ]

  # Create instance: bch_sccs_256B_21B_13b_1, and set properties
  set bch_sccs_256B_21B_13b_1 [ create_bd_cell -type ip -vlnv enclab:user:bch_sccs_256B_21B_13b:1.0.0 bch_sccs_256B_21B_13b_1 ]

  # Create instance: bch_sccs_256B_21B_13b_2, and set properties
  set bch_sccs_256B_21B_13b_2 [ create_bd_cell -type ip -vlnv enclab:user:bch_sccs_256B_21B_13b:1.0.0 bch_sccs_256B_21B_13b_2 ]

  # Create instance: bch_sccs_256B_21B_13b_3, and set properties
  set bch_sccs_256B_21B_13b_3 [ create_bd_cell -type ip -vlnv enclab:user:bch_sccs_256B_21B_13b:1.0.0 bch_sccs_256B_21B_13b_3 ]

  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.EN_SAFETY_CKT {false} \
    CONFIG.Enable_32bit_Address {true} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_RSTA_Pin {true} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.Write_Depth_A {2048} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_0


  # Create instance: blk_mem_gen_1, and set properties
  set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_1 ]
  set_property -dict [list \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.EN_SAFETY_CKT {false} \
    CONFIG.Enable_32bit_Address {true} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_RSTA_Pin {true} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.Write_Depth_A {2048} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_1


  # Create instance: blk_mem_gen_2, and set properties
  set blk_mem_gen_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_2 ]
  set_property -dict [list \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.EN_SAFETY_CKT {false} \
    CONFIG.Enable_32bit_Address {true} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_RSTA_Pin {true} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.Write_Depth_A {2048} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_2


  # Create instance: blk_mem_gen_3, and set properties
  set blk_mem_gen_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_3 ]
  set_property -dict [list \
    CONFIG.Assume_Synchronous_Clk {true} \
    CONFIG.EN_SAFETY_CKT {false} \
    CONFIG.Enable_32bit_Address {true} \
    CONFIG.Enable_B {Use_ENB_Pin} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Port_B_Clock {100} \
    CONFIG.Port_B_Enable_Rate {100} \
    CONFIG.Port_B_Write_Rate {50} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_RSTA_Pin {true} \
    CONFIG.Use_RSTB_Pin {true} \
    CONFIG.Write_Depth_A {2048} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_3


  # Create instance: gpic_0, and set properties
  set gpic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 gpic_0 ]
  set_property -dict [list \
    CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
    CONFIG.NUM_MI {1} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.STRATEGY {0} \
  ] $gpic_0


  # Create instance: gpic_0_sub_0, and set properties
  set gpic_0_sub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 gpic_0_sub_0 ]
  set_property -dict [list \
    CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
    CONFIG.NUM_MI {8} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.STRATEGY {2} \
  ] $gpic_0_sub_0


  # Create instance: gpic_1, and set properties
  set gpic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 gpic_1 ]
  set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.STRATEGY {0} \
  ] $gpic_1


  # Create instance: gpic_0_sub, and set properties
  set gpic_0_sub [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 gpic_0_sub ]
  set_property -dict [list \
    CONFIG.NUM_MI {2} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.STRATEGY {0} \
  ] $gpic_0_sub


  # Create instance: hpic_0, and set properties
  set hpic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 hpic_0 ]
  set_property -dict [list \
    CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
    CONFIG.M00_HAS_DATA_FIFO {0} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {4} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.S00_HAS_REGSLICE {4} \
    CONFIG.S01_HAS_DATA_FIFO {2} \
    CONFIG.S01_HAS_REGSLICE {4} \
    CONFIG.S02_HAS_DATA_FIFO {2} \
    CONFIG.S02_HAS_REGSLICE {4} \
    CONFIG.S03_HAS_DATA_FIFO {2} \
    CONFIG.S03_HAS_REGSLICE {4} \
    CONFIG.STRATEGY {2} \
    CONFIG.SYNCHRONIZATION_STAGES {4} \
    CONFIG.XBAR_DATA_WIDTH {64} \
  ] $hpic_0


  # Create instance: pll_bank11, and set properties
  set pll_bank11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 pll_bank11 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {200.0} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {139.132} \
    CONFIG.CLKOUT1_PHASE_ERROR {154.682} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
    CONFIG.CLKOUT1_REQUESTED_PHASE {0} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {163.701} \
    CONFIG.CLKOUT2_PHASE_ERROR {154.682} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT3_JITTER {124.137} \
    CONFIG.CLKOUT3_PHASE_ERROR {154.682} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.JITTER_SEL {No_Jitter} \
    CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {24.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} \
    CONFIG.MMCM_CLKOUT0_PHASE {0.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {24} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {6} \
    CONFIG.MMCM_COMPENSATION {AUTO} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PHASESHIFT_MODE {LATENCY} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {true} \
  ] $pll_bank11


  # Create instance: pll_bank12, and set properties
  set pll_bank12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 pll_bank12 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {200.0} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {106.955} \
    CONFIG.CLKOUT1_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {118.642} \
    CONFIG.CLKOUT2_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT3_JITTER {96.669} \
    CONFIG.CLKOUT3_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {32.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {16.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {32} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {8} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {true} \
  ] $pll_bank12


  # Create instance: pll_bank13, and set properties
  set pll_bank13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 pll_bank13 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {200.0} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {106.955} \
    CONFIG.CLKOUT1_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {118.642} \
    CONFIG.CLKOUT2_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT3_JITTER {96.669} \
    CONFIG.CLKOUT3_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {32.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {16.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {32} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {8} \
    CONFIG.MMCM_DIVCLK_DIVIDE {1} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {true} \
  ] $pll_bank13


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_2, and set properties
  set proc_sys_reset_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_2 ]

  # Create instance: t4nfc_hlper_0, and set properties
  set t4nfc_hlper_0 [ create_bd_cell -type ip -vlnv enclab:user:t4nfc_hlper:1.0.2 t4nfc_hlper_0 ]

  # Create instance: t4nfc_hlper_1, and set properties
  set t4nfc_hlper_1 [ create_bd_cell -type ip -vlnv enclab:user:t4nfc_hlper:1.0.2 t4nfc_hlper_1 ]

  # Create instance: t4nfc_hlper_2, and set properties
  set t4nfc_hlper_2 [ create_bd_cell -type ip -vlnv enclab:user:t4nfc_hlper:1.0.2 t4nfc_hlper_2 ]

  # Create instance: t4nfc_hlper_3, and set properties
  set t4nfc_hlper_3 [ create_bd_cell -type ip -vlnv enclab:user:t4nfc_hlper:1.0.2 t4nfc_hlper_3 ]

  # Create instance: bch_skes_256B_21B_13b_0, and set properties
  set bch_skes_256B_21B_13b_0 [ create_bd_cell -type ip -vlnv enclab:user:bch_skes_256B_21B_13b:1.0.2 bch_skes_256B_21B_13b_0 ]

  # Create instance: iodelay_if_0, and set properties
  set iodelay_if_0 [ create_bd_cell -type ip -vlnv ENCLab:user:iodelay_if:1.0.0 iodelay_if_0 ]

  # Create instance: iodelay_if_0_dqs, and set properties
  set iodelay_if_0_dqs [ create_bd_cell -type ip -vlnv ENCLab:user:iodelay_if:1.0.0 iodelay_if_0_dqs ]

  # Create instance: pll_bank13_psr, and set properties
  set pll_bank13_psr [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pll_bank13_psr ]

  # Create instance: pll_bank11_psr, and set properties
  set pll_bank11_psr [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pll_bank11_psr ]

  # Create instance: pll_bank12_psr, and set properties
  set pll_bank12_psr [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pll_bank12_psr ]

  # Create instance: pll_bank10, and set properties
  set pll_bank10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 pll_bank10 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {200.0} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {106.955} \
    CONFIG.CLKOUT1_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100} \
    CONFIG.CLKOUT2_DRIVES {BUFG} \
    CONFIG.CLKOUT2_JITTER {118.642} \
    CONFIG.CLKOUT2_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {BUFG} \
    CONFIG.CLKOUT3_JITTER {96.669} \
    CONFIG.CLKOUT3_PHASE_ERROR {120.362} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {32.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {20.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {16.000} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {32} \
    CONFIG.MMCM_CLKOUT2_DIVIDE {8} \
    CONFIG.NUM_OUT_CLKS {3} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.USE_RESET {true} \
  ] $pll_bank10


  # Create instance: pll_bank10_psr, and set properties
  set pll_bank10_psr [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pll_bank10_psr ]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {1} $xlconcat_0


  # Create instance: smartconnect_0, and set properties
set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
set_property CONFIG.NUM_SI {1} $smartconnect_0


  # Create instance: proc_sys_reset_6, and set properties
  set proc_sys_reset_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_6 ]

  # Create instance: proc_sys_reset_7, and set properties
  set proc_sys_reset_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_7 ]

  # Create instance: v2nfc_0, and set properties
  set v2nfc_0 [ create_bd_cell -type ip -vlnv enclab:user:v2nfc:1.4.1 v2nfc_0 ]
  set_property -dict [list \
    CONFIG.BufferType {1} \
    CONFIG.DQIDelayInst {0} \
    CONFIG.DQIDelayValue {1100} \
    CONFIG.IDelayValue {1100} \
    CONFIG.InputClockBufferType {1} \
  ] $v2nfc_0


  # Create instance: v2nfc_1, and set properties
  set v2nfc_1 [ create_bd_cell -type ip -vlnv enclab:user:v2nfc:1.4.1 v2nfc_1 ]
  set_property -dict [list \
    CONFIG.DQIDelayInst {0} \
    CONFIG.DQIDelayValue {1100} \
    CONFIG.IDelayCtrlInst {1} \
    CONFIG.IDelayValue {1100} \
    CONFIG.InputClockBufferType {1} \
  ] $v2nfc_1


  # Create instance: v2nfc_2, and set properties
  set v2nfc_2 [ create_bd_cell -type ip -vlnv enclab:user:v2nfc:1.4.1 v2nfc_2 ]
  set_property -dict [list \
    CONFIG.DQIDelayInst {0} \
    CONFIG.DQIDelayValue {1100} \
    CONFIG.IDelayValue {1100} \
    CONFIG.InputClockBufferType {1} \
  ] $v2nfc_2


  # Create instance: v2nfc_3, and set properties
  set v2nfc_3 [ create_bd_cell -type ip -vlnv enclab:user:v2nfc:1.4.1 v2nfc_3 ]
  set_property -dict [list \
    CONFIG.BufferType {1} \
    CONFIG.DQIDelayInst {0} \
    CONFIG.DQIDelayValue {1100} \
    CONFIG.IDelayValue {1100} \
    CONFIG.InputClockBufferType {1} \
  ] $v2nfc_3


  # Create instance: nvme_ctrl_0, and set properties
  set nvme_ctrl_0 [ create_bd_cell -type ip -vlnv crztech:user:nvme_ctrl:1.0 nvme_ctrl_0 ]
  set_property -dict [list \
    CONFIG.C_PCIE_DATA_WIDTH {512} \
    CONFIG.C_S0_AXI_HIGHADDR {0xA000FFFF} \
  ] $nvme_ctrl_0


  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins gpic_1/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM1_FPD]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins hpic_0/S01_AXI] [get_bd_intf_pins t4nfc_hlper_1/nfch_data_if]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins hpic_0/S02_AXI] [get_bd_intf_pins t4nfc_hlper_2/nfch_data_if]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins hpic_0/S03_AXI] [get_bd_intf_pins t4nfc_hlper_3/nfch_data_if]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_2/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_2/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_bram_ctrl_3_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_3/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_3/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins gpic_0/M00_AXI] [get_bd_intf_pins gpic_0_sub_0/S00_AXI]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_0_bch_skes_if [get_bd_intf_pins bch_sccs_256B_21B_13b_0/bch_skes_if] [get_bd_intf_pins bch_skes_256B_21B_13b_0/bch_skes_ch0_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_0_from_ecc_if [get_bd_intf_pins bch_sccs_256B_21B_13b_0/from_ecc_if] [get_bd_intf_pins t4nfc_hlper_0/from_ecc_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_1_bch_skes_if [get_bd_intf_pins bch_sccs_256B_21B_13b_1/bch_skes_if] [get_bd_intf_pins bch_skes_256B_21B_13b_0/bch_skes_ch1_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_1_from_ecc_if [get_bd_intf_pins bch_sccs_256B_21B_13b_1/from_ecc_if] [get_bd_intf_pins t4nfc_hlper_1/from_ecc_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_2_bch_skes_if [get_bd_intf_pins bch_sccs_256B_21B_13b_2/bch_skes_if] [get_bd_intf_pins bch_skes_256B_21B_13b_0/bch_skes_ch2_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_2_from_ecc_if [get_bd_intf_pins t4nfc_hlper_2/from_ecc_if] [get_bd_intf_pins bch_sccs_256B_21B_13b_2/from_ecc_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_3_bch_skes_if [get_bd_intf_pins bch_sccs_256B_21B_13b_3/bch_skes_if] [get_bd_intf_pins bch_skes_256B_21B_13b_0/bch_skes_ch3_if]
  connect_bd_intf_net -intf_net bch_sccs_256B_21B_13b_3_from_ecc_if [get_bd_intf_pins t4nfc_hlper_3/from_ecc_if] [get_bd_intf_pins bch_sccs_256B_21B_13b_3/from_ecc_if]
  connect_bd_intf_net -intf_net gpic_0_M01_AXI [get_bd_intf_pins gpic_0_sub_0/M01_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net gpic_0_M03_AXI [get_bd_intf_pins gpic_0_sub_0/M03_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net gpic_0_M05_AXI [get_bd_intf_pins gpic_0_sub_0/M05_AXI] [get_bd_intf_pins axi_bram_ctrl_2/S_AXI]
  connect_bd_intf_net -intf_net gpic_0_M07_AXI [get_bd_intf_pins gpic_0_sub_0/M07_AXI] [get_bd_intf_pins axi_bram_ctrl_3/S_AXI]
  connect_bd_intf_net -intf_net gpic_0_sub_0_M00_AXI [get_bd_intf_pins t4nfc_hlper_0/nfch_cmd_if] [get_bd_intf_pins gpic_0_sub_0/M00_AXI]
  connect_bd_intf_net -intf_net gpic_0_sub_0_M02_AXI [get_bd_intf_pins t4nfc_hlper_1/nfch_cmd_if] [get_bd_intf_pins gpic_0_sub_0/M02_AXI]
  connect_bd_intf_net -intf_net gpic_0_sub_0_M04_AXI [get_bd_intf_pins t4nfc_hlper_2/nfch_cmd_if] [get_bd_intf_pins gpic_0_sub_0/M04_AXI]
  connect_bd_intf_net -intf_net gpic_0_sub_0_M06_AXI [get_bd_intf_pins gpic_0_sub_0/M06_AXI] [get_bd_intf_pins t4nfc_hlper_3/nfch_cmd_if]
  connect_bd_intf_net -intf_net gpic_0_sub_M00_AXI [get_bd_intf_pins gpic_0_sub/M00_AXI] [get_bd_intf_pins iodelay_if_0/ctrl__s]
  connect_bd_intf_net -intf_net gpic_0_sub_M01_AXI [get_bd_intf_pins gpic_0_sub/M01_AXI] [get_bd_intf_pins iodelay_if_0_dqs/ctrl__s]
  connect_bd_intf_net -intf_net gpic_1_M00_AXI [get_bd_intf_pins gpic_1/M00_AXI] [get_bd_intf_pins gpic_0_sub/S00_AXI]
  connect_bd_intf_net -intf_net gpic_1_M01_AXI [get_bd_intf_pins gpic_1/M01_AXI] [get_bd_intf_pins nvme_ctrl_0/s0_axi]
  connect_bd_intf_net -intf_net hpic_0_M00_AXI [get_bd_intf_pins hpic_0/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
  connect_bd_intf_net -intf_net nvme_ctrl_0_m0_axi [get_bd_intf_pins nvme_ctrl_0/m0_axi] [get_bd_intf_pins smartconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net nvme_ctrl_0_pci_exp [get_bd_intf_ports pci_exp_0] [get_bd_intf_pins nvme_ctrl_0/pci_exp]
  connect_bd_intf_net -intf_net pcie_ref_0_1 [get_bd_intf_ports pcie_ref] [get_bd_intf_pins nvme_ctrl_0/pcie_ref]
  connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
  connect_bd_intf_net -intf_net t4nfc_hlper_0_nfch_data_if [get_bd_intf_pins t4nfc_hlper_0/nfch_data_if] [get_bd_intf_pins hpic_0/S00_AXI]
  connect_bd_intf_net -intf_net t4nfc_hlper_0_to_ecc_if [get_bd_intf_pins bch_sccs_256B_21B_13b_0/to_ecc_if] [get_bd_intf_pins t4nfc_hlper_0/to_ecc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_0_ucode_if [get_bd_intf_pins t4nfc_hlper_0/ucode_if] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net t4nfc_hlper_0_v2nfc_if [get_bd_intf_pins t4nfc_hlper_0/v2nfc_if] [get_bd_intf_pins v2nfc_0/v2nfc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_1_to_ecc_if [get_bd_intf_pins bch_sccs_256B_21B_13b_1/to_ecc_if] [get_bd_intf_pins t4nfc_hlper_1/to_ecc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_1_ucode_if [get_bd_intf_pins blk_mem_gen_1/BRAM_PORTA] [get_bd_intf_pins t4nfc_hlper_1/ucode_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_1_v2nfc_if [get_bd_intf_pins t4nfc_hlper_1/v2nfc_if] [get_bd_intf_pins v2nfc_1/v2nfc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_2_to_ecc_if [get_bd_intf_pins t4nfc_hlper_2/to_ecc_if] [get_bd_intf_pins bch_sccs_256B_21B_13b_2/to_ecc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_2_ucode_if [get_bd_intf_pins t4nfc_hlper_2/ucode_if] [get_bd_intf_pins blk_mem_gen_2/BRAM_PORTA]
  connect_bd_intf_net -intf_net t4nfc_hlper_2_v2nfc_if [get_bd_intf_pins t4nfc_hlper_2/v2nfc_if] [get_bd_intf_pins v2nfc_2/v2nfc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_3_to_ecc_if [get_bd_intf_pins t4nfc_hlper_3/to_ecc_if] [get_bd_intf_pins bch_sccs_256B_21B_13b_3/to_ecc_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_3_ucode_if [get_bd_intf_pins blk_mem_gen_3/BRAM_PORTA] [get_bd_intf_pins t4nfc_hlper_3/ucode_if]
  connect_bd_intf_net -intf_net t4nfc_hlper_3_v2nfc_if [get_bd_intf_pins t4nfc_hlper_3/v2nfc_if] [get_bd_intf_pins v2nfc_3/v2nfc_if]
  connect_bd_intf_net -intf_net v2nfc_0_nand_if [get_bd_intf_ports nand_if_0] [get_bd_intf_pins v2nfc_0/nand_if]
  connect_bd_intf_net -intf_net v2nfc_1_nand_if [get_bd_intf_ports nand_if_1] [get_bd_intf_pins v2nfc_1/nand_if]
  connect_bd_intf_net -intf_net v2nfc_2_nand_if [get_bd_intf_ports nand_if_2] [get_bd_intf_pins v2nfc_2/nand_if]
  connect_bd_intf_net -intf_net v2nfc_3_nand_if [get_bd_intf_ports nand_if_3] [get_bd_intf_pins v2nfc_3/nand_if]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins gpic_0/S00_AXI]

  # Create port connections
  connect_net_sanitized ARESETN_1  [get_bd_pins proc_sys_reset_0/interconnect_aresetn] \
  [get_bd_pins gpic_0_sub_0/ARESETN]
  connect_net_sanitized CH0C133BUF_BUFGCE_O  [get_bd_pins pll_bank10/clk_out1] \
  [get_bd_pins v2nfc_0/iOutputDrivingClock] \
  [get_bd_pins v2nfc_0/iOutputStrobeClock]
  connect_net_sanitized CH1C133BUF_BUFGCE_O  [get_bd_pins pll_bank11/clk_out1] \
  [get_bd_pins v2nfc_1/iOutputDrivingClock] \
  [get_bd_pins v2nfc_1/iOutputStrobeClock]
  connect_net_sanitized CH2C133BUF_BUFGCE_O  [get_bd_pins pll_bank12/clk_out1] \
  [get_bd_pins v2nfc_2/iOutputDrivingClock] \
  [get_bd_pins v2nfc_2/iOutputStrobeClock]
  connect_net_sanitized CH3C133BUF_BUFGCE_O  [get_bd_pins pll_bank13/clk_out1] \
  [get_bd_pins v2nfc_3/iOutputDrivingClock] \
  [get_bd_pins v2nfc_3/iOutputStrobeClock]
  connect_net_sanitized M00_ARESETN_1  [get_bd_pins proc_sys_reset_2/peripheral_aresetn] \
  [get_bd_pins gpic_0/S00_ARESETN] \
  [get_bd_pins gpic_1/S00_ARESETN] \
  [get_bd_pins gpic_1/M00_ARESETN] \
  [get_bd_pins gpic_0_sub/S00_ARESETN] \
  [get_bd_pins hpic_0/M00_ARESETN]
  connect_net_sanitized M00_ARESETN_2  [get_bd_pins pll_bank10_psr/interconnect_aresetn] \
  [get_bd_pins gpic_0_sub_0/M00_ARESETN] \
  [get_bd_pins gpic_0_sub_0/M01_ARESETN] \
  [get_bd_pins hpic_0/S00_ARESETN]
  connect_net_sanitized M02_ARESETN_1  [get_bd_pins pll_bank11_psr/interconnect_aresetn] \
  [get_bd_pins gpic_0_sub_0/M02_ARESETN] \
  [get_bd_pins gpic_0_sub_0/M03_ARESETN] \
  [get_bd_pins hpic_0/S01_ARESETN]
  connect_net_sanitized M04_ARESETN_1  [get_bd_pins pll_bank12_psr/interconnect_aresetn] \
  [get_bd_pins gpic_0_sub_0/M04_ARESETN] \
  [get_bd_pins gpic_0_sub_0/M05_ARESETN] \
  [get_bd_pins hpic_0/S02_ARESETN]
  connect_net_sanitized M06_ARESETN_1  [get_bd_pins pll_bank13_psr/interconnect_aresetn] \
  [get_bd_pins gpic_0_sub_0/M06_ARESETN] \
  [get_bd_pins gpic_0_sub_0/M07_ARESETN] \
  [get_bd_pins hpic_0/S03_ARESETN]
  connect_net_sanitized S00_ARESETN_1  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins iodelay_if_0/sys__srstn] \
  [get_bd_pins iodelay_if_0_dqs/sys__srstn] \
  [get_bd_pins gpic_0/M00_ARESETN] \
  [get_bd_pins gpic_0_sub_0/S00_ARESETN] \
  [get_bd_pins gpic_0_sub/M00_ARESETN] \
  [get_bd_pins gpic_0_sub/M01_ARESETN]
  connect_net_sanitized iodelay_if_0_dqs_iodly_00__tap  [get_bd_pins iodelay_if_0_dqs/iodly_00__tap] \
  [get_bd_pins v2nfc_0/iDQSIDelayTap]
  connect_net_sanitized iodelay_if_0_dqs_iodly_00__tap_load  [get_bd_pins iodelay_if_0_dqs/iodly_00__tap_load] \
  [get_bd_pins v2nfc_0/iDQSIDelayTapLoad]
  connect_net_sanitized iodelay_if_0_dqs_iodly_01__tap  [get_bd_pins iodelay_if_0_dqs/iodly_01__tap] \
  [get_bd_pins v2nfc_1/iDQSIDelayTap]
  connect_net_sanitized iodelay_if_0_dqs_iodly_01__tap_load  [get_bd_pins iodelay_if_0_dqs/iodly_01__tap_load] \
  [get_bd_pins v2nfc_1/iDQSIDelayTapLoad]
  connect_net_sanitized iodelay_if_0_dqs_iodly_02__tap  [get_bd_pins iodelay_if_0_dqs/iodly_02__tap] \
  [get_bd_pins v2nfc_2/iDQSIDelayTap]
  connect_net_sanitized iodelay_if_0_dqs_iodly_02__tap_load  [get_bd_pins iodelay_if_0_dqs/iodly_02__tap_load] \
  [get_bd_pins v2nfc_2/iDQSIDelayTapLoad]
  connect_net_sanitized iodelay_if_0_dqs_iodly_03__tap  [get_bd_pins iodelay_if_0_dqs/iodly_03__tap] \
  [get_bd_pins v2nfc_3/iDQSIDelayTap]
  connect_net_sanitized iodelay_if_0_dqs_iodly_03__tap_load  [get_bd_pins iodelay_if_0_dqs/iodly_03__tap_load] \
  [get_bd_pins v2nfc_3/iDQSIDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_00__tap  [get_bd_pins iodelay_if_0/iodly_00__tap] \
  [get_bd_pins v2nfc_0/iDQ0IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_00__tap_load  [get_bd_pins iodelay_if_0/iodly_00__tap_load] \
  [get_bd_pins v2nfc_0/iDQ0IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_01__tap  [get_bd_pins iodelay_if_0/iodly_01__tap] \
  [get_bd_pins v2nfc_0/iDQ1IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_01__tap_load  [get_bd_pins iodelay_if_0/iodly_01__tap_load] \
  [get_bd_pins v2nfc_0/iDQ1IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_02__tap  [get_bd_pins iodelay_if_0/iodly_02__tap] \
  [get_bd_pins v2nfc_0/iDQ2IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_02__tap_load  [get_bd_pins iodelay_if_0/iodly_02__tap_load] \
  [get_bd_pins v2nfc_0/iDQ2IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_03__tap  [get_bd_pins iodelay_if_0/iodly_03__tap] \
  [get_bd_pins v2nfc_0/iDQ3IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_03__tap_load  [get_bd_pins iodelay_if_0/iodly_03__tap_load] \
  [get_bd_pins v2nfc_0/iDQ3IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_04__tap  [get_bd_pins iodelay_if_0/iodly_04__tap] \
  [get_bd_pins v2nfc_0/iDQ4IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_04__tap_load  [get_bd_pins iodelay_if_0/iodly_04__tap_load] \
  [get_bd_pins v2nfc_0/iDQ4IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_05__tap  [get_bd_pins iodelay_if_0/iodly_05__tap] \
  [get_bd_pins v2nfc_0/iDQ5IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_05__tap_load  [get_bd_pins iodelay_if_0/iodly_05__tap_load] \
  [get_bd_pins v2nfc_0/iDQ5IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_06__tap  [get_bd_pins iodelay_if_0/iodly_06__tap] \
  [get_bd_pins v2nfc_0/iDQ6IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_06__tap_load  [get_bd_pins iodelay_if_0/iodly_06__tap_load] \
  [get_bd_pins v2nfc_0/iDQ6IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_07__tap  [get_bd_pins iodelay_if_0/iodly_07__tap] \
  [get_bd_pins v2nfc_0/iDQ7IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_07__tap_load  [get_bd_pins iodelay_if_0/iodly_07__tap_load] \
  [get_bd_pins v2nfc_0/iDQ7IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_08__tap  [get_bd_pins iodelay_if_0/iodly_08__tap] \
  [get_bd_pins v2nfc_1/iDQ0IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_08__tap_load  [get_bd_pins iodelay_if_0/iodly_08__tap_load] \
  [get_bd_pins v2nfc_1/iDQ0IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_09__tap  [get_bd_pins iodelay_if_0/iodly_09__tap] \
  [get_bd_pins v2nfc_1/iDQ1IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_09__tap_load  [get_bd_pins iodelay_if_0/iodly_09__tap_load] \
  [get_bd_pins v2nfc_1/iDQ1IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_10__tap  [get_bd_pins iodelay_if_0/iodly_10__tap] \
  [get_bd_pins v2nfc_1/iDQ2IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_10__tap_load  [get_bd_pins iodelay_if_0/iodly_10__tap_load] \
  [get_bd_pins v2nfc_1/iDQ2IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_11__tap  [get_bd_pins iodelay_if_0/iodly_11__tap] \
  [get_bd_pins v2nfc_1/iDQ3IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_11__tap_load  [get_bd_pins iodelay_if_0/iodly_11__tap_load] \
  [get_bd_pins v2nfc_1/iDQ3IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_12__tap  [get_bd_pins iodelay_if_0/iodly_12__tap] \
  [get_bd_pins v2nfc_1/iDQ4IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_12__tap_load  [get_bd_pins iodelay_if_0/iodly_12__tap_load] \
  [get_bd_pins v2nfc_1/iDQ4IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_13__tap  [get_bd_pins iodelay_if_0/iodly_13__tap] \
  [get_bd_pins v2nfc_1/iDQ5IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_13__tap_load  [get_bd_pins iodelay_if_0/iodly_13__tap_load] \
  [get_bd_pins v2nfc_1/iDQ5IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_14__tap  [get_bd_pins iodelay_if_0/iodly_14__tap] \
  [get_bd_pins v2nfc_1/iDQ6IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_14__tap_load  [get_bd_pins iodelay_if_0/iodly_14__tap_load] \
  [get_bd_pins v2nfc_1/iDQ6IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_15__tap  [get_bd_pins iodelay_if_0/iodly_15__tap] \
  [get_bd_pins v2nfc_1/iDQ7IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_15__tap_load  [get_bd_pins iodelay_if_0/iodly_15__tap_load] \
  [get_bd_pins v2nfc_1/iDQ7IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_16__tap  [get_bd_pins iodelay_if_0/iodly_16__tap] \
  [get_bd_pins v2nfc_2/iDQ0IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_16__tap_load  [get_bd_pins iodelay_if_0/iodly_16__tap_load] \
  [get_bd_pins v2nfc_2/iDQ0IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_17__tap  [get_bd_pins iodelay_if_0/iodly_17__tap] \
  [get_bd_pins v2nfc_2/iDQ1IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_17__tap_load  [get_bd_pins iodelay_if_0/iodly_17__tap_load] \
  [get_bd_pins v2nfc_2/iDQ1IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_18__tap  [get_bd_pins iodelay_if_0/iodly_18__tap] \
  [get_bd_pins v2nfc_2/iDQ2IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_18__tap_load  [get_bd_pins iodelay_if_0/iodly_18__tap_load] \
  [get_bd_pins v2nfc_2/iDQ2IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_19__tap  [get_bd_pins iodelay_if_0/iodly_19__tap] \
  [get_bd_pins v2nfc_2/iDQ3IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_19__tap_load  [get_bd_pins iodelay_if_0/iodly_19__tap_load] \
  [get_bd_pins v2nfc_2/iDQ3IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_20__tap  [get_bd_pins iodelay_if_0/iodly_20__tap] \
  [get_bd_pins v2nfc_2/iDQ4IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_20__tap_load  [get_bd_pins iodelay_if_0/iodly_20__tap_load] \
  [get_bd_pins v2nfc_2/iDQ4IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_21__tap  [get_bd_pins iodelay_if_0/iodly_21__tap] \
  [get_bd_pins v2nfc_2/iDQ5IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_21__tap_load  [get_bd_pins iodelay_if_0/iodly_21__tap_load] \
  [get_bd_pins v2nfc_2/iDQ5IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_22__tap  [get_bd_pins iodelay_if_0/iodly_22__tap] \
  [get_bd_pins v2nfc_2/iDQ6IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_22__tap_load  [get_bd_pins iodelay_if_0/iodly_22__tap_load] \
  [get_bd_pins v2nfc_2/iDQ6IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_23__tap  [get_bd_pins iodelay_if_0/iodly_23__tap] \
  [get_bd_pins v2nfc_2/iDQ7IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_23__tap_load  [get_bd_pins iodelay_if_0/iodly_23__tap_load] \
  [get_bd_pins v2nfc_2/iDQ7IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_24__tap  [get_bd_pins iodelay_if_0/iodly_24__tap] \
  [get_bd_pins v2nfc_3/iDQ0IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_24__tap_load  [get_bd_pins iodelay_if_0/iodly_24__tap_load] \
  [get_bd_pins v2nfc_3/iDQ0IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_25__tap  [get_bd_pins iodelay_if_0/iodly_25__tap] \
  [get_bd_pins v2nfc_3/iDQ1IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_25__tap_load  [get_bd_pins iodelay_if_0/iodly_25__tap_load] \
  [get_bd_pins v2nfc_3/iDQ1IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_26__tap  [get_bd_pins iodelay_if_0/iodly_26__tap] \
  [get_bd_pins v2nfc_3/iDQ2IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_26__tap_load  [get_bd_pins iodelay_if_0/iodly_26__tap_load] \
  [get_bd_pins v2nfc_3/iDQ2IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_27__tap  [get_bd_pins iodelay_if_0/iodly_27__tap] \
  [get_bd_pins v2nfc_3/iDQ3IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_27__tap_load  [get_bd_pins iodelay_if_0/iodly_27__tap_load] \
  [get_bd_pins v2nfc_3/iDQ3IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_28__tap  [get_bd_pins iodelay_if_0/iodly_28__tap] \
  [get_bd_pins v2nfc_3/iDQ4IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_28__tap_load  [get_bd_pins iodelay_if_0/iodly_28__tap_load] \
  [get_bd_pins v2nfc_3/iDQ4IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_29__tap  [get_bd_pins iodelay_if_0/iodly_29__tap] \
  [get_bd_pins v2nfc_3/iDQ5IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_29__tap_load  [get_bd_pins iodelay_if_0/iodly_29__tap_load] \
  [get_bd_pins v2nfc_3/iDQ5IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_30__tap  [get_bd_pins iodelay_if_0/iodly_30__tap] \
  [get_bd_pins v2nfc_3/iDQ6IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_30__tap_load  [get_bd_pins iodelay_if_0/iodly_30__tap_load] \
  [get_bd_pins v2nfc_3/iDQ6IDelayTapLoad]
  connect_net_sanitized iodelay_if_0_iodly_31__tap  [get_bd_pins iodelay_if_0/iodly_31__tap] \
  [get_bd_pins v2nfc_3/iDQ7IDelayTap]
  connect_net_sanitized iodelay_if_0_iodly_31__tap_load  [get_bd_pins iodelay_if_0/iodly_31__tap_load] \
  [get_bd_pins v2nfc_3/iDQ7IDelayTapLoad]
  connect_net_sanitized nvme_ctrl_0_dev_irq_assert  [get_bd_pins nvme_ctrl_0/dev_irq_assert] \
  [get_bd_pins xlconcat_0/In0]
  connect_net_sanitized nvme_ctrl_0_user_lnk_up  [get_bd_pins nvme_ctrl_0/user_lnk_up] \
  [get_bd_ports user_lnk_up_0]
  connect_net_sanitized pcie_perst_n_0_1  [get_bd_ports pcie_perst_n] \
  [get_bd_pins nvme_ctrl_0/pcie_perst_n]
  connect_net_sanitized pll_bank10_clk_out2  [get_bd_pins pll_bank10/clk_out2] \
  [get_bd_pins t4nfc_hlper_0/iClock] \
  [get_bd_pins bch_sccs_256B_21B_13b_0/iClock] \
  [get_bd_pins v2nfc_0/iSystemClock] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins gpic_0_sub_0/M00_ACLK] \
  [get_bd_pins gpic_0_sub_0/M01_ACLK] \
  [get_bd_pins hpic_0/S00_ACLK] \
  [get_bd_pins pll_bank10_psr/slowest_sync_clk]
  connect_net_sanitized pll_bank10_clk_out3  [get_bd_pins pll_bank10/clk_out3] \
  [get_bd_pins v2nfc_0/iDelayRefClock]
  connect_net_sanitized pll_bank10_locked  [get_bd_pins pll_bank10/locked] \
  [get_bd_pins pll_bank10_psr/dcm_locked]
  connect_net_sanitized pll_bank11_clk_out2  [get_bd_pins pll_bank11/clk_out2] \
  [get_bd_pins t4nfc_hlper_1/iClock] \
  [get_bd_pins bch_sccs_256B_21B_13b_1/iClock] \
  [get_bd_pins v2nfc_1/iSystemClock] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] \
  [get_bd_pins gpic_0_sub_0/M02_ACLK] \
  [get_bd_pins gpic_0_sub_0/M03_ACLK] \
  [get_bd_pins hpic_0/S01_ACLK] \
  [get_bd_pins pll_bank11_psr/slowest_sync_clk]
  connect_net_sanitized pll_bank11_clk_out3  [get_bd_pins pll_bank11/clk_out3] \
  [get_bd_pins v2nfc_1/iDelayRefClock]
  connect_net_sanitized pll_bank11_locked  [get_bd_pins pll_bank11/locked] \
  [get_bd_pins pll_bank11_psr/dcm_locked]
  connect_net_sanitized pll_bank12_clk_out2  [get_bd_pins pll_bank12/clk_out2] \
  [get_bd_pins bch_sccs_256B_21B_13b_2/iClock] \
  [get_bd_pins t4nfc_hlper_2/iClock] \
  [get_bd_pins v2nfc_2/iSystemClock] \
  [get_bd_pins axi_bram_ctrl_2/s_axi_aclk] \
  [get_bd_pins gpic_0_sub_0/M04_ACLK] \
  [get_bd_pins gpic_0_sub_0/M05_ACLK] \
  [get_bd_pins hpic_0/S02_ACLK] \
  [get_bd_pins pll_bank12_psr/slowest_sync_clk]
  connect_net_sanitized pll_bank12_clk_out3  [get_bd_pins pll_bank12/clk_out3] \
  [get_bd_pins v2nfc_2/iDelayRefClock]
  connect_net_sanitized pll_bank12_locked  [get_bd_pins pll_bank12/locked] \
  [get_bd_pins pll_bank12_psr/dcm_locked]
  connect_net_sanitized pll_bank13_clk_out2  [get_bd_pins pll_bank13/clk_out2] \
  [get_bd_pins t4nfc_hlper_3/iClock] \
  [get_bd_pins bch_sccs_256B_21B_13b_3/iClock] \
  [get_bd_pins v2nfc_3/iSystemClock] \
  [get_bd_pins axi_bram_ctrl_3/s_axi_aclk] \
  [get_bd_pins gpic_0_sub_0/M06_ACLK] \
  [get_bd_pins gpic_0_sub_0/M07_ACLK] \
  [get_bd_pins hpic_0/S03_ACLK] \
  [get_bd_pins pll_bank13_psr/slowest_sync_clk]
  connect_net_sanitized pll_bank13_clk_out3  [get_bd_pins pll_bank13/clk_out3] \
  [get_bd_pins v2nfc_3/iDelayRefClock]
  connect_net_sanitized pll_bank13_locked  [get_bd_pins pll_bank13/locked] \
  [get_bd_pins pll_bank13_psr/dcm_locked]
  connect_net_sanitized proc_sys_reset_0_peripheral_reset  [get_bd_pins proc_sys_reset_0/peripheral_reset] \
  [get_bd_pins bch_skes_256B_21B_13b_0/iReset] \
  [get_bd_pins pll_bank10/reset] \
  [get_bd_pins pll_bank11/reset] \
  [get_bd_pins pll_bank12/reset] \
  [get_bd_pins pll_bank13/reset]
  connect_net_sanitized proc_sys_reset_1_peripheral_aresetn  [get_bd_pins pll_bank13_psr/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_3/s_axi_aresetn]
  connect_net_sanitized proc_sys_reset_1_peripheral_reset  [get_bd_pins pll_bank13_psr/peripheral_reset] \
  [get_bd_pins t4nfc_hlper_3/iReset] \
  [get_bd_pins bch_sccs_256B_21B_13b_3/iReset] \
  [get_bd_pins v2nfc_3/iReset]
  connect_net_sanitized proc_sys_reset_2_interconnect_aresetn  [get_bd_pins proc_sys_reset_2/interconnect_aresetn] \
  [get_bd_pins gpic_0/ARESETN] \
  [get_bd_pins gpic_1/ARESETN] \
  [get_bd_pins gpic_0_sub/ARESETN] \
  [get_bd_pins hpic_0/ARESETN]
  connect_net_sanitized proc_sys_reset_3_peripheral_aresetn  [get_bd_pins pll_bank11_psr/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
  connect_net_sanitized proc_sys_reset_3_peripheral_reset  [get_bd_pins pll_bank11_psr/peripheral_reset] \
  [get_bd_pins t4nfc_hlper_1/iReset] \
  [get_bd_pins bch_sccs_256B_21B_13b_1/iReset] \
  [get_bd_pins v2nfc_1/iReset]
  connect_net_sanitized proc_sys_reset_4_peripheral_aresetn  [get_bd_pins pll_bank12_psr/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn]
  connect_net_sanitized proc_sys_reset_4_peripheral_reset  [get_bd_pins pll_bank12_psr/peripheral_reset] \
  [get_bd_pins bch_sccs_256B_21B_13b_2/iReset] \
  [get_bd_pins t4nfc_hlper_2/iReset] \
  [get_bd_pins v2nfc_2/iReset]
  connect_net_sanitized proc_sys_reset_5_peripheral_aresetn  [get_bd_pins pll_bank10_psr/peripheral_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
  connect_net_sanitized proc_sys_reset_5_peripheral_reset  [get_bd_pins pll_bank10_psr/peripheral_reset] \
  [get_bd_pins t4nfc_hlper_0/iReset] \
  [get_bd_pins bch_sccs_256B_21B_13b_0/iReset] \
  [get_bd_pins v2nfc_0/iReset]
  connect_net_sanitized proc_sys_reset_6_peripheral_aresetn  [get_bd_pins proc_sys_reset_6/peripheral_aresetn] \
  [get_bd_pins nvme_ctrl_0/m0_axi_aresetn] \
  [get_bd_pins smartconnect_0/aresetn]
  connect_net_sanitized proc_sys_reset_7_peripheral_aresetn  [get_bd_pins proc_sys_reset_7/peripheral_aresetn] \
  [get_bd_pins nvme_ctrl_0/s0_axi_aresetn] \
  [get_bd_pins gpic_1/M01_ARESETN]
  connect_net_sanitized processing_system7_0_FCLK_CLK0  [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
  [get_bd_pins bch_skes_256B_21B_13b_0/iClock] \
  [get_bd_pins iodelay_if_0/sys__clk] \
  [get_bd_pins iodelay_if_0_dqs/sys__clk] \
  [get_bd_pins pll_bank10/clk_in1] \
  [get_bd_pins gpic_0/M00_ACLK] \
  [get_bd_pins gpic_0_sub_0/ACLK] \
  [get_bd_pins gpic_0_sub_0/S00_ACLK] \
  [get_bd_pins gpic_0_sub/M00_ACLK] \
  [get_bd_pins gpic_0_sub/M01_ACLK] \
  [get_bd_pins pll_bank11/clk_in1] \
  [get_bd_pins pll_bank12/clk_in1] \
  [get_bd_pins pll_bank13/clk_in1] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_net_sanitized processing_system7_0_FCLK_CLK2  [get_bd_pins zynq_ultra_ps_e_0/pl_clk1] \
  [get_bd_pins gpic_0/ACLK] \
  [get_bd_pins gpic_0/S00_ACLK] \
  [get_bd_pins gpic_1/ACLK] \
  [get_bd_pins gpic_1/S00_ACLK] \
  [get_bd_pins gpic_1/M00_ACLK] \
  [get_bd_pins gpic_0_sub/ACLK] \
  [get_bd_pins gpic_0_sub/S00_ACLK] \
  [get_bd_pins hpic_0/ACLK] \
  [get_bd_pins hpic_0/M00_ACLK] \
  [get_bd_pins proc_sys_reset_2/slowest_sync_clk] \
  [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] \
  [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk] \
  [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]
  connect_net_sanitized v2nfc_0_oReadyBusy  [get_bd_pins v2nfc_0/oReadyBusy] \
  [get_bd_pins t4nfc_hlper_0/iReadyBusy]
  connect_net_sanitized v2nfc_1_oReadyBusy  [get_bd_pins v2nfc_1/oReadyBusy] \
  [get_bd_pins t4nfc_hlper_1/iReadyBusy]
  connect_net_sanitized v2nfc_2_oReadyBusy  [get_bd_pins v2nfc_2/oReadyBusy] \
  [get_bd_pins t4nfc_hlper_2/iReadyBusy]
  connect_net_sanitized v2nfc_3_oReadyBusy  [get_bd_pins v2nfc_3/oReadyBusy] \
  [get_bd_pins t4nfc_hlper_3/iReadyBusy]
  connect_net_sanitized xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
  connect_net_sanitized zynq_ultra_ps_e_0_pl_clk2  [get_bd_pins zynq_ultra_ps_e_0/pl_clk2] \
  [get_bd_pins nvme_ctrl_0/s0_axi_aclk] \
  [get_bd_pins gpic_1/M01_ACLK] \
  [get_bd_pins proc_sys_reset_7/slowest_sync_clk]
  connect_net_sanitized zynq_ultra_ps_e_0_pl_clk3  [get_bd_pins zynq_ultra_ps_e_0/pl_clk3] \
  [get_bd_pins nvme_ctrl_0/m0_axi_aclk] \
  [get_bd_pins proc_sys_reset_6/slowest_sync_clk] \
  [get_bd_pins smartconnect_0/aclk] \
  [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
  connect_net_sanitized zynq_ultra_ps_e_0_pl_resetn0  [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in] \
  [get_bd_pins pll_bank13_psr/ext_reset_in] \
  [get_bd_pins pll_bank11_psr/ext_reset_in] \
  [get_bd_pins pll_bank12_psr/ext_reset_in] \
  [get_bd_pins pll_bank10_psr/ext_reset_in]
  connect_net_sanitized zynq_ultra_ps_e_0_pl_resetn1  [get_bd_pins zynq_ultra_ps_e_0/pl_resetn1] \
  [get_bd_pins proc_sys_reset_2/ext_reset_in]
  connect_net_sanitized zynq_ultra_ps_e_0_pl_resetn2  [get_bd_pins zynq_ultra_ps_e_0/pl_resetn2] \
  [get_bd_pins proc_sys_reset_7/ext_reset_in]
  connect_net_sanitized zynq_ultra_ps_e_0_pl_resetn3  [get_bd_pins zynq_ultra_ps_e_0/pl_resetn3] \
  [get_bd_pins proc_sys_reset_6/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0xA0000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0]
  assign_bd_address -offset 0xA0001000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0]
  assign_bd_address -offset 0xA0002000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0]
  assign_bd_address -offset 0xA0003000 -range 0x00001000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs axi_bram_ctrl_3/S_AXI/Mem0]
  assign_bd_address -offset 0xB0010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs iodelay_if_0_dqs/ctrl__s/reg0]
  assign_bd_address -offset 0xB0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs iodelay_if_0/ctrl__s/reg0]
  assign_bd_address -offset 0xB0020000 -range 0x00020000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs nvme_ctrl_0/s0_axi/reg0]
  assign_bd_address -offset 0xA0010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs t4nfc_hlper_0/C/reg0]
  assign_bd_address -offset 0xA0020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs t4nfc_hlper_1/C/reg0]
  assign_bd_address -offset 0xA0030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs t4nfc_hlper_2/C/reg0]
  assign_bd_address -offset 0xA0040000 -range 0x00010000 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs t4nfc_hlper_3/C/reg0]
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_0/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW]
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_1/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW]
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_2/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW]
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_3/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW]
  assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces nvme_ctrl_0/m0_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_DDR_LOW]

  # Exclude Address Segments
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces nvme_ctrl_0/m0_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_LPS_OCM]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces nvme_ctrl_0/m0_axi] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP3/HP1_QSPI]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_0/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_0/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_1/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_1/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_2/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_2/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI]
  exclude_bd_addr_seg -offset 0xFF000000 -range 0x01000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_3/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_LPS_OCM]
  exclude_bd_addr_seg -offset 0xC0000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces t4nfc_hlper_3/D] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_QSPI]


  # Restore current instance
  current_bd_instance $oldCurInst

  # Harmonize AXI attributes to avoid 2019.1 CRITICAL warnings.
  foreach iface {
    gpic_1/s00_couplers/s00_data_fifo/M_AXI
    gpic_1/m01_couplers/auto_ds/M_AXI
    gpic_0_sub/s00_couplers/s00_data_fifo/M_AXI
    gpic_0_sub/m00_couplers/auto_cc/M_AXI
    gpic_0_sub/m01_couplers/auto_cc/M_AXI
  } {
    catch { set_property CONFIG.SUPPORTS_NARROW_BURST {0} [get_bd_intf_pins $iface] }
  }
  foreach iface {
    blk_mem_gen_0/BRAM_PORTB
    blk_mem_gen_1/BRAM_PORTB
    blk_mem_gen_2/BRAM_PORTB
    blk_mem_gen_3/BRAM_PORTB
  } {
    catch { set_property MASTER_TYPE {BRAM_CTRL} [get_bd_intf_pins $iface] }
  }

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
