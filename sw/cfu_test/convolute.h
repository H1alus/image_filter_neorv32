// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#ifndef CONVOLUTE_H_INCLUDED
#define CONVOLUTE_H_INCLUDED

#include <neorv32.h>
#include <string.h>

#define convolute(p) neorv32_cfu_r4_instr(0b000, (\
        p[0][0] << 16) | (p[0][1] << 8) | (p[0][2] << 0),\
	(p[1][0] << 16) | (p[1][1] << 8) | (p[1][2] << 0),\
	(p[2][0] << 16) | (p[2][1] << 8) | (p[2][2] << 0))    // R4-type instruction

void set_kernel(uint32_t W1, uint32_t W2, uint32_t W3);
// int32_t convolute(uint32_t p[3][3]);

#endif
