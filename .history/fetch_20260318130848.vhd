----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: register_file -
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is
    port(
        clk         : in  std_logic;
        reset       : in  std_logic;
        pc_plus2    : in  std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(15 downto 0)
    );
end fetch;
