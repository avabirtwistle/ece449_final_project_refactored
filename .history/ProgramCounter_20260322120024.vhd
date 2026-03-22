----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/09/2026 04:54:41 PM
-- Design Name: 
-- Module Name: ProgramCounter - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity program_counter is
Port ( 
    clk: in std_logic;
    mode: in std_logic_vector(1 downto 0);
    current_pc: out std_logic_vector(15 downto 0);
    new_pc: in std_logic_vector(15 downto 0) -- new_pc is the immediate value to load into the program counter when mode is PC_IM_VALUE
);
end program_counter;

architecture Behavioral of program_counter is
    signal pc_curr: std_logic_vector(15 downto 0) := (others => '0'); -- using others 0 is better than "0000000000000000" because it is more concise and less error-prone
begin
    -- Process to update the program counter on the rising edge of the clock
    process(clk)
    begin
        if rising_edge(clk) then
            case mode is
                when PC_INCREMENT =>
                    pc_curr <= std_logic_vector(unsigned(pc_curr) + 2); -- increment by 2 to get the next instruction address
                when PC_IM_VALUE =>
                    pc_curr <= ; -- load the immediate value into the program counter
                when PC_RESET =>
                    pc_curr <= (others => '0'); -- reset the program counter to 0
                when others =>
                    pc_curr <= pc_curr; -- hold the current value of the program counter


end Behavioral;
