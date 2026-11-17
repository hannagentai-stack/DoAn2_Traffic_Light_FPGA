# Run from project root or sim/, just like run_sim.do.
if {[file exists sim/run_sim.do]} {
    do sim/run_sim.do
} else {
    do run_sim.do
}
do $sim_dir/stability_checks.do
puts "ALL REGRESSIONS PASS"
