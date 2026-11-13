@echo off
setlocal enabledelayedexpansion

echo ===============================================================
echo           STANDALONE IP UNIT-LEVEL VERIFICATION SUITE         
echo ===============================================================

echo.
echo [1/7] Testing GPIO Controller IP...
iverilog -o sim_gpio.vvp -g2012 rtl/ips/gpio/gpio_top.sv tb/unit_tests/tb_gpio_unit.sv
if %ERRORLEVEL% neq 0 (echo GPIO compilation failed! & exit /b 1)
vvp sim_gpio.vvp
if %ERRORLEVEL% neq 0 (echo GPIO simulation failed! & exit /b 1)

echo.
echo [2/7] Testing Standard Timer IP...
iverilog -o sim_timer.vvp -g2012 rtl/ips/timer/timer_std.sv tb/unit_tests/tb_timer_std_unit.sv
if %ERRORLEVEL% neq 0 (echo Timer compilation failed! & exit /b 1)
vvp sim_timer.vvp
if %ERRORLEVEL% neq 0 (echo Timer simulation failed! & exit /b 1)

echo.
echo [3/7] Testing Seven-Segment Display Controller IP...
iverilog -o sim_7seg.vvp -g2012 rtl/ips/seven_segment/seven_segment_ctrl.sv tb/unit_tests/tb_seven_segment_unit.sv
if %ERRORLEVEL% neq 0 (echo Seven-Segment compilation failed! & exit /b 1)
vvp sim_7seg.vvp
if %ERRORLEVEL% neq 0 (echo Seven-Segment simulation failed! & exit /b 1)

echo.
echo [4/7] Testing UART Controller IP...
iverilog -o sim_uart.vvp -g2012 rtl/ips/uart/uart_rx.sv rtl/ips/uart/uart_top.sv tb/unit_tests/tb_uart_unit.sv
if %ERRORLEVEL% neq 0 (echo UART compilation failed! & exit /b 1)
vvp sim_uart.vvp
if %ERRORLEVEL% neq 0 (echo UART simulation failed! & exit /b 1)

echo.
echo [5/7] Testing Enhanced Timer IP...
iverilog -o sim_etimer.vvp -g2012 rtl/ips/enhanced_timer/enhanced_timer.sv tb/unit_tests/tb_enhanced_timer_unit.sv
if %ERRORLEVEL% neq 0 (echo Enhanced Timer compilation failed! & exit /b 1)
vvp sim_etimer.vvp
if %ERRORLEVEL% neq 0 (echo Enhanced Timer simulation failed! & exit /b 1)

echo.
echo [6/7] Testing DMA Controller IP...
iverilog -o sim_dma.vvp -g2012 rtl/ips/dma/dma_pkg.sv rtl/ips/dma/dma_fifo.sv rtl/ips/dma/dma_uart_to_mem.sv tb/unit_tests/tb_dma_unit.sv
if %ERRORLEVEL% neq 0 (echo DMA compilation failed! & exit /b 1)
vvp sim_dma.vvp
if %ERRORLEVEL% neq 0 (echo DMA simulation failed! & exit /b 1)

echo.
echo [7/7] Testing CRC-32 Accelerator IP...
iverilog -o sim_crc.vvp -g2012 rtl/ips/crc/crc32_pkg.sv rtl/ips/crc/crc32_byte_core.sv rtl/ips/crc/crc32_controller.sv rtl/ips/crc/crc32_axi_lite_slave.sv rtl/ips/crc/crc32_axi_read_master.sv rtl/ips/crc/crc32_top.sv tb/unit_tests/tb_crc32_unit.sv
if %ERRORLEVEL% neq 0 (echo CRC compilation failed! & exit /b 1)
vvp sim_crc.vvp
if %ERRORLEVEL% neq 0 (echo CRC simulation failed! & exit /b 1)

echo.
echo ===============================================================
echo   ALL 7 STANDALONE IP UNIT-LEVEL TESTS COMPLETED WITH 0 ERRORS!
echo ===============================================================
