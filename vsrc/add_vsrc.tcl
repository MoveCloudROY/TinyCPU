# List of files to exclude
set exclude_files {
    sram_ctl.v
    ctrl.v
    hilo_reg.v
}

# Get the list of all Verilog and VHDL files in the current directory
set verilog_files [glob -nocomplain *.v *.vh]

# Filter out the excluded files
foreach file $exclude_files {
    set verilog_files [lsearch -all -inline -not -glob $verilog_files *$file*]
}

# Get the list of Verilog files in the "tb" directory
set tb_files [glob -nocomplain tb/*.v]

# Filter out the files in the "tb" directory
set verilog_files [lsearch -all -inline -not -glob $verilog_files $tb_files]

# Add the remaining Verilog files to the Vivado project
foreach file $verilog_files {
    add_files -norecurse $file
}

# Print the list of added files (optional, for verification)
puts "Added the following Verilog files:"
foreach file $verilog_files {
    puts "  $file"
}