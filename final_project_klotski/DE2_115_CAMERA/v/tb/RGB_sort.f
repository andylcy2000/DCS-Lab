// Simulation Settings
// -----------------------------------------------------------------------------
+v2k 
-debug_access+all 
-P /usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/novas.tab
/usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/pli.a
-sverilog
+notimingcheck

// Verilog Library Extensions
// -----------------------------------------------------------------------------
+libext+.v+.sv+.vlib

// Module Search Path
// -----------------------------------------------------------------------------
-y /usr/cad/synopsys/synthesis/cur/dw/sim_ver 
+incdir+/usr/cad/synopsys/synthesis/cur/dw/sim_ver/+

// Your Design Files
// -----------------------------------------------------------------------------
./tb_RGB_sort.sv
../RGB_sort.sv