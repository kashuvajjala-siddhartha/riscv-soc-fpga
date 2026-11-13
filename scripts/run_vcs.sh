#!/usr/bin/env bash
# ===============================================================
#     SYNOPSYS VCS & VERDI SIMULATION RUNNER (RED HAT LINUX)
# ===============================================================
set -e

echo "==============================================================="
echo "   COMPILING WAVEGUARD SOC WITH SYNOPSYS VCS                   "
echo "==============================================================="

# Generate firmware hex if python3 is available
if command -v python3 &> /dev/null; then
    python3 scripts/generate_hex.py firmware
fi

# 1. Compile with Synopsys VCS:
#    -full64           : 64-bit architecture
#    -sverilog         : Enable SystemVerilog IEEE-1800 features
#    +v2k              : Verilog-2000 compatibility for legacy modules
#    -timescale=1ns/1ps: Universal simulation timescale
#    -debug_access+all : Full signal visibility for Verdi dumping
#    +define+DUMP_FSDB : Activates $fsdbDumpfile("dump.fsdb")
#    -f scripts/sim_files.f : Reads all RTL & TB source files
#    -top waveguard_soc_tb  : Sets top testbench module
#    -o simv           : Binary output name
vcs -full64 \
    -sverilog \
    +v2k \
    -timescale=1ns/1ps \
    -debug_access+all \
    +define+DUMP_FSDB \
    -f scripts/sim_files.f \
    -top waveguard_soc_tb \
    -o simv

echo ""
echo "==============================================================="
echo "   RUNNING SIMULATION (GENERATING dump.fsdb FOR VERDI)...      "
echo "==============================================================="
./simv

echo ""
echo "==============================================================="
echo "   SIMULATION FINISHED SUCCESSFULLY!                           "
echo "   To view waveforms in Synopsys Verdi, run:                   "
echo "   verdi -ssf dump.fsdb &                                      "
echo "==============================================================="
