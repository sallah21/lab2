#!/bin/bash
# This script is used to run the VCS simulation for a given design.
vcs -f rtl_files.f -l vcs_coverage.log -o vcs_simv -debug_access+all -kdb -cm line+tgl+cond+fsm+branch
# Run the simulation with coverage options
./vcs_simv -l vcs_coverage_run.log -cm line+tgl+cond+fsm+branch
# Generate coverage database
urg -dir vcs_simv.vdb
# Run the simulation in GUI mode
verdi -cov -covdir vcs_simv.vdb 
# Check if the simulation was successful
if [ $? -eq 0 ]; then
    echo "Simulation completed successfully."
else
    echo "Simulation failed. Check vcs_run.log for details."
fi
