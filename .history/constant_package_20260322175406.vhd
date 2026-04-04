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


    -- The opcode values for the instruction types
    constant OP_NOP      : std_logic_vector(6 downto 0) := "0000000";
    constant OP_ADD      : std_logic_vector(6 downto 0) := "0000001";
    constant OP_SUB      : std_logic_vector(6 downto 0) := "0000010";
    constant OP_MUL      : std_logic_vector(6 downto 0) := "0000011";
    constant OP_NAND     : std_logic_vector(6 downto 0) := "0000100";
    constant OP_SHL      : std_logic_vector(6 downto 0) := "0000101";
    constant OP_SHR      : std_logic_vector(6 downto 0) := "0000110";
    constant OP_TEST     : std_logic_vector(6 downto 0) := "0000111";
    constant OP_LOAD     : std_logic_vector(6 downto 0) := "0010000";
    constant OP_STORE    : std_logic_vector(6 downto 0) := "0010001";
    constant OP_LOADIMM  : std_logic_vector(6 downto 0) := "0010010";
    constant OP_MOV      : std_logic_vector(6 downto 0) := "0010011";
    constant OP_OUT      : std_logic_vector(6 downto 0) := "0100000";
    constant OP_IN       : std_logic_vector(6 downto 0) := "0100001";
    constant OP_BRR      : std_logic_vector(6 downto 0) := "1000000";
    constant OP_BRR_N    : std_logic_vector(6 downto 0) := "1000001";
    constant OP_BRR_Z    : std_logic_vector(6 downto 0) := "1000010";
    constant OP_BR       : std_logic_vector(6 downto 0) := "1000011";
    constant OP_BR_N     : std_logic_vector(6 downto 0) := "1000100";
    constant OP_BR_Z     : std_logic_vector(6 downto 0) := "1000101";
    constant OP_BR_SUB   : std_logic_vector(6 downto 0) := "1000110";
    constant OP_RETURN   : std_logic_vector(6 downto 0) := "1000111";

end package constants_package;