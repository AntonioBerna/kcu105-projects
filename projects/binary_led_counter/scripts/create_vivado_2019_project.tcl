# Vivado 2019 project setup for binary_led_counter
# Usage examples:
#   vivado -mode batch -source scripts/create_vivado_2019_project.tcl
#   vivado -mode batch -source scripts/create_vivado_2019_project.tcl -tclargs xcku040-ffva1156-2-e binary_led_counter_vivado

set script_dir [file normalize [file dirname [info script]]]
set origin_dir [file normalize [file join $script_dir ..]]

# Optional CLI args:
#   argv0 = FPGA part (default below)
#   argv1 = project name
set fpga_part "xcku040-ffva1156-2-e"
set proj_name "binary_led_counter_vivado"

if {[llength $argv] >= 1 && [string length [lindex $argv 0]] > 0} {
  set fpga_part [lindex $argv 0]
}
if {[llength $argv] >= 2 && [string length [lindex $argv 1]] > 0} {
  set proj_name [lindex $argv 1]
}

set proj_dir [file normalize [file join $origin_dir vivado $proj_name]]
set rtl_file [file normalize [file join $origin_dir rtl binary_led_counter.sv]]
set tb_top_file [file normalize [file join $origin_dir tb tb.sv]]
set xdc_file [file normalize [file join $origin_dir constraints led_bar.xdc]]

if {![file exists $rtl_file]} {
  error "RTL file not found: $rtl_file"
}
if {![file exists $tb_top_file]} {
  error "TB file not found: $tb_top_file"
}
if {![file exists $xdc_file]} {
  error "Constraints file not found: $xdc_file"
}

puts "INFO: Creating Vivado project '$proj_name' in '$proj_dir'"
puts "INFO: Using part '$fpga_part'"

create_project $proj_name $proj_dir -part $fpga_part -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Design sources
add_files -fileset sources_1 -norecurse $rtl_file
set_property file_type {SystemVerilog} [get_files $rtl_file]
set_property top binary_led_counter [get_filesets sources_1]

# Simulation sources
add_files -fileset sim_1 -norecurse $tb_top_file
set_property file_type {SystemVerilog} [get_files $tb_top_file]
set_property top tb [get_filesets sim_1]

# Constraint sources
add_files -fileset constrs_1 -norecurse $xdc_file
set_property file_type {XDC} [get_files $xdc_file]

# Includes in tb/tb.sv are written from project root (e.g. tb/classes/...)
set_property include_dirs [list $origin_dir] [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
update_compile_order -fileset constrs_1

puts "INFO: Vivado project created successfully."
puts "INFO: Open GUI with: vivado [file join $proj_dir ${proj_name}.xpr]"
