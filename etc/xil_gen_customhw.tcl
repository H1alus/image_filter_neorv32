# ================================================================================ 
# image_filter_NEORV32: hardware accelerated image filter for neorv32                             
# -------------------------------------------------------------------------------- 
# Project repository - https://github.com/H1alus/image_filter_neorv32              
# Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
# Licensed under the BSD-3-Clause license, see LICENSE for details.                
# SPDX-License-Identifier: BSD-3-Clause                                            
# ================================================================================
set neorv32_home  "."
set part_name "xc7z020clg400-1"

set file_list_file [read [open "$neorv32_home/file_list_soc.f" r]]
set file_list [string map [list "./rtl" "$neorv32_home/rtl"] $file_list_file]
set module [lindex $argv 0]
set proj_name [lindex $argv 1]
set module_path [lindex $argv 2]
set tb_name "./customHW/sim/neorv32_tb.vhd"
set uartrx_name "./customHW/sim/uart_rx.vhd"

create_project -force pynqz2_$proj_name ./pynqz2_$proj_name -part $part_name
foreach file [glob -nocomplain -directory $module_path *] {
  lappend file_list $file
}

set idx [lsearch $file_list *application_image*]
set file_list [lreplace $file_list $idx $idx]
if {$module == "cfs"} {
  set idx [lsearch $file_list *cfs*]
  set file_list [lreplace $file_list $idx $idx]
} elseif {$module == "cfu"} {
  set idx [lsearch $file_list *cfu*]
  set file_list [lreplace $file_list $idx $idx]
}
add_files -fileset sources_1 $file_list
add_files -fileset sim_1 $tb_name
add_files -fileset sim_1 $uartrx_name

set_property library neorv32 [get_files -of_objects [get_filesets sources_1]]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]
