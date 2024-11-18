// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#include "convolute.h"

int32_t w1;
int32_t w2;
int32_t w3;

void set_kernel(uint32_t W1, uint32_t W2, uint32_t W3) {
	w1 = W1;
	w2 = W2;
	w3 = W3;
}

int32_t convolute(uint32_t p[3][3]) {
	return p[0][0]*w1 + p[0][1]*w2 + p[0][2]*w1 + 
		   p[1][0]*w2 + p[1][1]*w3 + p[1][2]*w2 + 
		   p[2][0]*w1 + p[2][1]*w2 + p[2][2]*w1 ;
}
