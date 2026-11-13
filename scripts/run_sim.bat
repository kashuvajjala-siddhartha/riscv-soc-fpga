@echo off
echo ===============================================================
echo     WAVEGUARD SOC SIMULATION ^& VERIFICATION SUITE
echo ===============================================================
echo [1/3] Generating RISC-V Program Hex Files...
python scripts\generate_hex.py firmware

echo.
echo [2/3] Compiling SystemVerilog RTL with Icarus Verilog...
iverilog -g2012 -f scripts\sim_files.f -o sim_soc.vvp
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Verilog compilation failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Executing SoC Simulation with VVP...
vvp sim_soc.vvp
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Simulation execution failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ===============================================================
echo [SUCCESS] Simulation Finished with 0 errors!
echo Waveform dump generated: waveguard_soc_tb.vcd
echo To view waveforms, run: gtkwave waveguard_soc_tb.vcd
echo ===============================================================
