-- ================================================================================ --
-- image_filter_NEORV32: hardware accelerated image filter for neorv32              --                
-- -------------------------------------------------------------------------------- --
-- Project repository - https://github.com/H1alus/image_filter_neorv32              --
-- Copyright (c) 2024 Vittorio Folino. All rights reserved.                         --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.math_real.all;
library neorv32;
use neorv32.buf_pkg.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity stateMachine is
    Port (
    clock : in std_logic;
    reset : in std_logic;
    start : in std_logic;
    enable_i : in std_logic;
    cnt : in std_logic_vector(latencyL - 1 downto 0); 
    cntLast : in std_logic_vector(npixelsL - 1 downto 0);
    
    reset_last: out std_logic;
    valid : out std_logic;
    last : out  std_logic
    );
end stateMachine;

architecture Behavioral of stateMachine is

    -- define states of the state machine
    type state_t is (base, wait_state, processing, paused, wait_last, finale);
    signal state, prev_state : state_t;

begin
    process(clock, reset)
    begin
        if reset = '1' then
           state <= base;
           prev_state <= base;
           valid <= '0';
           last <= '0';
           reset_last <= '0';
        elsif(rising_edge(clock)) then
            valid <= '0';
            last <= '0';
            reset_last <= '0';
            case(state) is
                when base =>
                    if start = '1' then
                        state <= wait_state;
                        prev_state <= wait_state;
                     else
                      state <= base;
                    end if;

                when wait_state =>
                    if enable_i = '0' then
                        state <= paused;
                        prev_state <= wait_state;
                    elsif cnt >= latencyS + 3 then 
                        state <= processing;
                        valid <= '1';                        
                    else
                      state <= wait_state;
                    end if;

                when processing =>
                    if enable_i = '0' then
                        state <= paused;
                        prev_state <= processing;
                    elsif cntLast >= npixelsS - 1 then
                        state <= wait_last;
                        reset_last <= '1';
                        valid <= '1';
                        last <= '1';
                    else
                      state <= processing;
                      valid <= '1';
                    end if;
                
                when paused =>
                    if enable_i = '1' then
                        state <= prev_state;
                    else
                        state <= paused;
                    end if;
                
                when wait_last =>
                     if enable_i = '0' then
                        state <= paused;
                        prev_state <= wait_last;
                    elsif cnt >= latencyS + 2 then
                        state <= finale;
                    else
                      state <= wait_last;
                      valid <= '1';
                      last <= '1';
                    end if;
                
                 when finale =>
                    if enable_i = '0' then
                        state <= paused;
                        prev_state <= finale;
                    elsif start='0' then
                      state <= base;
                    else
                      state <= finale;
                    end if;
              
            end case;
        end if;
    end process;

end Behavioral;
