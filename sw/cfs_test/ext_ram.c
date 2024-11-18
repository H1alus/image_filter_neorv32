// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#include "ext_ram.h"

uint32_t readFromExtRAM(uint32_t addr) {
	const uint32_t base_address = 0xf0000000;
	uint32_t read_addr = base_address + addr;
  	uint32_t value = (uint32_t) neorv32_cpu_load_unsigned_word(read_addr);
  	if(neorv32_cpu_csr_read(CSR_MCAUSE) != 0) {
#ifdef USE_UART0
		neorv32_uart0_printf("\n<<< EXCEPTION IN READING FROM EXT MEMORY >>>\n\n");
#endif //USE_UART0
		return 0;
  	}
  	return value;
}
void writeToExtRAM(uint32_t addr, uint32_t data) {
	const uint32_t base_address = 0xf0000000 + 0x1000; //1023*4
	uint32_t write_addr = base_address + addr;
  	neorv32_cpu_store_unsigned_word(write_addr, data);
}
