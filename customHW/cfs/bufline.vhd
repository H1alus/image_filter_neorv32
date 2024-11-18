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
library neorv32;
use neorv32.buf_pkg.all;

entity bufferLine is
       port(
            clk, rst : in std_logic;
            enable_i : in std_logic;
            idata : in std_logic_vector(pixelSize - 1 downto 0);
            odata : out buf_t
            );
end bufferline;


architecture Behavioral of bufferLine is

	type reg_mat_t is array(mrows - 1 downto 1, fifoL - 1 downto 0) of 
		std_logic_vector(pixelSize - 1 downto 0);

    -- internal matrix
	signal d : buf_t;

    -- buffers of the fifos
	signal buffers : reg_mat_t;

begin

    -- generation of the matrix
		proc : process(clk)
		begin
		mat_gen: for i in 0 to mrows - 1 loop
		    
			if rising_edge(clk) then
			    if rst = '1' then
                  for j in 0 to mcols - 1 loop
                    d(i, j) <= (others=>'0');
                end loop;
                elsif enable_i = '1' then
                    if i > 0 then
                        d(i, 0) <= buffers(i, fifoL - 1);
                    else
                        d(0, 0) <= idata(pixelSize - 1 downto 0);
                    end if;
                    assign: for j in mcols - 1 downto 1 loop
                        d(i, j) <= d(i, j - 1);
                    end loop;
                end if;
		    end if;
		   end loop;
		end process;
	

    -- generation of the fifos
		proc2 : process(clk)
		begin
			fifos_gen : for i in 1 to mrows - 1 loop           
			if rising_edge(clk) then
			     if rst = '1' then
                    resetaLL: for j in 0 to fifoL - 1 loop
                    buffers(i, j) <= (others=>'0');
                    end loop;
                 elsif enable_i = '1' then
                    buffers(i, 0) <= d(i - 1, mcols - 1);
                    genff: for j in fifoL - 1 downto 1 loop
                       buffers(i, j) <= buffers(i, j - 1);
                   end loop;
                 end if;
			end if;
		end loop;
		end process;
    odata <= d;

end Behavioral;
