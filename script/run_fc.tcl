############################################################
## Fusion Compiler Flow: CSS Surface Code Syndrome Decoder
## Target: SAED 14nm LVT | Core: surface_decoder_uf_grid
############################################################

############################
## 1. Setup
############################
set_host_options -max_cores 6

############################
## 2. Create Library
############################
create_lib quantum_decoder_lib \
  -ref_libs /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK/SAED14nm_EDK_STD_LVT/ndm/saed14lvt_base_frame_timing.ndm \
  -technology /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK/SAED14nm_EDK_TECH_DATA/tf/saed14nm_1p9m.tf

save_lib
report_ref_libs
current_lib

############################
## 3. Read RTL
############################
# Updated path to your q_full directory
analyze -f verilog /home/vlsi/q_full/surface_decoder_uf_grid.v
elaborate surface_decoder_uf_grid
set_top_module surface_decoder_uf_grid
current_block

############################
## 4. Constraints & MMMC
############################
set scenario1 "WORST"
# Updated path to your SDC file
set scenario_constraints($scenario1) "/home/vlsi/q_full/decoder.sdc"

set scenario2 "BEST"
# Updated path to your SDC file
set scenario_constraints($scenario2) "/home/vlsi/q_full/decoder.sdc"

remove_modes -all
remove_corners -all
remove_scenarios -all

foreach s [array name scenario_constraints] {
    create_mode $s
    create_corner $s
    create_scenario -name $s -mode $s -corner $s
}

foreach s [array name scenario_constraints] {
    current_scenario $s
    source $scenario_constraints($s)
}

set_scenario_status $scenario1 -setup true  -hold false -leakage_power true -dynamic_power true  -active true
set_scenario_status $scenario2 -setup false -hold true  -leakage_power true -dynamic_power false -active true
report_scenarios

############################
## 5. Parasitic Tech
############################
current_corner BEST
read_parasitic_tech -tlup /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK/SAED14nm_EDK_TECH_DATA/tlup/saed14nm_1p9m_Cmax.tlup \
 -layermap /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK/SAED14nm_EDK_TECH_DATA/map/saed14nm_tf_itf_tluplus.map -name CBest
set_parasitic_parameters -early_spec CBest

current_corner WORST
read_parasitic_tech -tlup /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK/SAED14nm_EDK_TECH_DATA/tlup/saed14nm_1p9m_Cmin.tlup \
 -layermap /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK/SAED14nm_EDK_TECH_DATA/map/saed14nm_tf_itf_tluplus.map -name CWorst
set_parasitic_parameters -late_spec CWorst

############################
## 6. Initial Synthesis
############################
compile_fusion -to initial_map
save_block -as initial_map

############################
## 7. Floorplan
############################
initialize_floorplan -core_utilization 0.40 -core_offset {2 2 2 2}

############################
## 8. Power Planning
############################
create_net VDD
create_net VSS
connect_pg_net -automatic -verbose

create_pg_strap -net VDD -layer M5 -direction vertical   -width 0.24 -pitch 8 -start 1.5 -stop 18
create_pg_strap -net VSS -layer M5 -direction vertical   -width 0.24 -pitch 8 -start 3   -stop 18
create_pg_strap -net VDD -layer M4 -direction horizontal -width 0.24 -pitch 8 -start 1.5 -stop 18
create_pg_strap -net VSS -layer M4 -direction horizontal -width 0.24 -pitch 8 -start 3   -stop 18

############################
## 9. Logic Optimization
############################
compile_fusion -to logic_opto
save_block -as logic_opto

############################
## 10. Placement Optimization
############################
compile_fusion -to final_opto
save_block -as final_opto

############################
## 11. Clock Routing Rules
############################
create_routing_rule 2w2s \
 -spacings {M1 0.052 M2 0.052 M3 0.052 M4 0.08 M5 0.08 M6 0.08 M7 0.08 M8 0.08 M9 0.08} \
 -widths   {M1 0.068 M2 0.068 M3 0.068 M4 0.12 M5 0.12 M6 0.12 M7 0.12 M8 0.12 M9 0.12} \
 -default_reference_rule

set_clock_routing_rules -net_type root     -rule 2w2s -min_routing_layer M4 -max_routing_layer M8
set_clock_routing_rules -net_type internal -rule 2w2s -min_routing_layer M4 -max_routing_layer M8
set_clock_routing_rules -net_type sink     -min_routing_layer M4 -max_routing_layer M6 -default_rule

############################
## 12. Clock Tree
############################
clock_opt -from build_clock -to route_clock
save_block -as route_clock
clock_opt -to final_opto
save_block -as clock_final_opto

############################
## 13. Routing
############################
route_auto
route_opt
save_block -as route_opt

############################
## 14. Fillers
############################
create_stdcell_fillers -lib_cells [get_lib_cells *FILL*]

############################
## 15. Outputs            
############################
write_gds -design [current_block] surface_decoder_layout.gds
write_verilog surface_decoder_layout.v
write_def surface_decoder_layout.def

############################
## 16. Reports
############################
report_placement
report_timing -delay_type min -sig 3
report_timing -delay_type max -sig 3
report_global_timing -pba_mode path
report_power
check_routes
check_lvs
