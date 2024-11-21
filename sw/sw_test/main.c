// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#include <neorv32.h>
#include <stdint.h>
#include <string.h>

#include "ext_ram.h"
#include "convolute.h"
#include "rw_addr.h"

#define BAUD_RATE 19200
//#define USE_UART0
//#define PERF_COUNT


int main() {

 	neorv32_rte_setup();

#ifdef USE_UART0
 	 // setup UART at default baud rate, no interrupts
 	neorv32_uart0_setup(BAUD_RATE, 0);
#endif //USE_UART0
	

#ifdef PERF_COUNT
	neorv32_cpu_csr_write(CSR_MCYCLE, 0); // start timing
#endif //PERF_COUNT
	uint32_t window[3][3] = {0};
	//underlying array DONT USE
	// the underlying array is of dimension ncols + filter_radius to account for the border extensions
	// first element contains the last value of previous row
	// last element contains the first element of previous row
	uint32_t in_arr[3][34] = {0}; 
	//buffer to reference
	uint32_t *buffer[3] = {in_arr[0], in_arr[1], in_arr[2]};	
	// convoluted pixel
	uint32_t convoluted = 0;
	uint32_t start, end;

	set_kernel(0,  1, -4);
	//init the buffer's second row
	for(int j = 1; j < 33; j++) 
		buffer[1][j] = readFromExtRAM(nextReadAddr()); // reading from external memory
	
	//algorithm's iteration 
	for(int i = 1; i < 33; i++) { //rows loop

		// init third row
		if( i < 32) {//prevents from reading memory area that is not part of the image
			if(i == 1) {
				start = 1;
				end = 34;
			} else if(i < 31) {
				buffer[2][1] = buffer[1][33];
				start = 2;
				end = 34;
			} else {
				buffer[2][1] = buffer[1][33];
				buffer[2][33] = 0;
				start = 2;
				end = 33;
			}
			
			for(int j = start; j < end; j++)  {
				buffer[2][j] =  readFromExtRAM(nextReadAddr()); // reading from external MEMORY
			}
			
			//assign border extensions
			buffer[2][0] = buffer[1][32];
		}
		else {
			memset(buffer[2], 0, 34*sizeof(uint32_t));
		}
	
		// window generation and convolution
		for(int j = 1; j < 33; j++) { //coloumns loop
			// window init
			// the first window will be 
			//  | 0      0      0      |
			//  | 0      p(0,0) p(0,1) |
			//  | p(0,31) p(1,0) p(1,1)|

			for(int h = 0; h < 3; h++)
				for(int k = 0; k < 3; k++) {
						window[h][k] = buffer[h][j- 1 + k]; // 1st pixel behind, 2nd pixel to convolute, 3rd pixel forward
				}			
			convoluted = convolute(window);
			writeToExtRAM(nextWriteAddr(), convoluted); //write to external ram the convoluted pixel
		}
		//shift the circular buffer
		uint32_t *temp = buffer[0];
		buffer[0] = buffer[1];
		buffer[1] = buffer[2];
		buffer[2] = temp; // LAST INDEX MUST BE DIFFERENT THAN PREV SO WE CAN OVERWRITE
		
	}
	#ifdef PERF_COUNT
	uint32_t time_count = neorv32_cpu_csr_read(CSR_MCYCLE);
	#ifdef USE_UART0
	neorv32_uart0_printf("\n\n%d\n\n", time_count);
	#endif //USE_UART0
	#endif //PERF_COUNT
	return 0;
}
