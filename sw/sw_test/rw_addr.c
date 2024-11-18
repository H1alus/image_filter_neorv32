// ================================================================================ 
// image_filter_NEORV32: hardware accelerated image filter for neorv32                             
// -------------------------------------------------------------------------------- 
// Project repository - https://github.com/H1alus/image_filter_neorv32              
// Copyright (c) 2024 Vittorio Folino. All rights reserved.                         
// Licensed under the BSD-3-Clause license, see LICENSE for details.                
// SPDX-License-Identifier: BSD-3-Clause                                            
// ================================================================================
int next_read = -4;
int next_write = -4;

int nextReadAddr() {
	next_read += 4;
	return next_read;
}

void rewindReadAddr() {
	next_read -= 4;
}

int nextWriteAddr() {
	next_write += 4;
	return next_write;
}

void rewindWriteAddr() {
	next_write -= 4;
}
