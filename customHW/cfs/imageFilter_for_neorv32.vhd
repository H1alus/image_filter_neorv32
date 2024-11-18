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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library neorv32;
use neorv32.buf_pkg.all;

entity imageFilter_for_neorv32 is
 Port (
       clk_i  : in std_logic;                       -- clock
       rstn_i : in std_logic;                       -- global reset
       init_i : in std_logic;                       -- init submodule
       W1, W2, W3   : in std_logic_vector(3 downto 0); -- coefficientss for the kernel filter
       wr_i   : in std_logic;                       -- write access(fifo)
       data_i : in std_logic_vector(7 downto 0);    -- input data (fifo)
       data_o : out std_logic_vector(7 downto 0);   -- output data (fifo)
       re_i   : in std_logic;                          -- read enable (fifo)
       validated : out std_logic                      -- response, 1 if valid data 0 if not valid data
 );
end imageFilter_for_neorv32;

architecture Behavioral of imageFilter_for_neorv32 is
    component image_filter is
    Port(
        clock, reset : in std_logic;
        enable_i : in std_logic;
        start_i : in std_logic;
        W1, W2, W3 : in std_logic_vector(3 downto 0); 
        data_i : in std_logic_vector(pixelSize - 1 downto 0);
        valid_o : out std_logic;
        data_o : out std_logic_vector(pixelSize - 1 downto 0)
        );
end component;


    signal init_or_reset : std_logic;
    
    signal enabled : std_logic;
    signal start : std_logic;
    signal started: std_logic;
    constant FIFO_DEPTH : natural := 1024;
    constant countL : natural := natural(ceil(log2(real(FIFO_DEPTH))));
    type fifo_t is array (FIFO_DEPTH - 1 downto 0) of std_logic_vector(7 downto 0);
    signal in_fifo, out_fifo : fifo_t;
    signal cnt_in , cnt_out : std_logic_vector(countL downto 0);
    signal valid : std_logic;
    signal data_o_in : std_logic_vector(7 downto 0);
begin

    init_or_reset <= init_i or not rstn_i;
     -- write access --
    input_fifo: process(clk_i) 
     begin
        if rising_edge(clk_i) then
            if init_or_reset = '1' then -- reset or init asked from the top entity
                in_fifo <= (others => (others => '0'));
            elsif wr_i = '1' or enabled = '1' then -- new data is being written in to the fifo
                in_fifo(0) <= data_i;
                for i in FIFO_DEPTH - 1 downto 1 loop
                    in_fifo(i) <= in_fifo(i - 1);
                end loop;
           end if;
       end if;
    end process;
    
     write_access: process(clk_i) 
     begin
        if rising_edge(clk_i) then
            start <= '0';
            if init_or_reset = '1' then  -- reset or init asked from the top entity
                enabled <= '0';
                start <= '0';
                started <= '0';
            elsif cnt_in = std_logic_vector(to_unsigned(FIFO_DEPTH, countL + 1)) then
                enabled <= '1';
                if started = '0' then
                    start <= '1';
                    started <= '1';
                end if;
           end if;
       end if;
    end process;
    
    input_fifo_counter : process(clk_i) 
     begin
        if rising_edge(clk_i) then
            if init_or_reset = '1' then -- reset or init asked from the top entity
                cnt_in <= (others => '0');
            elsif wr_i = '1' then
                cnt_in <= cnt_in + '1';
            end if;
       end if;
    end process;
    
    -- read access -- 
     output_fifo_counter : process(clk_i) 
     begin
        if rising_edge(clk_i) then
            if init_or_reset = '1' then -- reset or init asked from the top entity
                cnt_out <= (others => '0');
            elsif valid = '1' then
                cnt_out <= cnt_out + '1';
            end if;
       end if;
    end process;
    
  
    output_fifo: process(clk_i) 
     begin
        if rising_edge(clk_i) then
            if init_or_reset = '1' then -- reset or init asked from the top entity
                out_fifo <= (others => (others => '0'));
            elsif valid = '1' or re_i = '1' then -- new data is being written in to the fifo
                out_fifo(0) <= data_o_in;
                for i in FIFO_DEPTH - 1 downto 1 loop
                    out_fifo(i) <= out_fifo(i - 1);
                end loop;
           end if;
       end if;
    end process;
    data_o <= out_fifo(FIFO_DEPTH - 1);
   
     read_access: process(clk_i) 
     begin
        if rising_edge(clk_i) then
            if init_or_reset = '1' then  -- reset or init asked from the top entity
               validated <= '0';
            elsif cnt_out = std_logic_vector(to_unsigned(FIFO_DEPTH - 1, countL)) then
               validated <= '1';
           end if;
       end if;
    end process;
   
    -- submodule instance -- 
    image_filter_i : image_filter
        port map(
            clock         => clk_i,
            reset         => init_or_reset,
            enable_i      => enabled,
            start_i       => start,
            W1            => W1,
            W2            => W2,
            W3            => W3,
            data_i        => in_fifo(FIFO_DEPTH - 1),
            valid_o       => valid,
            data_o        => data_o_in -- no problem if valid is 0, we just overwrite the first position since the fifo is data gated
         );

end Behavioral;


