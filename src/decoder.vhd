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
            -- opcode <= instruction(15 downto 9);

            -- Robin Changes Start
            -- Explanation of changes:
            -- 1) Leave opcode driven by the concurrent assignment at the bottom of the file.
            -- 2) Split TEST / OUT / IN into separate cases.
            -- 3) IN writes to destination_reg because bits [8:6] name the register being loaded.
            -- 4) OUT also drives source_2 so the selected register value is available on rd_data2.
            -- Robin Changes End.
            destination_reg <= (others => '0');
            source_1        <= (others => '0'); -- the first data source to read
            source_2        <= (others => '0'); -- the second data source to read
            shift_amt       <= (others => '0');
            disp            <= (others => '0');
            
            case instruction(15 downto 9) is 
                when OP_NOP => -- format A0
                    NULL;

                -- Format A
                when OP_ADD | OP_SUB | OP_MUL | OP_NAND => -- A1 Format
                    destination_reg <= instruction(8 downto 6); -- index for ra
                    source_1        <= instruction(5 downto 3); -- index for rb
                    source_2        <= instruction(2 downto 0); -- index for rc

                when OP_SHL | OP_SHR => -- A2 Format
                    source_1        <= instruction(8 downto 6); -- index for ra
                    destination_reg <= instruction(8 downto 6);
                    shift_amt       <= instruction(3 downto 0);

                -- Robin Changes Start
                -- Explanation of changes:
                -- 1) Add Format L decode support for LOAD, STORE, LOADIMM, and MOV.
                -- 2) LOAD uses bits [8:6] as destination and bits [5:3] as the address register.
                -- 3) STORE uses bits [8:6] as the address register and bits [5:3] as the data register.
                -- 4) LOADIMM builds a value in the link register (R7), so it both reads and writes R7.
                -- 5) MOV copies source register bits [5:3] into destination bits [8:6].
                -- Robin Changes End.
                when OP_LOAD => -- Format L
                    destination_reg <= instruction(8 downto 6);
                    source_1        <= instruction(5 downto 3);

                when OP_STORE => -- Format L
                    source_1 <= instruction(8 downto 6);
                    source_2 <= instruction(5 downto 3);

                when OP_LOADIMM => -- Format L
                    destination_reg <= LINK_REGISTER;
                    source_1        <= LINK_REGISTER;

                when OP_MOV => -- Format L
                    destination_reg <= instruction(8 downto 6);
                    source_1        <= instruction(5 downto 3);

                -- when OP_TEST | OP_OUT |OP_IN => -- A3 Format
                --     source_1 <= instruction(8 downto 6); -- index for register we are testing
                -- --                when OP_IN   => 
                -- --                    destination_reg <= instruction (8 downto 6); -- Changed OP_IN from source_1 to destination register

                -- Robin Changes Start
                -- Explanation of changes:
                -- TEST only needs source_1.
                -- OUT should place the selected register on source_2 as well so it can ride the rd_data2 path.
                -- IN should target destination_reg so the external input gets written into the requested register.
                -- Robin Changes End.
                when OP_TEST => -- A3 Format
                    source_1 <= instruction(8 downto 6); -- index for register we are testing

                when OP_OUT => -- A3 Format
                    source_1 <= instruction(8 downto 6);
                    source_2 <= instruction(8 downto 6);

                when OP_IN => -- A3 Format
                    destination_reg <= instruction(8 downto 6);
                
                -- Format B
                when OP_BRR | OP_BRR_N | OP_BRR_Z | OP_BRR_V => -- B1 format
                   disp <= shift_left(resize(signed(instruction(8 downto 0)), 16), 1); -- the displcement amount to add
                
                when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB => -- format b2
                    source_1 <= instruction(8 downto 6); -- index for the register we will add the displacement to
                    disp <= shift_left(resize(signed(instruction(5 downto 0)), 16), 1); -- the displcement amount to add
                
                    if instruction(15 downto 9) = OP_BR_SUB then
                        destination_reg <= LINK_REGISTER;
                    end if;
                
                when OP_RETURN => -- format b3
                    source_1 <= LINK_REGISTER; -- register 7
                
                when others =>
                    null;
            end case;
    end process;

    opcode <= instruction(15 downto 9);
end Behavioral;
