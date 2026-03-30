library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants_package.all;

entity decoder is
    port(
        -- from IF/ID
        instruction    : in  std_logic_vector(15 downto 0);

        opcode      : out std_logic_vector(6 downto 0); -- the opcode of the instruction, which will be used by the controller to generate control signals
        destination_reg : out std_logic_vector(2 downto 0); -- the index of the register to write for R-type instructions
        source_1 : out std_logic_vector(2 downto 0); -- the index of the register to read for operand 1 (for R-type instructions) or the register to read for branch comparison (for branch instructions)
        source_2 : out std_logic_vector(2 downto 0); -- the index of the register to read for operand 2 (for R-type instructions)
        shift_amt : out std_logic_vector(3 downto 0); -- the amount to shift for shift instructions
        disp: out signed(15 downto 0)
        );
end decoder;

architecture Behavioral of decoder is
begin
    process(instruction) -- only needs to run when the INSTUCTION changes, but it doesn't matter if it runs more often than that
        begin
            -- defaults
            opcode <= instruction(15 downto 9);
            destination_reg <= (others => '0');
            source_1        <= (others => '0'); -- the first data source to read
            source_2        <= (others => '0'); -- the second data source to read
            shift_amt    <= (others => '0');
            disp <= (others => '0');
            
            case instruction(15 downto 9) is 
                when OP_NOP => -- format A0
                    NULL;

                -- Format A
                when OP_ADD | OP_SUB | OP_MUL | OP_NAND =>-- A1 Format
                    destination_reg<= instruction(8 downto 6); -- index for ra
                    source_1<= instruction(5 downto 3); -- index for rb
                    source_2<= instruction(2 downto 0); -- index for rc

                when OP_SHL | OP_SHR =>-- A2 Format
                    source_1 <= instruction(8 downto 6); -- index for ra
                    destination_reg <= instruction(8 downto 6);
                    shift_amt <= instruction(3 downto 0);

                when OP_TEST | OP_OUT | OP_IN =>-- A3 Format
                    source_1 <= instruction(8 downto 6); -- index for register we are testing
                
                -- Format B
                when OP_BRR | OP_BRR_N | OP_BRR_Z => -- B1 format
                   disp <= shift_left(resize(signed(instruction(8 downto 0)), 16), 1); -- the displcement amount to add
                
                when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB => -- format b2
                    source_1 <= instruction(8 downto 6); -- index for the register we will add the displacement to
                    disp <= shift_left(resize(signed(instruction(5 downto 0)), 16), 1); -- the displcement amount to add
                
                    if instruction(15 downto 9) = OP_BR_SUB then
                        destination_reg <= LINK_REGISTER;
                    end if;
                
                when OP_RETURN => -- format b3
                    source_1 <= LINK_REGISTER; -- register 7
                
                when others=>
                    null;
            end case;
    end process;
    opcode <= instruction(15 downto 9);
end Behavioral;
