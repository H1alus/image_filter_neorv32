// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#include <neorv32.h>
#include <string.h>
#include "imageFilterCFS.h"
#include "ext_ram.h"

#define BAUD_RATE 19200
#define USE_UART0
#define PERF_COUNT

int main() {
	uint32_t temp;
#ifdef USE_UART0
  	// check if UART unit is implemented at all
  	if (neorv32_uart0_available() == 0) {
    		return 1;
  	}
#endif //USE_UART0
 	 // capture all exceptions and give debug info via UART
 	neorv32_rte_setup();
 	 // disable all interrupt sources
 	 //neorv32_cpu_csr_write(CSR_MIE, 0);
#ifdef USE_UART0
 	 // setup UART at default baud rate, no interrupts
 	neorv32_uart0_setup(BAUD_RATE, 0);
#endif //USE_UART0

#ifdef PERF_COUNT
	neorv32_cpu_csr_write(CSR_MCYCLE, 0); // start timing
#endif //PERF_COUNT
 	// clear all interrupts, enable only where needed
	neorv32_cpu_csr_write(CSR_MIE, 0);
	neorv32_cpu_csr_set(CSR_MIE, 1 << CSR_MIE_FIRQ1E); // enable FIRQ1 interrupt source
  	neorv32_cpu_csr_set(CSR_MSTATUS, 1 << CSR_MSTATUS_MIE); // enable machine-mode interrupts
 	 // intro

	init_imageFilter();
	setImageKernel(0,1,-4);
	
	for(int i = 0; i < 0x1000; i = i + 4) {
		temp = readFromExtRAM(i);
		pushDataToFilter(temp);
	}

	neorv32_cpu_sleep();
	
	for(int i = 0; i < 0x1000;i = i + 4) {
		temp = pullDataFromImageFilter();
		writeToExtRAM(i, temp);
	}
        #ifdef PERF_COUNT
	uint32_t time_count = neorv32_cpu_csr_read(CSR_MCYCLE);
	#ifdef USE_UART0
	neorv32_uart0_printf("\n\n%d\n\n", time_count);
	#endif //USE_UART0
	#endif //PERF_COUNT
  return 0;
}




