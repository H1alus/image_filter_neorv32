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
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cfs is
  generic (
    CFS_CONFIG   : std_ulogic_vector(31 downto 0); -- custom CFS configuration generic
    CFS_IN_SIZE  : natural; -- size of CFS input conduit in bits
    CFS_OUT_SIZE : natural  -- size of CFS output conduit in bits
  );
  port (
    clk_i       : in  std_ulogic; -- global clock line
    rstn_i      : in  std_ulogic; -- global reset line, low-active, use as async
    bus_req_i   : in  bus_req_t; -- bus request
    bus_rsp_o   : out bus_rsp_t := rsp_terminate_c; -- bus response
    clkgen_en_o : out std_ulogic := '0'; -- enable clock generator
    clkgen_i    : in  std_ulogic_vector(7 downto 0); -- "clock" inputs
    irq_o       : out std_ulogic := '0'; -- interrupt request
    cfs_in_i    : in  std_ulogic_vector(CFS_IN_SIZE-1 downto 0); -- custom inputs
    cfs_out_o   : out std_ulogic_vector(CFS_OUT_SIZE-1 downto 0) := (others => '0') -- custom outputs
  );
end neorv32_cfs;

architecture neorv32_cfs_rtl of neorv32_cfs is

  -- default CFS interface registers --
  type cfs_regs_t is array (0 to 3) of std_ulogic_vector(31 downto 0); -- just implement 4 registers for this example
  signal cfs_reg_wr : cfs_regs_t; -- interface registers for WRITE accesses
  signal cfs_reg_rd : cfs_regs_t := (others => (others => '1')); -- interface registers for READ accesses
  signal data_o_submod : std_logic_vector(7 downto 0);
  signal init_submod : std_logic;
  signal wr_submod, re_submod : std_logic;
  signal validated_submod : std_logic;
  signal irq_o_in : std_ulogic := '0';

begin
  cfs_out_o <= (others => '0'); 
  clkgen_en_o <= '0';
  bus_access: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      cfs_reg_wr(0) <= (others => '0');
      cfs_reg_wr(1) <= (others => '0');
      cfs_reg_wr(2) <= (others => '0');
      cfs_reg_wr(3) <= (others => '0');
      init_submod <= '0';
      wr_submod <= '0';
      
      bus_rsp_o     <= rsp_terminate_c;
      
    elsif rising_edge(clk_i) then -- synchronous interface for read and write accesses
      -- transfer/access acknowledge --
      bus_rsp_o.ack <= bus_req_i.stb;

      -- tie to zero if not explicitly used --
      bus_rsp_o.err <= '0';

      -- defaults --
      bus_rsp_o.data <= (others => '0'); -- the output HAS TO BE ZERO if there is no actual (read) access
      init_submod <= '0';
      wr_submod <= '0';
      re_submod <= '0';
      -- bus access --
      if (bus_req_i.stb = '1') then -- valid access cycle, STB is high for one cycle

        -- write access --
        if (bus_req_i.rw = '1') then
          if (bus_req_i.addr(7 downto 2) = "000000") then -- address size is fixed! -- init submodule platform
            init_submod <= '1';
          end if;
          if (bus_req_i.addr(7 downto 2) = "000001") then -- set kernel coefficients w1
            cfs_reg_wr(0) <= bus_req_i.data;
          end if;
          
          if (bus_req_i.addr(7 downto 2) = "000010") then -- set kernel coefficient W2
            cfs_reg_wr(1) <= bus_req_i.data;
          end if;
          
          if (bus_req_i.addr(7 downto 2) = "000011") then -- set kernel coefficient W3
            cfs_reg_wr(2) <= bus_req_i.data;
          end if;
          
          if (bus_req_i.addr(7 downto 2) = "000100") then -- write data to fifo
            cfs_reg_wr(3) <= bus_req_i.data;
            wr_submod <= '1';
          end if;

        -- read access --
        else
          if (bus_req_i.addr(7 downto 2) = "000000") then -- read data from fifo 
            re_submod <= '1';
            bus_rsp_o.data(7 downto 0) <= data_o_submod;
          end if;
        end if;
      end if;
    end if;
  end process bus_access;


  -- CFS Function Core
    image_filter : entity neorv32.imageFilter_for_neorv32
     port map (
       clk_i               => clk_i,                          -- clock
       rstn_i              => rstn_i,                         -- global reset
       init_i              => init_submod,                    -- init submodule
       W1                  => cfs_reg_wr(0)(3 downto 0),
       W2                  => cfs_reg_wr(1)(3 downto 0),
       W3                  => cfs_reg_wr(2)(3 downto 0),
       wr_i                => wr_submod,                      -- write access(fifo)
       data_i              => cfs_reg_wr(3)(7 downto 0),      -- input data (fifo)
       data_o              => data_o_submod,      -- output data (fifo)
       re_i                => re_submod,                      -- read enable (fifo)
       validated           => validated_submod               -- tells us if data is available (fifo)
    );

    irq_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            --default state--
            irq_o <= '0';
            if (init_submod or not rstn_i) = '1' then
                irq_o <= '0';
                irq_o_in <= '0';
            elsif (validated_submod and not irq_o_in) = '1' then
                irq_o <= '1';
                irq_o_in <= '1';
            end if;
        end if;
    end process;

end neorv32_cfs_rtl;
