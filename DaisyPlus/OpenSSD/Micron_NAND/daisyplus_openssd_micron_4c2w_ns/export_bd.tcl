open_project cosm-plus-sys/cosm-plus-sys.xpr
set bd_file [lindex [get_files -quiet */sys_top.bd] 0]
if { $bd_file eq "" } {
  puts "ERROR: sys_top.bd not found"; exit 1
}
open_bd_design $bd_file
write_bd_tcl -force ./scripts/sys_top_bd_2024.tcl
write_hwdef -force ./scripts/sys_top_bd_2024.hdf
close_bd_design $bd_file
close_project
exit
