// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#include "convolute.h"

//#define cfu_convolute(r1, r2, r3) neorv32_cfu_r4_instr(0b000, r1, r2, r3)    // R4-type instruction
#define csr_set_W1(W) neorv32_cpu_csr_write(CSR_CFUREG0, W)
#define csr_set_W2(W) neorv32_cpu_csr_write(CSR_CFUREG1, W)
#define csr_set_W3(W) neorv32_cpu_csr_write(CSR_CFUREG2, W)

void set_kernel(uint32_t W1, uint32_t W2, uint32_t W3) {
	csr_set_W1(W1);
	csr_set_W2(W2);
	csr_set_W3(W3);
}

/*
int32_t convolute(uint32_t p[3][3]) {
	uint32_t r1, r2, r3;
	r1 = (p[0][0] << 16) | (p[0][1] << 8) | (p[0][2] << 0);
	r2 = (p[1][0] << 16) | (p[1][1] << 8) | (p[1][2] << 0);
	r3 = (p[2][0] << 16) | (p[2][1] << 8) | (p[2][2] << 0);
	return cfu_convolute(r1, r2, r3);
}
*/
