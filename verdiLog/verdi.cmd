wvCreateWindow
wvSetPosition -win $_nWave2 {("G1" 0)}
wvOpenFile -win $_nWave2 \
           {/home/student/Documents/1602-23-735-045./PROJECT_DIRECTERY/run/axi_interconnect_wrap_4x2_tb.fsdb}
verdiWindowResize -win $_Verdi_1 "330" "84" "900" "700"
verdiWindowResize -win $_Verdi_1 "330" "84" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetSignalFilter -win $_nWave2 \
           "s00_axi_awaddr
s00_axi_awvalid
s00_axi_awready

m00_axi_awaddr
m00_axi_awvalid
m00_axi_awready

m01_axi_awaddr
m01_axi_awvalid
m01_axi_awready"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/Unnamed_\$axi_interconnect_wrap_4x2_tb_sv_1086"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
}
wvSetPosition -win $_nWave2 {("G1" 0)}
wvGetSignalClose -win $_nWave2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb/dut"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/dut/axi_interconnect_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/dut/axi_interconnect_inst/arb_inst"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/Unnamed_\$axi_interconnect_wrap_4x2_tb_sv_1086"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb/dut"
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetPosition -win $_nWave2 {("G1" 1)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awvalid"
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 2 )} 
wvSetPosition -win $_nWave2 {("G1" 2)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_awready"
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 3 )} 
wvSetPosition -win $_nWave2 {("G1" 3)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSetPosition -win $_nWave2 {("G1" 4)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_awvalid"
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSetPosition -win $_nWave2 {("G1" 5)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_awready
"
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSetPosition -win $_nWave2 {("G1" 5)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_awready
"
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 5 )} 
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSetPosition -win $_nWave2 {("G1" 6)}
wvGetSignalSetSignalFilter -win $_nWave2 "
m01_axi_awaddr"
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 6 )} 
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSetPosition -win $_nWave2 {("G1" 7)}
wvGetSignalSetSignalFilter -win $_nWave2 "m01_axi_awvalid"
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 8 )} 
wvSetPosition -win $_nWave2 {("G1" 8)}
wvGetSignalSetSignalFilter -win $_nWave2 "m01_axi_awready"
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 9 )} 
wvSetPosition -win $_nWave2 {("G1" 9)}
wvGetSignalClose -win $_nWave2
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvZoomAll -win $_nWave2
wvSetCursor -win $_nWave2 584503.667137 -snap {("G2" 0)}
wvSetCursor -win $_nWave2 242735.986694 -snap {("G2" 0)}
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb/dut"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/dut/axi_interconnect_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/dut/axi_interconnect_inst/arb_inst"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb/dut"
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_wdata"
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 10 )} 
wvSetPosition -win $_nWave2 {("G1" 10)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_wdata"
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvSetPosition -win $_nWave2 {("G1" 11)}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSelectGroup -win $_nWave2 {G2}
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb/dut"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/dut/axi_interconnect_inst"
wvGetSignalSetScope -win $_nWave2 \
           "/axi_interconnect_wrap_4x2_tb/dut/axi_interconnect_inst/arb_inst"
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_wrap_4x2_tb/dut"
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_wvalid"
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 11 )} 
wvSetPosition -win $_nWave2 {("G1" 11)}
wvGetSignalSetSignalFilter -win $_nWave2 "s00_axi_wready"
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 12 )} 
wvSetPosition -win $_nWave2 {("G1" 12)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_wdata"
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 13 )} 
wvSetPosition -win $_nWave2 {("G1" 13)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_wvalid"
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 14 )} 
wvSetPosition -win $_nWave2 {("G1" 14)}
wvGetSignalSetSignalFilter -win $_nWave2 "m00_axi_wready"
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 15 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvGetSignalSetSignalFilter -win $_nWave2 "
m01_axi_wdata"
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 15 )} 
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wdata\[63:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 16 )} 
wvSetPosition -win $_nWave2 {("G1" 16)}
wvGetSignalSetSignalFilter -win $_nWave2 "m01_axi_wvalid"
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 17)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wvalid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 17 )} 
wvSetPosition -win $_nWave2 {("G1" 17)}
wvGetSignalSetSignalFilter -win $_nWave2 "m01_axi_wready"
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 18 )} 
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 18 )} 
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awaddr\[31:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_awready} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/s00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m00_axi_wready} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wdata\[63:0\]} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wvalid} \
{/axi_interconnect_wrap_4x2_tb/dut/m01_axi_wready} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 18 )} 
wvSetPosition -win $_nWave2 {("G1" 18)}
wvGetSignalClose -win $_nWave2
wvZoomAll -win $_nWave2
