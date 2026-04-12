----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2026 11:17:36 AM
-- Design Name: 
-- Module Name: memory - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work; 
use work.constants_package.all;

entity writeback is
    Port (
        alu_result   : in  std_logic_vector(15 downto 0);
        mem_data     : in  std_logic_vector(15 downto 0);
        dest_reg     : in  std_logic_vector(2 downto 0);
        pc_plus2     : in  std_logic_vector(15 downto 0);

        reg_write    : in  std_logic;
        wb_src       : in  std_logic_vector(1 downto 0);

        in_data      : in  std_logic_vector(15 downto 0);

        wb_data      : out std_logic_vector(15 downto 0);
        wb_dest_reg  : out std_logic_vector(2 downto 0);
        wb_reg_write : out std_logic
    );
end writeback;

architecture Behavioral of writeback is

    signal mux_out : std_logic_vector(15 downto 0);

begin

    u_mux : entity work.MUX
        port map (
            a           => alu_result,
            b           => mem_data,
            c           => pc_plus2,
            control_sel => wb_src,
            d_out       => mux_out
        );

    -- Final writeback data:
    -- Auxiliary writeback covers synthesized immediates and carried input-port values.
    wb_data <= in_data when wb_src = WB_AUX else mux_out;

    -- Pass through register file control info
    wb_dest_reg  <= dest_reg;
    wb_reg_write <= reg_write;
end Behavioral;