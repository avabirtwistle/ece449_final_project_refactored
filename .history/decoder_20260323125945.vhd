library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constant_package.all;

entity decoder is
    port(
        -- from IF/ID
        instruction    : in  std_logic_vector(15 downto 0);

        opcode      : out std_logic_vector(6 downto 0); -- the opcode of the instruction, which will be used by the controller to generate control signals
        ra         : out std_logic_vector(2 downto 0); -- the index of the register to read for operand 1 (for R-type instructions) or the register to read for branch comparison (for branch instructions)
        rb         : out std_logic_vector(2 downto 0); -- the index of the register to read for operand 2 (for R-type instructions)
        rc         : out std_logic_vector(2 downto 0); -- the index of the register to write for R-type instructions
        shift_amount : out std_logic_vector(3 downto 0); -- the amount to shift for shift instructions
        disp_long   : out std_logic_vector(8 downto 0); -- the
        disp_short  : out std_logic_vector(5 downto 0); -- the short displacement for branch instructions
        );
end decoder;

architecture Behavioral of decoder is
    signal opcode      : std_logic_vector(6 downto 0);
    signal destination_reg          : std_logic_vector(2 downto 0);
    signal source_1          : std_logic_vector(2 downto 0);
    signal source_2          : std_logic_vector(2 downto 0);
    signal shift_amount : std_logic_vector(3 downto 0);
    signal disp_long   : std_logic_vector(8 downto 0);
    signal disp_short  : std_logic_vector(5 downto 0);
begin
    opcode <= instruction(15 downto 9); -- the opcode is always the top 7 bits of the instruction, but we will only use the top 4 bits for our instruction set (see constant_package.vhd)
    process(instruction) -- only needs to run when the INSTUCTION changes, but it doesn't matter if it runs more often than that
        begin
            case opcode is 
                when OP_NOP -- format A0
                
                when OP_ADD | OP_SUB | OP_MUL | OP_NAND -- A1 Format
                    destination_reg<= instruction(8 downto 6); -- index for ra
                    source_1<= instruction(5 downto 3); -- index for rb
                    source_2<= instruction(2 downto 0); -- index for rc

                when OP_SHL | OP_SHR -- A2 Format
                    source_1 <= instruction(8 downto 6); -- index for ra
                    destination_reg <= instruction(8 downto 6);
                    shift_amount <= instruction(3 downto 0);

                when OP_TEST | OP_OUT | OP_IN -- A3 Format
                    source_1 <= instruction(8 downto 6); -- index for register we are testing

            -- TODO: how to deal with the PC mode ? signal needs to be sent to fetch stage
                when OP_BRR | OP_BRR_N | OP_BRR_Z -- B1 format
                    disp_long <= instruction(8 downto 0);
                when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB | OP_RETURN -- format b2
                    source_1 <= instruction(8 downto 6);
                    disp_short <= instruction(5 downto 0);
            end case;
    end process;

    opcode <= opcode; -- connect the opcode signal to the output port to pass it to the controller for control signal generation
    ra <= ra; -- connect the ra signal to the output port to pass it to the register file for reading operand 1
    rb <= rb; -- connect the rb signal to the output port to pass it to the
    rc <= rc; -- connect the rc signal to the output port to pass it to the register file for reading operand 2 or writing the result
    shift_amount <= shift_amount; -- connect the shift amount signal to the output port to pass it to the ALU for shift operations
    disp_long <= disp_long; -- connect the long displacement signal to the output port to pass
    disp_short <= disp_short; -- connect the short displacement signal to the output port to pass it to the ALU for branch target calculation
end Behavioral;
