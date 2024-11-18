# Modify this variable to fit your NEORV32 setup (neorv32 home folder)
PROJECT_HOME = ../..
NEORV32_HOME ?= ../../neorv32
SOLUTION_NAME ?= cfs

include $(NEORV32_HOME)/sw/common/common.mk

#targets the riscv base isa
MARCH = rv32i_zicsr_zifencei
MABI  = ilp32

finalize:
	cp $(NEORV32_HOME)/rtl/core/neorv32_application_image.vhd $(PROJECT_HOME)/customHW/$(SOLUTION_NAME)
