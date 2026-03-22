library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants_package is 

    -- ALU operation modes 
    -- IF this gets changed Please comment it out instead of completely removing it
    constant ALU_NOP        : std_logic_vector(2 downto 0) := "000";
    constant ALU_ADD        : std_logic_vector(2 downto 0) := "001";
    constant ALU_SUB        : std_logic_vector(2 downto 0) := "010";
    constant ALU_MUL        : std_logic_vector(2 downto 0) := "011";
    constant ALU_NAND       : std_logic_vector(2 downto 0) := "100";
    constant ALU_SHL        : std_logic_vector(2 downto 0) := "101";
    constant ALU_SHR        : std_logic_vector(2 downto 0) := "110";
    constant ALU_TEST       : std_logic_vector(2 downto 0) := "111";
    -- TODO: add more ALU operation modes as needed

    -- TODO: add control signal constants

    -- program counter modes
    constant PC_INCREMENT   : std_logic_vector(1 downto 0) := "00"; -- increment the PC by 2 to point to the next instruction
    constant PC_IM_VALUE    : std_logic_vector(1 downto 0) := "01"; -- update the PC with an immediate value (for jumps and branches)
    constant PC_NOP         : std_logic_vector(1 downto 0) := "10"; -- hold the current value of the PC (no update)
    constant PC_TBD         : std_logic_vector(1 downto 0) := "11"; -- to be determined (for future use, if needed)

    -- Opcode constants from ISA table
    constant OP_NOP         : std_logic_vector(6 downto 0) := "0000000"; -- 0
    constant OP_ADD         : std_logic_vector(6 downto 0) := "0000001"; -- 1
    constant OP_SUB         : std_logic_vector(6 downto 0) := "0000010"; -- 2
    constant OP_MUL         : std_logic_vector(6 downto 0) := "0000011"; -- 3
    constant OP_NAND        : std_logic_vector(6 downto 0) := "0000100"; -- 4
    constant OP_SHL         : std_logic_vector(6 downto 0) := "0000101"; -- 5
    constant OP_SHR         : std_logic_vector(6 downto 0) := "0000110"; -- 6
    constant OP_TEST        : std_logic_vector(6 downto 0) := "0000111"; -- 7
    constant OP_OUT_PORT    : std_logic_vector(6 downto 0) := "0100000"; -- 32
    constant OP_IN_PORT     : std_logic_vector(6 downto 0) := "0100001"; -- 33
    
    constant OP_BRR         : std_logic_vector(6 downto 0) := "1000000"; -- 64
    constant OP_BRR_N       : std_logic_vector(6 downto 0) := "1000001"; -- 65
    constant OP_BRR_Z       : std_logic_vector(6 downto 0) := "1000010"; -- 66
    constant OP_BR          : std_logic_vector(6 downto 0) := "1000011"; -- 67
    constant OP_BR_N        : std_logic_vector(6 downto 0) := "1000100"; -- 68
    constant OP_BR_Z        : std_logic_vector(6 downto 0) := "1000101"; -- 69
    constant OP_BR_SUB      : std_logic_vector(6 downto 0) := "1000110"; -- 70
    constant OP_RETURN      : std_logic_vector(6 downto 0) := "1000111"; -- 71

    
    

end package constants_package;