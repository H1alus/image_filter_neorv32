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
set proj_name [lindex $argv 0]
set top_name [lindex $argv 1]
set tb_name "./neorv32/sim/neorv32_tb.vhd"
set uartrx_name "./neorv32/sim/uart_rx.vhd"

if {[llength $argv] == 0} {
    puts "no top setup selected"
    create_project -force pynqz2_base ./pynqz2_base -part $part_name

} else {
    create_project -force pynqz2_$proj_name ./pynqz2_$proj_name -part $part_name
    add_files -fileset sources_1 $top_name
    add_files -fileset sim_1 $tb_name
    add_files -fileset sim_1 $uartrx_name
}

add_files -fileset sources_1 $file_list

# Set VHDL library property on neorv32 files
set_property library neorv32 [get_files -of_objects [get_filesets sources_1]]

# Update to set top and file compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property FILE_TYPE {VHDL 2008} [get_files *.vhd]
