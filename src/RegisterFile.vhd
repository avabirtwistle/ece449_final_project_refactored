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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity register_file is
  Port (
        clk, reset, wr_en: in std_logic;
        w_addr: in std_logic_vector(2 downto 0);
        w_data: in std_logic_vector(15 downto 0);
        r_addr0, r_addr1: in std_logic_vector(2 downto 0);
        r_data0, r_data1: out std_logic_vector(15 downto 0);
        dbg_r0, dbg_r1, dbg_r2, dbg_r3: out std_logic_vector(15 downto 0);
        dbg_r4, dbg_r5, dbg_r6, dbg_r7: out std_logic_vector(15 downto 0)
  );
end register_file;

architecture rtl of register_file is

type reg_file_type is array (7 downto 0) of std_logic_vector(15 downto 0);

signal array_reg: reg_file_type;
signal array_next: reg_file_type;
signal en: std_logic_vector(7 downto 0);

begin
    process(clk,reset)
    begin
        if(reset = '1') then
            array_reg(0) <= (others => '0');
            array_reg(1) <= (others => '0');
            array_reg(2) <= (others => '0');
            array_reg(3) <= (others => '0');
            array_reg(4) <= (others => '0');
            array_reg(5) <= (others => '0');
            array_reg(6) <= (others => '0');
            array_reg(7) <= (others => '0');
        elsif (rising_edge(clk)) then
            array_reg(0) <= array_next(0);            
            array_reg(1) <= array_next(1);            
            array_reg(2) <= array_next(2);            
            array_reg(3) <= array_next(3);            
            array_reg(4) <= array_next(4);            
            array_reg(5) <= array_next(5);            
            array_reg(6) <= array_next(6);            
            array_reg(7) <= array_next(7);                          
        end if;
     end process;
     
     process(array_reg, wr_en, w_addr, w_data)
     begin
        array_next <= array_reg;
        if wr_en = '1' then
            array_next(to_integer(unsigned(w_addr))) <= w_data;
        end if;
     end process;

     -- Robin Changes Start
     -- Explanation of changes:
     -- 1) Added write-through behavior on the read ports.
     -- 2) When decode reads the same register that WB is writing in the current cycle,
     --    the read ports now return w_data immediately instead of the stale array_reg value.
     -- 3) This fixes the remaining RAW hazard where a consumer still captured the old operand
     --    even after stalling until the producer reached MEM/WB.
     -- Robin Changes End.
     -- r_data0 <= array_reg(to_integer(unsigned(r_addr0)));
     -- r_data1 <= array_reg(to_integer(unsigned(r_addr1)));
     r_data0 <= w_data when (wr_en = '1' and w_addr = r_addr0) else array_reg(to_integer(unsigned(r_addr0)));
     r_data1 <= w_data when (wr_en = '1' and w_addr = r_addr1) else array_reg(to_integer(unsigned(r_addr1)));

     dbg_r0 <= array_reg(0);
     dbg_r1 <= array_reg(1);
     dbg_r2 <= array_reg(2);
     dbg_r3 <= array_reg(3);
     dbg_r4 <= array_reg(4);
     dbg_r5 <= array_reg(5);
     dbg_r6 <= array_reg(6);
     dbg_r7 <= array_reg(7);
     
end rtl;
