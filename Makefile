BASIC_TCL_SCRIPT = ./etc/xil_gen.tcl
CUSTOM_TCL_SCRIPT = ./etc/xil_gen_customhw.tcl

MINIMALBOOT   =   ./neorv32/rtl/processor_templates/neorv32_ProcessorTop_MinimalBoot.vhd  
MINIMAL       =   ./neorv32/rtl/processor_templates/neorv32_ProcessorTop_Minimal.vhd
CFS           =   ./customHW/cfs/
CFU           =   ./customHW/cfu/
SW            =   ./customHW/sw/

base:
	vivado -mode batch -source $(BASIC_TCL_SCRIPT)
	make clean-logs

minimalboot:
	vivado -mode batch -source $(BASIC_TCL_SCRIPT) -tclargs minimalboot $(MINIMALBOOT)
	make clean-logs 

minimal:
	vivado -mode batch -source $(BASIC_TCL_SCRIPT) -tclargs minimal $(MINIMAL)
	make clean-logs 
	
cfs:
	vivado -mode batch -source $(CUSTOM_TCL_SCRIPT) -tclargs cfs cfs $(CFS)
	make clean-logs 

cfu:
	vivado -mode batch -source $(CUSTOM_TCL_SCRIPT) -tclargs cfu cfu $(CFU)
	make clean-logs 

softw:
	vivado -mode batch -source $(CUSTOM_TCL_SCRIPT) -tclargs none sw $(SW)
	make clean-logs 

clean-logs:
	rm -rf vivado*.log
	rm -rf vivado*.jou
	rm -rf .Xil/
clean:
	rm -rf vivado*.log
	rm -rf vivado*.jou
	rm -rf neorv32_pynqz2
