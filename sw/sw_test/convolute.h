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

void set_kernel(uint32_t W1, uint32_t W2, uint32_t W3);
int32_t convolute(uint32_t p[3][3]);

#endif
