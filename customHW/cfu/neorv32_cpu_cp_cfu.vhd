-- ================================================================================ --
-- image_filter_NEORV32: hardware accelerated image filter for neorv32              --                
-- -------------------------------------------------------------------------------- --
-- Project repository - https://github.com/H1alus/image_filter_neorv32              --
-- Copyright (c) 2024 Vittorio Folino. All rights reserved.                         --
-- Licensed under the BSD-3-Clause license, see LICENSE for details.                --
-- SPDX-License-Identifier: BSD-3-Clause                                            --
-- ================================================================================ --
library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity neorv32_cpu_cp_cfu is
  port (
    -- global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    -- operation control --
    start_i     : in std_ulogic; -- operation trigger/strobe
    active_i    : in std_ulogic; -- operation in progress, CPU is waiting for CFU
    -- CSR interface --
    csr_we_i    : in  std_ulogic; -- write enable
    csr_addr_i  : in  std_ulogic_vector(1 downto 0); -- address (CSR address 0x800 to 0x803)
    csr_wdata_i : in  std_ulogic_vector(31 downto 0); -- write data
    csr_rdata_o : out std_ulogic_vector(31 downto 0); -- read data
    -- operands (form/via custom instruction word) --
    rtype_i     : in std_ulogic; -- instruction type (R3-type or R4-type); from instruction word's "opcode[5]" bit
    funct3_i    : in std_ulogic_vector(2 downto 0); -- "funct3" bit-field from custom instruction word
    funct7_i    : in std_ulogic_vector(6 downto 0); -- "funct7" bit-field from custom instruction word
    rs1_i       : in  std_ulogic_vector(31 downto 0); -- rf source 1 via "rs1" bit-field from custom instruction word
    rs2_i       : in  std_ulogic_vector(31 downto 0); -- rf source 2 via "rs2" bit-field from custom instruction word
    rs3_i       : in  std_ulogic_vector(31 downto 0); -- rf source 3 via "rs3" bit-field from custom instruction word
    -- result and status --
    result_o    : out std_ulogic_vector(31 downto 0); -- operation result
    valid_o     : out std_ulogic -- result valid, operation done; set one cycle before result_o is valid
  );
end neorv32_cpu_cp_cfu;

architecture neorv32_cpu_cp_cfu_rtl of neorv32_cpu_cp_cfu is

  -- CFU instruction type formats --
  constant r3type_c : std_ulogic := '0'; -- R3-type CFU instructions (custom-0 opcode)
  constant r4type_c : std_ulogic := '1'; -- R4-type CFU instructions (custom-1 opcode)
  
  -- convolute the window R4-type instruction --
  constant convolute_c  : std_ulogic_vector(2 downto 0) := "000"; -- we give window r4 type instr 
  
  type window_t is array (2 downto 0, 2 downto 0) of std_logic_vector(7 downto 0);
  signal p : window_t;


  signal WS1, WS2, WS3 : std_logic_vector(3 downto 0); -- registers set via csr access
  signal sForW1, sForW2, sForW3 : std_logic_vector(10 downto 0);
  type m_t is array (3 downto 1) of std_logic_vector(14 downto 0); -- 15 bit
  signal prods : m_t;
  signal convoluted : std_logic_vector(16 downto 0); -- 17 bit output

  signal data_o : std_logic_vector(7 downto 0);
  
  signal done : std_logic_vector(2 downto 0);

