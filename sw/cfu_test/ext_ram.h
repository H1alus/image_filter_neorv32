// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#ifndef EXT_RAM_H_INCLUDED
#define EXT_RAM_H_INCLUDED

#include <neorv32.h>
#include <string.h>

uint32_t readFromExtRAM(uint32_t addr);
void writeToExtRAM(uint32_t addr, uint32_t data);

#endif
