// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#ifndef IMAGEFILTERCFS_H_INCLUDED
#define IMAGEFILTERCFS_H_INCLUDED

#include <neorv32.h>
#include <string.h>

#define MAX_4BIT_SIGNED 7
#define MIN_4BIT_SIGNED -8

void init_imageFilter();
int setImageKernel(int8_t W1, int8_t W2, int8_t W3);
void pushDataToFilter(uint32_t data);
uint32_t pullDataFromImageFilter();

#endif
