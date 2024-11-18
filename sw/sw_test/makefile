PROJECT_HOME = ../..
NEORV32_HOME ?= ../../neorv32
SOLUTION_NAME ?= sw

#targets the riscv base isa for neorv32 plus m extension
MARCH = rv32im_zicsr_zifencei
MABI  = ilp32


include $(NEORV32_HOME)/sw/common/common.mk

finalize:
	cp $(NEORV32_HOME)/rtl/core/neorv32_application_image.vhd $(PROJECT_HOME)/customHW/$(SOLUTION_NAME)
