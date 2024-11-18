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

entity neorv32_mine is
  port (
    -- Global control --
    clk_i  : in  std_logic;
    rstn_i : in  std_logic;
    
    -- External bus interface (available if XBUS_EN = true) --
    xbus_adr_o     : out std_ulogic_vector(31 downto 0);                    -- address
    xbus_dat_o     : out std_ulogic_vector(31 downto 0);                    -- write data
    xbus_tag_o     : out std_ulogic_vector(2 downto 0);                     -- access tag
    xbus_we_o      : out std_ulogic;                                        -- read/write
    xbus_sel_o     : out std_ulogic_vector(3 downto 0);                     -- byte enable
    xbus_stb_o     : out std_ulogic;                                        -- strobe
    xbus_cyc_o     : out std_ulogic;                                        -- valid cycle
    xbus_dat_i     : in  std_ulogic_vector(31 downto 0) := (others => 'L'); -- read data
    xbus_ack_i     : in  std_ulogic := 'L';                                 -- transfer acknowledge
    xbus_err_i     : in  std_ulogic := 'L';                                 -- transfer error

    
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o    : out std_ulogic;                                        -- UART0 send data
    uart0_rxd_i    : in  std_ulogic;                                 -- UART0 receive data
    uart0_rts_o    : out std_ulogic;                                        -- HW flow control: UART0.RX ready to receive ("RTR"), low-active, optional
    uart0_cts_i    : in  std_ulogic;                                 -- HW flow control: UART0.TX allowed to transmit, low-active, optional
    
    -- CPU interrupts (for chip-internal usage only) --
    mtime_irq_i    : in  std_ulogic := 'L';                                 -- machine timer interrupt, available if IO_MTIME_EN = false
    msw_irq_i      : in  std_ulogic := 'L';                                 -- machine software interrupt
    mext_irq_i     : in  std_ulogic := 'L'                                  -- machine external interrupt
  );
end entity;

architecture neorv32_mine_rtl of neorv32_mine is

begin

  -- The core of the problem ----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_inst: entity neorv32.neorv32_top
  generic map (
    -- General --
    CLOCK_FREQUENCY              => 100_000_000,   -- clock frequency of clk_i in Hz
    BOOT_MODE_SELECT             => 2,             -- boot configuration select (default = 0 = bootloader)
    IO_TRNG_EN                   => false,
    -- riscv extensions --
    RISCV_ISA_M                  => false,
    RISCV_ISA_Zxcfu              => true,
    
    -- Internal Instruction memory --
    MEM_INT_IMEM_EN              => true,   -- implement processor-internal instruction memory
    MEM_INT_IMEM_SIZE            => 8*1024, -- size of processor-internal instruction memory in bytes
    -- Internal Data memory --
    MEM_INT_DMEM_EN              => true,   -- implement processor-internal data memory
    MEM_INT_DMEM_SIZE            => 64*1024, -- size of processor-internal data memory in bytes
    -- Processor peripherals --
    IO_MTIME_EN                  => false,      -- implement machine system timer (MTIME)?
    IO_PWM_NUM_CH                => 0,      -- number of PWM channels to implement (0..12); 0 = disabled
    IO_UART0_EN                  => false,       -- implement primary universal asynchronous receiver/transmitter (UART0)?
    IO_CFS_EN                    => false,       -- implement custom functions subsystem (CFS)?
    -- External bus interface --
    XBUS_EN               => true,          -- implement external memory bus interface?
    XBUS_TIMEOUT          => 256,           -- cycles after a pending bus access auto-terminates (0 = disabled)
    XBUS_REGSTAGE_EN      => true,          -- add register stage
    XBUS_CACHE_EN         => true,          -- enable external bus cache (x-cache)
    XBUS_CACHE_NUM_BLOCKS => 4,             -- x-cache: number of blocks (min 1), has to be a power of 2
    XBUS_CACHE_BLOCK_SIZE => 32            -- x-cache: block size in bytes (min 4), has to be a power of 2
    
  )
  port map (
    -- Global control --
    clk_i  => clk_i,    -- global clock, rising edge
    rstn_i => rstn_i,   -- global reset, low-active, async
    
    -- primary UART0 (available if IO_UART0_EN = true) --
    uart0_txd_o    => uart0_txd_o,       -- UART0 send data
    uart0_rxd_i    => '0',       -- UART0 receive data
    uart0_rts_o    => uart0_rts_o,       -- HW flow control: UART0.RX ready to receive ("RTR"), low-active, optional
    uart0_cts_i    => '0',       -- HW flow control: UART0.TX allowed to transmit, low-active, optional
    
    -- External bus interface (available if XBUS_EN = true) --
    xbus_adr_o     => xbus_adr_o,                                           -- address
    xbus_dat_o     => xbus_dat_o,                                           -- write data
    xbus_tag_o     => xbus_tag_o,                                           -- access tag
    xbus_we_o      => xbus_we_o,                                            -- read/write
    xbus_sel_o     => xbus_sel_o,                                           -- byte enable
    xbus_stb_o     => xbus_stb_o,                                           -- strobe
    xbus_cyc_o     => xbus_cyc_o,                                           -- valid cycle
    xbus_dat_i     => xbus_dat_i,                                           -- read data
    xbus_ack_i     => xbus_ack_i,                                           -- transfer acknowledge
    xbus_err_i     => xbus_err_i,                                            -- transfer error
    
     -- CPU interrupts (for chip-internal usage only) --
    mtime_irq_i    => mtime_irq_i,                               -- machine timer interrupt, available if IO_MTIME_EN = false
    msw_irq_i      => msw_irq_i,                                -- machine software interrupt
    mext_irq_i     =>  mext_irq_i                                -- machine external interrupt
  );

end architecture;
