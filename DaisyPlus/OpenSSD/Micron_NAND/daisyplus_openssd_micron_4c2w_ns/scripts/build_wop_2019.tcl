# Vivado 2019.1 project recreation script
# Generates a clean project under cosm-plus-sys-2019 using exported BD.

set script_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $script_dir .. "cosm-plus-sys-2019"]]
set bd_script [file normalize [file join $script_dir "sys_top_bd_2019.tcl"]]
set ip_repo    [file normalize [file join $script_dir .. "cosm-plus-sys" "cosm-plus-sys.ipdefs" "ip-repo_0_0"]]
set constr_dir [file normalize [file join $project_root "constraints"]]

if {![file exists $bd_script]} {
  puts "ERROR: BD script not found at $bd_script"; exit 1
}
if {![file exists $project_root]} {
  file mkdir $project_root
}

create_project cosm_plus_sys_2019 $project_root -part xczu17eg-ffvc1760-2-e -force
set_property target_language VHDL [current_project]
set_property target_language Verilog [current_project]

if {[file exists $ip_repo]} {
  set_property ip_repo_paths [list $ip_repo] [current_project]
  update_ip_catalog
} else {
  puts "WARNING: IP repository $ip_repo missing."
}

# Recreate block design
source $bd_script

# Save BD and generate wrapper
set bd_file [lindex [get_files -quiet */sys_top.bd] 0]
if {$bd_file eq ""} {
  puts "ERROR: sys_top.bd not found after sourcing"; exit 1
}
set wrapper_files [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_files
set_property top sys_top_wrapper [current_fileset]

# Import top-level constraints
if {[file exists $constr_dir]} {
  foreach constr_file [glob -nocomplain -types f -directory $constr_dir *.xdc] {
    add_files -fileset constrs_1 $constr_file
  }
} else {
  puts "WARNING: constraint directory $constr_dir missing"
}
write_project_tcl -force [file join $project_root build_wop_2019_generated.tcl]
close_project
exit
