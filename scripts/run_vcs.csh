#!/bin/csh -f
# ===============================================================
#     SYNOPSYS VCS & VERDI SIMULATION RUNNER (CSH)
# ===============================================================

# 1. Source Synopsys environment setup
if ( -f /home/student/cshrc ) then
    source /home/student/cshrc
endif

echo "==============================================================="
echo "   COMPILING WAVEGUARD SOC WITH SYNOPSYS VCS                   "
echo "==============================================================="

# Generate firmware hex
python3 scripts/generate_hex.py firmware

# 2. Compile with Synopsys VCS:
vcs -full64 \
    -sverilog \
    +v2k \
    -timescale=1ns/1ps \
    -debug_access+all \
    +define+DUMP_FSDB \
    -f scripts/sim_files.f \
    -top waveguard_soc_tb \
    -o simv

if ( $status != 0 ) then
    echo "[ERROR] VCS Compilation Failed!"
    exit 1
endif

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