begin

  -- CFU-Internal Control and Status Registers (CFU-CSRs): 128-Bit Key Storage
  -- synchronous write access --
  csr_write_access: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      WS1 <= (others => '0');
      WS2 <= (others => '0');
      WS3 <= (others => '0');
    elsif rising_edge(clk_i) then
      if (csr_we_i = '1') then -- CSR write enable
      case csr_addr_i is
        when "00" => WS1 <= std_logic_vector(resize(signed(csr_wdata_i), 4)); -- write to CSR address
        when "01" => WS2 <= std_logic_vector(resize(signed(csr_wdata_i), 4)); -- write to CSR address
        when "10" => WS3 <= std_logic_vector(resize(signed(csr_wdata_i), 4)); -- write to CSR address
        when others => 
            WS1 <= WS1;
            WS2 <= WS2;
            WS3 <= WS3;
      end case;           
      end if;
    end if;
  end process csr_write_access;
  csr_rdata_o <= (others => '0');
   -- Convolution
    p(0,0) <= rs1_i(23 downto 16);
    p(0,1) <= rs1_i(15 downto 8);
    p(0,2) <= rs1_i(7 downto 0);
    p(1,0) <= rs2_i(23 downto 16);
    p(1,1) <= rs2_i(15 downto 8);
    p(1,2) <= rs2_i(7 downto 0);
    p(2,0) <= rs3_i(23 downto 16);
    p(2,1) <= rs3_i(15 downto 8);
    p(2,2) <= rs3_i(7 downto 0);
    
   convolution: process(rstn_i, clk_i)
   begin
     if (rstn_i = '0') then
      done <= (others => '0');
      -- p <= (others => (others => (others => '0')));
     elsif rising_edge(clk_i) then
         done(0) <= '0';
         done(1) <= done(0);
         done(2) <= done(1);
        if start_i = '1' and rtype_i = r4type_c then
            case funct3_i is
                when convolute_c =>
                    done(0) <= '1';
                    -- input mapping --
               when others => 
                    done(0) <= '0';
               end case;
        end if;
     end if;
   end process;
        -- pre adder
   pre_adder: process(clk_i, rstn_i)
   begin
     if rstn_i = '0' then
        sForW1 <= (others => '0');
        sForW2 <= (others => '0');
        sForW3 <= (others => '0');
     elsif rising_edge(clk_i) then
        sForW1 <= ("000" & p(0,0)) + ("000" & p(0,2)) + ("000" & p(2,0)) + ("000" & p(2,2));
        sForW2 <= ("000" & p(0,1)) + ("000" & p(1,0)) + ("000" & p(1,2)) + ("000" & p(2,1));
        sForW3 <= "000" & p(1,1);
     end if;
   end process;
   
   --  multipliers 
   mul: process(clk_i, rstn_i)
   begin
     if rstn_i = '0' then
        prods(1) <= (others => '0');
        prods(2) <= (others => '0');
        prods(3) <= (others => '0');
     elsif rising_edge(clk_i) then
        prods(1) <= std_logic_vector(signed(sForW1) * signed(WS1));
        prods(2) <= std_logic_vector(signed(sForW2) * signed(WS2));
        prods(3) <= std_logic_vector(signed(sForW3) * signed(WS3));
            --report " is " & to_hstring(prods(3));
     end if;
   end process;

   -- sum for convolution
    convoluted <= std_logic_vector(resize(signed(prods(1)), 17) + resize(signed(prods(2)), 17) + resize(signed(prods(3)), 17));
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

  -- Function Result Select
  result_select: process(rtype_i, funct3_i, done)
  begin
    if (rtype_i = r4type_c) then -- R4-type instructions; function select via "funct3" and ""funct7
    -- ----------------------------------------------------------------------
      case funct3_i is -- just check "funct3" here; "funct7" bit-field is ignored
        when convolute_c => 
          result_o <= std_logic_vector(resize(unsigned(data_o), 32));
          valid_o  <= done(2); -- 3 stage multi cycle operation
          
        when others => -- all unspecified operations
          result_o <= (others => '0'); -- no logic implemented
          valid_o  <= '0'; -- this will cause an illegal instruction exception after timeout
      end case;

    else -- R3 type
      result_o <= (others => '0'); -- no logic implemented
      valid_o  <= '0'; -- this will cause an illegal instruction exception after timeout
    end if;
  end process result_select;

end neorv32_cpu_cp_cfu_rtl;
