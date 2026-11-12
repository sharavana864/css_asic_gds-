# 14nm ASIC Physical Design: Sub-400ns CSS Surface Code Quantum Error Decoder (`css_asic_gds-`)

![Technology](https://img.shields.io/badge/Node-SAED%2014nm%20FinFET%20LVT-blue)
![EDA Tool](https://img.shields.io/badge/Physical%20Design-Synopsys%20Fusion%20Compiler-purple)
![Clock](https://img.shields.io/badge/Frequency-200%20MHz%20(5.0%20ns)-brightgreen)
![Latency](https://img.shields.io/badge/Latency-65%20ns%20(13%20Cycles)-orange)
![Interface](https://img.shields.io/badge/Protocol-AXI4--Stream-red)

Complete RTL-to-GDSII/OASIS physical design implementation of a deterministic, ultra-low-latency **Calderbank-Shor-Steane (CSS) Rotated Surface Code (d = 3) Quantum Error Syndrome Decoder**. Synthesized, floorplanned, clock-tree synthesized, and routed on the **Synopsys SAED 14nm LVT (`saed14nm_1p9m`)** standard cell library using **Synopsys Fusion Compiler**.

---

## 1. Executive Summary & Silicon Motivation

Superconducting quantum processors require real-time syndrome decoding within their sub-microsecond decoherence window (typically under 400 ns) to prevent logical state corruption. While FPGAs serve as effective functional prototypes, scaling to thousands of physical qubits requires custom, low-power, compact **ASIC decoder IP blocks** capable of operating tightly integrated with the quantum control plane.

This repository presents the full physical silicon implementation of the `surface_decoder_uf_grid` core:
* **Dual-Plane Parallel Architecture:** Independently decodes Z-stabilizer (`sz[3:0]`) and X-stabilizer (`sx[3:0]`) syndromes in parallel to resolve bit-flip (Pauli-X), phase-flip (Pauli-Z), and correlated (Pauli-Y) error chains.
* **Deterministic 65 ns Execution:** Completes cluster growth and boundary consensus in exactly **13 clock cycles (65 ns at 200 MHz)**, providing a **6x timing margin** ahead of the 400 ns decoherence limit.
* **Full Signoff-Ready Physical Flow:** Implements Multi-Mode Multi-Corner (MMMC) timing analysis (`BEST` and `WORST` Cmin/Cmax corners), automated VDD/VSS M4/M5 power strapping, non-default clock routing rules (`2w2s`), and standard-cell filler insertion.

---

## 2. Physical Design & Architecture Specifications

| Parameter | Specification |
| :--- | :--- |
| **Top-Level Module** | `surface_decoder_uf_grid` |
| **Technology Library** | Synopsys SAED 14nm FinFET LVT (`saed14lvt_base_frame_timing.ndm`) |
| **Metal Stack** | 1P9M (`saed14nm_1p9m.tf` - 9 Metal Layers) |
| **Target Clock (`aclk`)** | 200 MHz (5.0 ns Clock Period) |
| **Corner Scenarios** | MMMC: `WORST` (Setup / Cmin) & `BEST` (Hold / Cmax) |
| **Core Utilization** | 40% Target Floorplan Utilization (`2 um` Core Offset) |
| **Power Grid Strategy** | Vertical M5 & Horizontal M4 VDD/VSS Straps (Width: `0.24 um`, Pitch: `8 um`) |
| **Clock Tree Rules** | Non-Default Rule `2w2s` (Double Width, Double Spacing on M4-M8) |
| **Total Placed Components** | 1,260 Cells (Standard Logic + LVT Fillers), 42 I/O Pins, 289 Nets |
| **Hardware Decode Latency** | 13 Clock Cycles (65 ns) |

---

## 3. Physical Layout & Post-Route Verification (`image/`)

The screenshots below capture the complete physical implementation inside **Synopsys Fusion Compiler**, including the routed 14nm standard-cell layout, top-level schematic symbol, floorplan, and timing/DRC verification views.

### 3.1 Routed 14nm Silicon Layout & Block Schematic
![Routed Layout and Schematic](image/Screenshot%20from%202026-11-12%2009-13-41.png)

### 3.2 Physical Design & Routing Views
![Physical Layout View 2](image/Screenshot%20from%202026-11-12%2009-16-03.png)

![Physical Layout View 3](image/Screenshot%20from%202026-11-12%2009-47-37.png)

![Physical Layout View 4](image/Screenshot%20from%202026-11-12%2009-48-22.png)

---

## 4. Pin & Interface Mapping

| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `aclk` | Input | 1-bit | 200 MHz system clock (5.0 ns period) |
| `aresetn` | Input | 1-bit | Active-low synchronous reset |
| `s_axis_tdata` | Input | 8-bit | Bits `[7:4]` = X-Stabilizers (`sx`), Bits `[3:0]` = Z-Stabilizers (`sz`) |
| `s_axis_tvalid` | Input | 1-bit | AXI4-Stream slave valid handshake |
| `s_axis_tready` | Output | 1-bit | AXI4-Stream slave ready flag |
| `m_axis_tdata` | Output | 18-bit | Bits `[17:9]` = 9-bit Pauli-Z Mask, Bits `[8:0]` = 9-bit Pauli-X Mask |
| `m_axis_tuser` | Output | 8-bit | Cycle latency counter (`8'd13` = 13 clock cycles) |
| `m_axis_tvalid` | Output | 1-bit | AXI4-Stream master valid flag |
| `m_axis_tready` | Input | 1-bit | AXI4-Stream master downstream ready handshake |

---

## 5. Repository Directory Structure

```text
css_asic_gds-/
|-- constraints/
|   +-- decoder.sdc                                  # 200 MHz clock, jitter, and I/O timing constraints
|-- image/
|   |-- Screenshot from 2026-11-12 09-13-41.png      # Fusion Compiler routed layout & schematic view
|   |-- Screenshot from 2026-11-12 09-16-03.png      # Physical implementation screenshot 2
|   |-- Screenshot from 2026-11-12 09-47-37.png      # Physical implementation screenshot 3
|   +-- Screenshot from 2026-11-12 09-48-22.png      # Physical implementation screenshot 4
|-- outputs/
|   |-- surface_decoder_layout.oasis                 # Final physical layout stream (OASIS format)
|   |-- surface_decoder_layout.def                   # Routed Design Exchange Format (DEF) layout
|   +-- surface_decoder_layout.v                     # Post-route gate-level Verilog netlist
|-- report/
|   |-- area.rpt                                     # Post-route standard cell & silicon area report
|   |-- power.rpt                                    # Dynamic and leakage power consumption report
|   +-- timing.rpt                                   # Static Timing Analysis (STA) setup/hold report
|-- rtl/
|   +-- surface_decoder_uf_grid.v                    # Synthesizable dual-plane CSS decoder Verilog RTL
|-- script/
|   +-- run_fc.tcl                                   # Automated RTL-to-Layout Fusion Compiler Tcl script
+-- README.md                                        # Repository documentation
```

---

## 6. How to Reproduce the Physical Design Flow

To run the complete RTL-to-Layout physical implementation in **Synopsys Fusion Compiler**:

```bash
# 1. Execute the automated physical design flow in batch mode
fc_shell -f script/run_fc.tcl | tee fc_layout.log

# 2. Launch the Fusion Compiler GUI to inspect the routed block
fc_shell -gui
```

### Physical Design Stages Executed in `script/run_fc.tcl`
1. **Library & Tech Setup:** Loads `saed14lvt_base_frame_timing.ndm` and `saed14nm_1p9m.tf`.
2. **RTL Elaboration:** Reads and elaborates `surface_decoder_uf_grid.v`.
3. **MMMC & Parasitics:** Configures `BEST` (`Cmax.tlup`) and `WORST` (`Cmin.tlup`) corners with `decoder.sdc`.
4. **Initial Synthesis & Floorplan:** Runs `compile_fusion -to initial_map` and initializes a 40% utilization floorplan.
5. **Power Network Synthesis (PNS):** Builds automatic VDD/VSS connections and vertical M5 / horizontal M4 power straps.
6. **Placement & Logic Optimization:** Executes `compile_fusion -to logic_opto` and `final_opto`.
7. **Clock Tree Synthesis (CTS):** Applies `2w2s` non-default routing rules on layers M4–M8 and runs `clock_opt`.
8. **Detail Routing & Filler Insertion:** Runs `route_auto`, `route_opt`, and populates empty tracks with `*FILL*` standard cells.
9. **Stream-Out & Signoff Reports:** Exports `.oasis`, `.def`, post-route `.v` netlist, and timing/power/area reports.

---

## 7. Author & Acknowledgments

Developed for the **VConnecTech Engineering Marathon 2026** (FPGA Design & Semiconductor/VLSI Track) in partnership with **Silicon Setu**, **IEEE Madras Section**, and **IEEE CASS Madras**.

* **Author / Team Lead:** Sharavanakumar R — *Rajalakshmi Institute of Technology, Chennai* ([GitHub: @sharavana864](https://github.com/sharavana864))
