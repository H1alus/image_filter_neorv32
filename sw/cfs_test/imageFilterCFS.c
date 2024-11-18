// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
#include "imageFilterCFS.h"

void init_imageFilter() {
	NEORV32_CFS->REG[0] = 1;
}

int setImageKernel(int8_t W1, int8_t W2, int8_t W3) {
	if(W1 <= MAX_4BIT_SIGNED && W1 >= MIN_4BIT_SIGNED) {
		NEORV32_CFS->REG[1] = W1;
	} else {
		return -1;
	}
	if(W2 <= MAX_4BIT_SIGNED && W2 >= MIN_4BIT_SIGNED) {
		NEORV32_CFS->REG[2] = W2;
	} else {
		return -1;
	}
	if(W3 <= MAX_4BIT_SIGNED && W3 >= MIN_4BIT_SIGNED) {
		NEORV32_CFS->REG[3] = W3;
	} else {
		return -1;
	}
	return 0;
}

void pushDataToFilter(uint32_t data) {
	NEORV32_CFS->REG[4] = data;
}

uint32_t pullDataFromImageFilter() {
	return NEORV32_CFS->REG[0];
}
