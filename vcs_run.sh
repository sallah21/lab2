#!/bin/bash
# This script is used to run the VCS simulation for a given design.
vcs -f rtl_files.f -sverilog -debug_pp -l vcs.log -o vcs_simv -debug_access+all -kdb
# Run the simulation
./vcs_simv -sv -l vcs_run.log
# Check if the simulation was successful
if [ $? -eq 0 ]; then
    echo "Simulation completed successfully."
else
    echo "Simulation failed. Check vcs_run.log for details."
fi
