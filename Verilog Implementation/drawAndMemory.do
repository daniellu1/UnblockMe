vlib work
vlog drawAndMemory.v
vsim -L altera_mf_ver drawFSM
log -r {/*}
add wave -r {/*}

force {reset} 0
force {clk50} 0 0ns , 1 {1ns} -r 2ns
run 4ns

force {reset} 1
force {clk50} 0 0ns , 1 {1ns} -r 2ns
run 4ns


force {reset} 0
force {clk50} 0 0ns , 1 {1ns} -r 2ns
run 1000ns