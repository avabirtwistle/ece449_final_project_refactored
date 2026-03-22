library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants_package is 

    -- ALU operation modes
    constant ALU_ADD : std_logic_vector(2 downto 0) := "000";
    constant ALU_SUB : std_logic_vector(2 downto 0) := "001";
    -- TODO: add more ALU operation modes as needed

    -- TODO: add control signal constants

    -- program counter modes
    constant PC_INCREMENT : std_logic_vector(1 downto 0) := "00"; -- increment the PC by 2 to point to the next instruction
    constant PC_IM_VALUE      : std_logic_vector(1 downto 0) := "01"; -- update the PC with an immediate value (for jumps and branches)
    constant PC_NOP           : std_logic_vector(1 downto 0) := "10"; -- hold the current value of the PC (no update)
    constant PC_TBD         : std_logic_vector(1 downto 0) := "11"; -- to be determined (for future use, if needed)


end package constants_package;