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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;


entity image_filter is
    Port(
        clock, reset : in std_logic;
        enable_i : in std_logic;
        start_i : in std_logic;
        W1, W2, W3 : in std_logic_vector(3 downto 0); 
        data_i : in std_logic_vector(pixelSize - 1 downto 0);
        valid_o : out std_logic;
        data_o : out std_logic_vector(pixelSize - 1 downto 0)
        );
end image_filter;

architecture Behavioral of image_filter is
    component bufferLine is
        port(
            clk, rst : in std_logic;
            enable_i : in std_logic;
            idata : in std_logic_vector(pixelSize - 1 downto 0);
            odata : out buf_t
            );
    end component;
    
    component stateMachine is
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
    end component;
    
    -- data seleceted from the input mux (last or 0 when circuit unused) --
    signal idataIn : std_logic_vector(pixelSize - 1 downto 0);
    
    -- window from the bufferline -- 
    signal P : buf_t; -- 8 bit
   
    signal preAdded : adds_t; -- 11 bit
    
    type m_t is array (3 downto 1) of std_logic_vector(14 downto 0); -- 15 bit
    signal prods : m_t;
    
    signal convoluted : std_logic_vector(16 downto 0); -- 17 bit output

    -- finite state machine and counters signals -- 
    signal cnt : std_logic_vector(latencyL - 1 downto 0);
    signal cntLast : std_logic_vector(npixelsL - 1 downto 0);
    signal last : std_logic;
    signal resetCount : std_logic;
    signal reset_last : std_logic;
   
    -- filter coefficients registers -- 
    signal ws : coeff_t (3 downto 1);
  
begin
    -- finite state machine -------------------------------------------------------------
    ---------------------------------------------------------------------------------------
    fsm : stateMachine port map(clock, reset, start_i, enable_i, cnt, cntLast, reset_last, valid_o, last);
    resetCount <= reset or reset_last;
    
    countValid : process(clock)
    begin
        if rising_edge(clock) then
            if resetCount = '1' then
                cnt <= (others => '0');
            elsif enable_i = '1' then
                cnt <= cnt + '1';
            end if;
        end if;
    end process;
    
    countLast : process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                cntLast <= (others => '0');
            elsif enable_i = '1' then
                cntLast <= cntLast + '1';
            end if;
        end if;
    end process; 
    
    -- registers for kernel coefficients ------------------------------------------------ 
    ---------------------------------------------------------------------------------------
    coeff_reg: process(clock, reset)
    begin
        if reset = '1' then  
           ws(1) <= (others => '0');
           ws(2) <= (others => '0');
           ws(3) <= (others => '0');
        elsif rising_edge(clock) then
           ws(1) <= W1;
           ws(2) <= W2;
           ws(3) <= W3;
         end if;
    end process;    
    
    -- the actual elaboration -----------------------------------------------------------
    ---------------------------------------------------------------------------------------
    
    -- mux the input -------------------------------------------------------------------
    ---------------------------------------------------------------------------------------
    input_mux_i : with last select idataIn <= 
                            data_i when '0',
                            (others => '0') when '1',
                            (others => '0') when others;
    
    -- bufferline ----------------------------------------------------------------------
    ---------------------------------------------------------------------------------------
    bufferLine_i : bufferLine port map(clk => clock, enable_i => enable_i, rst => reset, idata => idataIn, odata => P);
    
    -- pre adder ----------------------------------------------------------------------- 
    ---------------------------------------------------------------------------------------
   pre_adder: process(clock)
   begin
     if rising_edge(clock) then
        if reset = '1' then
            preAdded.sForW1 <= (others => '0');
            preAdded.sForW2 <= (others => '0');
            preAdded.sForW3 <= (others => '0');
        elsif enable_i = '1' then
            preAdded.sForW1 <= ("000" & P(0,0)) + ("000" & P(0,2)) + ("000" & P(2,0)) + ("000" & P(2,2));
            preAdded.sForW2 <= ("000" & P(0,1)) + ("000" & P(1,0)) + ("000" & P(1,2)) + ("000" & P(2,1));
            preAdded.sForW3 <= "000" & P(1,1);
        end if;
     end if;
   end process;
   
   --  multipliers --------------------------------------------------------------------
   -------------------------------------------------------------------------------------
   mul: process(clock)
   begin
     if rising_edge(clock) then
        if reset = '1' then
            prods(1) <= (others => '0');
            prods(2) <= (others => '0');
            prods(3) <= (others => '0');
        elsif enable_i = '1' then
            prods(1) <= std_logic_vector(signed(preAdded.sForW1) * signed(ws(1)));
            prods(2) <= std_logic_vector(signed(preAdded.sForW2) * signed(ws(2)));
            prods(3) <= std_logic_vector(signed(preAdded.sForW3) * signed(ws(3)));
            --report " is " & to_hstring(prods(3));
        end if;
     end if;
   end process;


   -- sum for convolution -------------------------------------------------------------
   ---------------------------------------------------------------------------------------
   -- pipe the output -- 
   sum_for_conv_reg: process(clock, reset)
    begin
        if rising_edge(clock) then  
            if reset = '1' then
                convoluted <= (others => '0');
            elsif enable_i = '1' then     
                convoluted <= std_logic_vector(resize(signed(prods(1)), 17) + resize(signed(prods(2)), 17) + resize(signed(prods(3)), 17));
            end if;
        end if;
    end process;
    
    -- saturation of the output
    saturation: process(convoluted)
    begin
        if unsigned(convoluted) > to_unsigned(255, convoluted'length) then
            data_o <= std_logic_vector(to_unsigned(255,data_o'length));
        elsif unsigned(convoluted) < to_unsigned(0, convoluted'length)  then
          data_o <= std_logic_vector(to_unsigned(0, data_o'length)) ;
        else
            data_o <= convoluted(7 downto 0);
        end if;
    end process;
end Behavioral;
