# Run after run_sim.do (compiled work library). RTL fault injection only.
onerror {if {[batch_mode]} {quit -f -code 2} else {abort}}
onbreak {if {[batch_mode]} {quit -f -code 1} else {abort}}
proc check {condition message} {
    if {![uplevel 1 [list expr $condition]]} {error "FAIL: $message"}
}
proc value {path} {examine -radix binary /traffic_light_top/$path}
proc number {path} {examine -radix decimal /traffic_light_top/$path}
proc await_value {path expected limit} {
    for {set elapsed 0} {$elapsed < $limit} {incr elapsed 10} {
        if {[value $path] eq $expected} {return}
        run 10ns
    }
    error "Timeout: $path expected $expected, got [value $path]"
}
proc boot {} {
    restart -f
    force CLOCK_50 0 0ns, 1 10ns -repeat 20ns
    force KEY 110
    force SW 11
    run 100ns
    force KEY 111
    run 160ns
    check {[value rst_n_s] eq "1"} "reset did not release"
}
vsim -t 1ns -voptargs=+acc -gSIMULATION=true work.traffic_light_top
boot
# Short asynchronous reset assertion, bounced release, synchronous qualification.
force KEY 110
run 1ns
check {[value rst_n_s] eq "0"} "reset assertion must be asynchronous"
force KEY 111
run 40ns
check {[value rst_n_s] eq "0"} "reset released too early"
force KEY 110
run 1ns
force KEY 111
run 60ns
check {[value rst_n_s] eq "0"} "bounced reset release was accepted"
run 100ns
check {[value rst_n_s] eq "1"} "stable reset release rejected"
puts "PASS: asynchronous reset assertion / qualified synchronous release"

# Exercise each control independently, both press and release bounce.
foreach {port active bit} {KEY 101 0 KEY 011 1 SW 10 2 SW 01 3} {
    boot
    set inactive [expr {$port eq "KEY" ? "111" : "11"}]
    force $port $active
    run 20ns
    force $port $inactive
    run 160ns
    check {[value control_clean] eq "1111"} "$port short pulse accepted"
    force $port $active
    run 160ns
    set clean [value control_clean]
    check {[string index $clean [expr {3-$bit}]] eq "0"} "$port stable press rejected"
    force $port $inactive
    run 20ns
    force $port $active
    run 160ns
    check {[value control_clean] eq $clean} "$port release bounce accepted"
    force $port $inactive
    run 160ns
    check {[value control_clean] eq "1111"} "$port stable release rejected"
}
puts "PASS: all four controls reject bounce on press and release"

# Full first second after each special-mode exit, independent of blink phase.
foreach {port active phase counter initial} {
    KEY 101 00 dem_lan_a 25
    KEY 011 10 dem_lan_b 30
    SW 10 00 dem_lan_a 25
} {
    foreach offset {180 540 880} {
        boot
        force $port $active
        run 200ns
        run ${offset}ns
        set inactive [expr {$port eq "KEY" ? "111" : "11"}]
        force $port $inactive
        await_value nap_pha_s 1 500
        await_value nap_pha_s 0 100
        check {[value chon_pha_s] eq $phase} "wrong restart phase"
        check {[number khoi_dem_thoi_gian/$counter] == $initial} "wrong reload"
        run 980ns
        check {[number khoi_dem_thoi_gian/$counter] == $initial} "first second shortened"
        run 20ns
        check {[number khoi_dem_thoi_gian/$counter] == $initial-1} "first second too long"
    }
}
puts "PASS: full first second after emergency A/B and night, at three offsets"

# Preserve fractional second across pause, while blink continues independently.
boot
run 320ns
force -freeze sw_tam_dung_s 1
run 1ns
set fraction [number khoi_chia_tan/dem_giay]
set seconds [number khoi_dem_thoi_gian/dem_lan_a]
set blink [value xung_chop_1hz_s]
run 500ns
check {[number khoi_chia_tan/dem_giay] == $fraction} "pause lost fractional second"
check {[number khoi_dem_thoi_gian/dem_lan_a] == $seconds} "pause decremented timer"
check {[value xung_chop_1hz_s] ne $blink} "pause stopped blink"
noforce sw_tam_dung_s
run 20ns
check {[number khoi_chia_tan/dem_giay] == $fraction+1} "resume did not retain fraction"
puts "PASS: pause preserves fractional second; blink remains free running"

# Inject pause precisely between timer expiry and FSM consumption.
boot
run 24000ns
await_value co_het_gio_s 1 2000
force -freeze sw_tam_dung_s 1
run 200ns
check {[value chon_pha_s] eq "00"} "phase changed during pause"
check {[value co_het_gio_s] eq "1"} "expiry was lost during pause"
noforce sw_tam_dung_s
run 20ns
check {[value chon_pha_s] eq "01"} "pending expiry not consumed on resume"
run 60ns
check {[value chon_pha_s] eq "01"} "stale expiry skipped yellow phase"
check {[value co_het_gio_s] eq "0"} "expiry not acknowledged"
puts "PASS: expiry survives pause and cannot skip next phase"

# Force raw FSM lamps to verify all three interlock conflict terms.
boot
foreach {ga gb ya yb} {1 1 0 0 1 0 0 1 0 1 1 0} {
    force -freeze den_xanh_a_s $ga
    force -freeze den_xanh_b_s $gb
    force -freeze den_vang_a_s $ya
    force -freeze den_vang_b_s $yb
    force -freeze den_do_a_s 0
    force -freeze den_do_b_s 0
    run 1ns
    check {[value LEDG] eq "00" && [value LEDR] eq "1010"} "interlock failed"
}
foreach sig {den_xanh_a_s den_xanh_b_s den_vang_a_s den_vang_b_s den_do_a_s den_do_b_s} {noforce $sig}
run 20ns
check {[value LEDG] eq "01" && [value LEDR] eq "1000"} "interlock did not recover"
puts "PASS: all three interlock conflicts and recovery (RTL injection)"
puts "STABILITY REGRESSION PASS"
