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
        w_addr: in std_logic_vector(2 downto 0); -- the index of the register to write to when wr_en is high
        w_data: in std_logic_vector(15 downto 0); -- the data to write
        r_addr0, r_addr1: in std_logic_vector(2 downto 0); -- the indices of the registers to read from
        
        r_data0, r_data1: out std_logic_vector(15 downto 0) -- the data read from the registers indexed by r_addr0 and r_addr1, respectively
  );
end register_file;

architecture rtl of register_file is

type reg_file_type is array (7 downto 0) of std_logic_vector(15 downto 0);

signal array_reg: reg_file_type;
signal array_next: reg_file_type;
signal en: std_logic_vector(7 downto 0);

begin
    process(clks)
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
     
        r_data0 <= array_reg(to_integer(unsigned(r_addr0)));
        r_data1 <= array_reg(to_integer(unsigned(r_addr1)));
     
end rtl;
