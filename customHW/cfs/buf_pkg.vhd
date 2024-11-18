-- ================================================================================ --
-- image_filter_NEORV32: hardware accelerated image filter for neorv32              --                
-- -------------------------------------------------------------------------------- --
-- Project repository - https://github.com/H1alus/image_filter_neorv32              --
-- Copyright (c) 2024 Vittorio Folino. All rights reserved.                         --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;
use IEEE.NUMERIC_STD.ALL;

-- package defines the type buf_t used to compose the circuit matrix
package buf_pkg is
    type coeff_t is array(natural range <>) of std_logic_vector(3 downto 0);
    -- ncols is number of coloumns of image
    constant ncols : natural := 32;
    -- dimension of single pixels
    constant pixelSize : natural := 8;
    
    -- matrix dimensions
    constant mrows : natural := 3;
    constant mcols : natural := mrows;
    
    -- radius of the matrix
    constant radius : natural := natural(ceil(real((mrows - 1)/2)));
    -- latency of the matrix 
    constant latency : natural := ((radius * ncols ) + radius);
    
    -- number of pixels in a square image
    constant npixels : natural := (ncols * ncols);
    
    -- length of the fifos
    constant fifoL : natural := ncols - mcols;

    -- latency std_logic_vector bit numbers
    -- used in state machine and counters
    constant latencyL : natural := natural(ceil(log2(real(latency + 1))));
    constant npixelsL : natural := natural(ceil(log2(real(npixels + 1))));
    
    -- latency and npixels are declared in buf_pkg
    -- this signal are std_logic_vector rappresentation of latency - 1 and npixels - 1 respectively
    constant latencyS : std_logic_vector(latencyL - 1 downto 0) := 
        std_logic_vector(to_unsigned(latency, latencyL));
        
    constant npixelsS : std_logic_vector(npixelsL - 1 downto 0) :=  
        std_logic_vector(to_unsigned(npixels, npixelsL));
    
    -- buffer type used to reduce code overhead
	type buf_t is
		array(mrows - 1 downto 0, mcols - 1 downto 0) of
		std_logic_vector(pixelSize - 1 downto 0);
	
	-- simplify notation of zero value for buf_t
	constant bufZero : buf_t := (others => (others => (others => '0')));
	
    -- type to simplify overall structure of the project, adderOut
    type adds_t is record -- 8 bit + 3 bit from pre adding.
    	sForW1 : std_logic_vector(pixelSize + 2 downto 0);
    	sForW2 : std_logic_vector(pixelSize + 2 downto 0);
    	sForW3 : std_logic_vector(pixelSize + 2 downto 0);
    end record adds_t;
    
    
end package buf_pkg;
